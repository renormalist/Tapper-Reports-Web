use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'Tapper::Reports::Web' }
BEGIN { use_ok 'Tapper::Reports::Web::Controller::Tapper::Reports' }

ok( request('/tapper/reports')->is_success, 'Request should succeed' );
ok( request('/tapper/reports/date/2011-08-05')->is_success, 'Request should succeed' );

done_testing;
