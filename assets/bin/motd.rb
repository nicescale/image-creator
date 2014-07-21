#!/opt/nicescale/support/bin/ruby
# encoding: utf-8
require 'fp/node'
require 'formatador'

def is_running(sid)
  if `/opt/nicescale/support/bin/nicedocker service #{sid} status`.strip =~ /running/i
    'running'
  else
    'stopped'
  end
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
  service_path = "/services/#{sid}"
  spec = {
    name: tags['service_name'],
    service: tags['image_name'] + ':' + tags['image_version'],
    path: service_path,
    status: is_running(sid),
    created_at: File.ctime(service_path)
  }
  
  if term_cols.to_i < 125
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
