package Artemis::Reports::Web::Util::Filter;

use DateTime;
use Data::Dumper;
use DateTime::Format::DateParse;

use Moose;

use common::sense;

has 'context' => (is => 'rw');
has 'today'   => (is => 'rw');

sub days
{
        my ($self, $filter_condition, $days) = @_;
        if (defined($self->today)) {
                push @{$filter_condition->{error}}, "Time filter already exists, only using first one";
                return $filter_condition;
        }
        $filter_condition->{days} = $days;
        my $now = DateTime->now();
        $self->today($now);

        $now->subtract(days => $days);
        $filter_condition->{early}->{created_at} = {'>' => $now};
        return $filter_condition;
}

sub host
{
        my ($self, $filter_condition, $host) = @_;
        my @hosts;
        @hosts = @{$filter_condition->{early}->{machine_name}->{in}} if $filter_condition->{early}->{machine_name};
        push @hosts, $host;
        $filter_condition->{early}->{machine_name} = {'in' => \@hosts};
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
        @suites = @{$filter_condition->{early}->{suite_id}->{in}} if $filter_condition->{suite_id};
        push @suites, $suite_id;

        $filter_condition->{early}->{suite_id} = {'in' => \@suites};
        return $filter_condition;
}

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

sub date
{
        my ($self, $filter_condition, $date) = @_;
        return $self->days($filter_condition, $date) if $date =~m/^\d+$/; # handle old date links correctly

        if (defined($self->today)) {
                push @{$filter_condition->{error}}, "Time filter already exists, only using first one";
                return $filter_condition;
        }

        $filter_condition->{days} = 1;

        my $today = DateTime::Format::DateParse->parse_datetime( $date );
        my $tomorrow = DateTime::Format::DateParse->parse_datetime( $date )->add(days => 1);
        if (not defined $today) {
                push @{$filter_condition->{error}}, "Can not parse date '$date'";
                return $filter_condition;
        }

        $filter_condition->{date} = $today->ymd('/');
        $self->today($today);
        push @{$filter_condition->{late}}, {created_at => {'>=' => $today}};
        push @{$filter_condition->{late}}, {created_at => {'<'  => $tomorrow}};
        return $filter_condition;
}

=head2 parse_filters

Parse filter arguments given by controller. The function expects an
array ref containing the filter arguments. This is achieved by providing
the arguments that Catalyst provide for a sub with :Args().

The function returns a hash ref containing the following elements (not
necessarily all every time):
* early - hash ref  - contains the filter conditions that can be given
                      in the initial search on reports
* late  - array ref - list of hash refs that contain filter conditions
                      which shall be applied as $report->search{$key => $value}
                      after the initial search returned a$report already
* error - array ref - contains all errors that occured as strings
* days  - int       - number of days that will be shown
* date  - string    - the exact date that will be shown


@param array ref - list of filter arguments

@return hash ref

=cut

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
                $filter_condition->{error} = $error_msg;
                return {};
        } else {
                while (@args) {
                        my $key   = shift @args;
                        my $value = shift @args;
                        given ($key){
                                when ('days')    { $filter_condition = $self->days($filter_condition, $value) }
                                when ('date')    { $filter_condition = $self->date($filter_condition, $value) }
                                when ('host')    { $filter_condition = $self->host($filter_condition, $value) }
                                when ('suite')   { $filter_condition = $self->suite($filter_condition, $value) }
                                when ('success') { $filter_condition = $self->success($filter_condition, $value) }
                        }
                }
        }
        return $filter_condition;
}

1;
