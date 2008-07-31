package Artemis::Reports::Web::Controller::Artemis::Reports;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

use DateTime::Format::Natural;

sub auto :Pivate
{
        my ( $self, $c ) = @_;

        $c->forward('/artemis/reports/prepare_navi');
}

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
                         id                    => $report->id,
                         suite_name            => $report->suite ? $report->suite->name : 'unknown',
                         suite_id              => $report->suite ? $report->suite->id : '0',
                         machine_name          => $report->machine_name || 'unknown',
                         created_at_ymd_hms    => $report->created_at->ymd('-')." ".$report->created_at->hms(':'),
                         created_at_ymd        => $report->created_at->ymd('-'),
                         success_ratio         => $report->success_ratio,
                         successgrade          => $report->successgrade,
                         reviewed_successgrade => $report->reviewed_successgrade,
                         total                 => $report->total,
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
        push @this_weeks_reportlists, {
                                       day     => $day[0],
                                       reports => $c->forward('/artemis/reports/prepare_simple_reportlist', [ $day0_reports ])
                                      };

        # ----- last week days -----
        foreach (1..6) {
                my $day_reports = $reports->search ({ -and => [ created_at => { '>', $day[$_]     },
                                                                created_at => { '<', $day[$_ - 1] },
                                                              ]});
                push @this_weeks_reportlists, {
                                               day => $day[$_],
                                               reports => $c->forward('/artemis/reports/prepare_simple_reportlist', [ $day_reports ])
                                              };
        }

        # ----- the rest -----
        my $rest_of_reports = $reports->search ({ created_at => { '<', $day[6] } });
        push @this_weeks_reportlists, {
                                       day => $day[6],
                                       reports => $c->forward('/artemis/reports/prepare_simple_reportlist', [ $rest_of_reports ])
                                      };

}

sub prepare_navi : Private
{
        my ( $self, $c ) = @_;

        my $navi : Stash = [
                            {
                             title  => "reports by date",
                             href   => "/artemis/reports/date/",
                             active => 0,
#                              subnavi => [
#                                          {
#                                           title  => "week",
#                                           href   => "/artemis/reports/date/week/",
#                                          },
#                                          {
#                                           title  => "month",
#                                           href   => "/artemis/reports/date/month/",
#                                          },
#                                          {
#                                           title  => "year",
#                                           href   => "/artemis/reports/date/year/",
#                                          },
#                                          {
#                                           title  => "all",
#                                           href   => "/artemis/reports/date/all/",
#                                          },
#                                         ],
                            },
                            {
                             title  => "reports by suite",
                             href   => "/artemis/reports/suite/all",
                             active => 0,
                            },
                            {
                             title  => "reports by topic",
                             href   => "/artemis/reports/topic/",
                             active => 0,
                            },
                            {
                             title  => "reports by people",
                             href   => "/artemis/reports/people/",
                             active => 0,
                            },
                           ];
}

1;
