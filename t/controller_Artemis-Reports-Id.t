use strict;
use warnings;
use Data::Dumper;
use Artemis::Schema::TestTools;
use Test::Fixture::DBIC::Schema;

use Test::More;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => reportsdb_schema, fixture => 't/fixtures/reportsdb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------


BEGIN { use_ok 'Catalyst::Test', 'Artemis::Reports::Web' }
BEGIN { use_ok 'Artemis::Reports::Web::Controller::Artemis::Reports::Id' }

#ok( request('/artemis/reports/id')->is_success, 'Request should succeed' );

#my $controller = Artemis::Reports::Web::Controller::Artemis::Reports::Id->new;
my $report     = reportsdb_schema->resultset('Report')->find(23);
unlike($report->tap->tapdom, qr/\$VAR1/, "no tapdom yet");
my $tapdom = $report->get_cached_tapdom;
is(Scalar::Util::reftype($tapdom), "ARRAY", "got tapdom");

my $failures   = Artemis::Reports::Web::Controller::Artemis::Reports::Id::get_report_failures(undef, $report);

diag Dumper($failures);

is($failures->[0]{description}, "- fink", "found failing test");

done_testing;
