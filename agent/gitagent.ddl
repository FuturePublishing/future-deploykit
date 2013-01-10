metadata    :name        => "gitagent",
            :description => "Git agent",
            :author      => "JHR",
            :license     => "BSD",
            :version     => "0.6",
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

    output :tstatus,
           :description => "Git-tag command status",
           :display_as  => "Git-tag status",
           :default     => nil
    
    output :bstatus,
           :description => "Git-branch command status",
           :display_as  => "Git-branch status",
           :default     => nil

    output :lrep,
           :description => "Agent version of repo",
           :display_as  => "Target repo",
           :default     => nil

end

action "git_checkout", :description => "Check out supplied tag from repository ditto" do
  input   :repo,
          :prompt      => "Please supply repository",
          :description => "Repository containing tag",
          :type        => :string,
          :validation  => '^.+$',
          :optional    => false,
          :maxlength   => 128

  input   :tag,
          :prompt      => "Please supply tag or branch",
          :description => "Tag to check out",
          :type        => :string,
          :validation  => '^.+$',
          :optional    => false,
          :maxlength   => 128

  input   :request_id,
          :prompt      => "Request-id, if required",
          :description => "Optional request-id for deploy audit",
          :type        => :string,
          :validation  => '^.+$',
          :optional    => true,
          :maxlength   => 64

  output  :prstat,
          :description  => "Pre-deploy command status",
          :display_as   => "Pre-deploy status",
          :default      => nil

  output  :prout,
          :description  => "Pre-deploy command STDOUT",
          :display_as   => "Pre-deploy STDOUT",
          :default      => nil

  output  :prerr,
          :description  => "Pre-deploy command STDERR",
          :display_as   => "Pre-deploy STDERR",
          :default      => nil

 output  :dstat,
         :description  => "Git checkout command status",
         :display_as   => "Git checkout status",
         :default      => nil

  output  :dout,
          :description  => "Git checkout command STDOUT",
          :display_as   => "Git checkout STDOUT",
          :default      => nil

  output  :derr,
          :description => "Git checkout command STDERR",
          :display_as   => "Git checkout STDERR",
          :default      => nil

  output  :status,
          :description  => "Post-deploy command status",
          :display_as   => "Post-deploy status",
          :default      => nil

  output  :out,
          :description  => "Post-deploy command STDOUT",
          :display_as   => "Post-deploy STDOUT",
          :default      => nil

  output  :err,
          :description  => "Post-deploy command STDERR",
          :display_as   => "Post-deploy STDERR",
          :default      => nil

end
