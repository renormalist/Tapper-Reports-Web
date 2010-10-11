#! /usr/bin/env perl

use strict;
use warnings;

use lib '.';

use Test::More;
use Artemis::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Artemis::Reports::Web;

plan tests => 1;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => reportsdb_schema, fixture => 't/fixtures/reportsdb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

is(Artemis::Reports::Web->config->{dummy_value}, "test", "Dummy value in Web::config");
