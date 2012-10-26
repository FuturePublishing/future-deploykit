module MCollective
  module Agent
    class Bloatagent<RPC::Agent

      require 'yaml'
      require 'stomp'
      require 'socket'
      
      metadata  :name        => "Bloat agent",
                :description => "Bloat agent",
                :author      => "JHR",
                :license     => "BSD",
                :version     => "0.5",
                :url         => "https://github.com/futureus/deploybot-40k",
                :timeout     => 60


      def create_id
        request.data[:request_id] = Digest::MD5.hexdigest request.data[:repo] + " " + request.data[:tag] + " " + "#{Time.now.to_i}"
      end

# Emit list of tags and branches for repo :repo belonging to site :site
# The file (site).yaml is generated as part of the puppet install
      action "git_tag" do
        validate :repo, String
        validate :site, String

        sitedata = YAML.load_file("/etc/facts.d/#{request[:site]}.yaml")
        repodir = sitedata["repo-root"]
        lrepo = repodir + "/" + request[:repo]

        reply[:lrep] = lrepo
        reply[:status] = run("/usr/bin/git tag", :stdout => :out, :stderr => :err, :cwd => lrepo, :chomp => true)
        reply[:tstatus] = reply[:status]
        reply[:tout] = reply[:out]

        reply[:status] = run("/usr/bin/git branch -a", :stdout => :out, :stderr => :err, :cwd => lrepo, :chomp => true)
        reply[:bstatus] = reply[:status]
        reply[:bout] = reply[:out]
      end

# Generate link-farm for :site from the (site).yaml file.
# You should only need to run this once, after puppet has installed
# and checked out the repos that make up the site. Doing it here
# rather than in puppet avoids the accidental reversion of a site to
# baseline state, which might be a Bad Thing. It would be a Bad Idea to
# expose this command to any web-based deploy tool.
      action "build_site" do
        validate :site, String

        sitedata = YAML.load_file("/etc/facts.d/#{request[:site]}.yaml")
        repodir = sitedata["repo-root"]
        deploydir = sitedata["deploy-root"]
        userdir = sitedata["user-root"]
        sitedir = sitedata["site-root"]
        repos = sitedata["repo-list"]
        userdata = sitedata["directorymap"]

        bstatus = "Bloatagent build site #{request[:site]}.\n\nRepos:\n"

        repos.each do |repo|
          rtarg = repo["target"]
          rname = repo["name"]
          rtag = repo["base_tag"]

          source = "#{deploydir}/#{rname}_#{rtag}"
          target = "#{sitedir}/#{rtarg}"

          if File.symlink?(target)
            gronk = File.unlink(target)
            bstatus << " Unlinked #{target}.\n" if gronk
          end
          File.symlink(source,target)
          bstatus << " Linked #{source} to #{target}.\n"
        end

        bstatus << "\nUserdata:\n"

        userdata.each do |udir|
          utarg = udir["target"]
          usource = udir["source"]


          source = "#{userdir}/#{usource}"
          target = "#{sitedir}/#{request[:site]}/#{utarg}"

          if File.symlink?(target)
            gronk = File.unlink(target)
            bstatus << " Unlinked #{target}.\n" if gronk
          end
          File.symlink(source,target)
          bstatus << " Linked #{source} to #{target}.\n"
        end
        reply[:status] = bstatus
        Log.info(bstatus)
      end

# Checkout given tag from repo and rebuild site on the expectation
# that the softlinks will now be in disarray.

      action "git_checkout" do
        validate :repo, String
        validate :tag, String
        validate :site, String

        create_id if request.data[:request_id] == nil
        sitedata = YAML.load_file("/etc/facts.d/#{request[:site]}.yaml")
        sconfig = YAML.load_file("/etc/git-agent/git-agent.yaml")
        host_name = Socket::gethostname

# sitedata is the puppet-generated site config file. On the expectation that there'll
# be more than one site per target and you could, if you wanted, give them very different configs.
# Although that'll bite you in the arse if you try it right now.
# I suspect the control-dir bits from facts.yaml might be better folded into the site config.

        stompconnector = sconfig["rserver"] + "?" + sconfig["stomp-options"]

        sclient = Stomp::Client.new(stompconnector)
        if sclient.nil?
          Log.info("Problem: can't connect to stomp server.")
        end
        report_topic = sconfig["report-topic"]

        repodir = sitedata["repo-root"]
        deploydir = sitedata["deploy-root"]
        sitedir = sitedata["site-root"]
        repolist = sitedata["repo-list"]
        udirlist = sitedata["directorymap"]
        userdir = sitedata["user-root"]
        wdir = sitedata["controldir"]

        lrepo =  repodir + "/" + request[:repo]
        deploytarget = deploydir + "/" + request[:repo] + "_" + request[:tag]
        Dir.mkdir(deploytarget) if !File.exists?(deploytarget)
        # File.chown(33,33,deploytarget)
# git --work-tree doesn't create the target, er work-tree. Or maybe it does and I can't read man pages.
# Chowning it to www-data:www-data is probably a waste of time. Let's find out...
# Oh. And. I wonder if there's a requirement for an extra shellscript between checkout and re-link?

        precmd = wdir + "/pre-deploy.sh"
        postcmd = wdir + "/post-deploy.sh"
        prelinkcmd = wdir + "/pre-link.sh"

        reply[:lrep] = lrepo
        reply[:lsit] = deploytarget
        reply[:trub1] = precmd
        reply[:trub2] = postcmd
        reply[:trub3] = prelinkcmd

        deploylog = "MC bloatagent deploy tag #{request[:tag]} request id #{request[:request_id]} on #{Time.now}"
        Log.info(deploylog)
        
