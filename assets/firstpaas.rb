require 'json'
require 'fp/config'
require 'fp/vars'
require 'fp/docker'

module MCollective
  module Agent
    class Firstpaas<RPC::Agent
      action "ping" do
        reply[:msg] = 'pong'
        reply[:instance_id] = Facts['instance_id']
      end
      
      # Run each checklist and return their results.
      action "checklist" do
        checklist = JSON.parse(request[:checklist])
        timeout = request[:timeout] || 5
        result = {}
        checklist.each_pair { |cmd_name, cmd|
          item = {:cmd => cmd, :status => 0, :stdout => '', :stderr => ''}
          item[:status] = run(cmd, :stdout => item[:stdout], :stderr => item[:stderr], :timeout => timeout)
          result[cmd_name] = item
        }

        reply[:result] = result
        reply[:instance_id] = Facts['instance_id']
      end

      action "puppet_apply" do
        if request[:force_reload_facts]
          run(FP::Config.instance.dynamic_facter_install_path)
        end
        
        reply[:instance_id] = Facts['instance_id']
        reply[:status] = run("#{FP::Config.instance.cf_agent} apply", :stdout => :stdout, :stderr => :stderr, :timeout => 600)
      end

      # Retrieve a single fact from the node
      action "get_fact" do
        reply[:fact] = request[:fact]
        reply[:value] = Facts[request[:fact]]
        reply[:instance_id] = Facts['instance_id']
      end

      # Retrieve multiple facts from the node
      action "get_facts" do
        response = {}
        request[:facts].split(',').map { |x| x.strip }.each do |fact|
          value = Facts[fact]
          response[fact] = value
        end
        reply[:values] = response
        reply[:instance_id] = Facts['instance_id']
      end

      action "prepare" do
        reply[:instance_id] = Facts['instance_id']
        reply[:status] = run("#{FP::Config.instance.cf_agent} prepare", :stdout => :stdout, :stderr => :stderr, :timeout => 600)
      end

      action "docker" do
        begin
          docker = FP::Docker.new(request, logger)
          results = docker.perform
          reply[:results] = results
          reply[:instance_id] = Facts['instance_id']
        rescue FP::InvalidParams
          reply.fail $!.message
        end
      end

    end
  end
end
