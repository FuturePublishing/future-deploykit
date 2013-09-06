These bits live on the git server.
(Or the SVN server, now there's a Subversion, er, version.)
(Or yea even the Debian repository server...)

**Post-receive.hook** is the actual hook-script. It allows one to cruft in
extra notification types, should one want that sort of thing.

**Post-receive-stomp.rb** is the ruby job that actually emits the commit messages.
**stomp-postrec.yaml** Config file.

**svn-stomp.rb** SVN post-commit hook script. Expects parameters per the post-commit email script.
**svn-stomp.yaml** Config file for above.

**auto-reprepro.rb** Run this from cron. Manages an incoming-repo directory tree. Emits messages.
**auto-reprepro.yaml** Config file.

Because we have a firewall that drops what it thinks are idle sessions, and 
because commit messages likely go a bit quiet of a weekend and/or overnight,
we require something to keep the connection up. Stomp does appear to support
a thing called heart-beat, but from limited fiddling, it seems that AMQ, er doesn't.

Thus a nasty cron-job which generates a close facsimile of those messages.
This lives in the stomp-keepalive directory.
