package Artemis::Reports::Web::Controller::Artemis::Reports;


use parent 'Artemis::Reports::Web::Controller::Base';

use DateTime::Format::Natural;
use Data::Dumper;

use Artemis::Reports::Web::Util::Filter;
use Artemis::Reports::Web::Util::Report;
use common::sense;


sub auto :Private
{
        my ( $self, $c ) = @_;

        $c->forward('/artemis/reports/prepare_navi');
}



sub index :Path :Args()
{
        my ( $self, $c, @args ) = @_;
        my $error_msg : Stash;

        exit 0 if $args[0] eq 'exit';

        my $filter = Artemis::Reports::Web::Util::Filter->new(context => $c);
        my $filter_condition = $filter->parse_filters(\@args);

        if ($filter_condition->{error}) {
                $error_msg = join("; ", @{$filter_condition->{error}});
                $c->res->redirect("/artemis/reports/");

        }

        my $requested_day : Stash = 
          $filter->requested_day || DateTime::Format::Natural->new->parse_datetime("today at midnight");

        $filter->{early}->{-or} = [{rga_primary => 1}, {rgt_primary => 1}];
        $c->forward('/artemis/reports/prepare_this_weeks_reportlists', [ $filter_condition ]);

}


sub prepare_this_weeks_reportlists : Private
{
        my ( $self, $c, $filter_condition ) = @_;

        my @this_weeks_reportlists : Stash = ();
        my $requested_day          : Stash;
        my $days                   : Stash = $filter_condition->{days};
        my $date                   : Stash = $filter_condition->{date};

        $filter_condition->{early} =  {} unless
          defined($filter_condition->{early}) and
            ref($filter_condition->{early}) eq 'HASH' ;

        # how long is "last weeks"
        my $lastday = $filter_condition->{days} ? $filter_condition->{days} - 1 : 6;

        # ----- general -----

        # Mnemonic: rga = ReportGroupArbitrary, rgt = ReportGroupTestrun
        my $reports = $c->model('ReportsDB')->resultset('Report')->search
            (
             $filter_condition->{early},
             {  order_by  => 'me.id desc',
                columns   => [ qw( id
                                   machine_name
                                   created_at
                                   success_ratio
                                   successgrade
                                   reviewed_successgrade
                                   total
                                   peerport
                                   peeraddr
                                   peerhost
                                )],
                join      => [ 'reportgrouparbitrary',              'reportgrouptestrun', 'suite' ],
                '+select' => [ 'reportgrouparbitrary.arbitrary_id', 'reportgrouparbitrary.primaryreport', 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport', 'suite.id', 'suite.name', 'suite.type', 'suite.description' ],
                '+as'     => [ 'rga_id',                            'rga_primary',                        'rgt_id',                        'rgt_primary',                      'suite_id', 'suite_name', 'suite_type', 'suite_description' ],
             }
            );
        foreach my $filter (@{$filter_condition->{late}}) {
                $reports = $reports->search($filter);
        }


        my $util_report = Artemis::Reports::Web::Util::Report->new();

        my @day    = ( $requested_day );
        push @day, $requested_day->clone->subtract( days => $_ ) foreach 1..$lastday;

        # ----- today -----
        my $day0_reports = $reports->search ( { created_at => { '>', $day[0] } } );
        push @this_weeks_reportlists, {
                                       day => $day[0],
                                       %{ $util_report->prepare_simple_reportlist($c, $day0_reports) }
                                      };

        # ----- last week days -----
        foreach (1..$lastday) {
                my $day_reports = $reports->search ({ -and => [ created_at => { '>', $day[$_]     },
                                                                created_at => { '<', $day[$_ - 1] },
                                                              ]});
                push @this_weeks_reportlists, {
                                               day => $day[$_],
                                               %{ $util_report->prepare_simple_reportlist($c, $day_reports) }
                                              };
        }


        my $list_count_all     : Stash = 0;
        my $list_count_pass    : Stash = 0;
        my $list_count_fail    : Stash = 0;
        my $list_count_unknown : Stash = 0;

        foreach (0..$lastday) {
                my $reportlist = $this_weeks_reportlists[$_];
                $list_count_all += @{$reportlist->{all_reports}};
                foreach my $report (@{$reportlist->{all_reports}}) {
                        if    ($report->{successgrade} eq 'PASS') { $list_count_pass++    }
                        elsif ($report->{successgrade} eq 'FAIL') { $list_count_fail++    }
                        else                                      { $list_count_unknown++ }
                }
        }
}

sub prepare_filter_path
{
        my ($self, $c, $days) = @_;
        my %args = @{$c->req->arguments};

        $args{days} = $days if $days;

        return join('/', %args );
}

sub prepare_navi : Private
{
        my ( $self, $c ) = @_;
        my $navi : Stash = [];

        my %args = @{$c->req->arguments};
        return [] if grep { /^date$/ } keys %args;

        $navi = [
                 {
                  title  => "reports by date",
                  href   => "/artemis/overview/date",
                  subnavi => [
                              {
                               title  => "today",
                               href   => "/artemis/reports/".$self->prepare_filter_path($c, 1),
                              },
                              {
                               title  => "2 days",
                               href   => "/artemis/reports/".$self->prepare_filter_path($c, 2),
                              },
                              {
                               title  => "1 week",
                               href   => "/artemis/reports/".$self->prepare_filter_path($c, 7),
                              },
                              {
                               title  => "2 weeks",
                               href   => "/artemis/reports/".$self->prepare_filter_path($c, 14),
                              },
                              {
                               title  => "3 weeks",
                               href   => "/artemis/reports/".$self->prepare_filter_path($c, 21),
                              },
                              {
                               title  => "1 month",
                               href   => "/artemis/reports/".$self->prepare_filter_path($c, 31),
                              },
                              {
                               title  => "2 months",
                               href   => "/artemis/reports/".$self->prepare_filter_path($c, 62),
                              },
                              {
                               title  => "4 months",
                               href   => "/artemis/reports/".$self->prepare_filter_path($c, 124),
                              },
                              {
                               title  => "6 months",
                               href   => "/artemis/reports/".$self->prepare_filter_path($c, 182),
                              },
                              {
                               title  => "12 months",
                               href   => "/artemis/reports/".$self->prepare_filter_path($c, 365),
                              },

                             ],
                 },
                 {
                  title  => "reports by suite",
                  href   => "/artemis/overview/suite",
                 },
                 {
                  title  => "reports by host",
                  href   => "/artemis/overview/host",
                 },
                 {
                  title  => "This list as RSS",
                  href   => "/artemis/rss/".$self->prepare_filter_path($c),
                  image  => "/artemis/static/images/rss.png",
                 }

                 # {
                 #  title  => "reports by people",
                 #  href   => "/artemis/reports/people/",
                 #  active => 0,
                 # },
                ];

}

1;
