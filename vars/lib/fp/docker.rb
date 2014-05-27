require 'fp/config'
require 'mcollective'
require 'shellwords'

module FP
  class Docker

    def initialize(params, logger)
      @service_ids = params[:service_ids].split(',')
      @action = params[:docker_action]
      @service_action = params[:service_action]
      @timeout = params[:timeout] || Config.instance.docker_cmd_timeout.to_i
      @logger = logger
    end

    # 
    def perform
      results = {}
      @service_ids.each { |service_id|
        next unless FP::Vars.has_service?(service_id)
        results[service_id] = self.__send__(@action.to_sym)
      }
      results
    end

    def run(service_id)
      tags = FP::Vars.get_global_var_by_service(service_id, 'deploy_tags', 'meta')
      service_name = tags['service_name']
      software_version = tags['software_version']
      software = tags['software']
      sh('run', software, software_version, service_name, service_id)
    end

    def service(service_id)
      supported_service_actions = %w[start stop restart reload status]
      unless supported_service_actions.include?(service_action)
        raise InvalidParams, "Unsupported service action. Only #{supported_service_actions.join(', ')} are supported"
      end
      sh('service', @service_action, service_id)
    end

    [:start, :stop, :restart, :rm, :commit].each { |m|
      define_method(m) do |service_id|
        sh(m.to_s, service_id)
      end
    }

    # Run a docker command.
    # The first parameter must be 'service_id'.
    def sh(*params)
      stdout = ''
      stderr = ''
      options = {
        'stdout' => stdout,
        'stderr' => stderr,
        'timeout' => @timeout
      }
      params.unshift(docker_exe)
      cmd = Shellwords.join(params)
      status = MCollective::Shell.new(cmd, options).runcommand
      @logger.info "Docker command: #{cmd} exited with #{status.exitstatus}"
      
      {
        stdout: stdout,
        stderr: stderr,
        status: status.exitstatus,
        service_id: params.first
      }
    end


    private
    def docker_exe
      Config.instance.docker_wrapper
    end
  end

  class InvalidParams < StandardError; end
end
