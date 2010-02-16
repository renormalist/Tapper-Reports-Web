package Artemis::Reports::Web::Controller::Artemis::Reports::Id;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

sub generate_metareport_link
{
        my ( $self ) = @_;
        my %metareport;
        %metareport = (url => '/artemis/metareports/Topic-ratio/AIMbench/monthly/',
                       img => "/artemis/static/metareports/Topic-ratio/AIMbench/monthly/2010-02-15_success_ratio_AIMbench.png",
                       alt => 'Metareport');
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
        
        %metareport = generate_metareport_link();
}

1;
