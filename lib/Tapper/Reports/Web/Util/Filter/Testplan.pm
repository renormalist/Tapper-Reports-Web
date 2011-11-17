package Tapper::Reports::Web::Util::Filter::Testplan;


=head1 NAME

Tapper::Reports::Web::Util::Filter::Testplan - Filter utilities for testrun listing

=head1 SYNOPSIS

 use Tapper::Reports::Web::Util::Filter::Testplan;
 my $filter              = Tapper::Reports::Web::Util::Filter::Testplan->new(context => $c);
 my $filter_args         = ['path','topic.xen.unstable','days','3'];
 my $allowed_filter_keys = ['path','days'];
 my $searchoptions       = $filter->parse_filters($filter_args, $allowed_filter_keys);

=cut



use Moose;
use Hash::Merge::Simple 'merge';

extends 'Tapper::Reports::Web::Util::Filter';

sub BUILD{
        my $self = shift;
        my $args = shift;

        $self->dispatch(
                        merge($self->dispatch,
                              {path => \&path,
                               name => \&name,
                              })
                       );
}


=head2 name

Filter testplans for a path given in dot format (i.e. topic.xen.unstable
instead of topic/xen/unstable)

@param hash ref - current version of filters
@param string   - path name

@return hash ref - updated filters

=cut

sub path
{
        my ($self, $filter_condition, $path) = @_;

        $path =~ s|\.|/|g;
        $filter_condition->{early}->{path} = $path ? $path : undef;

        return $filter_condition;
}

=head2 name

Filter testplans for a given name.

@param hash ref - current version of filters
@param string   - testplan instance name

@return hash ref - updated filters

=cut

sub name
{
        my ($self, $filter_condition, $name) = @_;


        $filter_condition->{early}->{name} = $name ? $name : undef;

        return $filter_condition;
}




1;
