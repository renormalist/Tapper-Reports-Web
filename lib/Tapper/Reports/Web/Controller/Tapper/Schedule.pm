package Tapper::Reports::Web::Controller::Tapper::Schedule;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Schedule - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $body = qx(tapper-testrun listqueue -v);
    
    $c->response->body("<pre>
$body
</pre>");
}


=head1 AUTHOR

Maik Hentsche

=head1 LICENSE

This program is released under the following license: freebsd

=cut

1;
