future-deploykit
================

A collection of Ruby daemons flying in close formation. AKA our startling message-based deploy environment.

Building the mcollective thing: Dump the clients and agent in your mcollective puppet module.
  (On the assumption that you manage your mcollective rig w/puppet.)

Stomp-jenkins: Watch future.git.commits, if a project we care about has been updated, prod Jenkins via HTTP to kick off a build.
  (future.git.commits is one of our own topics. Yours should be different.)

Github-stomp: Sinatra project. Expect a JSON bundle from github. Extract enough bits to generate a repo-update message on $topic.

Jenkins-helper: Emit status messages on future.jenkins and future.events.jenkins to the effect that a job has started, failed or succeeded.
  (A better way of doing this would be a STOMP plugin for Jenkins, obviously.)

Stomp-git: Watch $topic. If a project we care about had been updated, perform a git fetch on that repo.

	Build: fpm -s dir -t deb -n "stomp-git" -v 2.2 -a all -d "rubygem-systemu" --description "Stomp-listening robot git-updater (Ruby version)" -C ./stomp-git

Systemu is a Beardian module because it makes life more obvious for puppetry.
Generate same with: fpm -s gem -t deb systemu
Yes this should be a rake task.

puppet-module: Git repo management and stomp-git install/setup.

Server-malarkey: Hook scripts for git.

Stomp-keepalive: Cheap and nasty stomp heartbeat emulator to keep firewalls happy.
  (STOMP 1.0 doesn't do heartbeats. They're in the 1.1 spec, but implemented in a wonky sort of way
  on the kit we use. So. This is a quick hack to emit heartbeat packets just often enough to stop
  our firewalls from dropping the connection between client and broker. We have a random sort of
  f/w config. Consider yourself lucky if you can't see the need for this.)

