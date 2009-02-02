package Artemis::Reports::Web::Controller::Artemis::Reports;

use 5.010;
use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

use DateTime::Format::Natural;
use Data::Dumper;

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

        # Mnemonic:
        #           rga = ReportGroup Arbitrary
        #           rgt = ReportGroup Testrun

        my @all_reports;
        my @reports;
        my %rgt;
        my %rga;
        my %rgt_prims;
        my %rga_prims;
        say STDERR "------------------------------------------- {";
        foreach my $report ($reports->all)
        {
                #print STDERR join(", ", $report->get_columns), "\n";
                my $rga_id      = $report->get_column('rga_id');
                my $rgt_id      = $report->get_column('rgt_id');
                my $rga_primary = $report->get_column('rga_primary');
                my $rgt_primary = $report->get_column('rgt_primary');
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
                         rga_id                => $rga_id,
                         rga_primary           => $rga_primary,
                         rgt_id                => $rgt_id,
                         rgt_primary           => $rgt_primary,
                         peerport              => $report->peerport,
                         peeraddr              => $report->peeraddr,
                         peerhost              => $report->peerhost,
                        };
                #say STDERR "r = ".Dumper($r);# unless $r->{id};
                # --- arbitrary ---
                if ($rga_id and $rga_primary)
                {
                        push @reports, $r;
                        $rga_prims{$rga_id} = 1;
                }
                if ($rga_id and not $rga_primary)
                {
                        push @{$rga{$rga_id}}, $r;
                }

                # --- testrun ---
                if ($rgt_id and $rgt_primary)
                {
                        push @reports, $r;
                        $rgt_prims{$rgt_id} = 1;
                }
                if ($rgt_id and not $rgt_primary)
                {
                        push @{$rgt{$rgt_id}}, $r;
                }

                # --- none ---
                if (! $rgt_id and ! $rgt_id)
                {
                        push @reports, $r;
                }

                push @all_reports, $r; # for easier overall stats
        }
        say STDERR "\n------------------------------------------- }";

        # Find groups without primary report
        my @rga_noprim;
        my @rgt_noprim;
        foreach (keys %rga) {
                push @rga_noprim, $_ unless $rga_prims{$_};
        }
        foreach (keys %rgt) {
                push @rgt_noprim, $_ unless $rgt_prims{$_};
        }
        # Pull out latest one and put into @reports as primary
        foreach (@rga_noprim) {
                my $rga_primary = pop @{$rga{$_}};
                say STDERR "semi rga_primary: ".Dumper($rga_primary);
                push @reports, $rga_primary;
        }
        foreach (@rgt_noprim) {
                my $rgt_primary = pop @{$rgt{$_}};
                say STDERR "semi rgt_primary: ".Dumper($rgt_primary);
                push @reports, $rgt_primary;
        }

        return {
                all_reports => \@all_reports,
                reports     => \@reports,
                rga         => \%rga,
                rgt         => \%rgt,
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

        # Mnemonic: rga = ReportGroupArbitrary, rgt = ReportGroupTestrun
        my $reports = $c->model('ReportsDB')->resultset('Report')->search
            (
             $filter_condition,
             {  order_by  => 'id desc',
                join      => [ 'reportgrouparbitrary',              'reportgrouptestrun', ],
                '+select' => [ 'reportgrouparbitrary.arbitrary_id', 'reportgrouparbitrary.primaryreport', 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport' ],
                '+as'     => [ 'rga_id',                            'rga_primary',                        'rgt_id',                        'rgt_primary'                      ],
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

#         # ----- the rest -----
#         my $rest_of_reports = $reports->search ({ created_at => { '<', $day[$lastday] } });
#         push @this_weeks_reportlists, {
#                                        day => $day[$lastday],
#                                        %{ $c->forward('/artemis/reports/prepare_simple_reportlist', [ $rest_of_reports ]) }
#                                       };

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
