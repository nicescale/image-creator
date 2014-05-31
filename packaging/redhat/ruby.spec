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

BuildRequires: libffi-devel
BuildRequires: libyaml-devel
BuildRequires: openssl-devel
BuildRequires: sqlite-devel
BuildRequires: readline-devel
BuildRequires: zlib-devel

BuildArch: x86_64


%description
NiceScale management helper package.

%prep
yum groupinstall -y "Development Tools"
[ -f ruby-1.9.3-p547.tar.gz ] && rm -f ruby-1.9.3-p547.tar.gz
wget http://cache.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p547.tar.gz
[ -d ruby-1.9.3-p547 ] && rm -fr ruby-1.9.3-p547
tar -zxf ruby-1.9.3-p547.tar.gz

%build
cd ruby-1.9.3-p547
./configure --prefix=%{ruby_prefix} --disable-install-doc --disable-install-capi --disable-install-doc
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
for f in `ls %{ruby_prefix}/bin`; do
  ln -s %{ruby_prefix}/bin/$f %{bin_dir}/$f
done

%preun

%postun
bin_dir=/opt/nicescale/support/bin
for f in `ls $bin_dir`; do
  [ -L $bin_dir/$f ] && unlink $bin_dir/$f
done

%changelog
* Sat May 31 2014 mountkin@gmail.com
- Initial build
