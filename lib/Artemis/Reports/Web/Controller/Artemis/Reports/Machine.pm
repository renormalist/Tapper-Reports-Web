package Artemis::Reports::Web::Controller::Artemis::Reports::Machine;

use 5.010;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

#

sub index :Path :Args(1)
{
        my ( $self, $c, $machine_name ) = @_;

        my $reportlist          : Stash;
        my $filter_condition    : Stash = { machine_name => $machine_name };
        my $filter_machine_name : Stash = $machine_name;

        $c->forward('/artemis/reports/prepare_this_weeks_reportlists');
        my $all_reports = $c->model('ReportsDB')->resultset('Report')->search
            (
             $filter_condition,
             {
              order_by  => 'me.id desc',
              join      => [ 'reportgrouparbitrary',              'reportgrouptestrun', 'suite' ],
              '+select' => [ 'reportgrouparbitrary.arbitrary_id', 'reportgrouptestrun.testrun_id', 'suite.id', 'suite.name', 'suite.type', 'suite.description' ],
              '+as'     => [ 'arbitrary_id',                      'testrun_id',                    'suite_id', 'suite_name', 'suite_type', 'suite_description' ],
             });
        $reportlist     = $c->forward('/artemis/reports/prepare_simple_reportlist', [ $all_reports ]);
        $c->forward('/artemis/reports/prepare_navi');
}

1;
