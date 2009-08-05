package Artemis::Reports::Web::Controller::Artemis::Testruns::Rerun;

use strict;
use warnings;
use Artemis::Cmd::Testrun;

use parent 'Artemis::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $testrun_id ) = @_;
        my $testrun : Stash;
        $testrun = $c->model('TestrunDB')->resultset('Testrun')->find(id => $testrun_id);
        if (not $testrun) {
                $c->response->body(qq(No testrun with id "$testrun_id" found in the database!));
                return;
        }

        my $cmd = Artemis::Cmd::Testrun->new();
        my $retval = $cmd->rerun($testrun_id);
        if (not $retval) {
                $c->response->body(qq(Can't rerun testrun));
                return;
        }

        $testrun = $c->model('TestrunDB')->resultset('Testrun')->find($retval);

}


1;
