package Artemis::Reports::Web;

use strict;
use warnings;

use 5.010;

use Catalyst::Runtime '5.70';
use Hash::Merge;

use Class::C3::Adopt::NEXT;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use parent qw/Catalyst/;

our $VERSION = '2.010083';

# used by Catalyst::Plugin::ConfigLoader
sub finalize_config
{
        my $c = shift;

        $c->NEXT::ACTUAL::finalize_config;
        my $env =
            $ENV{HARNESS_ACTIVE}                 ? 'test'
                : $ENV{ARTEMIS_REPORTS_WEB_LIVE} ? 'live'
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

sub debug
{
        return $ENV{ARTEMIS_REPORTS_WEB_LIVE} || $ENV{HARNESS_ACTIVE} ? 0 : 1;
}

# I am sick of getting relocated/rebase on our local path!
# Cut away a trailing 'artemis/' from base and prepend it to path.
# All conditionally only when this annoying environment is there.
sub prepare_path
{
        my $c = shift;

        $c->NEXT::prepare_path(@_);

        my $base        =  $c->req->{base}."";
        $base           =~ s,artemis/$,, if $base;
        $c->req->{base} =  bless( do{\(my $o = $base)}, 'URI::http' );
        $c->req->path('artemis/'.$c->req->path) unless ( $c->req->path =~ m,^artemis/?,);
}


# Configure the application.
__PACKAGE__->config( name => 'Artemis::Reports::Web' );
__PACKAGE__->config->{static}->{dirs} = [
                                         'artemis/static',
                                        ];

# Start the application
__PACKAGE__->setup(qw/-Debug
                      ConfigLoader
                      Static::Simple Session
                      Session::State::Cookie
                      Session::Store::File/);


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

This program is released under the following license: proprietary

=cut

1;
