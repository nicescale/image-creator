#!/bin/bash

# This script should and must be run only once after the instance is created.
. /opt/nicescale/support/etc/nicescale.conf


init_conf_dir=$(dirname ${init_conf_path})

function get_mac {
  /sbin/ifconfig|grep HWaddr|awk '{print $NF}'|sort|tr -d '\n'|tr '[:upper:]' '[:lower:]'
}

function get_ip {
  /sbin/ifconfig|grep 'inet '|grep -v '127\.'|awk -F: '{print $2}'|awk '{print $1}'|sort|tr -d '\n'
}

function check_iaas_env {
  # QingCloud doesn't have a metadata server.
  # This approach is too fragile.
  if /bin/hostname|grep -qP '^i-.+'; then
    iaas=qingcloud
  elif curl --connect-timeout 1 http://169.254.169.254/2007-01-19/meta-data/public-hostname|grep -q amazon; then
    iaas=aws
  fi
}

function get_instance_id {
  if [ "$iaas" = "aws" ]; then
    curl http://169.254.169.254/latest/meta-data/instance-id
  elif [ "$iaas" = "qingcloud" ]; then
    /bin/hostname -s
  fi
}

function sign {
  local str="`get_instance_id``get_mac``get_ip`"
  echo -n $str|sha256sum|cut -d ' ' -f 1
}

function config_mcollective {
  . ${init_conf_path}
  conf_dir=$(dirname ${mco_server_conf_path})
  lib_dir=${mco_plugin_dir}
  [ -d $conf_dir ] || mkdir -p $conf_dir
  
  cat <<-EOS >{$conf_dir}/server.cfg
main_collective = ${mq_vhost}
collectives = ${mq_vhost}
libdir = ${lib_dir}
logfile = /var/log/mcollective.log
loglevel = info
daemonize = 1

# Plugins
securityprovider = psk
plugin.psk = unset

direct_addressing = 1
connector = rabbitmq
plugin.rabbitmq.vhost = /${mq_vhost}
plugin.rabbitmq.pool.size = 1
plugin.rabbitmq.pool.1.host = ${mq_host}
plugin.rabbitmq.pool.1.port = ${mq_port}
plugin.rabbitmq.pool.1.user = ${uuid}
plugin.rabbitmq.pool.1.password = ${key}

# Facts
factsource = yaml
plugin.yaml = ${conf_dir}/facts.yaml
EOS
  cat <<-EOS >${conf_dir}/client.cfg
main_collective = ${mq_vhost}
collectives = ${mq_vhost}
libdir = ${lib_dir}
logfile = /var/log/mcollective-client.log
loglevel = info

# Plugins
securityprovider = psk
plugin.psk = unset

connector = rabbitmq
plugin.rabbitmq.vhost = /${mq_vhost}
plugin.rabbitmq.pool.size = 1
plugin.rabbitmq.pool.1.host = ${mq_host}
plugin.rabbitmq.pool.1.port = ${mq_port}
plugin.rabbitmq.pool.1.user = ${uuid}
plugin.rabbitmq.pool.1.password = ${key}

# Facts
factsource = yaml
plugin.yaml = ${conf_dir}/facts.yaml
EOS
  service mcollective restart
}

# Remove the first boot marker file and this script
function cleanup {
  if [ -n "$TEST" ]; then
    echo "testing"
    return 0
  fi
  echo -e "#!/bin/sh\nexit 0\n">/etc/rc.local
  [ -f $ns_first_boot_marker ] && rm -f $ns_first_boot_marker
  rm -f $0
}

function load_credentials {
  [ -d $init_conf_dir ] || mkdir -p $init_conf_dir
  for i in `seq 1 120`; do
    local url="$ns_gateway/internal/instance-credentials/`get_instance_id`/`sign`.text"
    local http_status=`curl -s -o ${init_conf_path} -w '%{http_code}' -H"Host: api.firstpaas.com" $url`
    [ $http_status = 200 ] && break
    sleep 1
  done
}

function mock_credentials {
  [ -d $init_conf_dir ] || mkdir -p $init_conf_dir
  cat <<- EOS > $init_conf_path
project_id=mcollective
uuid=deadbeef
instance_id=`get_instance_id`
gateway=$ns_gateway
key=testaaaa
mq_vhost=test
mq_host=mq.lajipk.com
mq_port=61613
EOS
}

if [ ! -e $ns_first_boot_marker ]; then
  cleanup
  exit 0
fi

check_iaas_env

if [ -n "$TEST" ]; then
  mock_credentials
else
  load_credentials
fi

config_mcollective

cleanup
exit 0
