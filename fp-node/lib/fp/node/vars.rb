module FP
  class Vars
    AUTO_VARS_CACHE_TTL = 60

    class << self
      def get_service_var(service_id, key, namespace = nil)
        return nil if ENV['CFAGENT_PREPARE']
        if services_on_this_instance.include?(service_id)
          # Lookup the module vars
          local_vars_file = config.service_conf_path % ('m' + service_id)
          return nil unless File.exists?(local_vars_file)
          vars = JSON.parse(File.read(local_vars_file))
          get_namespace_var(vars, key, namespace)
        else
          # Try to lookup global vars first, then auto vars.
          get_global_var_by_service(service_id, key, namespace) || get_auto_var_by_service(service_id, key)
        end
      end

      def get_cluster_var(cluster_id, role, key, namespace = nil)
        service = find_service(cluster_id, role)
        service_id = service.keys.first
        return nil unless service_id
        get_service_var(service_id, key, namespace)
      end

      def get_auto_var_by_service(service_id, key)
        return nil if ENV['CFAGENT_PREPARE']
        if !File.exists?(config.dynamic_params_path) or Time.now - File.mtime(config.dynamic_params_path) >= AUTO_VARS_CACHE_TTL
          `#{config.dynamic_facter_install_path}`
        end
        vars = JSON.parse(File.read(config.dynamic_params_path))
        raise NotFound, "The key(#{key}) doesn't exist" unless vars[service_id].has_key?(key)
        vars[service_id][key]
      end

      def get_auto_var_by_cluster(cluster_id, role, key)
        service = find_service(cluster_id, role)
        service_id = service.keys.first
        return nil unless service_id
        get_auto_var_by_service(service_id, key)
      end

      def get_global_var_by_service(service_id, key, namespace = nil)
        return nil unless File.exists? config.global_vars_conf_path
        return nil if ENV['CFAGENT_PREPARE']
        vars = JSON.parse(File.read(config.global_vars_conf_path))[service_id]
        return nil unless vars
        
        get_namespace_var(vars, key, namespace)
      end

      def get_global_var_by_cluster(cluster_id, role, key, namespace = nil)
        return nil if ENV['CFAGENT_PREPARE']
        vars = find_service(cluster_id, role)
        return nil if vars.empty?
        service_id = vars.keys.first
        get_namespace_var(vars[service_id], key, namespace)
      end

      def services_on_this_instance
        manifest = project_metadata
        return [] unless manifest['instance_vars']
        manifest['instance_vars'][uuid]['services'].map { |s|
          s['id']
        }
      end

      def services_in_this_project
        manifest = project_metadata
        return [] unless manifest['instance_vars']
        r = manifest['instance_vars'].inject([]) { |ret, (uuid, iv)|
          ret.concat(iv['services'].map { |s| s['id'] })
        }.uniq
        puts r.to_json
        r
      end

      def has_service?(service_id)
        services_on_this_instance.include?(service_id)
      end

      # The uuid of this instance.
      # The uuid of the instance will never be changed, so it can be cached.
      def uuid
        @uuid ||= File.read(config.init_conf_path).split("\n").
          grep(/^uuid=/).first.split('=').last
      end

      def project_metadata
        manifest_file = config.project_metadata_conf_path
        return {} unless File.exists?(manifest_file)
        JSON.parse(File.read(manifest_file))
      end

      private
      def get_namespace_var(vars, key, namespace = nil)
        if namespace and vars[namespace]
          raise NotFound, "The key(#{key}) doesn't exist" unless vars[namespace].has_key?(key)
          vars[namespace][key]
        else
          raise NotFound, "The key(#{key}) doesn't exist" unless vars.has_key?(key)
          vars[key]
        end
      end

      def find_service(cluster_id, role)
        return {} unless cluster_id and File.exists?(config.global_vars_conf_path)
        vars = JSON.parse(File.read(config.global_vars_conf_path))

        vars.select { |sid, spec|
          next unless spec['meta'] and spec['meta']['cluster_id'] and spec['meta']['tags']

          spec['meta']['cluster_id'] == cluster_id and spec['meta']['tags'].include?(role)
        }
      end
      
      def config
        Config.instance
      end
    
    end

    class NotFound < StandardError; end
  end

end
