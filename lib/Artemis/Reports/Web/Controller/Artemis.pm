package Artemis::Reports::Web::Controller::Artemis;

use strict;
use warnings;

use parent 'Catalyst::Controller::BindLex';
__PACKAGE__->config->{bindlex}{Param} = sub { $_[0]->req->params };

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;

        # the easy way, to avoid fiddling with Mason autohandlers on
        # simple redirects

        my $body = <<EOF;
<html>
<head>
<meta http-equiv="refresh" content="0; URL=/artemis/reports">
<meta name="description" content="Artemis Reports"
<title>Artemis | Reports</title>
</head>
EOF
        $c->response->body($body);
}

1;
