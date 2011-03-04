package Tapper::Reports::Web::Controller::Tapper::Hardware;

use strict;
use warnings;

use parent 'Catalyst::Controller::BindLex';
__PACKAGE__->config->{bindlex}{Param} = sub { $_[0]->req->params };
__PACKAGE__->config->{unsafe_bindlex_ok} = 1;

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
}

1;

__END__

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Hardware - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This program is released under the following license: freebsd

=cut
