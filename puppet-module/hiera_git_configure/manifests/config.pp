class h_git_configure::config {

  $site = hiera('gitconfigure')

  create_resources('h_git_configure::git_site',$site)
}
