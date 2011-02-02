use strict;
use warnings;

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;

use Test::More;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns.yml' );
# -----------------------------------------------------------------------------------------------------------------


BEGIN { use_ok 'Catalyst::Test', 'Tapper::Reports::Web' }
BEGIN { use_ok 'Tapper::Reports::Web::Controller::Tapper::Testruns' }

# ok( request('/tapper/testruns')->is_success, 'Request should succeed' );
ok( request('/tapper/testruns/id/1')->is_success, 'Request should succeed' );
ok( request('/tapper/testruns/create')->is_success, 'Request should succeed' );

done_testing();
