package Tapper::Reports::Web::Util::Filter::Report;


=head1 NAME

Tapper::Reports::Web::Util::Filter::Report - Filter utilities for report listing

=head1 SYNOPSIS

 use Tapper::Reports::Web::Util::Filter::Report;
 my $filter              = Tapper::Reports::Web::Util::Filter::Report->new(context => $c);
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



=head2 owner

Adds filters for owner. Currently, owners are only determind by testruns.

@param hash ref - current version of filters
@param string   - owner name

@return hash ref - updated filters

=cut

sub owner
{
        my ($self, $filter_condition, $owner) = @_;
        push @{$filter_condition->{late}},
        { '-or' => [
                    {'reportgrouparbitrary.owner' => $owner},
                    {'reportgrouptestrun.owner' => $owner},
                   ]};

        return $filter_condition;
}

1;
