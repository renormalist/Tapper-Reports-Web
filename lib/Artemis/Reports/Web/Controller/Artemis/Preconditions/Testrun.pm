package Artemis::Reports::Web::Controller::Artemis::Preconditions::Testrun;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';
use Data::Dumper;

sub index :Path 
{
        my ( $self, $c, $testrun_id, $raw ) = @_;
        my $testrun_search  : Stash = $c->model('TestrunDB')->resultset('Testrun')->find(id => $testrun_id);

        if ($raw) {
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
                return;
        } else {
                        my $testrun        : Stash;
                        my $preconditions  : Stash;
                        
                        $testrun = $c->model('TestrunDB')->resultset('Testrun')->find($testrun_id);
                        
                        if (not $testrun) {
                                $c->response->body(qq(No testrun with id "$testrun_id" found in the database!));
                                return;
                        }
                        
                        $preconditions = [{type=> 'image', filename => 'suse/susi.txt'}];

        }
}

1;
