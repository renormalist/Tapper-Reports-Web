package Artemis::Reports::Web::Model::ReportsDB;

use strict;
use warnings;

use Artemis::Reports::Web;

use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
                    schema_class => 'Artemis::Schema::ReportsDB',
                    connect_info => [
                                     Artemis::Reports::Web->config->{database}{ReportsDB}{dsn},
                                     Artemis::Reports::Web->config->{database}{ReportsDB}{username},
                                     Artemis::Reports::Web->config->{database}{ReportsDB}{password},
                                    ],
                   );

=head1 NAME

Artemis::Reports::Web::Model::ReportsDB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<Artemis::Reports::Web>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Artemis::Schema::ReportsDB>

=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
