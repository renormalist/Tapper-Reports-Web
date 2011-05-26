package Tapper::Reports::Web::Util::Filter;

use DateTime;
use Data::Dumper;
use DateTime::Format::DateParse;
use Hash::Merge::Simple 'merge';

use Moose;



use common::sense;

has 'context'         => (is => 'rw');
has 'requested_day'   => (is => 'rw');
has 'dispatch'        => (is        => 'rw',
                          isa       => 'HashRef',
                          # builder   => 'build_dispatch',
                          # init_arg  => undef,
                         );

sub BUILD{
        my $self = shift;
        my $args = shift;

        $self->dispatch(
                        merge($self->dispatch, {days => \&days})
                       );
}


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

=head2 parse_filters

Parse filter arguments given by controller. The function expects an
array ref containing the filter arguments. This is achieved by providing
the arguments that Catalyst provide for a sub with :Args().

The second argument is a list of word that are valid filters.


The function returns a hash ref containing the following elements (not
necessarily all every time):
* early    - hash ref  - contains the filter conditions that can be given
                         in the initial search on reports
* late     - array ref - list of hash refs that contain filter conditions
                         which shall be applied as $report->search{$key => $value}
                         after the initial search returned a$report already
* function - hash ref  - functions that are to be applied as $report->$key($value);
* error    - array ref - contains all errors that occured as strings
* days     - int       - number of days that will be shown
* date     - string    - the exact date that will be shown


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

                        if (not $self->dispatch->{$key}) {
                                my @errors = @{$filter_condition->{error} || [] };
                                $filter_condition = {};
                                push @errors, "Can not parse filter $key/$value. No filters applied";
                                $filter_condition->{error} = \@errors;
                                return $filter_condition;
                        }
                        use Data::Dumper;
                        print STDERR Dumper $filter_condition;
                        $filter_condition = $self->dispatch->{$key}->($self, $filter_condition, $value);
                }
        }
        return $filter_condition;
}

1;
