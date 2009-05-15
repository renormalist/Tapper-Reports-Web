package Artemis::Reports::Web::Controller::Artemis::Reports::Id;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $report_id ) = @_;

        my $report         : Stash;
        my $reportlist_rga : Stash = {};
        my $reportlist_rgt : Stash = {};

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
                        join      => [ 'reportgrouparbitrary',              'reportgrouptestrun', ],
                        '+select' => [ 'reportgrouparbitrary.arbitrary_id', 'reportgrouparbitrary.primaryreport', 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport' ],
                        '+as'     => [ 'rga_id',                            'rga_primary',                        'rgt_id',                        'rgt_primary'                      ],
                     }
                    );
                $reportlist_rgt = $c->forward('/artemis/reports/prepare_simple_reportlist', [ $rgt_reports ]);
        }
}

1;
