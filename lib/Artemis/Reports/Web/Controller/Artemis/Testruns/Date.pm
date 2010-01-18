package Artemis::Reports::Web::Controller::Artemis::Testruns::Date;

use 5.010;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

#

sub auto :Private
{
        my ( $self, $c ) = @_;

        $c->forward('/artemis/testruns/prepare_navi');
}

sub index :Path :Args(1)
{
        my ( $self, $c, $showdays ) = @_;

        my $days             : Stash = $showdays || 2;

        # select report_id, rgt.testrun_id, rgts.success_ratio from reportgrouptestrun rgt, reportgrouptestrunstats rgts where rgt.testrun_id=rgts.testrun_id and rgt.testrun_id=25126 group by rgt.testrun_id;

        my $filter_condition : Stash = {
                                        #report_id, rgt.testrun_id, rgts.success_ratio from reportgrouptestrun rgt, reportgrouptestrunstats rgts where rgt.testrun_id=rgts.testrun_id group by rgt.testrun_id;
                                        "me.id" => { '>=', 22530 }
                                       };
        $c->forward('/artemis/testruns/prepare_this_weeks_reportlists');
}


1;
