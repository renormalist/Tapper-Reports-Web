package Artemis::Reports::Web::Controller::Artemis::Testruns::Precondition;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';
use Data::Dumper;

sub index :Path :Args(1)
{
        my ( $self, $c, $testrun_id ) = @_;
        my $testrun_search  : Stash = $c->model('TestrunDB')->resultset('Testrun')->find(id => $testrun_id);

        if ($testrun_search) {
                $c->response->content_type ('plain');
                $c->response->header ("Content-Disposition" => 'inline; filename="precondition-'.$testrun_id.'.yml"');
                
                my @preconditions;
                foreach my $precondition ($testrun_search->ordered_preconditions) {
                        push @preconditions, $precondition->precondition;
                }
                $c->response->body ( join "", @preconditions);
        } else {
                $c->response->content_type ("plain");
                $c->response->header ("Content-Disposition" => 'inline; filename="nonexistent.preconditions.'.$testrun_id.'"');
                $c->response->body ("Error: No report $testrun_id.");
        }
}

1;
