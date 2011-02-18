package Artemis::Reports::Web::Controller::Artemis::Testruns::IdList;

use 5.010;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

=head2 index

Index function for /artemis/testruns/idlist/. Expects a comma separated
list of testrun ids. The requested testruns are put into stash as has
%testrunlist because we use the template /artemis/testruns/testrunlist.mas 
which expects this.

@param string - comma separated ids

@stash hash   - hash with key testruns => array of testrun hashes

@return ignored

=cut

sub index :Path :Args(1)
{
        my ( $self, $c, $idlist ) = @_;
        
        my %testrunlist : Stash = ();
        my $filter_condition;
        
        my @ids = split (qr/, */, $idlist);
        
        $filter_condition = {
                             rgt_testrun_id  => { '-in' => [@ids] }
                            };



        my $testruns = $c->model('ReportsDB')->resultset('View020TestrunOverview')->search
          (
           $filter_condition,
           {
            order_by => 'rgt_testrun_id desc' }
          );
        
        %testrunlist = %{ $c->forward('/artemis/testruns/prepare_testrunlist', [ $testruns ]) };

}



1;
