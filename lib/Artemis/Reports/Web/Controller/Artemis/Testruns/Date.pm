package Artemis::Reports::Web::Controller::Artemis::Testruns::Date;

use 5.010;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

#

sub index :Path :Args(1)
{
        my ( $self, $c, $showdays ) = @_;

        my $days             : Stash = $showdays || 2;
        my $filter_condition : Stash = { "me.id" => { '>=', 22530 } };
        $c->forward('/artemis/reports/prepare_this_weeks_reportlists');
}

1;
