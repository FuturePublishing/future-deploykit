#!/usr/bin/perl -w

use strict;
use Cwd;
use File::Basename;
use Net::STOMP::Client;

my($stomp,$peer,$oldrev,$newrev,$refname,$subject,$body,$inline,$s,$dir);
my($fname,$fpath,$suffix);

while ( $inline=<STDIN> ) 
{
  chomp($inline);
  ($oldrev,$newrev,$refname) = split(/ /,$inline,3);

  if ($oldrev eq "0000000000000000000000000000000000000000")
  {
    $s = "\nNew branch $refname\n";
  }
  elsif ($newrev eq "0000000000000000000000000000000000000000")
  {
        $s = "\nDelete branch $refname\n";
  } 
  else
  {
    $s = qx(git log --reverse -r $oldrev..$newrev);
  }

  $dir = cwd();
  ($fname,$fpath,$suffix) = fileparse($dir,'\.git');

  $subject = "[$fname] $refname $newrev";
  $body = "repo: $fname\noldrev: $oldrev\nnewrev: $newrev\nrefname: $refname\n $s\n";

  $stomp = Net::STOMP::Client->new(uri => "stomp://broker01:61613");

  $peer = $stomp->peer();

  $stomp->connect( login => "gituser", passcode => "gitpw");

  $stomp->send( destination => "/topic/future.git.commits", subject => $subject, time => time(), body => $body);
  $stomp->send( destination => "/topic/future.events.gitolite", subject => "Talking to eventbot", time => time(), body => $subject);

  $stomp->disconnect();
}

#if (open(OUTFILE,">>/var/log/stomp-rx-git.log"))
#{
# print OUTFILE "$subject\n$body\n";
#}
#close(OUTFILE);
