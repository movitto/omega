%{!?ruby_sitelib: %define ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")}
%define rname motel
%define with_check 0

Name: ruby-%{rname}
Version: 0.2.0
Release: 1%{?dist}
Summary: Movable Object Tracking Encompassing Locations

Group: Development/Languages	
License: AGPL
URL: http://morsi.org/projects/motel		
Source0: http://downloads.sourceforge.net/motel/motel-0.1.tgz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildArch: noarch
BuildRequires: ruby >= 1.8
%if %with_check
#BuildRequires: ruby(active_record) >= 2.1.1
BuildRequires: ruby(qpid) >= 0.5
%endif

Requires: ruby(abi) = 1.8
#Requires: ruby(active_record) >= 2.1.1
Requires: ruby(qpid) >= 0.5
Provides: ruby(motel) = %{version}

%description
Ruby library providing 3D location tracking and movement 
in real time with AMQP interface .

%prep
%setup -q

%build

%install
rm -rf %{buildroot}

%{__install} -d -m0755 %{buildroot}%{_bindir}
%{__install} -d -m0755 %{buildroot}%{_sbindir}
%{__install} -d -m0755 %{buildroot}%{_initrddir}
%{__install} -d -m0755 %{buildroot}/%{ruby_sitelib}/
%{__install} -d -m0755 %{buildroot}/%{_sysconfdir}/motel/
%{__install} -d -m0755 %{buildroot}/%{_sysconfdir}/motel/migrations

cp -pr bin/clients/simple/main.rb  %{buildroot}/%{_bindir}/locc
cp -pr bin/server/main.rb          %{buildroot}/%{_sbindir}/locs
cp -pr conf/locs.init              %{buildroot}/%{_initrddir}/locs
cp -pr conf/*.yml                  %{buildroot}/%{_sysconfdir}/motel/
cp -pr db/migrate/*                %{buildroot}/%{_sysconfdir}/motel/migrations/
cp -pr lib/*                       %{buildroot}/%{ruby_sitelib}/

%check
%if %with_check
rake test
%endif

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_bindir}/locc
%{_sbindir}/locs
%{_initrddir}/locs
%{_sysconfdir}/motel
%{ruby_sitelib}/motel.rb
%{ruby_sitelib}/motel
#%doc README CHANGELOG LICENSE COPYING

%changelog
* Fri Sep 04 2009 Mohammed Morsi <movitto@yahoo.com>
- Initial motel specfile
