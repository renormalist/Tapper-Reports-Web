package Artemis::Reports::Web::Controller::Artemis::Reports::Id;

use strict;
use warnings;

use parent 'Catalyst::Controller::BindLex';
__PACKAGE__->config->{bindlex}{Param} = sub { $_[0]->req->params };

sub index :Path :Args(1)
{
        my ( $self, $c, $report_id ) = @_;

        my $report : Stash = $c->model('ReportsDB')->resultset('Report')->find($report_id);
}

1;
