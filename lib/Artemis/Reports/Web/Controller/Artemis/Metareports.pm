package Artemis::Reports::Web::Controller::Artemis::Metareports;

use strict;
use warnings;
use parent 'Artemis::Reports::Web::Controller::Base';
use File::Find::Rule;

use 5.010;



use Data::Dumper;

sub index :Path :Args(0)
{
        my ($self, $c) = @_;

        my $home = $c->path_to();
        my $rule =  File::Find::Rule->new;
        $rule->directory;
        $rule->relative;
        $rule->maxdepth(1);
        $rule->start("$home/root/artemis/static/metareports/");
        use Data::Dumper;
        print STDERR "home: $home\n";
        print STDERR "rule: ", Dumper($rule);
        my %categories;
        while (my $category = $rule->match) {
                print STDERR "category: ", Dumper($category);
                my ($short);
                {
                        open my $fh, "<", "$home/root/artemis/static/metareports/$category/short.txt" or last;
                        $short = <$fh>;
                        close $fh;
                }
                $categories{$category}->{short} = $short ||  '';
                my $rule_cat =  File::Find::Rule->new;
                $rule_cat->directory;
                $rule_cat->relative;
                $rule_cat->maxdepth(1);
                $rule_cat->start("$home/root/artemis/static/metareports/$category");
                while (my $report = $rule_cat->match) {
                        {
                                open my $fh, "<", "$home/root/artemis/static/metareports/$category/$report/short.txt" or last;
                                $short = <$fh>;
                                close $fh;
                        }
                        $categories{$category}->{data}->{$report}->{short} = $short || 'No short description';
                }
        }
        $c->stash(categories => \%categories);
}

sub base : Chained PathPrefix CaptureArgs(0) {
        my ( $self, $c ) = @_;
        my $rule =  File::Find::Rule->new;
        $c->stash(rule => $rule);
}

sub report_name : Chained('base') PathPart('') Args(2)
{
        my ( $self, $c, $category, $report_name ) = @_;

        my $home = $c->path_to();
        my $rule =  File::Find::Rule->new;
        $c->stash(report_name => $report_name);
        $c->stash(category    => $category);
        $rule->file;
        $rule->relative;
        $rule->name( '*.png' );
        $rule->start("$home/root/artemis/static/metareports/$category/$report_name/");
        my @files;
        while (my $match = $rule->match) {
                push @files, "/artemis/static/metareports/$category/$report_name/$match";
        }
        $c->stash(files    => \@files);
        print STDERR Dumper \@files;
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
