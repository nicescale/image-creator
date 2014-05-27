#!/bin/bash
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${SOURCE_DIR}/assets/nicescale.conf

cd /tmp
if `which apt-get >/dev/null` && test -x `which apt-get`; then
  apt-get install -y libssl-dev libsqlite3-dev build-essential libreadline6-dev zlib1g-dev libyaml-dev libffi-dev git
elif `which yum >/dev/null` && test -x `which yum`; then
  yum groupinstall -y "Development Tools"
  yum install -y libffi-devel git libyaml-devel openssl-devel sqlite-devel readline-devel zlib-devel
fi

wget http://cache.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p547.tar.gz
tar xf ruby-1.9.3-p547.tar.gz
cd ruby-1.9.3-p547
./configure --prefix=${ruby_prefix} --disable-install-doc --disable-install-capi --disable-install-doc
make -j8 > /tmp/build.log 2>&1
make install

${ruby_prefix}/bin/gem install --no-ri --no-rdoc facter hiera stomp parseconfig

cd /tmp
git clone https://github.com/mountkin/marionette-collective.git
cd marionette-collective
git checkout v2.5.1-patched
mco_conf_path=`dirname ${mco_client_conf_path}`
${ruby_prefix}/bin/ruby install.rb --no-rdoc --plugindir=${mco_plugin_dir} --configdir=${mco_conf_path} --bindir=${bin_dir} --sbindir=${sbin_dir}

cd /tmp

git clone https://github.com/puppetlabs/puppet.git
cd puppet
git checkout 3.6.0 -b v3.6.0
${ruby_prefix}/bin/ruby install.rb --no-rdoc --configdir=${puppet_conf_dir} --bindir=${bin_dir}

for f in `ls ${ruby_prefix}/bin`; do
  ln -s ${ruby_prefix}/bin/$f ${bin_dir}/$f
done

# First boot script
install -D -m 0644 $SOURCE_DIR/assets/firstpaas.rb ${mco_plugin_dir}/mcollective/agent/firstpaas.rb
install -D -m 0644 $SOURCE_DIR/assets/firstpaas.ddl ${mco_plugin_dir}/mcollective/agent/firstpaas.ddl

install -D -m 0755 $SOURCE_DIR/assets/first-boot.sh ${bin_dir}/first-boot.sh
install -D -m 0644 $SOURCE_DIR/assets/nicescale.conf ${ns_conf_path}
install -D -m 0644 $SOURCE_DIR/assets/facter_plugin.rb ${ruby_prefix}/lib/ruby/gems/1.9.1/gems/facter-2.0.1/lib/facter/facter_plugin.rb
install -D -m 0644 $SOURCE_DIR/assets/mcollective.conf /opt/nicescale/support/etc/mcollective.conf
install -D -m 0755 $SOURCE_DIR/assets/dynamic_facter.rb ${bin_dir}/dynamic_facter.rb
echo "*/15 * * * * root ${bin_dir}/dynamic_facter.rb"
touch $ns_first_boot_marker
cat <<-EOS > /etc/rc.local
#!/bin/sh -e
${bin_dir}/first-boot.sh
exit 0
EOS

cd $SOURCE_DIR/vars
ns_vars_gem=`$bin_dir/gem build vars.gemspec|grep File|awk '{print $2}'`
$bin_dir/gem install --local --no-ri --no-rdoc $ns_vars_gem

# logrotate

cat <<-EOS > /etc/logrotate.d/nicescale-facter
/var/log/facter.log {
  weekly
  missingok
  rotate 5
  compress
  notifempty
}
EOS
