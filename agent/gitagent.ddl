metadata    :name        => "gitagent",
            :description => "Git agent",
            :author      => "JHR",
            :license     => "BSD",
            :version     => "0.4",
            :url         => "https://github.com/futureus/deploybot-40k",
            :timeout     => 60

action "git_tag", :description => "Retrieve tag and branch info" do
    input :repo,
          :prompt      => "Please supply repository",
          :description => "Repository to query",
          :type        => :string,
          :validation  => '^.+$',
          :optional    => false,
          :maxlength   => 128

    input :count,
          :prompt      => "Please supply number of tags and branches to show",
          :description => "Number of most recent tags and branches to show",
          :type        => :number,
          :optional    => true

    output :tout,
           :description => "Tag list",
           :display_as  => "Tags",
           :default     => nil
    
    output :bout,
           :description => "Branch list",
           :display_as  => "Branches",
           :default     => nil
end
