use strict;
use warnings;

use inc::Module::Install;

name     'Tapper-Reports-Web';
all_from 'lib/Tapper/Reports/Web.pm';
author   'AMD OSRC Tapper Team <tapper@amd64.org>';
license  'freebsd';

perl_version '5.010';

build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Deep';

author_requires 'Module::Install::WriteAll';
#author_requires 'Module::Install::Catalyst';

#requires 'HTML::FromANSI';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Controller::BindLex';
requires 'Catalyst::Controller::HTML::FormFu';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Session' => "0.31";
requires 'Catalyst::Plugin::Session::State::Cookie' => "0.17";
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Runtime'     => '5.80032';
requires 'Catalyst::Test';
requires 'Catalyst::View::Mason' => '0.18';
requires 'Class::C3::Adopt::NEXT';
requires 'Data::DPath'           => "0.42";
requires 'Data::DPath';
requires 'DateTime::Format::DateParse';
requires 'DateTime::Format::Natural';
requires 'DateTime::Format::Strptime';
requires 'DateTime::Format::W3CDTF';
requires 'FCGI';
requires 'File::Copy::Recursive';
requires 'File::Find';
requires 'File::Find::Rule';
requires 'FindBin';
requires 'Getopt::Long';
requires 'HTML::FormFu';
requires 'Hash::Merge';
requires 'Pod::Usage';
requires 'Set::Intersection';
requires 'TAP::Formatter::HTML'  => '0.04';
requires 'TAP::Parser';
requires 'TAP::Parser';
requires 'Tapper::Cmd' => "3.000010";
requires 'Tapper::Config' => "3.000010";
requires 'Tapper::Model' => "3.000010";
requires 'Tapper::Schema' => "3.000010";
requires 'Tapper::TAP::Harness' => "3.000010";
requires 'Tapper::Test' => "3.000010";
requires 'Tapper::Testplan' => "3.000011";
requires 'Test::Fixture::DBIC::Schema';
requires 'Test::More';
requires 'XML::Feed';
requires 'YAML' => "0.72";
requires 'YAML::Syck' => "1.17";
requires 'common::sense';
requires 'parent';

catalyst;

install_script glob('script/*.pl');
auto_install;

repository 'git://github.com/amd/Tapper-Reports-Web.git';
bugtracker 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tapper-Reports-Web';

WriteAll;
