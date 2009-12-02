package Artemis::Reports::Web::Controller::Artemis::Metareports;

use strict;
use warnings;
use parent 'Artemis::Reports::Web::Controller::Base';
use File::Find::Rule;

use Artemis::Config;

use 5.010;



use Data::Dumper;

sub index :Path :Args(0)
{
        my ($self, $c) = @_;

        my $path = Artemis::Config->subconfig->{paths}{metareport_path};
        my $rule =  File::Find::Rule->new;
        $rule->directory;
        $rule->relative;
        $rule->maxdepth(1);
        $rule->start("$path/");
        use Data::Dumper;
        my %categories;
	use Cwd;
        while (my $category = $rule->match) {
                print STDERR "category: ", Dumper($category);
                my $short;
                {
                        open my $fh, "<", "$path/$category/short.txt" or last;
                        $short = <$fh>;
                        close $fh;
                }
                $categories{$category}->{short} = $short ||  '';
                my $rule_cat =  File::Find::Rule->new;
                $rule_cat->directory;
                $rule_cat->relative;
                $rule_cat->maxdepth(1);
                $rule_cat->start("$path/$category");
                while (my $subcategory = $rule_cat->match) {
                        my $sub_short;
                        {
                                open my $fh, "<", "$path/$category/$subcategory/short.txt" or last;
                                $sub_short = <$fh>;
                                close $fh;
                        }
                        $categories{$category}->{data}->{$subcategory}->{short} = $sub_short || '';

                        my $rule_subcat =  File::Find::Rule->new;
                        $rule_subcat->directory;
                        $rule_subcat->relative;
                        $rule_subcat->maxdepth(1);
                        $rule_subcat->start("$path/$category/$subcategory/");

                        while (my $report = $rule_subcat->match) {
                                my $report_short;
                                {
                                        open my $fh, "<", "$path/$category/$subcategory/$report/short.txt" or last;
                                        $report_short = <$fh>;
                                        close $fh;
                                }
                                $categories{$category}->{data}->{$subcategory}->{data}->{$report}->{short} = $report_short;
                        }

                }
        }
        $c->stash(categories => \%categories);
}

sub base : Chained PathPrefix CaptureArgs(0) {
        my ( $self, $c ) = @_;
        my $rule =  File::Find::Rule->new;
        $c->stash(rule => $rule);
}

sub report_name : Chained('base') PathPart('') Args(3)
{
        my ( $self, $c, $category, $subcategory, $report_name ) = @_;
        my $path = Artemis::Config->subconfig->{paths}{metareport_path};
        $c->stash(report_name => $report_name);
        $c->stash(category    => $category, subcategory => $subcategory);

        my @files =
          map { s,^.+/([^/]+\.png),/artemis/static/metareports/$category/$subcategory/$report_name/$1,; $_ }
            qx (ls -1 $path/$category/$subcategory/$report_name/*.png | tail -1);
        print STDERR Dumper \@files;
        $c->stash(files    => \@files);
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
