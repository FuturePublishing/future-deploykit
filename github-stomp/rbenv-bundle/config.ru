require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra'

set :env,  :production
disable :run

require './github-stomp.rb'

run Sinatra::Application
