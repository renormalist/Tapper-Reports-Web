use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Artemis::Reports::Web' }
BEGIN { use_ok 'Artemis::Reports::Web::Controller::Artemis::ReportFile::Id' }

ok( request('/artemis/reportfile/id')->is_success, 'Request should succeed' );


