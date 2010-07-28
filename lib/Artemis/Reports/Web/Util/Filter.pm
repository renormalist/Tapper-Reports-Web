package Artemis::Reports::Web::Util::Filter;

use 5.010;
use strict;
use warnings;

use DateTime;
use Data::Dumper;


use Moose;

has 'context' => (is => 'rw');

sub days
{
        my ($self, $filter_condition, $days) = @_;
        $self->context->stash(days => $days);
        my $now = DateTime->new(month => 11, year => 2009, day => 01);

#        my $now = DateTime->now();
        $now->subtract(days => $days);
        $filter_condition->{created_at} = {'>' => $now};
        return $filter_condition;
}

sub host
{
        my ($self, $filter_condition, $host) = @_;
        my @hosts;
        @hosts = @{$filter_condition->{machine_name}->{in}} if $filter_condition->{machine_name};
        push @hosts, $host;
        $filter_condition->{machine_name} = {'in' => \@hosts};
        return $filter_condition;
}

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
        @suites = @{$filter_condition->{suite_id}->{in}} if $filter_condition->{suite_id};
        push @suites, $suite_id;

        $filter_condition->{suite_id} = {'in' => \@suites};
        return $filter_condition;
}

sub success
{
        my ($self, $filter_condition, $success) = @_;
        if ($success =~/^\d+$/) {
                $filter_condition->{success_ratio} = int($success);
        } else {
                $filter_condition->{successgrade} = uc($success);
        }
        return $filter_condition;
        
}



sub parse_filters
{
        my ($self, $args) = @_;
        my @args = ref($args) eq 'ARRAY' ? @$args : ();
        my $filter_condition = {};
        if (int(@args) % 2) {
                my $error_msg = 'Wrong number of filter arguments in path. Using defaults. Found ';
                while (@args) {
                        $error_msg .= shift @args;
                        $error_msg .= " => ";
                        $error_msg .= @args ? shift @args : '(undef)';
                        $error_msg .= "; ";
                }
                return $error_msg;
        } else {
                while (@args) {
                        my $key   = shift @args;
                        my $value = shift @args;
                        given ($key){
                                when ('days')    {$filter_condition = $self->days($filter_condition, $value)}
                                when ('host')    {$filter_condition = $self->host($filter_condition, $value)}
                                when ('suite')   {$filter_condition = $self->suite($filter_condition, $value)}
                                when ('success') {$filter_condition = $self->success($filter_condition, $value)}
                        }
                }
        }
        return $filter_condition;
}

1;
