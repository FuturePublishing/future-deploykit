These bits live on the gitolite server.

Post-receive.hook is the actual hook-script. It allows one to cruft in
extra notification types, should one want that sort of thing.

Post-receive-stomp.rb is the ruby job that actually emits the commit messages.

Because we have a firewall that drops what it thinks are idle sessions, and 
because commit messages likely go a bit quiet of a weekend and/or overnight,
we require something to keep the connection up. Stomp does appear to support
a thing called heart-beat, but from limited fiddling, it seems that AMQ, er doesn't.

Thus a nasty cron-job which generates a close facsimile of those messages.
This lives in the stomp-keepalive directory.
