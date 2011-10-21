package Tapper::Reports::Web::Controller::Tapper::Reports::Id;

use 5.010;
use strict;
use warnings;

use Tapper::Reports::Web::Util::Report;
use File::Basename;
use File::stat;
use parent 'Tapper::Reports::Web::Controller::Base';
use YAML;

use Data::Dumper;
use Data::DPath 'dpath';

sub auto :Private
{
        my ( $self, $c ) = @_;

        my $navi : Stash = [
                 {
                  title  => "reports by date",
                  href   => "/tapper/overview/date",
                  subnavi => [
                              {
                               title  => "today",
                               href   => "/tapper/reports/days/1",
                              },
                              {
                               title  => "2 days",
                               href   => "/tapper/reports/days/2",
                              },
                              {
                               title  => "1 week",
                               href   => "/tapper/reports/days/7",
                              },
                              {
                               title  => "2 weeks",
                               href   => "/tapper/reports/days/14",
                              },
                              {
                               title  => "3 weeks",
                               href   => "/tapper/reports/days/21",
                              },
                              {
                               title  => "1 month",
                               href   => "/tapper/reports/days/31",
                              },
                              {
                               title  => "2 months",
                               href   => "/tapper/reports/days/62",
                              },
                              {
                               title  => "4 months",
                               href   => "/tapper/reports/days/124",
                              },
                              {
                               title  => "6 months",
                               href   => "/tapper/reports/days/182",
                              },
                              {
                               title  => "12 months",
                               href   => "/tapper/reports/days/365",
                              },

                             ],
                 },
                 {
                  title  => "reports by suite",
                  href   => "/tapper/overview/suite",
                 },
                 {
                  title  => "reports by host",
                  href   => "/tapper/overview/host",
                 },
                 # {
                 #  title  => "reports by people",
                 #  href   => "/tapper/reports/people/",
                 #  active => 0,
                 # },
                ];
}


sub younger
{
        my $astat = stat($a);
        my $bstat = stat($b);
        return $bstat->mtime() <=> $astat->mtime();
}


=head2 generate_metareport_link

Generate config for showing metareport image associated to given report.

@param hash - config describing the relevant report

@return success - hash containing (url, img, alt, headline)
@return error   - empty list

=cut

