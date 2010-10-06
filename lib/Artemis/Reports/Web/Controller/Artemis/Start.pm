package Artemis::Reports::Web::Controller::Artemis::Start;

use parent 'Artemis::Reports::Web::Controller::Base';

use common::sense;
## no critic (RequireUseStrict)

sub auto :Private
{
        my ( $self, $c ) = @_;
}

sub index :Path :Args()
{
        my ( $self, $c ) = @_;
}

1;
