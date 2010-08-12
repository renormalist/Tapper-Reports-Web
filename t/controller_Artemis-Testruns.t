use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok 'Catalyst::Test', 'Artemis::Reports::Web' }
BEGIN { use_ok 'Artemis::Reports::Web::Controller::Artemis::Testruns' }

ok( request('/artemis/testruns')->is_success, 'Request should succeed' );
ok( request('/artemis/testruns/create')->is_success, 'Request should succeed' );


