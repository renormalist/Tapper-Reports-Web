use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'Tapper::Reports::Web' }

ok( request('/tapper/testruns/date/2011-08-05')->is_success, 'Request should succeed' );

done_testing;
