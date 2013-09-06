#!/usr/bin/env ruby

require 'rubygems'
require 'syslog'
require 'stomp'
require 'systemu'
require 'optparse'

options = {}

optparse = OptionParser.new do|opts|
  opts.banner = "Usage: auto-reprepro.rb [options]"
 
  options[:debug] = false
  opts.on( '-d', '--debug', 'Much output.' ) do
    options[:debug] = true
  end

  options[:configfile] = "/etc/auto-reprepro.yaml"
    opts.on( '-c', '--config FILE', 'Config is FILE' ) do|file|
      options[:configfile] = file
    end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
        exit
  end
end

optparse.parse!

yconfig = YAML.load_file(options[:configfile])
puts YAML.dump(yconfig) if options[:debug]

Syslog.open('auto-reprepro', Syslog::LOG_CONS, Syslog::LOG_DAEMON)

stompconnector = yconfig["rserver"] + "?" + yconfig["stomp-options"]
report_topic = yconfig["report-topic"]
package_topic = yconfig["package-topic"]
jenkins_projects = yconfig["jenkins-projects"]
distros = yconfig["distro-list"]
incoming = yconfig["incoming-dir"]

client = Stomp::Client.new(stompconnector)

distros.each do |distro|
  dirpath = incoming + distro + "/*.deb"
  puts dirpath.inspect if options[:debug]
  Dir.glob(dirpath) do |pkg|
    commandline = "/usr/bin/reprepro -Vb /var/www/repo includedeb #{distro} #{pkg}"
    status,stdin,stdout = systemu(commandline)
    puts "Result: #{status.inspect}\nStdin: #{stdin.inspect}\nStdout: #{stdout.inspect}"

    packagename = File.basename(pkg)
    archivepkg = incoming + distro + "/archive/" + packagename
    File.rename(pkg,archivepkg)

    subject = "Package update: [#{packagename}]"
    body = "package: #{packagename}\n"
    body << status.inspect + '\n' + stdin.inspect + '\n' + stdout.inspect + '\n'

    eventdetail = "Package #{packagename} / #{distro} added to repository."
    Syslog.info(eventdetail)
    if client
      client.publish("/topic/#{report_topic}",eventdetail, {:subject => "Talking to eventbot"})
      client.publish("/topic/#{package_topic}",body, {:subject => subject})
    end
  end
end

Syslog.close
client.close
