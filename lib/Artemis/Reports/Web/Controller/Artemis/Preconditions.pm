package Artemis::Reports::Web::Controller::Artemis::Preconditions;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
        my @preconditions : Stash;

        my $precond_search = $c->model('TestrunDB')->resultset('Precondition');
        while (my $this_precond = $precond_search->next()) {
                my $hash = $this_precond->precondition_as_hash;
                $hash->{id} = $this_precond->id;

                push @preconditions, $hash;
        }
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
