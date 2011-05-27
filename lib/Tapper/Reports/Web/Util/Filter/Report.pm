package Tapper::Reports::Web::Util::Filter::Report;


=head1 NAME

Tapper::Reports::Web::Util::Filter::Report - Filter utilities for report listing

=head1 SYNOPSIS

 use Tapper::Reports::Web::Util::Filter::Report;
 my $filter              = Tapper::Reports::Web::Util::Filter::Report->new();
 my $filter_args         = ['host','bullock','days','3'];
 my $allowed_filter_keys = ['host','days'];
 my $searchoptions       = $filter->parse_filters($filter_args, $allowed_filter_keys);

=cut



use Moose;
use Hash::Merge::Simple 'merge';
use Set::Intersection 'get_intersection';

use Tapper::Model 'model';

extends 'Tapper::Reports::Web::Util::Filter';

sub BUILD{
        my $self = shift;
        my $args = shift;

        $self->dispatch(
                        merge($self->dispatch,
                              {host    => \&host,
                               suite   => \&suite,
                               success => \&success,
                               date    => \&date,
                               owner   => \&owner,
                              })
                       );
}


=head2 host

Add host filters to early filters.

@param hash ref - current version of filters
@param string   - host name

@return hash ref - updated filters

=cut

sub host
{
        my ($self, $filter_condition, $host) = @_;
        my @hosts;
        @hosts = @{$filter_condition->{early}->{machine_name}->{in}} if $filter_condition->{early}->{machine_name};
        push @hosts, $host;
        $filter_condition->{early}->{machine_name} = {'in' => \@hosts};
        return $filter_condition;
}

=head2 suite

Add test suite to early filters.

@param hash ref - current version of filters
@param string   - suite name or id

@return hash ref - updated filters

=cut

sub suite
{
        my ($self, $filter_condition, $suite) = @_;
        my $suite_id;
        if ($suite =~/^\d+$/) {
                $suite_id = $suite;
        } else {
                my $suite_rs = $self->context->model('ReportsDB')->resultset('Suite')->search({name => $suite});
                $suite_id = $suite_rs->first->id if $suite_rs->count;
        }

        my @suites;
        @suites = @{$filter_condition->{early}->{suite_id}->{in}} if $filter_condition->{suite_id};
        push @suites, $suite_id;

        $filter_condition->{early}->{suite_id} = {'in' => \@suites};
        return $filter_condition;
}

=head2 success

Add success filters to early filters. Valid values are pass, fail and a
ratio in percent.

@param hash ref - current version of filters
@param string   - success grade

@return hash ref - updated filters

=cut

sub success
{
        my ($self, $filter_condition, $success) = @_;
        if ($success =~/^\d+$/) {
                $filter_condition->{early}->{success_ratio} = int($success);
        } else {
                $filter_condition->{early}->{successgrade} = uc($success);
        }
        return $filter_condition;

}

=head2 date

Add a date to late filters. Furthermore, it sets the days value. Date
used to filter for the number of days (now provided by function
'days'). For backwards compatibility it checks whether the input to mean
day rather than days and forwards accordingly.

@param hash ref - current version of filters
@param string   - date

@return hash ref - updated filters

=cut


sub date
{
        my ($self, $filter_condition, $date) = @_;
        return $self->days($filter_condition, $date) if $date =~m/^\d+$/; # handle old date links correctly

        if (defined($self->requested_day)) {
                push @{$filter_condition->{error}}, "Time filter already exists, only using first one";
                return $filter_condition;
        }

        $filter_condition->{days} = 1;

        my $requested_day;
        my $one_day_later;
        eval {
                $requested_day = DateTime::Format::DateParse->parse_datetime( $date );
                $one_day_later = DateTime::Format::DateParse->parse_datetime( $date )->add(days => 1);
        };
        if (not defined $requested_day) {
                push @{$filter_condition->{error}}, "Can not parse date '$date'";
                return $filter_condition;
        }

        $filter_condition->{date} = $requested_day->ymd('/');
        $self->requested_day($requested_day);
        push @{$filter_condition->{late}}, {created_at => {'>=' => $requested_day}};
        push @{$filter_condition->{late}}, {created_at => {'<'  => $one_day_later}};
        return $filter_condition;
}


=head2 owner

Adds filters for owner. Currently, owners are only determind by testruns.

@param hash ref - current version of filters
@param string   - owner name

@return hash ref - updated filters

=cut

sub owner
{
        my ($self, $filter_condition, $owner) = @_;
        my $owner_result = model('TestrunDB')->resultset('User')->search({login => $owner})->first;

        if (not $owner_result) {
                return $filter_condition
        }

        my $testruns_rs = model('TestrunDB')->resultset('Testrun')->search({owner_user_id => $owner_result->id});
        my @tr_ids;
        while (my $testrun = $testruns_rs->next) {
                push @tr_ids, $testrun->id;
        }

        my $tr_group_rs = model('ReportsDB')->resultset('ReportgroupTestrun')->search({testrun_id => {in => \@tr_ids}});

        my @report_ids = map {$_->report_id} $tr_group_rs->all;
        @report_ids    = get_intersection(\@report_ids, $filter_condition->{early}->{"me.id"}) if $filter_condition->{early}->{"me.id"};
        $filter_condition->{early}->{"me.id"} = {'in' => \@report_ids};
        return $filter_condition;
}

1;
