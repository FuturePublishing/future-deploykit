future-deploykit
================

A collection of Ruby daemons flying in close formation. AKA our startling message-based deploy environment.


What?
=====

Weblog-based post-hack rationalisation: http://ops.failcake.net/blog/2012/04/19/one-very-important-thought/

More of the same, containing example Jenkins-plumbing: http://ops.failcake.net/blog/2012/04/19/a-hazelnut-in-every-bite/
 

Why?
====

One-click (more or less. Work with me here...) deploys. Jenkins integration. Standard bus. Devops-meccano.

Pretty pictures
===============

Some diagrams of how it works in practice for us.

Developer commits a change to the master git repo, and a post-commit-hook triggers a message to the queue:

![Developer commits to git repo, message sent to queue](http://slack.org.uk/images/Future-DeployKit/Step_1.png "Step 1")

Jenkins receives the message and runs the appropriate tests, then sends a success or failure message to the queue:

![Jenkins receives message and runs tests](http://slack.org.uk/images/Future-DeployKit/Step_2.png "Step 2")

The success message is received by all the servers that configuration management has told that they should have that code on them:

![Successful build message received by servers](http://slack.org.uk/images/Future-DeployKit/Step_3.png "Step 3")

Servers git fetch the latest changes, so that they always have a local copy of the full repo, to reduce dependencies on the central git server for deploys:

![Servers git fetch from master repo](http://slack.org.uk/images/Future-DeployKit/Step_4.png "Step 4")

Deployment works as follows:

User uses a [lightweight web wrapper](https://github.com/FuturePublishing/deploykit-frontend) to select what tag they want to deploy and to what servers, MCollective client issues a message to the queue:

![User requests deploy via UI, MCollective client sends message](http://slack.org.uk/images/Future-DeployKit/Deploy_1.png "Deploy Step 1")

MCollective agent receives the message, triggers the deploy process, running pre and post deploy scripts:

![MCollective agent receives message, triggers deploy](http://slack.org.uk/images/Future-DeployKit/Deploy_2.png "Deploy Step 2")

Other servers deploy if this succeeds, orchestrated by MCollective:

![Other servers deploy orchestrated by MCollective](http://slack.org.uk/images/Future-DeployKit/Deploy_3.png "Deploy Step 3")

Installation.
=============

Building the mcollective thing: Dump the clients and agent in your mcollective puppet module.
  (On the assumption that you manage your mcollective rig w/puppet.)

Stomp-jenkins: Watch future.git.commits, if a project we care about has been updated, prod Jenkins via HTTP to kick off a build.
  (future.git.commits is one of our own topics. Yours should be different.)

Github-stomp: Sinatra project. Expect a JSON bundle from github. Extract enough bits to generate a repo-update message on $topic.

Stomp-repo: Watch for package-update messages emitted by the Debian package repository. Run apt-get update if a package we're 
  interested in has a new version. (Not quite enough blind trust to install the thing automatically. That's what puppet/mcollective is for.)

Jenkins-helper: Emit status messages on future.jenkins and future.events.jenkins to the effect that a job has started, failed or succeeded.
  (A better way of doing this would be a STOMP plugin for Jenkins, obviously.)

Stomp-git: Watch $topic. If a project we care about had been updated, perform a git fetch on that repo.

	Build: fpm -s dir -t deb -n "stomp-git" -v 2.2 -a all -d "rubygem-systemu" --description "Stomp-listening robot git-updater (Ruby version)" -C ./stomp-git

Systemu is a Beardian module because it makes life more obvious for puppetry.
Generate same with: fpm -s gem -t deb systemu
Yes this should be a rake task.

puppet-module: Git repo management and stomp-git install/setup.

Server-malarkey: Hook scripts for git. Also hook script for SVN. I'm sorry.

Stomp-keepalive: Cheap and nasty stomp heartbeat emulator to keep firewalls happy.
  (STOMP 1.0 doesn't do heartbeats. They're in the 1.1 spec, but implemented in a wonky sort of way
  on the kit we use. So. This is a quick hack to emit heartbeat packets just often enough to stop
  our firewalls from dropping the connection between client and broker. We have a random sort of
  f/w config. Consider yourself lucky if you can't see the need for this.)

