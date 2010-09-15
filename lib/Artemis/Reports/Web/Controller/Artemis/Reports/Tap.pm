package Artemis::Reports::Web::Controller::Artemis::Reports::Tap;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $report_id ) = @_;
        my $report : Stash = $c->model('ReportsDB')->resultset('Report')->find($report_id);

        if ($report) {
                $c->response->content_type ('text/plain');
                $c->response->header ("Content-Disposition" => 'inline; filename="tap-'.$report_id.'.tap"');
                $c->response->body ($report->tap->tap || "Error: No TAP for report $report_id.");
        } else {
                $c->response->content_type ("text/plain");
                $c->response->header ("Content-Disposition" => 'inline; filename="nonexistent.report.tap.'.$report_id.'"');
                $c->response->body ("Error: No report $report_id.");
        }
}

1;
