class h_git_configure::package {

  package{ 'git' : ensure => present }
  package{ 'stomp-git' : ensure => present }

  file{ '/var/www/.ssh/id_dsa':
    owner   => www-data,
    group   => www-data,
    mode    => '0400',
    source  => 'puppet:///modules/h_git_configure/www-data.privkey',
    require => File['/var/www/.ssh'],
  }

  file{ '/etc/facts.d/sites_head':
    owner   => root,
    group   => root,
    mode    => '0400',
    source  => 'puppet:///modules/h_git_configure/sites_head',
  }

  file{ '/etc/facts.d/links_head':
    owner   => root,
    group   => root,
    mode    => '0400',
    source  => 'puppet:///modules/h_git_configure/links_head',
  }

  file{ '/var/www/.ssh':
    ensure  => directory,
    owner   => www-data,
    group   => www-data,
    mode    => '0700',
  }

  # You will likely need to change the target git-host here.
  # It should be a variable and I am aware that I have used as much brain
  # in documenting it as I might have used in fixing it. Pobol-y-cwm.
  exec{ 'prime-ssh-key-www-data':
    user    => www-data,
    path    => '/usr/bin:/bin',
    command => 'ssh-keyscan git.future.net.uk >> /var/www/.ssh/known_hosts',
    unless  => 'grep git\.future\.net\.uk /var/www/.ssh/known_hosts',
    require => File [ '/var/www/.ssh/id_dsa' ],
  }

}
