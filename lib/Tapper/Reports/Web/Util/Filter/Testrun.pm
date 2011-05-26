package Tapper::Reports::Web::Util::Filter::Testrun;


=head1 NAME

Tapper::Reports::Web::Util::Filter::Testrun - Filter utilities for testrun listing

=head1 SYNOPSIS

 use Tapper::Testruns::Web::Util::Filter::Testrun;
 my $filter              = Tapper::Testruns::Web::Util::Filter::Testrun->new();
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
                               status  => \&status,
                               topic   => \&topic,
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
        my $host_result = model('TestrunDB')->resultset('Host')->search({name => $host})->first;
        
        # (XXX) do we need to throw an error when someone filters for an
        # unknown host?
        if (not $host_result) {
                return $filter_condition;
        }

        my $jobs        = model('TestrunDB')->resultset('TestrunScheduling')->search({host_id => $host_result->id});
        my @ids = map {$_->testrun->id if $_->testrun} $jobs->all;
        @ids    = get_intersection(\@ids, $filter_condition->{early}->{id}) if $filter_condition->{early}->{id};
        $filter_condition->{early}->{id} = {'in' => \@ids};
        return $filter_condition;
}


=head2 status

Add status filters to early filters.

@param hash ref - current version of filters
@param string   - status

@return hash ref - updated filters

=cut

sub status
{
        my ($self, $filter_condition, $state) = @_;

        my $jobs        = model('TestrunDB')->resultset('TestrunScheduling')->search({status => $state});
        my @ids = map {$_->testrun->id if $_->testrun} $jobs->all;
        @ids    = get_intersection(\@ids, $filter_condition->{early}->{id}) if $filter_condition->{early}->{id};
        $filter_condition->{early}->{id} = {'in' => \@ids};


        return $filter_condition;
}

=head2 topic

Add topic filters to early filters.

@param hash ref - current version of filters
@param string   - topic name

@return hash ref - updated filters

=cut

sub topic
{
        my ($self, $filter_condition, $topic) = @_;

        $filter_condition->{early}->{topic_name} = $topic;

        return $filter_condition;
}


=head2 owner

Add owner filters to early filters.

@param hash ref - current version of filters
@param string   - owner login

@return hash ref - updated filters

=cut

sub owner
{
        my ($self, $filter_condition, $owner) = @_;

        my $owner_result = model('TestrunDB')->resultset('User')->search({login => $owner})->first;

        if (not $owner_result) {
                $filter_condition->{error} = "No user with login '$owner' found";
                return $filter_condition;
        }


        $filter_condition->{early}->{owner_user_id} = $owner_result->id;

        return $filter_condition;
}


1;
