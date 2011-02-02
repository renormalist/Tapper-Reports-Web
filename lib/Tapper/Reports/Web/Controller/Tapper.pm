package Tapper::Reports::Web::Controller::Tapper;

use strict;
use warnings;

use parent 'Tapper::Reports::Web::Controller::Base';

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;

        # the easy way, to avoid fiddling with Mason autohandlers on
        # simple redirects

        my $body = <<EOF;
<html>
<head>
<meta http-equiv="refresh" content="0; URL=/tapper/start">
<meta name="description" content="Tapper"
<title>Tapper</title>
</head>
EOF
        $c->response->body($body);
}

1;
