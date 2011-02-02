package Tapper::Reports::Web::Model::ReportsDB;

use strict;
use warnings;

use Tapper::Reports::Web;
use Tapper::Config;

use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
                    schema_class => 'Tapper::Schema::ReportsDB',
                    connect_info => [
                                     Tapper::Config->subconfig->{database}{ReportsDB}{dsn},
                                     Tapper::Config->subconfig->{database}{ReportsDB}{username},
                                     Tapper::Config->subconfig->{database}{ReportsDB}{password},
                                    ],
                   );

=head1 NAME

Tapper::Reports::Web::Model::ReportsDB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<Tapper::Reports::Web>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Tapper::Schema::ReportsDB>

=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
