package Artemis::Reports::Web::Controller::Artemis::Reports::Suite;

use strict;
use warnings;

use parent 'Catalyst::Controller::BindLex';
__PACKAGE__->config->{bindlex}{Param} = sub { $_[0]->req->params };

sub index :Path :Args(1)
{
        my ( $self, $c, $suite_id ) = @_;

        my $reports = $c->model('ReportsDB')->resultset('Report')->search
            (
             { suite_id => $suite_id },
             { order_by => 'id desc' },
            );
        $c->forward('/artemis/reports/prepare_simple_reportlist', [ $reports ]);

}

1;
