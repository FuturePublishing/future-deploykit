module MCollective
  module Agent
    class Gitagent<RPC::Agent

      require 'yaml'
      require 'stomp'
      require 'syslog'
      require 'socket'
      
      metadata :name        => "Git agent",
        :description => "Git agent",
        :author      => "JHR",
        :license     => "BSD",
        :version     => "0.4",
        :url         => "https://github.com/futureus/future-deploykit",
        :timeout     => 60

      activate_when do
        File.exists?("/etc/facts.d/facts.yaml")
      end

      action "git_tag" do
        validate :repo, String

        rconfig = YAML.load_file("/etc/facts.d/facts.yaml")
        lrepo = rconfig["repo_#{request[:repo]}"]
        reply[:lrep] = lrepo
        reply[:status] = run("/usr/bin/git tag", :stdout => :out, :stderr => :err, :cwd => lrepo, :chomp => true)
        reply[:tstatus] = reply[:status]
        reply[:tout] = reply[:out]

        reply[:status] = run("/usr/bin/git branch -a", :stdout => :out, :stderr => :err, :cwd => lrepo, :chomp => true)
        reply[:bstatus] = reply[:status]
        reply[:bout] = reply[:out]
      end
  
      action "git_checkout" do
        validate :repo, String
        validate :tag, String

        rconfig = YAML.load_file("/etc/facts.d/facts.yaml")
        sconfig = YAML.load_file("/etc/git-agent/git-agent.yaml")
        host_name = Socket::gethostname

        Syslog.open('git-agent', Syslog::LOG_CONS, Syslog::LOG_DAEMON)
        stompconnector = sconfig["rserver"] + "?" + sconfig["stomp-options"]

        sclient = Stomp::Client.new(stompconnector)
        if sclient.nil?
          Syslog.info("Can't connect to stomp server.")
        end
        report_topic = sconfig["report-topic"]

        lrepo = rconfig["repo_#{request[:repo]}"]
        lsite = rconfig["sitedir_#{request[:repo]}"]
        wdir = rconfig["controldir_#{request[:repo]}"] 
        precmd = wdir + "/pre-deploy.sh"
        postcmd = wdir + "/post-deploy.sh"

        reply[:lrep] = lrepo
        reply[:lsit] = lsite
        reply[:trub1] = precmd
        reply[:trub2] = postcmd
        
        if File.exists?(precmd) and File.executable?(precmd)
          reply[:status] = run("#{precmd} -t #{request[:tag]}", :stdout => :out, :stderr => :err, :cwd => wdir, :chomp => true)
          reply[:prstat] = reply[:status]
          reply[:prout] = reply[:out]
          reply[:prerr] = reply[:err]

          if  reply[:prstat] == 0
            reply[:status] = run("/bin/su - www-data -c \"cd #{lrepo} && /usr/bin/git --work-tree=#{lsite} checkout -f #{request[:tag]}\"", :stdout => :out, :stderr => :err, :cwd => lrepo, :chomp => true)
            reply[:dstat] = reply[:status]
            reply[:dout] = reply[:out]
            reply[:derr] = reply[:err]

            if reply[:dstat] == 0
              if File.exists?(postcmd) and File.executable?(postcmd)
                reply[:status] = run("#{postcmd} -t #{request[:tag]}", :stdout => :out, :stderr => :err, :cwd => wdir, :chomp => true)
                if sclient
                  eventdetail = "git-agent on #{host_name} checked out tag #{request[:tag]} from repo #{lrepo} to target #{lsite}"
                  Syslog.info(eventdetail)
                  sclient.publish("/topic/#{report_topic}",eventdetail, {:subject => "Talking to eventbot"})
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
        Syslog.close
      end
    end
  end
end

