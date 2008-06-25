package Artemis::Reports::Web::Controller::Artemis::Reports::Date;

use 5.010;

use strict;
use warnings;

use parent 'Catalyst::Controller::BindLex';
__PACKAGE__->config->{bindlex}{Param} = sub { $_[0]->req->params };

#

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;

        my $filter_condition : Stash = {};
        $c->forward('/artemis/reports/prepare_this_weeks_reportlists');
}

1;
