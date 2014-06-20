#!/opt/nicescale/support/bin/ruby
# encoding: utf-8
require 'fp/node'
require 'formatador'

def is_running(cid)
  return @running_services.find { |x| cid.start_with?(x) } if @running_services
  @running_services = []
  `docker ps`.split("\n").each_with_index { |s, i|
    next if i == 0
    @running_services << s.split.first
  }
  @running_services.find { |x| cid.start_with?(x) }
end

term_cols = if test('x', '/usr/bin/tput')
    `/usr/bin/tput cols`.to_i
  elsif test('x', '/bin/stty')
    `/bin/stty size`.split.last.to_i
  else
    120
  end

sids = FP::Vars.services_on_this_instance
services = []
sids.each { |sid|
  tags = FP::Vars.get_service_var(sid, 'deploy_tags', 'meta')
  next unless tags.kind_of?(Hash)
  spec = {
    name: tags['service_name'],
    service: tags['image_name'] + ':' + tags['image_version'],
    path: "/services/#{sid}",
    status: 'stopped',
    container_id: '',
    created_at: 'N/A'
  }
  
  container_id_path = spec[:path] + '/containerid' 
  if File.readable?(container_id_path)
    spec[:container_id] = File.read(container_id_path)[0..12]
    spec[:created_at]   = File.ctime(container_id_path)
    spec[:status] = 'running' if is_running(spec[:container_id])
  end

  if term_cols.to_i < 80
    spec.delete(:created_at)
    spec.delete(:container_id)
  elsif term_cols.to_i < 125
    spec.delete(:created_at)
  end

  services << spec
}

Formatador.display_line "[green]Welcome to use NiceScale."
Formatador.display_line "You have the folling services running on this server:[/]"
puts ""
Formatador.display_table(services) do
  # Disable sorting headers.
  0
end
