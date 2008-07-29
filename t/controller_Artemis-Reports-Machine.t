use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'Artemis::Reports::Web' }
BEGIN { use_ok 'Artemis::Reports::Web::Controller::Artemis::Reports::Machine' }

#ok( request('/artemis/reports/machine')->is_success, 'Request should succeed' );


