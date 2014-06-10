module FP
  class CFAgent
    class << self
      def prepare
        cfagent_exe = config.cf_agent
        ret = {}
        ret[:cf] = Util.sh([cfagent_exe, 'prepare'], 600)
        if ret[:cf][:status] == 0
          ret[:docker] = Docker.new({service_ids: Vars.services_on_this_instance.join(','), docker_action: 'prepare'}).perform
        end
        ret
      end

      def apply(force_reload_facts = true)
        if force_reload_facts
          Util.sh(config.dynamic_facter_install_path)
        end
        Util.sh([config.cf_agent, 'apply'], 600)
      end
      
      private
      def config
        Config.instance
      end
    end
  end
end
