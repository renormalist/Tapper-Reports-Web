# IMPORTANT: if you delete this file your app will not work as
# expected.  you have been warned
use inc::Module::Install;

name 'Artemis-Reports-Web';
all_from 'lib/Artemis/Reports/Web.pm';
license 'restrictive';

perl_version '5.010';

requires 'Artemis::Test';
requires 'Artemis::Config'       => '2.01';
requires 'Artemis::Cmd'          => '2.010018';
requires 'Artemis::Schema'       => '2.01';
requires 'Artemis::TAP::Harness' => '2.010030';
requires 'Catalyst::Runtime'     => '5.7014';
requires 'Catalyst::Test';
requires 'Catalyst::View::Mason' => '0.18';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Controller::HTML::FormFu';
requires 'Catalyst::Controller::BindLex';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Action::RenderView';
requires 'HTML::FormFu';
requires 'Test::Fixture::DBIC::Schema';
requires 'DateTime::Format::Natural';
requires 'DateTime::Format::DateParse';
requires 'TAP::Formatter::HTML'  => '0.04';
requires 'Getopt::Long';
requires 'TAP::Parser';
requires 'Hash::Merge';
requires 'Test::More';
requires 'Pod::Usage';
requires 'FindBin';
requires 'YAML';
requires 'FCGI';
requires 'parent';
requires 'Class::C3::Adopt::NEXT';
requires 'TryCatch';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
