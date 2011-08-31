package Tapper::Reports::Web::Controller::Tapper::Testplan;

use parent 'Tapper::Reports::Web::Controller::Base';

use common::sense;
## no critic (RequireUseStrict)

use DateTime::Format::Natural;
use Tapper::Reports::Web::Util::Filter::Testplan;
use Tapper::Model 'model';

sub auto :Private
{
        my ( $self, $c ) = @_;

        $c->forward('/tapper/testplan/prepare_navi');
}


=head2 index



=cut

sub index :Path :Args()
{
        my ( $self, $c, @args ) = @_;
        my $error_msg : Flash;

        my $filter = Tapper::Reports::Web::Util::Filter::Testplan->new(context => $c);
        my $filter_condition = $filter->parse_filters(\@args, ['days', 'date', 'path', 'name']);
        $c->stash->{title} = "Testplan list";

        if ($filter_condition->{error}) {
                $error_msg = join("; ", @{$filter_condition->{error}});
                $c->res->redirect("/tapper/testplan/days/2");
        }

        my $days = $filter_condition->{days} || 6;

        my $testplan_days : Stash = [];
        my $today = DateTime::Format::Natural->new->parse_datetime("today at midnight");

        # testplans after "today at midnight"
        # handling them special makes later code more readable
        {
                my $todays_instances = model('TestrunDB')->resultset('TestplanInstance')->search($filter_condition->{early});
                $todays_instances = $todays_instances->search({created_at => { '>' => $today}});

                my @details = $self->get_testrun_details($todays_instances);
                if (@details) {
                        push @$testplan_days, { date               => $today,
                                                testplan_instances => \@details,
                                              };
                }
        }



        for my $date (1..($days-1)) {
                my $yesterday = $today->clone->subtract( days => 1 );

                my $todays_instances = model('TestrunDB')->resultset('TestplanInstance')->search($filter_condition->{early});
                $todays_instances = $todays_instances->search({'-and' => [{created_at => { '>' => $yesterday}},
                                                                          {created_at => {'<=' => $today}},
                                                                         ]});
                my @details = $self->get_testrun_details($todays_instances);
                if (@details) {
                        push @$testplan_days, { date               => $today,
                                                testplan_instances => \@details,
                                              };
                }
                $today = $yesterday;
        }
        return;
}


=head2 get_testrun_details

Get the details of the testruns belonging to the testplan instance given
as argument.

@param DBIC ResultSet TestplanInstance - testplan instances of current day

@returnlist success - array ref of lists of details of testruns in given instances
@returnlist error   - empty list

=cut

sub get_testrun_details
{
        my ($self, $todays_instances) = @_;
        return unless $todays_instances and $todays_instances->can('next');

        my @testplan_instances;

        while ( my $instance = $todays_instances->next) {

                my $details = {
                               name => $instance->name,
                               id   => $instance->id,
                               path => $instance->path,
                              };
                $details->{count_unfinished} = int grep {$_->testrun_scheduling and
                                                           $_->testrun_scheduling->status ne 'finished'} $instance->testruns->all;


                my $testruns = $instance->testruns;
        TESTRUN:
                while ( my $testrun = $testruns->next) {
                        next TESTRUN if $testrun->testrun_scheduling->status ne 'finished';
                        my $stats   = model('ReportsDB')->resultset('ReportgroupTestrunStats')->search({testrun_id => $testrun->id})->first;

                        $details->{count_fail}++ if $stats and $stats->success_ratio  < 100;
                        $details->{count_pass}++ if $stats and $stats->success_ratio == 100;
                }
                push @testplan_instances, $details;
        }
        return @testplan_instances;
}

sub prepare_filter_path
{
        my ($self, $c, $days) = @_;
        my %args = @{$c->req->arguments};

        $args{days} = $days if $days;

        return join('/', %args );
}


=head2 reduced_filter_path

Create a filter path out of the filters given as first argument that
does not contain the second argument.

@param hash ref - current filter settings
@param string   - new path without that filter (should be a key in the hash)

@return string  - new path

=cut

sub reduced_filter_path
{
        my ($self, $filters, $remove) = @_;
        my %new_filters = %$filters;
        delete $new_filters{$remove};
        say STDERR join('/', %new_filters );
        return join('/', %new_filters );
}


sub prepare_navi : Private
{
        my ( $self, $c ) = @_;
        my $navi : Stash = [];

        my %args = @{$c->req->arguments};

        $navi = [
                 {
                  title  => "Matrix Overview",
                  href => "/tapper/testplan/taskjuggler/",
                 },
                 {
                  title  => "Testplan by date",
                  href   => "",
                  subnavi => [
                              {
                               title  => "today",
                               href   => "/tapper/testplan/".$self->prepare_filter_path($c, 1),
                              },
                              {
                               title  => "2 days",
                               href   => "/tapper/testplan/".$self->prepare_filter_path($c, 2),
                              },
                              {
                               title  => "1 week",
                               href   => "/tapper/testplan/".$self->prepare_filter_path($c, 7),
                              },
                              {
                               title  => "2 weeks",
                               href   => "/tapper/testplan/".$self->prepare_filter_path($c, 14),
                              },
                              {
                               title  => "3 weeks",
                               href   => "/tapper/testplan/".$self->prepare_filter_path($c, 21),
                              },
                              {
                               title  => "1 month",
                               href   => "/tapper/testplan/".$self->prepare_filter_path($c, 31),
                              },
                              {
                               title  => "2 months",
                               href   => "/tapper/testplan/".$self->prepare_filter_path($c, 62),
                              },
                              {
                               title  => "4 months",
                               href   => "/tapper/testplan/".$self->prepare_filter_path($c, 124),
                              },
                              {
                               title  => "6 months",
                               href   => "/tapper/testplan/".$self->prepare_filter_path($c, 182),
                              },
                              {
                               title  => "12 months",
                               href   => "/tapper/testplan/".$self->prepare_filter_path($c, 365),
                              },

                             ],
                 },
                ];

        push @$navi, {title   => 'Active Filters',
                      subnavi => [
                                  map {
                                          { title => "$_: ".$args{$_},
                                              href => "/tapper/reports/".$self->reduced_filter_path(\%args, $_),
                                                image  => "/tapper/static/images/minus.png",
                                          }
                                  } keys %args ]};

}


=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Testplan - Catalyst Controller for test plans

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index



=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 LICENSE

This program is released under the following license: freebsd

=cut

1;
