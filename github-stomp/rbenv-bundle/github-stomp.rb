require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'json'
require 'yaml'
require 'stomp'
require 'syslog'



settings = YAML.load_file("/etc/github-stomp/github-stomp.yaml")

Syslog.open('github-stomp', Syslog::LOG_CONS, Syslog::LOG_DAEMON)

trigger_topic = settings["trigger-topic"]
report_topic = settings["report-topic"]
stompconnector = settings["rserver"] + "?" + settings["stomp-options"]


post '/' do
  push = JSON.parse(params[:payload])
# puts "I got some JSON: #{push.inspect}"


  reponame = push["repository"]["name"]
  oldrev = push["before"]
  newrev = push["after"]
  refname = push["ref"]

  subject = "[#{reponame}] #{refname} #{newrev}"
  body = "repo: #{reponame}\noldrev: #{oldrev}\nnewrev: #{newrev}\nrefname: #{refname}\n"

  push["commits"].each do |flob|
    body2 = " commit #{flob["id"]}\nAuthor: #{flob["author"]["email"]}\nDate: #{flob["timestamp"]}\n\t#{flob["message"]}\n\n"
    body.concat(body2)
  end

  client = Stomp::Client.new(stompconnector)
  if client
    Syslog.info("Connected to #{trigger_topic}")
    client.publish("/topic/#{trigger_topic}",body, {:subject => subject})
    eventdetail = "Triggered fetch from Github: #{subject}"
    client.publish("/topic/#{report_topic}",eventdetail, {:subject => "Talking to eventbot"})
    Syslog.info("Pushed change: %s",subject)
    client.close
  end

#               puts "Subject: #{subject}"
#               puts "Body: #{body}"
end
