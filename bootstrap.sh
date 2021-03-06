#!/bin/bash
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${SOURCE_DIR}/assets/nicescale.conf

TMP_PATH=/tmp/`head -c 1000 /dev/urandom |tr -dc 'a-z0-9A-Z'|tail -c 10`
mkdir -p $TMP_PATH

function cleanup {
  echo "Removing temporary directory $TMP_PATH"
  test "$TMP_PATH" = "/tmp" || rm -fr $TMP_PATH
}
trap cleanup EXIT

function checksum {
  local md5=$1
  local file=$2
  local calculated_md5=`md5sum $file|cut -d ' ' -f 1`
  if test "$calculated_md5" = "$md5"; then
    return 0
  fi
  echo "File $file checksum mismatch. calculated: $calculated_md5, expected: $md5"
  exit 1
}

function fail {
  echo "$@" >&2
  exit 1
}

function get_github_archive {
  local url="$1"
  local archive=`echo $url|awk -F '/' '{print $NF}'`
  local tmp_dir=`head -c 1000 /dev/urandom|tr -dc 'a-z0-9A-Z'|head -c 20`
  wget --timeout=60 --output-document=$archive $url
  if ! test -f $archive; then
    fail "Failed to download $url"
  fi
  mkdir $tmp_dir
  unzip -q -d $tmp_dir $archive
  cd $tmp_dir/`ls $tmp_dir`
}


cd $TMP_PATH
pkg_manager=yum
if grep -qiP "ubuntu|debian" /etc/issue; then
  pkg_manager="apt-get"
fi

if test "$pkg_manager" = "apt-get"; then
  apt-get install -y unzip libssl1.0.0 libsqlite3-0 libyaml-0-2 libffi6 zlib1g libreadline6 wget debianutils
  deb_pkg=ns-ruby_1.9.3-p547_amd64.deb
  md5='ab4c172dee641a68cee2528cc4869393'
  wget --timeout=60 http://s3-us-west-2.amazonaws.com/nicescale-data/deb/$deb_pkg
  checksum $md5 $deb_pkg
  dpkg -i $deb_pkg 
  apt-get install -y -f
elif test "$pkg_manager" = "yum"; then
  yum install -y unzip wget which
  if ! grep -riq epel /etc/yum.repos.d/; then
    wget --timeout=60 http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
    if ! test -f epel-release-6-8.noarch.rpm; then
      fail "Failed to download epel RPM package"
    fi
    rpm -ivh epel-release-6-8.noarch.rpm
  fi
  if grep -q 'Amazon Linux AMI' /etc/issue; then
    rpm_file=ns-ruby-1.9.3-1.ami.x86_64.rpm
    md5='107978b0d73893eacf4b80f39aa4daf4'
  else
    rpm_file=ns-ruby-1.9.3-1.centos-6.5.x86_64.rpm
    md5='e0e5b47829b475693823b8414d406687'
  fi
  wget --timeout=60 http://s3-us-west-2.amazonaws.com/nicescale-data/rpm/$rpm_file
  if ! test -f $rpm_file; then
    echo "Failed to download RPM file($rpm_file)"
    exit 2
  fi
  checksum $md5 $rpm_file
  yum -y localinstall $rpm_file
fi

$bin_dir/gem install --no-ri --no-rdoc -v 2.0.2 facter
$bin_dir/gem install --no-ri --no-rdoc -v 1.3.2 stomp
$bin_dir/gem install --no-ri --no-rdoc -v 1.0.4 parseconfig
$bin_dir/gem install --no-ri --no-rdoc -v 1.3.4 hiera
$bin_dir/gem install --no-ri --no-rdoc -v 0.2.5 formatador

cd $TMP_PATH
get_github_archive https://github.com/mountkin/marionette-collective/archive/v2.5.1-patched.zip
mco_conf_path=`dirname ${mco_client_conf_path}`
${bin_dir}/ruby install.rb --no-rdoc --plugindir=${mco_plugin_dir} --configdir=${mco_conf_path} --bindir=${bin_dir} --sbindir=${sbin_dir}

cd $TMP_PATH
get_github_archive https://github.com/puppetlabs/puppet/archive/3.6.0.zip
${bin_dir}/ruby install.rb --no-rdoc --configdir=${puppet_conf_dir} --bindir=${bin_dir}
${bin_dir}/puppet module install puppetlabs-stdlib

# First boot script
install -D -m 0644 $SOURCE_DIR/assets/firstpaas.rb ${mco_plugin_dir}/mcollective/agent/firstpaas.rb
install -D -m 0644 $SOURCE_DIR/assets/firstpaas.ddl ${mco_plugin_dir}/mcollective/agent/firstpaas.ddl

install -D -m 0755 $SOURCE_DIR/assets/bin/first-boot.sh ${bin_dir}/first-boot.sh
install -D -m 0755 $SOURCE_DIR/assets/bin/mount.sh ${bin_dir}/mount.sh
install -D -m 0755 $SOURCE_DIR/assets/bin/volume-detector.sh ${bin_dir}/volume-detector.sh

install -D -m 0644 $SOURCE_DIR/assets/nicescale.conf ${ns_conf_path}
install -D -m 0644 $SOURCE_DIR/assets/facter_plugin.rb ${ruby_prefix}/lib/ruby/gems/1.9.1/gems/facter-2.0.2/lib/facter/facter_plugin.rb
install -D -m 0644 $SOURCE_DIR/assets/mcollective.conf /opt/nicescale/support/etc/mcollective.conf

install -D -m 0755 $SOURCE_DIR/assets/bin/dynamic_facter.rb ${bin_dir}/dynamic_facter.rb
install -D -m 0755 $SOURCE_DIR/assets/bin/motd.rb ${bin_dir}/motd.rb
echo "/opt/nicescale/support/bin/motd.rb" > /etc/profile.d/z-nicescale.sh

# Disable password login and motd
sed -i -e '/PrintMotd/d' -e '/PrintLastLog/d' -e '/PasswordAuthentication/d' /etc/ssh/sshd_config
cat <<-EOS >>/etc/ssh/sshd_config
PrintMotd no
PrintLastLog no
PasswordAuthentication no
EOS

cd $TMP_PATH
get_github_archive https://github.com/NiceScale/mcollective-facter-facts/archive/master.zip
install -D -m 0644 facts/facter_facts.ddl ${mco_plugin_dir}/mcollective/facts/facter_facts.ddl
install -D -m 0644 facts/facter_facts.rb ${mco_plugin_dir}/mcollective/facts/facter_facts.rb

grep -q dynamic_facter /etc/crontab || echo "*/15 * * * * root ${bin_dir}/dynamic_facter.rb" >> /etc/crontab
touch $ns_first_boot_marker
cat <<-EOS > /etc/rc.local
#!/bin/sh -e
${bin_dir}/first-boot.sh &
exit 0
EOS

cd $SOURCE_DIR/fp-node
ns_vars_gem=`$bin_dir/gem build fp-node.gemspec|grep File|awk '{print $2}'`
$bin_dir/gem install --local --no-ri --no-rdoc $ns_vars_gem

# logrotate
cat <<-EOS > /etc/logrotate.d/nicescale-facter
/var/log/facter.log 
/var/log/volume-change.log
{
  weekly
  missingok
  rotate 5
  compress
  notifempty
}
EOS

# udev rules
rm -f /etc/udev/rules.d/*-nicescale-volume.rules
cat <<-EOS > /etc/udev/rules.d/95-nicescale-volume.rules
SUBSYSTEM=="block", RUN+="/opt/nicescale/support/bin/volume-detector.sh"
EOS
