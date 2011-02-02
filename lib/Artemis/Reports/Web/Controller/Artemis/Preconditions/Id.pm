package Tapper::Reports::Web::Controller::Tapper::Preconditions::Id;

use strict;
use warnings;

use parent 'Tapper::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $id ) = @_;
        my $precondition : Stash;
        
        my $precond_search = $c->model('TestrunDB')->resultset('Precondition')->find($id);
        if (not $precond_search) {
                $c->response->body(qq(No precondition with id "$id" found in the database!));
                return;
        }
        $precondition = $precond_search->precondition_as_hash;
        $precondition->{id} = $precond_search->id;
        return;
}

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Preconditions - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index 



=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
