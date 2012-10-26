Usage:

include h_git_configure

In a relevant part of your hiera tree:

  gitconfigure:
    bleng1:
      site: www.blah.com
      repo: wormpress
      origin: 'git@git.future.net.uk:wormpress'
      base_tag: 3.4.1-future
      target: 'www.blah.com'
    bleng2:
      site: www.blah.com
      repo: repo-name
      origin: 'git@git.future.net.uk:repo-name'
      base_tag: 3.4.9.1
      target: 'www.blah.com/my-repo-goes-here'

... Where the blengs are placeholders to make create_resources work.

As part of the setup, it installs a perl daemon called stomp-git, which waits for
traffic about (repo) on future.git.commits. The repo and site-dir are written into
the YAML config file (/etc/stomp-git/stomp-git.yaml) by the puppet code.

Patches welcome.
