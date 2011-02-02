use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'Tapper::Reports::Web' }
BEGIN { use_ok 'Tapper::Reports::Web::Controller::Tapper::Testruns::Date' }

#ok( request('/tapper/testruns/date')->is_success, 'Request should succeed' );


