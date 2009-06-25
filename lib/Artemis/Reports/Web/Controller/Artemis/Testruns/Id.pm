package Artemis::Reports::Web::Controller::Artemis::Testruns::Id;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $testrun_id ) = @_;
        my $report         : Stash;
        
        my $reportlist_rgt : Stash = {};
        my $testrun = $c->model('TestrunDB')->resultset('Testrun')->find(id => $testrun_id);
        
        if (not $testrun) {
                $c->response->body(qq(No testrun with id "$testrun_id" found in the database!));
                return;
        }

        
        
        my $rgt_reports = $c->model('ReportsDB')->resultset('Report')->search
          (
           {
            "reportgrouptestrun.testrun_id" => $testrun_id
           },
           {  order_by  => 'id desc',
              join      => [ 'reportgrouptestrun', ],
              '+select' => [ 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport' ],
              '+as'     => [ 'rgt_id',                        'rgt_primary'                      ],
           }
          );
        $reportlist_rgt = $c->forward('/artemis/reports/prepare_simple_reportlist', [ $rgt_reports ]);
        $report = $c->model('ReportsDB')->resultset('Report')->find
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
