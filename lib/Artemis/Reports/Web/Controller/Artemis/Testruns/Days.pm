package Artemis::Reports::Web::Controller::Artemis::Testruns::Days;

use 5.010;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

#

sub auto :Private
{
        my ( $self, $c ) = @_;

        $c->forward('/artemis/testruns/prepare_navi');
}

sub index :Path :Args(1)
{
        my ( $self, $c, $showdays ) = @_;

        my $days : Stash = $showdays || 2;
        $c->forward('/artemis/testruns/prepare_reportlists');
}


1;
