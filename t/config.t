#! /usr/bin/env perl

use strict;
use warnings;

use lib '.';

use Test::More;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Tapper::Reports::Web;

plan tests => 1;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => reportsdb_schema, fixture => 't/fixtures/reportsdb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

is(Tapper::Reports::Web->config->{dummy_value}, "test", "Dummy value in Web::config");
