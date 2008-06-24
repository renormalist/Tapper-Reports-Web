package Artemis::Reports::Web::Controller::Artemis::Reports::Machine;

use 5.010;

use strict;
use warnings;

use parent 'Catalyst::Controller::BindLex';
__PACKAGE__->config->{bindlex}{Param} = sub { $_[0]->req->params };

#

sub index :Path :Args(1)
{
        my ( $self, $c, $machine_name ) = @_;

        my $filter_condition    : Stash = { machine_name => $machine_name };
        my $filter_machine_name : Stash = $machine_name;

        $c->forward('/artemis/reports/prepare_this_weeks_reportlists');
        $c->forward('/artemis/reports/prepare_navi');
}

1;
