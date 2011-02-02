package Tapper::Reports::Web::Controller::Base;

use strict;
use warnings;

use parent qw(Catalyst::Controller::HTML::FormFu Catalyst::Controller::BindLex);
__PACKAGE__->config->{bindlex}{Param}    = sub { $_[0]->req->params };
__PACKAGE__->config->{unsafe_bindlex_ok} = 1;

1;
