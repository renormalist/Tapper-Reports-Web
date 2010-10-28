package Artemis::Reports::Web::Controller::Artemis::Schedule;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Artemis::Reports::Web::Controller::Artemis::Schedule - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $body = qx(artemis-testrun listqueue -v);
    
    $c->response->body("<pre>
$body
</pre>");
}


=head1 AUTHOR

Maik Hentsche

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
