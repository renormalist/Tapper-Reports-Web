package Artemis::Reports::Web::Controller::Artemis::Testruns::Id;

use 5.010;

use strict;
use warnings;
use Artemis::Model 'model';


use parent 'Artemis::Reports::Web::Controller::Base';


sub index :Path :Args(1)
{
        my ( $self, $c, $testrun_id ) = @_;
        my $report        : Stash;
        my $testrun       : Stash;
        my $overview      : Stash;
        my $hostname      : Stash;
        my $time          : Stash;

        my $reportlist_rgt : Stash = {};
        eval {
                $testrun = $c->model('TestrunDB')->resultset('Testrun')->find($testrun_id);
        };
        if ($@ or not $testrun) {
                $c->response->body(qq(No testrun with id "$testrun_id" found in the database!));
                return;
        }

        return unless $testrun->testrun_scheduling;

        $time     = $testrun->starttime_testrun ? "started at ".$testrun->starttime_testrun : "Scheduled for ".$testrun->starttime_earliest;
        $hostname = $testrun->testrun_scheduling->host ? $testrun->testrun_scheduling->host->name : "unknown";

        $overview = $c->forward('/artemis/testruns/get_testrun_overview', [ $testrun ]);

        my $rgt_reports = $c->model('ReportsDB')->resultset('Report')->search
          (
           {
            "reportgrouptestrun.testrun_id" => $testrun_id
           },
           {  order_by  => 'id desc',
              join      => [ 'reportgrouptestrun', 'suite'],
              '+select' => [ 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport', 'suite.name', 'suite.type', 'suite.description' ],
              '+as'     => [ 'rgt_id',                        'rgt_primary',                      'suite_name', 'suite_type', 'suite_description' ],
           }
          );
        $reportlist_rgt = $c->forward('/artemis/reports/prepare_simple_reportlist', [ $rgt_reports ]);
        $report = $c->model('ReportsDB')->resultset('Report')->search
          (
           {
            "reportgrouptestrun.primaryreport" => 1,
           },
           {
            join => [ 'reportgrouptestrun', ]
           }
           );



}


1;
