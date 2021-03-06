package Tapper::Reports::Web::Controller::Tapper::Reports::Tap;

use strict;
use warnings;

use parent 'Tapper::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $report_id ) = @_;
        my $report : Stash = $c->model('ReportsDB')->resultset('Report')->find($report_id);

        if ($report) {
                if ($report->tap->tap_is_archive) {
                        $c->response->content_type ('application/x-compressed');
                        $c->response->header ("Content-Disposition" => 'inline; filename="tap-'.$report_id.'.tgz"');
                } else {
                        $c->response->content_type ('text/plain');
                        $c->response->header ("Content-Disposition" => 'inline; filename="tap-'.$report_id.'.tap"');
                }
                $c->response->body ($report->tap->tap || "Error: No TAP for report $report_id.");
        } else {
                $c->response->content_type ("text/plain");
                $c->response->header ("Content-Disposition" => 'inline; filename="nonexistent.report.tap.'.$report_id.'"');
                $c->response->body ("Error: No report $report_id.");
        }
}

1;
