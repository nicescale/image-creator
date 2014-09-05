module FP
  class Docker

    def initialize(params, logger = nil)
      @service_ids = params[:service_ids].split(',')
      @action = params[:docker_action]
      @service_action = params[:service_action]
      @config = Config.instance
      @timeout = params[:timeout] || @config.cmd_timeout.to_i
      @logger = logger
    end

    # 
    def perform
      results = {}
      @service_ids.each { |service_id|
        tags = Vars.get_service_var(service_id, 'deploy_tags', 'meta')
        next unless tags['image_name']
        next unless tags['instance_ids'] and tags['instance_ids'].include?(Vars.uuid)
        results[service_id] = self.__send__(@action.to_sym, service_id)
      }
      results
    end

    def run(service_id, action = 'run')
      tags = Vars.get_service_var(service_id, 'deploy_tags', 'meta')
      service_name = tags['service_name']
      image_version = tags['image_version']
      image_name = tags['image_name']
      sh(action, image_name, image_version, service_name, service_id)
    end

    def prepare(service_id)
      run(service_id, 'prepare')
    end

    def create(service_id)
      run(service_id, 'create')
    end

    def service(service_id)
      supported_service_actions = %w[start stop restart reload status]
      unless supported_service_actions.include?(@service_action)
        raise InvalidParams, "Unsupported service action. Only #{supported_service_actions.join(', ')} are supported"
      end
      sh('service', service_id, @service_action)
    end

    [:start, :stop, :restart, :commit].each { |m|
      define_method(m) do |service_id|
        sh(m.to_s, service_id)
      end
    }

    def rm(service_id)
      # Call CF API to update local config cache.
      CFAgent.prepare(false)
      sh('service', service_id, 'destroy')
    end

    # Run a docker command.
    # The first parameter must be 'service_id'.
    def sh(*params)
      params.unshift(docker_exe)
      @logger.info "Begin to run docker command: #{params.join(' ')}" if @logger
      ret = Util.sh(params)
      @logger.info "Docker command: #{params.join(' ')} exited with #{ret[:status]}" if @logger
      ret
    end


    private
    def docker_exe
      @config.docker_wrapper
    end
  end

  class InvalidParams < StandardError; end
end
