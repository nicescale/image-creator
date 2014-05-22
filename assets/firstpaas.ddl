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
     
     output :msg,
            :description => "pong",
            :display_as  => "msg"
     
     output :fp_uuid,
            :description => "FirstPaaS unique resource ID",
            :display_as  => "fp_uuid"
end

action "checklist", :description => "Execute arbitary commands and return their results" do
     display :always
     input :checklist,
           :prompt      => "checklist",
           :description => "JSON encoded checklist",
           :type        => :string,
           :optional    => false,
           :validation  => '^\{.+\}$',
           :maxlength   => 2048

     input :timeout,
           :prompt      => "timeout",
           :description => "maximum execute time for each check item",
           :type        => :integer,
           :optional    => true

     output :result,
            :description => "Execute results of each check items.",
            :display_as  => "result"
     
     output :instance_id,
            :description => "instance ID of the instance",
            :display_as  => "instance_id"
     
     output :fp_uuid,
            :description => "FirstPaaS unique resource ID",
            :display_as  => "fp_uuid"
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
     
     output :fp_uuid,
            :description => "FirstPaaS unique resource ID",
            :display_as  => "fp_uuid"
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
     
     output :fp_uuid,
            :description => "FirstPaaS unique resource ID",
            :display_as  => "fp_uuid"
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
     
     output :fp_uuid,
            :description => "FirstPaaS unique resource ID",
            :display_as  => "fp_uuid"

    summarize do
        aggregate summary(:value)
    end
end

action "prepare", :description => "Download global variables before puppet apply" do
     display :always
     output :checksum,
            :description => "The SHA1 checksum of the downloaded file",
            :display_as  => "checksum"
     
     output :instance_id,
            :description => "instance ID of the instance",
            :display_as  => "instance_id"
     
     output :fp_uuid,
            :description => "FirstPaaS unique resource ID",
            :display_as  => "fp_uuid"
end
