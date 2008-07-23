use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'Artemis::Reports::Web' }

ok( request('/')->is_success, 'Request should succeed' );
