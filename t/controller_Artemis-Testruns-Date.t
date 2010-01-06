use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'Artemis::Reports::Web' }
BEGIN { use_ok 'Artemis::Reports::Web::Controller::Artemis::Testruns::Date' }

#ok( request('/artemis/testruns/date')->is_success, 'Request should succeed' );


