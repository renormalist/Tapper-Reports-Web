package Tapper::Reports::Web::Controller::Tapper::Testruns::Days;

use 5.010;

use strict;
use warnings;

use parent 'Tapper::Reports::Web::Controller::Base';

#

sub auto :Private
{
        my ( $self, $c ) = @_;

        $c->forward('/tapper/testruns/prepare_navi');
}

sub index :Path :Args(1)
{
        my ( $self, $c, $showdays ) = @_;

        my $days : Stash = $showdays || 2;
        $c->forward('/tapper/testruns/prepare_testrunlists');
}


1;
