#!/usr/bin/env ruby

require 'rubygems'
require 'grit'
require 'yaml'
require 'stomp'
require 'syslog'

yconfig = YAML.load_file("/etc/stomp-postrec/stomp-postrec.yaml")

Syslog.open('stomp-postrec', Syslog::LOG_CONS, Syslog::LOG_DAEMON)

stompconnector = yconfig["rserver"] + "?" + yconfig["stomp-options"]
trigger_topic = yconfig["trigger-topic"]
report_topic = yconfig["report-topic"]

cdiff = " "

while msg = gets
  msg.chomp!
  old_sha, new_sha, ref = msg.split(' ', 3)

  # Syslog.info("Called with #{old_sha} / #{new_sha} / #{ref}")

  rdir = Dir.pwd
  fname = File.basename(rdir,".git")
  repo = Grit::Repo.new(rdir)

  # Syslog.info("Working dir #{rdir} / repo name #{fname}")

  if repo
    commit = repo.commit(new_sha)
    sref = ref.chomp

    subject = "[#{fname}] #{sref} #{new_sha}"

    cdiff << "#{new_sha}\nAuthor: #{commit.author}\nDate: #{commit.committed_date}\n\n#{commit.message}\n"

    body = "repo: #{fname}\noldrev: #{old_sha}\nnewrev: #{new_sha}\nrefname: #{sref}\n#{cdiff}\n"

    client = Stomp::Client.new(stompconnector)
    if client
      Syslog.info(subject)
      client.publish("/topic/#{trigger_topic}",body,{:subject => subject})
      client.publish("/topic/#{report_topic}",subject, {:subject => "Talking to eventbot"})
      client.close
    end
  else
    Syslog.info("Can't create grit instance for repo #{fname}")
  end
end
Syslog.close
