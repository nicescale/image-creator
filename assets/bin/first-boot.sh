#!/bin/bash

# This script should and must be run only once after the instance is created.

if [ -f /etc/.fp/csp.conf ]; then
  . /etc/.fp/csp.conf
  PROVIDER=$name
  REGION=$region
  unset name region
fi
CPI_HOST=${CPI_HOST:-cpi.nicescale.com}
. /opt/nicescale/support/etc/nicescale.conf
if [ -n "$TESTENV" ]; then
  cpi_base_url="http://$CPI_HOST"
else
  cpi_base_url="https://$CPI_HOST"
fi
init_conf_dir=$(dirname ${init_conf_path})

function check_iaas_env {
  if [ -f /etc/qingcloud/userdata/metadata.env ]; then
    iaas=qingcloud
  elif curl --connect-timeout 1 http://169.254.169.254/2007-01-19/meta-data/local-ipv4 -o /dev/null 2>/dev/null; then
    iaas=aws
  fi
}

function get_instance_id {
  if [ "$iaas" = "aws" ]; then
    curl -s http://169.254.169.254/latest/meta-data/instance-id
  elif [ "$iaas" = "qingcloud" ]; then
    grep instance_id /etc/qingcloud/userdata/metadata.env|awk -F '=' '{print $2}'|tr -dc 'a-z0-9-'
  fi
}


function config_mcollective {
  . ${init_conf_path}
  conf_dir=$(dirname ${mco_server_conf_path})
  lib_dir=${mco_plugin_dir}
  [ -d $conf_dir ] || mkdir -p $conf_dir
  
  cat <<-EOS >${conf_dir}/server.cfg
main_collective = ${mq_vhost}
collectives = ${mq_vhost}
libdir = ${lib_dir}
logfile = /var/log/mcollective.log
loglevel = info
daemonize = 0

# Plugins
securityprovider = psk
plugin.psk = ${project_id}
plugin.psk_serializer = yaml
identity = ${uuid}

direct_addressing = 1
connector = rabbitmq
plugin.rabbitmq.vhost = /${mq_vhost}
plugin.rabbitmq.pool.size = 1
plugin.rabbitmq.pool.1.host = ${mq_host}
plugin.rabbitmq.pool.1.port = ${mq_port}
plugin.rabbitmq.pool.1.user = ${uuid}
plugin.rabbitmq.pool.1.password = ${key}

# Facts
factsource = facter
fact_cache_time = 0
plugin.facter.facterlib = ${ruby_prefix}/lib/ruby/gems/1.9.1/gems/facter-2.0.2/lib/facter
EOS
  cat <<-EOS >${conf_dir}/client.cfg
main_collective = ${mq_vhost}
collectives = ${mq_vhost}
libdir = ${lib_dir}
logfile = /var/log/mcollective-client.log
loglevel = info

# Plugins
securityprovider = psk
plugin.psk = ${project_id}
plugin.psk_serializer = yaml
identity = ${uuid}

connector = rabbitmq
plugin.rabbitmq.vhost = /${mq_vhost}
plugin.rabbitmq.pool.size = 1
plugin.rabbitmq.pool.1.host = ${mq_host}
plugin.rabbitmq.pool.1.port = ${mq_port}
plugin.rabbitmq.pool.1.user = ${uuid}
plugin.rabbitmq.pool.1.password = ${key}

# Facts
factsource = facter
fact_cache_time = 0
plugin.facter.facterlib = ${ruby_prefix}/lib/ruby/gems/1.9.1/gems/facter-2.0.1/lib/facter
EOS
  mv ${ns_config_dir}/mcollective.conf /etc/init/
  start mcollective
}

# Remove the first boot marker file and this script
function cleanup {
  echo -e "#!/bin/sh\nexit 0\n">/etc/rc.local
  [ -f $ns_first_boot_marker ] && rm -f $ns_first_boot_marker
  rm -f $0
}

function load_credentials {
  [ -d $init_conf_dir ] || mkdir -p $init_conf_dir
  if [ "$iaas" = "aws" ]; then
    for i in `seq 1 120`; do
      local http_status=`curl -s -o ${init_conf_path} -w '%{http_code}' http://169.254.169.254/latest/user-data`
      [ "$http_status" = "200" ] && break
      sleep 1
    done
  elsif [ "$iaas" = "qingcloud" ]; then
    cp -f /etc/qingcloud/userdata/userdata.string $init_conf_path
  fi

  if ! test -e $init_conf_path || ! grep -q project_id $init_conf_path; then
    echo "Failed to load NiceScale initial config." >>/root/nicescale-init.log
    echo "You can rerun $0 manually." >>/root/nicescale-init.log
    exit 1
  fi
  get_instance_id >>$init_conf_path
}

function load_hosts {
  if [ -n "$TESTENV" ]; then
    grep -P "localhost|$(hostname)|ip6-" /etc/hosts >/tmp/hosts.old
    for i in `seq 1 300`; do
      local http_status=$(curl -s -o /tmp/hosts -w '%{http_code}' https://raw.githubusercontent.com/NiceScale/hosts/master/${PROVIDER}-${REGION}.txt)
      [ "$http_status" = "200" ] && break
      sleep 1
    done
    cat /tmp/hosts.old >/etc/hosts
    cat /tmp/hosts >>/etc/hosts
    rm /tmp/hosts*
  fi
}


if [ ! -e $ns_first_boot_marker ]; then
  cleanup
  exit 0
fi

[ -f /root/nicescale-init.log ] && rm /root/nicescale-init.log
check_iaas_env
load_hosts
load_credentials
config_mcollective
cleanup
exit 0
