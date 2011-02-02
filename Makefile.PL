# IMPORTANT: if you delete this file your app will not work as
# expected.  you have been warned
use inc::Module::Install;

name     'Tapper-Reports-Web';
all_from 'lib/Tapper/Reports/Web.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';
license  'freebsd';

perl_version '5.010';

build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::Perl::Critic';

#requires 'HTML::FromANSI';
requires 'Tapper::Cmd'          => '2.010035';
requires 'Tapper::Config'       => '2.010074';
requires 'Tapper::Schema'       => '2.010067';
requires 'Tapper::TAP::Harness' => '2.010030';
requires 'Tapper::Test';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Controller::BindLex';
requires 'Catalyst::Controller::HTML::FormFu';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Runtime'     => '5.7014';
requires 'Catalyst::Test';
requires 'Catalyst::View::Mason' => '0.18';
requires 'Class::C3::Adopt::NEXT';
requires 'common::sense';
requires 'Data::DPath';
requires 'DateTime::Format::DateParse';
requires 'DateTime::Format::Natural';
requires 'FCGI';
requires 'FindBin';
requires 'File::Find';
requires 'File::Find::Rule';
requires 'Getopt::Long';
requires 'Data::DPath' => "0.42";
requires 'TAP::Parser';
requires 'Hash::Merge';
requires 'HTML::FormFu';
requires 'parent';
requires 'Pod::Usage';
requires 'TAP::Formatter::HTML'  => '0.04';
requires 'TAP::Parser';
requires 'Test::Fixture::DBIC::Schema';
requires 'Test::More';
requires 'XML::Feed';
requires 'YAML';

catalyst;

install_script glob('script/*.pl');
auto_install;

WriteAll;
