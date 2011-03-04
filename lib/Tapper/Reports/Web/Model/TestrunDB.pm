package Tapper::Reports::Web::Model::TestrunDB;

use strict;
use warnings;

use Tapper::Reports::Web;
use Tapper::Config;

use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
                    schema_class => 'Tapper::Schema::TestrunDB',
                    connect_info => [
                                     Tapper::Config->subconfig->{database}{TestrunDB}{dsn},
                                     Tapper::Config->subconfig->{database}{TestrunDB}{username},
                                     Tapper::Config->subconfig->{database}{TestrunDB}{password},
                                    ],
                   );

=head1 NAME

Tapper::Reports::Web::Model::TestrunDB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<Tapper::Reports::Web>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Tapper::Schema::TestrunDB>

=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This program is released under the following license: freebsd

=cut

1;
