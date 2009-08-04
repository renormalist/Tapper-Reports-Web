package Artemis::Reports::Web::Controller::Artemis::Testruns;

use strict;
use warnings;
use DateTime;
use parent 'Artemis::Reports::Web::Controller::Base';

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
        my @testruns : Stash;

        my $format = '%T %F';
        my $testrun_search = $c->model('TestrunDB')->resultset('Testrun');
        while (my $this_testrun = $testrun_search->next()) {
                my $state = 'Not started';
                my $start_time;
                my $end_time;

                if ($this_testrun->starttime_testrun) {
                        $state = 'Running or stopped';
                        $start_time = $this_testrun->starttime_testrun->strftime($format);
                }
                if ($this_testrun->endtime_test_program) {
                        $state = 'Finished';
                        $end_time = $this_testrun->endtime_test_program->strftime($format);

                }

                push @testruns, {id => $this_testrun->id,
                                 state => $state,
                                 start_time => $start_time,
                                 finish_time => $end_time};
        }
        return;
}

=head1 NAME

Artemis::Reports::Web::Controller::Artemis::Testruns - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index



=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
