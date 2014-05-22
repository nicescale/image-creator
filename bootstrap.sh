#!/bin/bash
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
./configure --prefix=/opt/nicescale/support/ruby-1.9.3-p547 --disable-install-doc --disable-install-capi --disable-install-doc
make -j8 > /tmp/build.log 2>&1
make install

/opt/nicescale/support/ruby-1.9.3-p547/bin/gem install --no-ri --no-rdoc facter hiera stomp

cd /tmp
git clone https://github.com/mountkin/marionette-collective.git
cd marionette-collective
git checkout v2.5.1-patched
/opt/nicescale/support/ruby-1.9.3-p547/bin/ruby install.rb --no-rdoc --plugindir=/opt/nicescale/support/libexec --configdir=/opt/nicescale/support/etc/mcollective --bindir=/opt/nicescale/support/bin --sbindir=/opt/nicescale/support/sbin

cd /tmp

git clone https://github.com/puppetlabs/puppet.git
cd puppet
git checkout 3.6.0 -b v3.6.0
/opt/nicescale/support/ruby-1.9.3-p547/bin/ruby install.rb --no-rdoc --configdir=/opt/nicescale/support/etc/puppet --bindir=/opt/nicescale/support/bin

for f in `ls /opt/nicescale/support/ruby-1.9.3-p547/bin`; do
  ln -s /opt/nicescale/support/ruby-1.9.3-p547/bin/$f /opt/nicescale/support/bin/$f
done

# First boot script
cp $SOURCE_DIR/assets/firstpaas.* /opt/nicescale/support/libexec/mcollective/agent/
cp $SOURCE_DIR/assets/first-boot.sh /opt/nicescale/support/bin/
chmod +x /opt/nicescale/support/bin/first-boot.sh
touch /opt/nicescale/first-boot
cat <<-EOS > /etc/rc.local
#!/bin/sh -e
/opt/nicescale/support/bin/first-boot.sh
exit 0
EOS
