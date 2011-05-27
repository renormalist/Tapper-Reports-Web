use strict;
use warnings;
use Test::More;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Test::Deep;

use Tapper::Model 'model';

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns.yml' );
construct_fixture( schema  => reportsdb_schema, fixture => 't/fixtures/reportsdb/report_util.yml' );
# -----------------------------------------------------------------------------------------------------------------




BEGIN { use_ok 'Tapper::Reports::Web::Util::Testrun' }
my $util = Tapper::Reports::Web::Util::Testrun->new();
my $tr_result = model('TestrunDB')->resultset('Testrun')->search({shortname => 'Autoinstall'});
is($tr_result->count, 1, 'Found one testrun');
my $testruns = $util->prepare_testrunlist($tr_result);
is(ref $testruns, 'ARRAY' , 'Got a list of testrun descriptions');
cmp_deeply($testruns->[0], superhashof({'success_ratio' => '75',
                                        'testrun_id' => 1,
                                        'machine_name' => 'iring',
                                        'topic_name' => 'Software',
                                        'primary_report_id' => 21,}),
           'First testrun description, scalar parts');
is($testruns->[0]->{status}, 'running', 'Status of first testrun');



done_testing();
