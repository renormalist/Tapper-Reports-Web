package Tapper::Reports::Web::Util::Filter;

use DateTime;
use Data::Dumper;
use DateTime::Format::DateParse;

use Moose;

use common::sense;

has 'context' => (is => 'rw');
has 'requested_day'   => (is => 'rw');

sub days
{
        my ($self, $filter_condition, $days) = @_;
        if (defined($self->requested_day)) {
                push @{$filter_condition->{error}}, "Time filter already exists, only using first one";
                return $filter_condition;
        }
        $filter_condition->{days} = $days;
        my $parser = new DateTime::Format::Natural;
        my $requested_day  = $parser->parse_datetime("today at midnight");
        $self->requested_day($requested_day);

        my $yesterday = $parser->parse_datetime("today at midnight")->subtract(days => $days);
        $filter_condition->{early}->{created_at} = {'>' => $yesterday};
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

=head2 parse_filters

Parse filter arguments given by controller. The function expects an
array ref containing the filter arguments. This is achieved by providing
the arguments that Catalyst provide for a sub with :Args().

The second argument is a list of word that are valid filters.


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
@param array ref - list of allowed filters

@return hash ref

=cut

sub parse_filters
{
        my ($self, $args, $allowed_filters) = @_;
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

                        if (ref $allowed_filters eq 'ARRAY' and not grep {$_ eq $key} @$allowed_filters) {
                                $filter_condition->{error} = "Can not filter for $key";
                                return $filter_condition;
                        }

                        given ($key){
                                when ('days')    { $filter_condition = $self->days($filter_condition, $value) }
                                when ('date')    { $filter_condition = $self->date($filter_condition, $value) }
                                when ('host')    { $filter_condition = $self->host($filter_condition, $value) }
                                when ('suite')   { $filter_condition = $self->suite($filter_condition, $value) }
                                when ('success') { $filter_condition = $self->success($filter_condition, $value) }
                                default {my @errors = @{$filter_condition->{error} || [] };
                                         $filter_condition = {};
                                         push @errors, "Can not parse filter $key/$value. No filters applied";
                                         $filter_condition->{error} = \@errors;
                                         return $filter_condition;
                                 }
                        }
                }
        }
        return $filter_condition;
}

1;
