metadata :name => "firstpaas",
         :description => "FirstPaaS config engine plugin",
         :author => "mountkin <mountkin@gmail.com>",
         :license => "private",
         :version => "1.0",
         :url => "http://firstpaas.com",
         :timeout => 600

action "ping", :description => "show I'm alive" do
     display :always
     output :instance_id,
            :description => "instance ID of the instance",
            :display_as  => "instance_id"
     
     output :ipaddress,
            :description => "Private IP address of eth0",
            :display_as  => "ipaddress"
end

action "puppet_apply", :description => "Run puppet apply command immediately" do
     display :always
     input :force_reload_facts,
           :prompt      => "force_reload_facts",
           :description => "Whether to force reload dynamical facts before call puppet apply",
           :type        => :boolean,
           :optional    => true
     
     output :stdout,
            :description => "stdout of the command",
            :display_as  => "stdout"

     output :stderr,
            :description => "stderr of the command",
            :display_as  => "stderr"

     output :status,
            :description => "exit status of the command",
            :display_as  => "status"
     
     output :instance_id,
            :description => "instance ID of the instance",
            :display_as  => "instance_id"
end

action "get_facts", :description => "Retrieve multiple facts from the fact store" do
     display :always

     input :facts,
           :prompt      => "Comma-separated list of facts",
           :description => "Facts to retrieve",
           :type        => :string,
           :validation  => '^\s*[\w\.\-]+(\s*,\s*[\w\.\-]+)*$',
           :optional    => false,
           :maxlength   => 200

     output :values,
            :description => "List of values of the facts",
            :display_as => "Values"
     
     output :instance_id,
            :description => "instance ID of the instance",
            :display_as  => "instance_id"
end

action "get_fact", :description => "Retrieve a single fact from the fact store" do
     display :always

     input :fact,
           :prompt      => "The name of the fact",
           :description => "The fact to retrieve",
           :type        => :string,
           :validation  => '^[\w\-\.]+$',
           :optional    => false,
           :maxlength   => 40

     output :fact,
            :description => "The name of the fact being returned",
            :display_as => "Fact"

     output :value,
            :description => "The value of the fact",
            :display_as => "Value"
     
     output :instance_id,
            :description => "instance ID of the instance",
            :display_as  => "instance_id"

    summarize do
        aggregate summary(:value)
    end
end

action "prepare", :description => "Prepare service runtime environment" do
     display :always
     
     output :results,
            :description => "result of the prepare commands",
            :display_as  => "results"
     
     output :instance_id,
            :description => "instance ID of the instance",
            :display_as  => "instance_id"
end

action "docker", :description => "Run docker commands" do
     display :always
     input :service_ids,
           :prompt      => "service_ids",
           :description => "Comma separated service IDs",
           :type        => :string,
           :validation  => '^.+$',
           :optional    => false,
           :maxlength   => 2500
     
     input :docker_action,
           :prompt      => "action",
           :description => "The subcommand of our docker wrapper",
           :type        => :string,
           :validation  => '^.+$',
           :optional    => false,
           :maxlength   => 60
     
     input :service_action,
           :prompt      => "service_action",
           :description => "The subcommand of our docker wrapper's service command",
           :type        => :string,
           :validation  => '^.+$',
           :optional    => true,
           :maxlength   => 60
     
     input :timeout,
           :prompt      => "timeout",
           :description => "maximum execute time",
           :type        => :integer,
           :optional    => true
     
     output :instance_id,
            :description => "instance ID of the instance",
            :display_as  => "instance_id"
     
     output :results,
            :description => "Docker execute result hash",
            :display_as  => "results"
end

action "mount", :description => "Format and mount an EBS volume" do
     display :always
     input :volume_id,
           :prompt      => "volume_id",
           :description => "The IaaS volume ID",
           :type        => :string,
           :validation  => '^.+$',
           :optional    => false,
           :maxlength   => 16
     
     output :instance_id,
            :description => "instance ID of the instance",
            :display_as  => "instance_id"
     
     output :result,
            :description => "Result of the mount script",
            :display_as  => "result"
end

action "update_env", :description => "Update shared service variables such as ip_address, port, etc." do
     input :auto_restart,
           :prompt      => "auto_restart",
           :description => "Whether to restart the service after updating the env file",
           :type        => :boolean,
           :optional    => true
end
