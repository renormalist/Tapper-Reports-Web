package Artemis::Reports::Web::Controller::Artemis::Reports;

use strict;
use warnings;
use diagnostics;

use parent 'Catalyst::Controller::BindLex';
__PACKAGE__->config->{bindlex}{Param} = sub { $_[0]->req->params };

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
}

sub prepare_simple_reportlist : Private
{
        my ( $self, $c, $reports ) = @_;

        my @simple_reportlist : Stash;
        while (my $report = $reports->next)
        {
                my $r = {
                         id                 => $report->id,
                         suite_name         => $report->suite ? $report->suite->name : 'unknown',
                         suite_id           => $report->suite ? $report->suite->id : '0',
                         machine_name       => $report->machine_name || 'unknown',
                         created_at_ymd_hms => $report->created_at->ymd('-')." ".$report->created_at->hms(':'),
                         created_at_ymd     => $report->created_at->ymd('-'),
                         success_ratio      => $report->success_ratio,
                        };
                push @simple_reportlist, $r;
        }
}

1;
