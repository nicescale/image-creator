# A plugin for gathering config data from FirstPaaS center.
require 'fp/node'

def parse_ini(file)
  return {} unless File.exists?(file)
  
  cfg = {}
  File.open(file, 'r') { |f|
    f.each { |line|
      line = line.strip
      next if line.start_with? '#'
      line = line.split('=', 2).map(&:strip)
      next unless line[1]
      cfg[line[0]] = line[1]
    }
  }
  cfg
end

def load_initial_vars
  fp_conf = FP::Config.instance.init_conf_path
  cfg = parse_ini(fp_conf)
  
  ['gateway', 'project_id', 'uuid'].each { |x|
    Facter.add("fp_#{x}".to_sym) { setcode { cfg[x] } }
  }

  Facter.add(:instance_id) { setcode { cfg['instance_id'] } }
end

def load_ini_vars(cfg_file)
  cfg = parse_ini(cfg_file)
  cfg.each { |k, v|
    Facter.add(k.to_sym) { setcode { v } }
  }
end

# The service IDs of this node
def set_service_ids
  vars = FP::Vars.services_on_this_instance
  service_ids = vars['modules'].keys.join(',')
  Facter.add(:service_ids) { setcode { service_ids} }
end

load_initial_vars
set_service_ids
