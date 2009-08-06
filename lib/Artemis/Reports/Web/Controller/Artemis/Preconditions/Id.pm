package Artemis::Reports::Web::Controller::Artemis::Preconditions::Id;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $id ) = @_;
        my $precondition : Stash;
        
        my $precond_search = $c->model('TestrunDB')->resultset('Precondition')->find($id);
        $precondition = $precond_search->precondition_as_hash;
        $precondition->{id} = $precond_search->id;
        return;
}

=head1 NAME

Artemis::Reports::Web::Controller::Artemis::Preconditions - Catalyst Controller

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
