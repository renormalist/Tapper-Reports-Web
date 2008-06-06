package Artemis::Reports::Web;

use strict;
use warnings;

use Catalyst::Runtime '5.70';
use Hash::Merge;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use parent qw/Catalyst/;

our $VERSION = '2.01';

# used by Catalyst::Plugin::ConfigLoader
sub finalize_config
{
        my $c = shift;

        $c->NEXT::ACTUAL::finalize_config;
        my $env =
            $ENV{HARNESS_ACTIVE}  ? 'test'
                : $ENV{KZVS_LIVE} ? 'live'
                    : 'development';
        Hash::Merge::set_behavior('RIGHT_PRECEDENT');
        $c->config(
                   Hash::Merge::merge(
                                      $c->config,
                                      $c->config->{ $env },
                                     )
                  );
        return;
}

# Configure the application. 
#
# Note that settings in artemis_reports_web.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'Artemis::Reports::Web' );

# Start the application
__PACKAGE__->setup(qw/-Debug ConfigLoader Static::Simple/);


=head1 NAME

Artemis::Reports::Web - Catalyst based application

=head1 SYNOPSIS

    script/artemis_reports_web_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Artemis::Reports::Web::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Copyright 2008 OSRC SysInt Team, all rights reserved.

=head1 LICENSE

This program is released under the following license: restrictive

=cut

1;
