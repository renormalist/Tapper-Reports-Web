package Artemis::Reports::Web::Controller::Artemis::Reports::Date;

use 5.010;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

#

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;

        my $filter_condition : Stash = {};
        $c->forward('/artemis/reports/prepare_this_weeks_reportlists');
}

1;
