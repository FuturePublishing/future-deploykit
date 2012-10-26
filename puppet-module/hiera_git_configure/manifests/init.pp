class h_git_configure {
  anchor { 'h_git_configure::start': } ->
  class { 'h_git_configure::package': } ~>
  class { 'h_git_configure::config': } ~>
  class { 'h_git_configure::service': } ~>
  anchor { 'h_git_configure::end': }
}
