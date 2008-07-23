use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Artemis::Reports::Web' }
BEGIN { use_ok 'Artemis::Reports::Web::Controller::Artemis::Reports::Freestyle' }

ok( request('/artemis/reports/freestyle')->is_success, 'Request should succeed' );


