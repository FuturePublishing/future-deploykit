module MCollective
  module Agent
    class Gitagent<RPC::Agent

      require 'yaml'
      require 'stomp'
      require 'syslog'
      require 'socket'
      
      activate_when do
        File.exists?("/etc/facts.d/facts.yaml")
      end

      def create_id
        request.data[:request_id] = Digest::MD5.hexdigest request.data[:repo] + " " + request.data[:tag] + " " + "#{Time.now.to_i}"
      end

      action "git_tag" do
        validate :repo, String

        rconfig = YAML.load_file("/etc/facts.d/facts.yaml")
        lrepo = rconfig["repo_#{request[:repo]}"]
        reply[:lrep] = lrepo

        count = request.data.fetch(:count) { nil }
        if count
          validate :count, Fixnum
          reply[:status] = run("/usr/bin/git for-each-ref --format '%(refname)' --sort=-taggerdate --count=#{count} refs/tags", :stdout => :out, :stderr => :err, :cwd => lrepo, :chomp => true)
          reply[:tstatus] = reply[:status]
          reply[:tout] = reply[:out]

          reply[:status] = run("/usr/bin/git for-each-ref --format '%(refname)' --sort=-committerdate --count=#{count} refs/", :stdout => :out, :stderr => :err, :cwd => lrepo, :chomp => true)
          reply[:bstatus] = reply[:status]
          reply[:bout] = reply[:out]
        else
          reply[:status] = run("/usr/bin/git tag", :stdout => :out, :stderr => :err, :cwd => lrepo, :chomp => true)
          reply[:tstatus] = reply[:status]
          reply[:tout] = reply[:out]

          reply[:status] = run("/usr/bin/git branch -a", :stdout => :out, :stderr => :err, :cwd => lrepo, :chomp => true)
          reply[:bstatus] = reply[:status]
          reply[:bout] = reply[:out]
        end
      end
  
      action "git_checkout" do
        validate :repo, String
        validate :tag, String

        create_id if request.data[:request_id] == nil

        stompconfig = "/usr/share/mcollective/plugins/mcollective/agent/git-agent.yaml"

        host_name = Socket::gethostname
        rconfig = YAML.load_file("/etc/facts.d/facts.yaml")

        lrepo = rconfig["repo_#{request[:repo]}"]
        lsite = rconfig["sitedir_#{request[:repo]}"]
        sitetype = rconfig["sitetype_#{request[:repo]}"]
        wdir = rconfig["controldir_#{request[:repo]}"] 
        precmd = wdir + "/pre-deploy.sh"
        postcmd = wdir + "/post-deploy.sh"

        reply[:lrep] = lrepo
        reply[:lsit] = lsite
        reply[:trub1] = precmd
        reply[:trub2] = postcmd


        deploylog = "MC gitagent deploy tag #{request[:tag]} on #{Time.now}"
        Log.info(deploylog)
        
        if File.exists?(precmd) and File.executable?(precmd)
          reply[:status] = run("#{precmd} -t #{request[:tag]}", :stdout => :out, :stderr => :err, :cwd => wdir, :chomp => true)
          reply[:prstat] = reply[:status]
          reply[:prout] = reply[:out]
          reply[:prerr] = reply[:err]

          deploylog = "Pre-deploy status: #{reply[:status]} stdout: #{reply[:out]} stderr: #{reply[:err]}"
          Log.info(deploylog)

          if  reply[:prstat] == 0
            reply[:status] = run("/bin/su - www-data -c \"cd #{lrepo} && /usr/bin/git --work-tree=#{lsite} checkout -f #{request[:tag]}\"", :stdout => :out, :stderr => :err, :cwd => lrepo, :chomp => true)
            reply[:dstat] = reply[:status]
            reply[:dout] = reply[:out]
            reply[:derr] = reply[:err]

            deploylog = "git-command status: #{reply[:status]} stdout: #{reply[:out]} stderr: #{reply[:err]}"
            Log.info(deploylog)

            if reply[:dstat] == 0
              if File.exists?(postcmd) and File.executable?(postcmd)
                reply[:status] = run("#{postcmd} -t #{request[:tag]}", :stdout => :out, :stderr => :err, :cwd => wdir, :chomp => true)
                deploylog = "Post-deploy status: #{reply[:status]} stdout: #{reply[:out]} stderr: #{reply[:err]}"
                Log.info(deploylog)
                eventdetail = "git-agent on #{host_name} checked out tag #{request[:tag]} from repo #{lrepo} to target #{lsite} request id #{request[:request_id]} type #{sitetype}"
                Log.info(eventdetail)

                if File.exists?(stompconfig)
                  sconfig = YAML.load_file(stompconfig)
                  stompconnector = sconfig["rserver"] + "?" + sconfig["stomp-options"]

                  report_topic = sconfig["report-topic"]
                  sclient = Stomp::Client.new(stompconnector)
                  if sclient
                    sclient.publish("/topic/#{report_topic}",eventdetail, {:subject => "Talking to eventbot"})
                    sclient.close
                  end
                end
              else
                reply[:status] = 1
                reply[:out] = ""
                reply[:err] = "File '#{postcmd}' does not exist or is not executable"
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

