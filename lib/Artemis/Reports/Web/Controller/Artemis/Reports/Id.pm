package Artemis::Reports::Web::Controller::Artemis::Reports::Id;

use 5.010;
use strict;
use warnings;

use File::Basename;
use File::stat;
use parent 'Artemis::Reports::Web::Controller::Base';
use YAML;

use Data::Dumper;

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
        my $path = Artemis::Config->subconfig->{paths}{config_path};
        $path .= "/web/metareport_associate.yml";
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

                $path  = Artemis::Config->subconfig->{paths}{metareport_path};
                my ($filename) = sort younger <$path/$category/$subcategory/teaser/*.png>;
                if (not $filename) {
                        ($filename) = sort younger <$path/$category/$subcategory/$time_frame/*.png>;
                        $filename = "/artemis/static/metareports/$category/$subcategory/$time_frame/".basename($filename);
                } else {
                        $filename = "/artemis/static/metareports/$category/$subcategory/teaser/".basename($filename);
                }
                return () if not $filename;

                %metareport = (url => "/artemis/metareports/$category/$subcategory/$time_frame/",
                               img => $filename,
                               alt => $suite->{alt},
                               headline => $suite->{headline},
                              );
        }
        return %metareport;
}

sub index :Path :Args(1)
{
        my ( $self, $c, $report_id ) = @_;

        my $report         : Stash;
        my $reportlist_rga : Stash = {};
        my $reportlist_rgt : Stash = {};
        my %metareport     : Stash;
        my $overview       : Stash = undef;

        $report = $c->model('ReportsDB')->resultset('Report')->find($report_id);

        if (not $report) {
                $c->response->body("No such report");
                return;
        }

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
                $reportlist_rga = $c->forward('/artemis/reports/prepare_simple_reportlist', [ $rga_reports ]);
        }

        if (my $rgt = $report->reportgrouptestrun) {
                #my $rgt_reports = $c->model('ReportsDB')->resultset('ReportgroupTestrun')->search ({ testrun_id => $rgt->testrun_id });
                my $rgt_reports = $c->model('ReportsDB')->resultset('Report')->search
                    (
                     {
                      "reportgrouptestrun.testrun_id" => $rgt->testrun_id
                     },
                     {  order_by  => 'id desc',
                        join      => [ 'reportgrouparbitrary',              'reportgrouptestrun', 'suite'],
                        '+select' => [ 'reportgrouparbitrary.arbitrary_id', 'reportgrouparbitrary.primaryreport', 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport', 'suite.name', 'suite.type', 'suite.description' ],
                        '+as'     => [ 'rga_id',                            'rga_primary',                        'rgt_id',                        'rgt_primary',                      'suite_name', 'suite_type', 'suite_description' ],
                     }
                    );
                $reportlist_rgt = $c->forward('/artemis/reports/prepare_simple_reportlist', [ $rgt_reports ]);

                my %cols = $rgt_reports->first->get_columns;
                my $testrun_id = $cols{rgt_id};
                my $testrun    = $c->model('TestrunDB')->resultset('Testrun')->find($testrun_id);
                $overview      = $c->forward('/artemis/testruns/get_testrun_overview', [ $testrun ]);
        }

        my $tmp = [ grep {defined($_->{rgt_primary}) and $_->{rgt_primary} == 1} @{$reportlist_rgt->{all_reports}} ]->[0]->{suite_name};
        my $report_data = {suite => $report->suite ? $report->suite->name : 'unknownsuite' ,
                           group_suite => $tmp};

        %metareport = $self->generate_metareport_link($report_data);
}

1;