# I'm not sure I care for the massive cascade of tests here. There's going to be a better way.
# Pre-deploy shellscript.
        if File.exists?(precmd) and File.executable?(precmd)
          reply[:status] = run("#{precmd} -t #{request[:tag]}", :stdout => :out, :stderr => :err, :cwd => wdir, :chomp => true)
          reply[:prstat] = reply[:status]
          reply[:prout] = reply[:out]
          reply[:prerr] = reply[:err]

          deploylog = "Pre-deploy status: #{reply[:status]} stdout: #{reply[:out]} stderr: #{reply[:err]}"
          Log.info(deploylog)

# If that worked, then yer actual deploy.
          if  reply[:prstat] == 0
            reply[:status] = run("cd #{lrepo} && /usr/bin/git --work-tree=#{deploytarget} checkout -f #{request[:tag]}", :stdout => :out, :stderr => :err, :cwd => lrepo, :chomp => true)
            # reply[:status] = run("/bin/su - www-data -c \"cd #{lrepo} && /usr/bin/git --work-tree=#{deploytarget} checkout -f #{request[:tag]}\"", :stdout => :out, :stderr => :err, :cwd => lrepo, :chomp => true)
            reply[:dstat] = reply[:status]
            reply[:dout] = reply[:out]
            reply[:derr] = reply[:err]

            deploylog = "git-command status: #{reply[:status]} stdout: #{reply[:out]} stderr: #{reply[:err]}"
            Log.info(deploylog)

# And if *that* worked, the pre-link shellscript.
            if reply[:dstat] == 0
              if File.exists?(prelinkcmd) and File.executable?(prelinkcmd)
                reply[:status] = run("#{prelinkcmd} -t #{request[:tag]}", :stdout => :out, :stderr => :err, :cwd => wdir, :chomp => true)
                reply[:plstat] = reply[:status]
                reply[:plout] = reply[:out]
                reply[:plerr] = reply[:err]

                deploylog = "Pre-link status: #{reply[:status]} stdout: #{reply[:out]} stderr: #{reply[:err]}"
                Log.info(deploylog)

# Then if that worked too, the actual re-linking of the site.
#                
# This atomic malarkey made sense at the time. Honest.
# By and large, the web-tree is generated from a pile of checked-out git repositories and 
# as many not-git-managed user content dirs as required. In theory, quick to update and easy to roll back.
                if reply[:plstat] == 0 
                  bstatus = "Bloatagent softlinks for #{request[:site]}.\n\nRepos:\n"
                  spog = Hash.new { |hash, key| hash[key] = {} }

                  repolist.each do |repol|
                    rtarg = repol["target"]
                    rname = repol["name"]

                    linktarget = "#{sitedir}/#{rtarg}"
                    existinglink = File.readlink(linktarget)

                    spog[rname]["linktarget"] = linktarget
                    spog[rname]["linksource"] = existinglink
                  end
# Cruft in the new tag we've just checked out.
                  spog[lrepo]["linksource"] = deploytarget

# Iterating through the from-yaml data again preserves the ordering, which is important in the specific
# Wordpress case where the plugins dir is a child of the WP item. Imagine the fun if WP gets upgraded
# and all the links go away...
                  repolist.each do |repol|
                    rname = repol["name"]
                    lsource = spog[rname]["linksource"]
                    ltarget = spog[rname]["linktarget"]

                    gronk = File.unlink(ltarget)
                    bstatus << " Unlinked #{ltarget}.\n" if gronk
                    File.symlink(lsource,ltarget)
                    bstatus << " Linked #{lsource} to #{ltarget}.\n"
                  end

                  bstatus << "\nUserdata:\n"

                  udirlist.each do |udir|
                    utarg = udir["target"]
                    usource = udir["source"]

                    source = "#{userdir}/#{usource}"
                    target = "#{sitedir}/#{request[:site]}/#{utarg}"

                    gronk = File.unlink(target)
                    bstatus << " Unlinked #{target}.\n" if gronk
                    File.symlink(source,target)
                    bstatus << " Linked #{source} to #{target}.\n\n"
                  end
                  reply[:bstatus] = bstatus
                  Log.info(bstatus)
    
                  if File.exists?(postcmd) and File.executable?(postcmd)
                    reply[:status] = run("#{postcmd} -t #{request[:tag]}", :stdout => :out, :stderr => :err, :cwd => wdir, :chomp => true)
                    deploylog = "Post-deploy status: #{reply[:status]} stdout: #{reply[:out]} stderr: #{reply[:err]}"
                    Log.info(deploylog)
                    if sclient
                      eventdetail = "bloatagent on #{host_name} checked out tag #{request[:tag]} from repo #{lrepo} to target #{deploytarget} request id #{request[:request_id]}"
                      sclient.publish("/topic/#{report_topic}",eventdetail, {:subject => "Talking to eventbot"})
                    end
                  else
                    reply[:status] = 1
                    reply[:out] = ""
                    reply[:err] = "File '#{postcmd}' does not exist or is not executable"
                  end
                end
              else
                reply[:plstat] = 1
                reply[:plout] = ""
                reply[:plerr] = "File '#{prelinkcmd}' does not exist or is not executable"
              end
            end
          end
        else
          reply[:prstat] = 1
          reply[:prout] = ""
          reply[:prerr] = "File '#{precmd}' does not exist or is not executable"
        end
      end
    end
  end
end
