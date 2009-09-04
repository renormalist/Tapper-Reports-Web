package Artemis::Reports::Web::Controller::Artemis::Metareports;

use strict;
use warnings;
use parent 'Artemis::Reports::Web::Controller::Base';
use File::Find::Rule;

use 5.010;



use Data::Dumper;

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
        return;
}

sub base : Chained PathPrefix CaptureArgs(0) { }

sub report_name : Chained('base') PathPart('') CaptureArgs(1)
{
        my ( $self, $c, $report_name ) = @_;
        my $rule =  File::Find::Rule->new;
        $c->stash(report_name => $report_name);
        $rule->file;
        $rule->relative;
        $rule->name( '*.png' );
        $c->stash(rule => $rule);

}

sub days : Chained('report_name') PathPart('days') Args(1)
{
        my ( $self, $c, $days ) = @_;
        my $rule         = $c->stash->{rule};
        my $report_name  = $c->stash->{report_name};
        my $day_seconds  = 24*60*60;
        my $oldest_mtime = time - $days * $day_seconds;
        $rule->mtime(">=$oldest_mtime");
        $rule->start("root/artemis/static/metareports/$report_name/");
        my @files;
        while (my $match = $rule->match) {
                push @files, "/artemis/static/metareports/$report_name/$match";
        } 
        
        say STDERR "files found";
        say STDERR join "\n",@files;
        $c->stash(files => \@files);
}

=head1 NAME

Artemis::Reports::Web::Controller::Artemis::Testruns - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index



=head1 AUTHOR

OSRC SysInt

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
