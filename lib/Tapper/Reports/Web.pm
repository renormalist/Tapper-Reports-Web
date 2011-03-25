package Tapper::Reports::Web;

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

our $VERSION = '3.000006';

# used by Catalyst::Plugin::ConfigLoader
sub finalize_config
{
        my $c = shift;

        $c->NEXT::ACTUAL::finalize_config;
        my $env =
            $ENV{HARNESS_ACTIVE}                 ? 'test'
                : $ENV{TAPPER_REPORTS_WEB_LIVE} ? 'live'
                    : 'development';
        Hash::Merge::set_behavior('RIGHT_PRECEDENT');
        $c->config(
                   Hash::Merge::merge(
                                      $c->config,
                                      $c->config->{ $env } || {} ,
                                     )
                  );

        return;
}

sub debug
{
        return $ENV{TAPPER_REPORTS_WEB_LIVE} || $ENV{HARNESS_ACTIVE} ? 0 : 1;
}

# I am sick of getting relocated/rebase on our local path!
# Cut away a trailing 'tapper/' from base and prepend it to path.
# All conditionally only when this annoying environment is there.
sub prepare_path
{
        my $c = shift;

        $c->NEXT::prepare_path(@_);

        my $base        =  $c->req->{base}."";
        $base           =~ s,tapper/$,, if $base;
        $c->req->{base} =  bless( do{\(my $o = $base)}, 'URI::http' );
        $c->req->path('tapper/'.$c->req->path) unless ( $c->req->path =~ m,^tapper/?,);
}


# Configure the application.
__PACKAGE__->config( name => 'Tapper::Reports::Web' );
__PACKAGE__->config->{static}->{dirs} = [
                                         'tapper/static',
                                        ];

# Start the application
__PACKAGE__->setup(qw/-Debug
                      ConfigLoader
                      Static::Simple Session
                      Session::State::Cookie
                      Session::Store::File/);


=head1 NAME

Tapper::Reports::Web - Tapper - Frontend web application based on Catalyst

=head1 SYNOPSIS

    script/tapper_reports_web_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Tapper::Reports::Web::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

=head1 LICENSE

This program is released under the following license: proprietary

=cut

1;
