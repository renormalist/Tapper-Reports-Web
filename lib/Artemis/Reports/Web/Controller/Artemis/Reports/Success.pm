package Artemis::Reports::Web::Controller::Artemis::Reports::Success;

use strict;
use warnings;

use parent 'Catalyst::Controller::BindLex';
__PACKAGE__->config->{bindlex}{Param} = sub { $_[0]->req->params };

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
}

1;
