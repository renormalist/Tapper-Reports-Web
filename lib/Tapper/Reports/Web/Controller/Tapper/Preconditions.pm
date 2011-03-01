package Tapper::Reports::Web::Controller::Tapper::Preconditions;

use strict;
use warnings;

use parent 'Tapper::Reports::Web::Controller::Base';
use Tapper::Cmd::Precondition;
use Tapper::Model 'model';

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

        my $cmd = Tapper::Cmd::Precondition->new();
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



sub new_create : Chained('base') :PathPart('create') :Args(0) :FormConfig
{
        my ($self, $c) = @_;

        my $form = $c->stash->{form};

        if ($form->submitted_and_valid) {
                my $cmd  = Tapper::Cmd::Precondition->new();
                my $file = $form->param('precondition');
                my $data = $file->slurp;
                my @preconditions;
                eval { @preconditions = $cmd->add($data)};
                if($@) {
                          $c->stash(error => $@);
                }
                $c->stash(preconditions => \@preconditions);
        } else {
                print STDERR "created form for new precondition";
        }

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

This program is released under the following license: freebsd

=cut

1;
