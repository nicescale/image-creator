# A plugin for gathering config data from FirstPaaS center.

require 'json'
require 'fp/config'
require 'fp/vars'

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

# Set the tags of this instance
# NB. Must be run after set_service_ids
def set_tags
  global_vars_file = FP::Config.instance.global_vars_conf_path
  return unless File.exists?(global_vars_file)
  vars = JSON.parse(File.read(global_vars_file))
  service_ids = Facter[:service_ids].value.split(',')
  service_ids.each { |sid|
    tags = vars[sid]['meta']['deploy_tags']
    next unless tags and tags.kind_of?(Hash)
    tags.each_pair { |tkey, tval|
      Facter.add("tag_#{tkey}".to_sym) {
        setcode { tval }
      }
    }
  }
end

load_initial_vars
set_service_ids
set_tags
