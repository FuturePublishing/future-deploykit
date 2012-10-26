class h_git_configure::service {
    
  service{ 'stomp-git':
    ensure  => running,
    require => Package[ 'stomp-git' ],
  } 
}
