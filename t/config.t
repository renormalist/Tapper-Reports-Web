#! /usr/bin/env perl

use strict;
use warnings;

use lib '.';

use Test::More;
use Artemis::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Artemis::Reports::Web;

plan tests => 3;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => reportsdb_schema, fixture => 't/fixtures/reportsdb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

is(Artemis::Reports::Web->config->{database}{ReportsDB}{dsn}, "dbi:SQLite:dbname=t/artemis_schema_reportsdb_test.sqlite", "dsn");
is(Artemis::Reports::Web->config->{database}{ReportsDB}{username}, "", "username");
is(Artemis::Reports::Web->config->{database}{ReportsDB}{password}, "", "password");
