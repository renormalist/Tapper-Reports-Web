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

sub show_all : Chained('report_name') PathPart('') Args(0)
{
        my ( $self, $c ) = @_;
        $c->stash(template => "artemis/metareports/list.mas");
        $self->list($c);
}

sub list
{
        my ( $self, $c ) = @_;
        my $rule         = $c->stash->{rule};
        my $report_name  = $c->stash->{report_name};
        $rule->start("root/artemis/static/metareports/$report_name/");
        my @files;
        while (my $match = $rule->match) {
                push @files, "/artemis/static/metareports/$report_name/$match";
        } 
        
        $c->stash(files => \@files);
}

sub days : Chained('report_name') Args(1)
{
        my ( $self, $c, $days ) = @_;
        my $report_name  = $c->stash->{report_name};
        my $day_seconds  = 24*60*60;
        my $oldest_mtime = time - $days * $day_seconds;
        $c->stash->{rule}->mtime(">=$oldest_mtime");
        $c->stash(template => "artemis/metareports/list.mas");
        $self->list($c);
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
