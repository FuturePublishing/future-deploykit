#!/usr/bin/env ruby

# Code I said I'd never write - the SVN post-commit to Stomp-bus emitter.
# Acts like a 'normal' SVN post-commit hook script, but emits messages
# that can be parsed by other tools + eventbot.
# Well, I say 'other tools'. The only one that matters thus far is the
# Jenkins-kicker, which is called stomp-jenkins.
# Install wherever is convenient + config file in /etc/svn-stomp

require 'rubygems'
require 'yaml'
require 'stomp'
require 'syslog'

yconfig = YAML.load_file("/etc/svn-stomp/svn-stomp.yaml")

Syslog.open('svn-stomp', Syslog::LOG_CONS, Syslog::LOG_DAEMON)

stompconnector = yconfig["rserver"] + "?" + yconfig["stomp-options"]
trigger_topic = yconfig["trigger-topic"]
report_topic = yconfig["report-topic"]

SVNLOOK = "/usr/bin/svnlook"
repo = ARGV[0]
rev = ARGV[1]

cdiff = " "
project = ""

Syslog.info("Called with #{repo} / #{rev}")

fname = File.basename(repo)
log_message = `#{SVNLOOK} log #{repo} -r #{rev}`.strip
author = `#{SVNLOOK} author #{repo} -r #{rev}`.strip
committed_date = `#{SVNLOOK} date #{repo} -r #{rev}`.strip
changed_dirs = `#{SVNLOOK} dirs-changed #{repo} -r #{rev}`.strip

changed_dirs.each do |line|
  bob1,bob2 = line.split('/trunk')
  pobble = bob1.split('/')
  project = pobble.last
end

subject = "[#{fname}] #{rev} "

cdiff << "Author: #{author}\nDate: #{committed_date}\nProject: #{project}\n\nDirs:\n#{changed_dirs}\n\n#{log_message}\n"

body = "repo: #{fname}\nrevname: #{rev}\n#{cdiff}\n"

client = Stomp::Client.new(stompconnector)
if client
  Syslog.info(subject)
  client.publish("/topic/#{trigger_topic}",body,{:subject => subject})
  client.publish("/topic/#{report_topic}",subject, {:subject => "Talking to eventbot"})
  client.close
end
Syslog.close
