package Artemis::Reports::Web::Controller::Artemis::Reports::Precondition;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';
use Data::Dumper;

sub index :Path :Args(1)
{
        my ( $self, $c, $report_id ) = @_;
        my $report  : Stash = $c->model('ReportsDB')->resultset('Report')->find($report_id);

        if (my $rgt = $report->reportgrouptestrun) {
                my $testrun_search = $c->model('TestrunDB')->resultset('Testrun')->find(id => $rgt->testrun_id);
                $c->response->content_type ('plain');
                $c->response->header ("Content-Disposition" => 'inline; filename="precondition-'.$rgt->testrun_id.'.yml"');

                my @preconditions;
                foreach my $precondition ($testrun_search->ordered_preconditions) {
                        push @preconditions, $precondition->precondition;
                }
                $c->response->body ( join "", @preconditions);
        } else {
                $c->response->content_type ("plain");
                $c->response->header ("Content-Disposition" => 'inline; filename="nonexistent.report.tap.'.$report_id.'"');
                $c->response->body ("Error: No report $report_id.");
        }
}

1;
