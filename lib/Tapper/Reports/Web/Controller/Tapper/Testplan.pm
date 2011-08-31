package Tapper::Reports::Web::Controller::Tapper::Testplan;

use parent 'Tapper::Reports::Web::Controller::Base';

use common::sense;
## no critic (RequireUseStrict)

use DateTime::Format::Natural;
use Tapper::Reports::Web::Util::Filter::Testplan;
use Tapper::Model 'model';

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
