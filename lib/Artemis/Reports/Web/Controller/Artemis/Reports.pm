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

        my @reports;
        my %reportgrouptestrun;
        my %reportgrouparbitrary;
        while (my $report = $reports->next)
        {
                #print STDERR join(", ", $report->get_columns), "\n";
                my $reportgroup_arbitrary_id = $report->get_column('arbitrary_id');
                my $reportgroup_testrun_id   = $report->get_column('testrun_id');
                my $r = {
                         id                       => $report->id,
                         suite_name               => $report->suite ? $report->suite->name : 'unknown',
                         suite_id                 => $report->suite ? $report->suite->id : '0',
                         machine_name             => $report->machine_name || 'unknown',
                         created_at_ymd_hms       => $report->created_at->ymd('-')." ".$report->created_at->hms(':'),
                         created_at_ymd           => $report->created_at->ymd('-'),
                         success_ratio            => $report->success_ratio,
                         successgrade             => $report->successgrade,
                         reviewed_successgrade    => $report->reviewed_successgrade,
                         total                    => $report->total,
                         reportgroup_arbitrary_id => $reportgroup_arbitrary_id,
                         reportgroup_testrun_id   => $reportgroup_testrun_id,
                         peerport                 => $report->peerport,
                         peeraddr                 => $report->peeraddr,
                         peerhost                 => $report->peerhost,
                        };
                push @reports, $r;
                push @{$reportgrouptestrun{$reportgroup_testrun_id}},     $report->id if $reportgroup_testrun_id;
                push @{$reportgrouparbitrary{$reportgroup_arbitrary_id}}, $report->id if $reportgroup_arbitrary_id;
        }
        # delete single entry groups
        foreach (keys %reportgrouptestrun) {
                delete $reportgrouptestrun{$_} if @{$reportgrouptestrun{$_}} == 1;
        }
        foreach (keys %reportgrouparbitrary) {
                delete $reportgrouparbitrary{$_} if @{$reportgrouparbitrary{$_}} == 1;
        }
        return {
                reports              => \@reports,
                reportgrouptestrun   => \%reportgrouptestrun,
                reportgrouparbitrary => \%reportgrouparbitrary
               };
}

sub prepare_this_weeks_reportlists : Private
{
        my ( $self, $c ) = @_;

        my $filter_condition       : Stash;
        my @this_weeks_reportlists : Stash = ();

        # how long is "last weeks"
        my $days : Stash;
        my $lastday = $days ? $days - 1 : 6;

        # ----- general -----

        my $reports = $c->model('ReportsDB')->resultset('Report')->search
            (
             $filter_condition,
             {  order_by  => 'id desc',
                join      => [ 'reportgrouparbitrary',              'reportgrouptestrun' ],
                '+select' => [ 'reportgrouparbitrary.arbitrary_id', 'reportgrouptestrun.testrun_id' ],
                '+as'     => [ 'arbitrary_id',                      'testrun_id' ]
             }
            );

        my $parser = new DateTime::Format::Natural;
        my $today = $parser->parse_datetime("today at midnight");
        my @day = ( $today );
        push @day, $today->clone->subtract( days => $_ ) foreach 1..$lastday;

        # ----- today -----
        my $day0_reports = $reports->search ( { created_at => { '>', $day[0] } } );
        push @this_weeks_reportlists, {
                                       day => $day[0],
                                       %{ $c->forward('/artemis/reports/prepare_simple_reportlist', [ $day0_reports ]) }
                                      };

        # ----- last week days -----
        foreach (1..$lastday) {
                my $day_reports = $reports->search ({ -and => [ created_at => { '>', $day[$_]     },
                                                                created_at => { '<', $day[$_ - 1] },
                                                              ]});
                push @this_weeks_reportlists, {
                                               day => $day[$_],
                                               %{ $c->forward('/artemis/reports/prepare_simple_reportlist', [ $day_reports ]) }
                                              };
        }

        # ----- the rest -----
        my $rest_of_reports = $reports->search ({ created_at => { '<', $day[$lastday] } });
        push @this_weeks_reportlists, {
                                       day => $day[$lastday],
                                       %{ $c->forward('/artemis/reports/prepare_simple_reportlist', [ $rest_of_reports ]) }
                                      };

}

sub prepare_navi : Private
{
        my ( $self, $c ) = @_;

        my $navi : Stash = [
                            {
                             title  => "reports by date",
                             href   => "/artemis/reports/date/7",
                             active => 0,
                             subnavi => [
                                         {
                                          title  => "1 week",
                                          href   => "/artemis/reports/date/7",
                                         },
                                         {
                                          title  => "2 weeks",
                                          href   => "/artemis/reports/date/14",
                                         },
                                         {
                                          title  => "3 weeks",
                                          href   => "/artemis/reports/date/21",
                                         },
                                         {
                                          title  => "1 month",
                                          href   => "/artemis/reports/date/30",
                                         },
                                         {
                                          title  => "2 months",
                                          href   => "/artemis/reports/date/60",
                                         },
                                        ],
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
