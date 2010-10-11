package Artemis::Reports::Web::Model::TestrunDB;

use strict;
use warnings;

use Artemis::Reports::Web;
use Artemis::Config;

use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
                    schema_class => 'Artemis::Schema::TestrunDB',
                    connect_info => [
                                     Artemis::Config->subconfig->{database}{TestrunDB}{dsn},
                                     Artemis::Config->subconfig->{database}{TestrunDB}{username},
                                     Artemis::Config->subconfig->{database}{TestrunDB}{password},
                                    ],
                   );

=head1 NAME

Artemis::Reports::Web::Model::TestrunDB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<Artemis::Reports::Web>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Artemis::Schema::TestrunDB>

=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
