package Artemis::Reports::Web::Controller::Artemis::Preconditions::Delete;

use strict;
use warnings;
use Artemis::Cmd::Precondition;

use parent 'Artemis::Reports::Web::Controller::Base';

sub index :Path 
{
        my ( $self, $c, $testrun_id, $force ) = @_;
        my $id : Stash;
        my $done : Stash;
        $id = $testrun_id;
        $done = $force;

        return if not $force;

        my $testrun = $c->model('TestrunDB')->resultset('Testrun')->find($testrun_id);
        if (not $testrun) {
                $c->response->body(qq(No testrun with id "$testrun_id" found in the database!));
                return;
        }

        my $cmd = Artemis::Cmd::Precondition->new();
        my $retval = $cmd->del($testrun_id);
        if ($retval) {
                $c->response->body(qq(Can't rerun testrun: $retval));
                return;
        }
        $done = 1;
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
