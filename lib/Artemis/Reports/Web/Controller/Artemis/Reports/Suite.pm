package Artemis::Reports::Web::Controller::Artemis::Reports::Suite;

use 5.010;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

#

sub index :Path :Args(1)
{
        my ( $self, $c, $suite_id ) = @_;

        my $reportlist : Stash;

        if ($suite_id eq 'all') {
                $c->detach ('/artemis/reports/suite/all');
        } else {
                my $filter_condition   : Stash = $suite_id ? { suite_id => $suite_id } : {};
                my $filter_suite       : Stash = $c->model('ReportsDB')->resultset('Suite')->find($suite_id);
                my $all_reports = $c->model('ReportsDB')->resultset('Report')->search( $filter_condition, { order_by => 'id desc' } );
                #$c->forward('/artemis/reports/prepare_this_weeks_reportlists');
                $reportlist = $c->forward('/artemis/reports/prepare_simple_reportlist', [ $all_reports ]);
         }
}

sub all : Private {
        my ( $self, $c ) = @_;

        my $template : Stash = '/artemis/reports/suite/all.mas';
        my $suites   : Stash = $c->model('ReportsDB')->resultset('Suite')->search({}, {order_by => 'name'});
}

1;
