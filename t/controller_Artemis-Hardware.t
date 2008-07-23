use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Artemis::Reports::Web' }
BEGIN { use_ok 'Artemis::Reports::Web::Controller::Artemis::Hardware' }

ok( request('/artemis/hardware')->is_success, 'Request should succeed' );


