package Artemis::Reports::Web::Controller::Artemis::Reports::Tap;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $report_id ) = @_;
        my $report : Stash = $c->model('ReportsDB')->resultset('Report')->find($report_id);

        if ($report) {
                $c->response->content_type ('plain');
                $c->response->header ("Content-Disposition" => 'attachment; filename="tap-'.$report_id.'.tap"');
                $c->response->body ($report->tap);
        }
}

1;
