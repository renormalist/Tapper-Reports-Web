package Tapper::Reports::Web::Controller::Base;

use strict;
use warnings;

use parent qw(Catalyst::Controller::HTML::FormFu Catalyst::Controller::BindLex);
__PACKAGE__->config->{bindlex}{Param}    = sub { $_[0]->req->params };
__PACKAGE__->config->{unsafe_bindlex_ok} = 1;

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
        return join('/', %new_filters );
}

=head2 prepare_filter_path

Create the URL part for the current filter setting with the requested
number of days.

@param catalyst context
@param int - number of days

@return url part

=cut

sub prepare_filter_path
{
        my ($self, $c, $days) = @_;
        my %args = @{$c->req->arguments};

        $args{days} = $days if $days;

        return join('/', %args );
}


sub begin :Private
{
        my ( $self, $c ) = @_;

        $c->stash->{logo}   = Tapper::Config->subconfig->{web}{logo};
        $c->stash->{title}  = Tapper::Config->subconfig->{web}{title};
        $c->stash->{footer} = Tapper::Config->subconfig->{web}{footer};
}


1;
