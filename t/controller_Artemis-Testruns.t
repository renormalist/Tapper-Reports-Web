use strict;
use warnings;

use Artemis::Schema::TestTools;
use Test::Fixture::DBIC::Schema;

use Test::More;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns.yml' );
# -----------------------------------------------------------------------------------------------------------------


BEGIN { use_ok 'Catalyst::Test', 'Artemis::Reports::Web' }
BEGIN { use_ok 'Artemis::Reports::Web::Controller::Artemis::Testruns' }

# ok( request('/artemis/testruns')->is_success, 'Request should succeed' );
ok( request('/artemis/testruns/id/1')->is_success, 'Request should succeed' );
ok( request('/artemis/testruns/create')->is_success, 'Request should succeed' );

done_testing();
