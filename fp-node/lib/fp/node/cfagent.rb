module FP
  class CFAgent
    class << self
      def prepare(with_docker = true)
        ret = {}
        ret[:cf] = Util.sh([cfagent_exe, 'prepare'], 600)
        if ret[:cf][:status] == 0 and with_docker
          service_ids = Vars.services_on_this_instance.join(',')
          ret[:docker] = Docker.new({service_ids: service_ids,
                                     docker_action: 'prepare'}).perform
        end
        ret
      end

      # Apply config files.
      # N.B. This action must be called after 'prepare'.
      def apply(force_reload_facts = true)
        if force_reload_facts
          Util.sh(config.dynamic_facter_install_path)
        end
        service_ids = Vars.services_on_this_instance.map { |sid|
          'm' + sid
        }.join(' ')
        Util.sh([config.cf_agent, 'apply', service_ids], 600)
      end

      def mount(volume_id)
        raise "Must specify a volume_id" unless volume_id
        1.upto(120) { |i|
          break if File.exists?(config.volume_log)
          raise "No block device attach event detected" if i == 120
          sleep(0.5)
        }
        dev_log = `grep -P "\tadd\t" #{config.volume_log}`.
          split("\n").last.split("\t")
        raise "No block device attach event detected" unless dev_log.any?
        dev = dev_log[2]
        fstype = dev_log[4] || 'ext4'
        cmd = [config.bin_dir + '/mount.sh', dev, volume_id, fstype]
        Util.sh(cmd, 600)
      end

      def update_env(auto_restart = false)
        base_path = config.service_base_path
        Vars.services_on_this_instance.each { |sid|
          ret = Util.sh([config.cf_agent, 'prjenv-dump'], 20)
          if auto_restart and ret[:status] == 0
            Docker.new({service_ids: sid, docker_action: 'service',
                        service_action: 'restart'}).perform
          end
        }
      end

      def data_sync(srv_id, sync_id)
        Util.run_in_background(config.cf_agent, 'drs', srv_id, sync_id)
      end
      
      private
      def config
        Config.instance
      end

      def cfagent_exe
        config.cf_agent
      end
    end
  end
end
