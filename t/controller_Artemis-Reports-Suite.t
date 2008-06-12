use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Artemis::Reports::Web' }
BEGIN { use_ok 'Artemis::Reports::Web::Controller::Artemis::Reports::Suite' }

ok( request('/artemis/reports/suite')->is_success, 'Request should succeed' );


