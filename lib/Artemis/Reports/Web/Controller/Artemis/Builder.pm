package Artemis::Reports::Web::Controller::Artemis::Builder;

=head1 NAME

Builder - Frontend for Artemis::Builder

=head1 SYNOPSIS

This module is used in a Catalyst web and therefore does not get a
SYNOPSIS.

=head1 DESCRIPTION

Artemis::Builder is currently only a shell script collection in Connys
machine park. This module allows to order builds in this builder.

=cut


use parent 'Artemis::Reports::Web::Controller::Base';

use English;
use common::sense;

sub auto :Private
{
        my ( $self, $c ) = @_;
}

=head2 call_builder

Fill out a form for generating a build request.

=cut

sub base : Chained PathPrefix CaptureArgs(0) { }


sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
        $c->res->redirect("/artemis/builder/create/");
}

sub new_create : Chained('base') :PathPart('create') :Args(0) :FormConfig
{
        my ( $self, $c ) = @_;
        my $form = $c->stash->{form};
        my $msg : Stash;

        if ($form->submitted_and_valid) {
                my $data = $form->input();
                my $changeset = $data->{changeset_text} ? $data->{changeset_text} : $data->{changeset};
                my $error = qx(ssh root\@hernando artemis_builder.sh $data->{repo} $changeset);
                $msg = $CHILD_ERROR ? "Building not started: $error" : "Building started";
        }
}



1;
