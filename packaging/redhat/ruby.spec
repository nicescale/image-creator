Summary: NiceScale ruby 1.9.3-p547
Name: ns-ruby
Version: 1.9.3
Release: 1
License: Ruby License/GPL - see COPYING
URL: http://cache.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p547.tar.gz
Source: http://cache.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p547.tar.gz
BuildRoot: %{_tmppath}/%{name}

Requires: libffi
Requires: libyaml
Requires: openssl
Requires: sqlite
Requires: readline
Requires: zlib

BuildArch: x86_64

%description
A dynamic, open source programming language with a focus on simplicity and 
productivity. It has an elegant syntax that is natural to read and easy to write.

%prep
yum groupinstall -y "Development Tools"
yum install -y libffi-devel libyaml-devel openssl-devel sqlite-devel readline-devel zlib-devel

[ -f ruby-1.9.3-p547.tar.gz ] && rm -f ruby-1.9.3-p547.tar.gz
wget http://cache.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p547.tar.gz
[ -d ruby-1.9.3-p547 ] && rm -fr ruby-1.9.3-p547
tar -zxf ruby-1.9.3-p547.tar.gz

%build
cd ruby-1.9.3-p547
./configure --prefix=%{ruby_prefix} --disable-install-doc --disable-install-capi --disable-install-doc --bindir=%{bin_dir} --sbindir=%{sbin_dir}
make -j8

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
cd ruby-1.9.3-p547
make DESTDIR=$RPM_BUILD_ROOT install
install -d -m 0755 $RPM_BUILD_ROOT/%{bin_dir}
install -d -m 0755 $RPM_BUILD_ROOT/%{sbin_dir}
install -d -m 0755 $RPM_BUILD_ROOT/%{ns_config_dir}

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root, 0755)

%dir
%{ruby_prefix}
%{sbin_dir}
%{bin_dir}
%{ns_config_dir}

%pre

%post

%preun

%postun

%changelog
* Sat May 31 2014 mountkin@gmail.com
- Initial build