sub generate_metareport_link
{
        my ( $self, $report ) = @_;
        my %metareport;
        my $path = Tapper::Config->subconfig->{paths}{config_path};
        $path .= "/web/metareport_associate.yml";

        return if not -e $path;

        my $config;
        eval {
                $config = YAML::LoadFile($path);
        };
        if ($@) {
                # TODO: Enable Log4perl
                # $self->log->error("Can not open association config for metareports: $@");
                say STDERR "Can not open association config for metareports: $@";
                return ();
        }
        use Data::Dumper;
        my $suite;
        $suite = $config->{suite}->{$report->{suite}} || $config->{suite}->{$report->{group_suite}};
        if ($suite) {
                my $category    = $suite->{category};
                my $subcategory = $suite->{subcategory};
                my $time_frame  = $suite->{time_frame};

                $path  = Tapper::Config->subconfig->{paths}{metareport_path};
                my ($filename) = sort younger <$path/$category/$subcategory/teaser/*.png>;
                if (not $filename) {
                        ($filename) = sort younger <$path/$category/$subcategory/$time_frame/*.png>;
                        $filename = "/tapper/static/metareports/$category/$subcategory/$time_frame/".basename($filename);
                } else {
                        $filename = "/tapper/static/metareports/$category/$subcategory/teaser/".basename($filename);
                }
                return () if not $filename;

                %metareport = (url => "/tapper/metareports/$category/$subcategory/$time_frame/",
                               img => $filename,
                               alt => $suite->{alt},
                               headline => $suite->{headline},
                              );
        }
        return %metareport;
}

# get array of not_ok sub tests

sub get_report_failures
{
        my ($self, $report) = @_;

        return $report->get_cached_tapdom ~~ dpath '//tap//lines//is_ok[value eq 0]/..';
}

sub index :Path :Args(1)
{
        my ( $self, $c, $report_id ) = @_;

        my $report         : Stash;
        my $failures       : Stash = {};
        my $reportlist_rga : Stash = {};
        my $reportlist_rgt : Stash = {};
        my %metareport     : Stash;
        my $overview       : Stash = undef;
        $report = $c->model('ReportsDB')->resultset('Report')->find($report_id);

        if (not $report) {
                $c->response->body("No such report");
                $c->stash->{title} = "No such report";
                return;
        }

        my $suite_name = $report->suite->name;
        $c->stash->{title} = "Report ID $report_id, $suite_name";

        my $util_report = Tapper::Reports::Web::Util::Report->new();

        if (my $rga = $report->reportgrouparbitrary) {
                #my $rga_reports = $c->model('ReportsDB')->resultset('ReportgroupArbitrary')->search ({ arbitrary_id => $rga->arbitrary_id });
                my $rga_reports = $c->model('ReportsDB')->resultset('Report')->search
                    (
                     {
                      "reportgrouparbitrary.arbitrary_id" => $rga->arbitrary_id
                     },
                     {  order_by  => 'me.id desc',
                        join      => [ 'reportgrouparbitrary',              'reportgrouptestrun', 'suite'],
                        '+select' => [ 'reportgrouparbitrary.arbitrary_id', 'reportgrouparbitrary.primaryreport', 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport', 'suite.id', 'suite.name', 'suite.type', 'suite.description' ],
                        '+as'     => [ 'rga_id',                            'rga_primary',                        'rgt_id',                        'rgt_primary',                      'suite_id', 'suite_name', 'suite_type', 'suite_description' ],
                     }
                    );
                $reportlist_rga = $util_report->prepare_simple_reportlist($c,  $rga_reports);

                $rga_reports->reset;
                while (my $r = $rga_reports->next) {
                        if (my @report_failures = @{ $self->get_report_failures($r) }) {
                                $failures->{$r->id}{name} = $r->suite->name;
                                push @{$failures->{$r->id}{failures}}, @report_failures;
                        }
                }
        }

        if (my $rgt = $report->reportgrouptestrun) {
                #my $rgt_reports = $c->model('ReportsDB')->resultset('ReportgroupTestrun')->search ({ testrun_id => $rgt->testrun_id });
                my $rgt_reports = $c->model('ReportsDB')->resultset('Report')->search
                    (
                     {
                      "reportgrouptestrun.testrun_id" => $rgt->testrun_id
                     },
                     {  order_by  => 'me.id desc',
                        join      => [ 'reportgrouparbitrary',              'reportgrouptestrun', 'suite'],
                        '+select' => [ 'reportgrouparbitrary.arbitrary_id', 'reportgrouparbitrary.primaryreport', 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport', 'suite.name', 'suite.type', 'suite.description' ],
                        '+as'     => [ 'rga_id',                            'rga_primary',                        'rgt_id',                        'rgt_primary',                      'suite_name', 'suite_type', 'suite_description' ],
                     }
                    );
                $reportlist_rgt = $util_report->prepare_simple_reportlist($c,  $rgt_reports);

                $rgt_reports->reset;
                while (my $r = $rgt_reports->next) {
                        if (my @report_failures = @{ $self->get_report_failures($r) }) {
                                $failures->{$r->id}{name} = $r->suite->name;
                                push @{$failures->{$r->id}{failures}}, @report_failures;
                        }
                }

                my %cols = $rgt_reports->first->get_columns;
                my $testrun_id = $cols{rgt_id};
                my $testrun;
                eval {
                        $testrun    = $c->model('TestrunDB')->resultset('Testrun')->find($testrun_id);
                };
                $overview      = $c->forward('/tapper/testruns/get_testrun_overview', [ $testrun ]);
        }

        my $tmp = [ grep {defined($_->{rgt_primary}) and $_->{rgt_primary} == 1} @{$reportlist_rgt->{all_reports}} ]->[0]->{suite_name};
        my $report_data = {suite => $report->suite ? $report->suite->name : 'unknownsuite' ,
                           group_suite => $tmp};

        unless (my @report_failures = @{$failures->{$report->id}{failures} || []}) {
                $failures->{$report->id}{name} = $report->suite->name;
                push @{$failures->{$report->id}{failures}}, @report_failures;
        }
        %metareport = $self->generate_metareport_link($report_data);

}

1;
