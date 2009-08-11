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


sub base : Chained PathPrefix CaptureArgs(0) { }

sub id : Chained('base') PathPart('') CaptureArgs(1)
{
        my ( $self, $c, $precondition_id ) = @_;
        $c->stash(precondition => $c->model('TestrunDB')->resultset('Precondition')->find($precondition_id));
        if (not $c->stash->{precondition}) {
                $c->response->body(qq(No precondition with id "$precondition_id" found in the database!));
                return;
        }
}

sub delete : Chained('id') PathPart('delete')
{
        my ( $self, $c, $force) = @_;
        # when "done" is true, the precondition will already be deleted by the
        # controller once we get into the template, hence the name
        $c->stash(done => 0);

        return if not $force;

        my $cmd = Artemis::Cmd::Precondition->new();
        my $retval = $cmd->del($c->stash->{precondition}->id);
        if ($retval) {
                $c->response->body(qq(Can't delete precondition: $retval));
                return;
        }
        $c->stash(done => 1);
}


sub similar : Chained('id') PathPart('similar') Args(0)
{
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
