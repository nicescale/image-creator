#!/opt/nicescale/support/bin/ruby

require 'mcollective'
require 'fileutils'
require 'tempfile'
require 'json'
require 'fp/config'
require 'timeout'
require 'logger'

include MCollective::RPC

# Currently supported auto-vars:
#   #{service_id}.ip

def load_instance_ips
  dyn_vars_file = FP::Config.instance.dynamic_params_path
  path = File.dirname(dyn_vars_file)
  FileUtils.mkdir_p(path) unless File.directory?(path)
  rpc = rpcclient('firstpaas', :configfile => FP::Config.instance.mco_client_conf_path)
  rpc.verbose = false
  rpc.progress = false
  nodes = {}
  rpc.get_facts(:facts => 'service_ids,ipaddress').each { |resp|
    v = resp[:data][:values]
    service_ids = v['service_ids'].split(',')
    service_ids.each { |sid|
      nodes[sid] ||= {ips: []}
      nodes[sid][:ips] << v['ipaddress']
    }
  }
  
  content = content.chop
  tmp_file = Tempfile.new(File.basename(dyn_vars_file))
  tmp_file.write nodes.to_json
  tmp_file.close
  FileUtils.mv(tmp_file.path, dyn_vars_file, :force => true)
ensure
  rpc.disconnect if rpc
end

def single_instance(&block)
  if File.open($0).flock(File::LOCK_EX|File::LOCK_NB)
    block.call
  else
    warn "Script #{ $0 } is already running"
  end 
end

single_instance do
  begin
    Timeout.timeout(120) {
      load_instance_ips
    }
  rescue => e
    logger = Logger.new('/var/log/facter.log')
    logger.error "Failed to load facts: errtype(#{e.class}), errmsg(#{e.message})"
  end
end
