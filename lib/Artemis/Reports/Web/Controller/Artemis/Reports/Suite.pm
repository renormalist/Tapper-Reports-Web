package Artemis::Reports::Web::Controller::Artemis::Reports::Suite;

use 5.010;

use strict;
use warnings;

use parent 'Catalyst::Controller::BindLex';
__PACKAGE__->config->{bindlex}{Param} = sub { $_[0]->req->params };

#

sub index :Path :Args(1)
{
        my ( $self, $c, $suite_id ) = @_;

        my $filter_condition : Stash = { suite_id => $suite_id };
        $c->forward('/artemis/reports/prepare_this_weeks_reportlists');
}

1;
