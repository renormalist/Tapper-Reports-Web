use strict;
use warnings;
use Test::More;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use Artemis::Schema::TestTools;
use Test::Fixture::DBIC::Schema;


BEGIN { use_ok 'Catalyst::Test', 'Artemis::Reports::Web' }
BEGIN { use_ok 'Artemis::Reports::Web::Controller::Artemis' }

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'Artemis::Reports::Web');
$mech->get_ok('/artemis/start');
$mech->page_links_ok('/artemis/start', 'All links on start page deliver HTTP/ok');

$mech->follow_link_ok({text => 'Create a new testrun'}, "Click on 'Create new testrun'");

$mech->get_ok('/artemis/testruns/create','Create form exists');

$mech->forms(0);
is(scalar($mech->find_all_inputs(name => 'use_case')), 1, 'First form on create_testrun is selection of use cases');


my $kernel_build;
# actually there is hardly a way for this test to fail because the
# controller only included the existing files in the first place
foreach my $form_element ( @{($mech->find_all_inputs(name => 'use_case'))[0]->{menu}} ) {
        ok(-e $form_element->{value}, 'Use case file '.$form_element->{value}.' exists');
        $kernel_build = $form_element->{value} if $form_element->{value} =~ /kernel_build/;
}


$mech->submit_form(button => 'submit');
$mech->content_contains('This field is required', 'No form without use case accepted');

die "No kernelbuild use case found" unless $kernel_build;

$mech->submit_form(fields => {use_case => $kernel_build} , button => 'submit');
$mech->content_contains('Use case details', 'Form to fill out use case details loaded');

# if the content test fails, we need to know what page actually was shown
diag($mech->content) unless $mech->content() =~ /Use case details/;

$mech->forms(0);
$mech->submit_form(button => 'submit' );
$mech->content_like(qr/This field is required/, 'Form rejected with empty git url');


$mech->set_fields(giturl => 'git://osrc.amd.com/linux-2.6.git');
$mech->submit_form(button => 'submit' );
$mech->content_like(qr/Testrun \d+.+created with preconditions/, 'Testrun created');


done_testing();
