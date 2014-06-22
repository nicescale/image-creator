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

      def mount(volume_id)
        raise "Must specify a volume_id" unless volume_id
        1.upto(120) { |i|
          break if File.exists?(config.volume_log)
          raise "No block device attach event detected" if i == 120
          sleep(0.5)
        }
        dev_log = `grep -P "\tadd\t" #{config.volume_log}`.split("\n").last.split("\t")
        raise "No block device attach event detected" unless dev_log.any?
        dev = dev_log[2]
        fstype = dev_log[4] || 'ext4'
        cmd = [config.bin_dir + '/mount.sh', dev, volume_id, fstype]
        Util.sh(cmd, 600)
      end
      
      private
      def config
        Config.instance
      end
    end
  end
end
