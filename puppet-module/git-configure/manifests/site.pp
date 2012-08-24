define git-configure::site( $site = 'doin-it-rong', $repo = 'spog', $rootdir = '/data' )
{
	motd::register{"git-configure::site: ${site}":}

	package{ "git" : ensure => present }
	package{ "stomp-git" : ensure => present } 

	file{ "/var/www/.ssh/id_dsa":
		owner   => www-data,
        	group   => www-data,
        	mode    => 400,
        	source  => "puppet:///modules/git-configure/www-data.privkey",
        	require => File["/var/www/.ssh"],
	}

	file{ "/var/www/.ssh":
		ensure 	=> directory,
                owner   => www-data,
                group   => www-data,
                mode    => 700, 
        }

	file{ "${rootdir}/${site}":
                ensure  => directory,
                owner   => www-data,
                group   => www-data,
                mode    => 755,
        }
	
	file{ "${rootdir}/repo":
                ensure  => directory,
                owner   => www-data,
                group   => www-data,
                mode    => 755,
        }
	
	file{ "${rootdir}/repo/${site}":
                ensure  => directory,
                owner   => www-data,
                group   => www-data,
                mode    => 755,
        }

	exec{ "git-clone-${repo}":
		user	=> "www-data",
		cwd	=> "${rootdir}/repo",
		path	=> "/usr/bin",
		command	=> "git clone git@git.future.net.uk:${repo} ${site}",
		creates	=> "${rootdir}/${site}/.git/description",
		require	=> [ Package[ "git" ], File[ "${rootdir}/${site}" ], File[ "/var/www/.ssh/id_dsa" ] ],
	}

	exec{ "prime-ssh-key-${repo}":
		user	=> "www-data",
		path	=> "/usr/bin:/bin",
		command	=> "ssh-keyscan git.future.net.uk >> /var/www/.ssh/known_hosts",
		unless	=> "grep \"git.future.net.uk\" /var/www/.ssh/known_hosts",
		before	=> File[ "/var/www/.ssh/id_dsa" ],
	}

	exec{ "add-yaml1-${repo}":
		path	=> "/usr/bin:/bin",
		command	=> "echo ${repo}: ${rootdir}/repo/${site} >> /etc/stomp-git/stomp-git.yaml",
		unless	=> "grep ^${repo} /etc/stomp-git/stomp-git.yaml",
		require	=> Package[ "stomp-git" ],
		notify	=> Service[ "stomp-git" ],
	}

	exec{ "add-yaml2-${repo}":
                path    => "/usr/bin:/bin",
                command => "echo repo_${repo}: ${rootdir}/repo/${site} >> /etc/facts.d/facts.yaml",
                unless  => "grep ^repo_${repo} /etc/facts.d/facts.yaml",
                require => Package[ "stomp-git" ],
                notify  => Service[ "stomp-git" ],
        }

	exec{ "add-yaml3-${repo}":
                path    => "/usr/bin:/bin",
                command => "echo sitedir_${repo}: ${rootdir}/${site} >> /etc/facts.d/facts.yaml",
                unless  => "grep ^sitedir_${repo} /etc/facts.d/facts.yaml",
                require => Package[ "stomp-git" ],
                notify  => Service[ "stomp-git" ],
        }

	exec{ "add-yaml4-${repo}":
                path    => "/usr/bin:/bin",
                command => "echo controldir_${repo}: ${rootdir}/repo/${site}/future-control >> /etc/facts.d/facts.yaml",
                unless  => "grep ^controldir_${repo} /etc/facts.d/facts.yaml",
                require => Package[ "stomp-git" ],
                notify  => Service[ "stomp-git" ],
        }

	service{ "stomp-git":
		ensure	=> running,
		require => Package[ "stomp-git" ],
	}
}
