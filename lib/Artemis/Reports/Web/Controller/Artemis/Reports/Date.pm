package Artemis::Reports::Web::Controller::Artemis::Reports::Date;

use strict;
use warnings;

use parent 'Catalyst::Controller::BindLex';
__PACKAGE__->config->{bindlex}{Param} = sub { $_[0]->req->params };

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;

        my @reports : Stash;
        my $reports = $c->model('ReportsDB')->resultset('Report')->search({}, {order_by => 'id desc'});

        while (my $report = $reports->next)
        {
                my $r = {
                         id           => $report->id,
                         suite_name   => $report->suite ? $report->suite->name : 'unknown',
                         suite_id     => $report->suite ? $report->suite->id : '0',
                         machine_name => $report->machine_name || 'unknown',
                         created_at   => $report->created_at->ymd('-')." ".$report->created_at->hms(':'),
                        };
                push @reports, $r;
        }
}

1;
