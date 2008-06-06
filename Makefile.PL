# IMPORTANT: if you delete this file your app will not work as
# expected.  you have been warned
use inc::Module::Install;

name 'Artemis-Reports-Web';
all_from 'lib/Artemis/Reports/Web.pm';

perl_version '5.010';

requires 'Artemis::Config'       => '2.01';
requires 'Artemis::Schema'       => '2.01';
requires 'Catalyst::Runtime'     => '5.7014';
requires 'Catalyst::View::Mason' => '0.16';
requires 'Catalyst::Test';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Controller::HTML::FormFu';
requires 'Catalyst::Controller::BindLex';
requires 'Catalyst::Action::RenderView';
requires 'TAP::Formatter::HTML';
requires 'TAP::Parser';
requires 'Hash::Merge';
requires 'parent';
requires 'YAML';
requires 'FindBin';
requires 'Pod::Usage';
requires 'Test::More';
requires 'Getopt::Long';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
