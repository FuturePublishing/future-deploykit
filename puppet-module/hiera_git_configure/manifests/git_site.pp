define h_git_configure::git_site($repo,$site,$origin,$base_tag,$target) {

  # notify{"Grenk: ${repo} ${site} ${origin} ${base_tag} ${target} : ${name}:":}

  exec{ "git-clone-${repo}":
    user    => www-data,
    group   => www-data,
    cwd     => '/data/repo',
    path    => '/usr/bin',
    command => "git clone ${origin} ${repo}",
    creates => "/data/repo/${repo}/.git/description",
  }

  exec{ "git-checkout-${repo}":
    user    => www-data,
    group   => www-data,
    cwd     => "/data/repo/${repo}",
    path    => '/usr/bin:/bin',
    command => "mkdir /data/deploy/${repo}_${base_tag} && git --work-tree=/data/deploy/${repo}_${base_tag} checkout -f ${base_tag}",
    creates => "/data/deploy/${repo}_${base_tag}",
  }

  exec{ "add-yaml1-${repo}":
    path    => '/usr/bin:/bin',
    command => "echo \"  ${repo}:\n    repo: /data/repo/${repo}\n    mode: normal\n\" >> /etc/stomp-git/stomp-git.yaml",
    unless  => "grep ${repo} /etc/stomp-git/stomp-git.yaml",
    notify  => Service[ 'stomp-git' ],
  }

  exec{ "add-yaml2-${repo}":
    path    => '/usr/bin:/bin',
    command => "echo \"  - name: ${repo}\n    target: ${target}\n    base_tag: ${base_tag}\n\" >> /etc/facts.d/${site}_repos_part",
    unless  => "grep ${repo} /etc/facts.d/${site}_repos_part",
  }

  exec{ "add-yaml3-${repo}":
    path    => '/usr/bin:/bin',
    command => "echo \"controldir: /data/site/${site}/future-control\n\" >> /etc/facts.d/${site}_control_part",
    unless  => "grep ${site} /etc/facts.d/${site}_control_part",
    notify  => Exec["build-yaml-${repo}"],
  }

  exec{ "build-yaml-${repo}":
    path        => '/usr/bin:/bin',
    cwd         => '/etc/facts.d',
    command     => "cat sites_head ${site}_repos_part ${site}_control_part links_head ${site}_links_part > ${site}.yaml",
    refreshonly => true,
  }
}
