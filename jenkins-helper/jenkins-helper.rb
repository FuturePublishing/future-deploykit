#!/usr/bin/ruby 

require 'rubygems'
require 'yaml'
require 'stomp'
require 'syslog'
require 'optparse'

 
options = {}
 
optparse = OptionParser.new do|opts|
	opts.banner = "Usage: jenkins-helper.rb [options]"
 
	options[:debug] = false
	opts.on( '-d', '--debug', 'Much output, do not detach' ) do
		options[:debug] = true
	end
	
	options[:begin] = false
        opts.on( '-b', '--begin', 'Report start of Jenkins job.' ) do
                options[:begin] = true
        end

	options[:profit] = false
        opts.on( '-p', '--profit', 'Jenkins job reports success!' ) do
                options[:profit] = true
        end

	options[:cake] = false
        opts.on( '-c', '--cake', 'Jenkins job comedy blamestorm!' ) do
                options[:cake] = true
        end
 
	opts.on( '-h', '--help', 'Display this screen' ) do
		puts opts
     		exit
	end
end

optparse.parse!


puts "DEBUG" if options[:debug]

flob = YAML.load_file("/etc/jenkins-helper/jenkins-helper.yaml")

puts YAML.dump(flob) if options[:debug]

Syslog.open('jenkins-helper', Syslog::LOG_CONS, Syslog::LOG_DAEMON)

client = Stomp::Client.new("#{flob["rserver"]}")

if client
	standardsubject = "job #{ENV['BUILD_NUMBER']} - [#{ENV['JOB_NAME']}] #{ENV['GIT_BRANCH']} #{ENV['GIT_COMMIT']}"
	eventdetail = standardsubject

	if options[:begin]
		eventdetail = "Begin " + standardsubject
		status = "Start job"
	end

	if options[:profit]
		eventdetail = "Complete " + standardsubject
		status = "Success"
	end

	if options[:cake]
		eventdetail = "Fail " + standardsubject
		status = "Cake"
	end

	body = "Repo: #{ENV['JOB_NAME']}\nURL: #{ENV['BUILD_URL']}\nStatus: #{status}\n"

	Syslog.info(eventdetail)
	client.publish("/topic/future.jenkins",body, {:subject => eventdetail})
	client.publish("/topic/future.events.jenkins",eventdetail, {:subject => "Talking to eventbot"})

	client.close
end
