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

        my @reportlist;
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
                push @reportlist, $r;
        }
        return \@reportlist;
}

sub prepare_this_weeks_reportlists : Private
{
        my ( $self, $c ) = @_;

        my $filter_condition       : Stash;
        my @this_weeks_reportlists : Stash = ();


        # ----- general -----

        my $reports = $c->model('ReportsDB')->resultset('Report')->search
            (
             $filter_condition,
             { order_by => 'id desc' },
            );

        my $parser = new DateTime::Format::Natural;
        my $today = $parser->parse_datetime("today at midnight");
        my @day = (
                   $today,                               # 0, e.g., Sunday
                   $today->clone->subtract( days => 1 ), # 1, e.g., Saturday
                   $today->clone->subtract( days => 2 ), # 2, e.g., Friday
                   $today->clone->subtract( days => 3 ), # 3, e.g., Thursday
                   $today->clone->subtract( days => 4 ), # 4, e.g., Wednesday
                   $today->clone->subtract( days => 5 ), # 5, e.g., Tuesday
                   $today->clone->subtract( days => 6 ), # 6, e.g., Monday
                  );

        # ----- today -----
        my $day0_reports = $reports->search ( { created_at => { '>', $day[0] } } );
        push @this_weeks_reportlists, $c->forward('/artemis/reports/prepare_simple_reportlist', [ $day0_reports ]);

        # ----- last week days -----
        foreach (1..6) {
                my $day_reports = $reports->search ({ -and => [ created_at => { '>', $day[$_]     },
                                                                created_at => { '<', $day[$_ - 1] },
                                                              ]});
                push @this_weeks_reportlists, $c->forward('/artemis/reports/prepare_simple_reportlist', [ $day_reports ]);
        }

        # ----- the rest -----
        my $rest_of_reports = $reports->search ({ created_at => { '<', $day[6] } });
        push @this_weeks_reportlists, $c->forward('/artemis/reports/prepare_simple_reportlist', [ $rest_of_reports ]);

}

1;
