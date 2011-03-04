package Tapper::Reports::Web::Controller::Tapper::Testruns::IdList;

use 5.010;

use strict;
use warnings;
use Tapper::Reports::Web::Util::Testrun;

use parent 'Tapper::Reports::Web::Controller::Base';

=head2 index

Index function for /tapper/testruns/idlist/. Expects a comma separated
list of testrun ids. The requested testruns are put into stash as has
%testrunlist because we use the template /tapper/testruns/testrunlist.mas
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
                             id  => { '-in' => [@ids] }
                            };


        my $util = Tapper::Reports::Web::Util::Testrun->new();
        my $testruns = $c->model('TestrunDB')->resultset('Testrun')->search
          (
           $filter_condition,
           {
            order_by => 'id desc' }
          );

        %testrunlist = (testruns => $util->prepare_testrunlist($testruns) );

}



1;
