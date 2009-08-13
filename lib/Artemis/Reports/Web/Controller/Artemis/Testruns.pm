package Artemis::Reports::Web::Controller::Artemis::Testruns;

use strict;
use warnings;
use DateTime;
use parent 'Artemis::Reports::Web::Controller::Base';

use Artemis::Cmd::Testrun;
use Artemis::Model 'model';
use DateTime::Format::DateParse;

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

sub base : Chained PathPrefix CaptureArgs(0) { }

sub id : Chained('base') PathPart('') CaptureArgs(1)
{
        my ( $self, $c, $testrun_id ) = @_;
        $c->stash(testrun => $c->model('TestrunDB')->resultset('Testrun')->find($testrun_id));
        if (not $c->stash->{testrun}) {
                $c->response->body(qq(No testrun with id "$testrun_id" found in the database!));
                return;
        }

}

sub delete : Chained('id') PathPart('delete')
{
        my ( $self, $c, $force) = @_;
        $c->stash(force => $force);

        return if not $force;

        my $cmd = Artemis::Cmd::Testrun->new();
        my $retval = $cmd->del($c->stash->{testrun}->id);
        if ($retval) {
                $c->response->body(qq(Can't delete testrun: $retval));
                return;
        }
        $c->stash(force => 1);
}

sub rerun : Chained('id') PathPart('rerun') Args(0)
{
        my ( $self, $c ) = @_;

        my $cmd = Artemis::Cmd::Testrun->new();
        my $retval = $cmd->rerun($c->stash->{testrun}->id);
        if (not $retval) {
                $c->response->body(qq(Can't rerun testrun));
                return;
        }
        $c->stash(testrun => $c->model('TestrunDB')->resultset('Testrun')->find($retval));
}

sub preconditions : Chained('id') PathPart('preconditions') CaptureArgs(0)
{
        my ( $self, $c ) = @_;
        $c->stash(preconditions => $c->stash->{testrun}->ordered_preconditions);
}

sub as_yaml : Chained('preconditions') PathPart('yaml') Args(0)
{
        my ( $self, $c ) = @_;

        my $id = $c->stash->{testrun}->id;
        $c->response->content_type ('plain');
        $c->response->header ("Content-Disposition" => 'inline; filename="precondition-'.$id.'.yml"');

        my @preconditions;
        foreach my $precondition ($c->stash->{preconditions}) {
                push @preconditions, $precondition->precondition;
        }
        $c->response->body ( join "", @preconditions);
}

sub show_precondition : Chained('preconditions') PathPart('show') Args(0)
{
        my ( $self, $c ) = @_;

}


sub similar : Chained('id') PathPart('similar') Args(0)
{
}

sub new_create : Chained('base') :PathPart('create') :Args(0) :FormConfig
{
        my ($self, $c) = @_;
        my $form = $c->stash->{form};

        if ($form->submitted_and_valid) {
                my $cmd = Artemis::Cmd::Testrun->new();
                my $data = $form->input();
                $data->{starttime_earliest} = DateTime::Format::DateParse->parse_datetime($data->{starttime});
                my $testrun;
                my $retval = $cmd->add($data);
                if (not $retval) {
                        $c->response->body(qq(Testrun not created successfully));
                } else {
                        $testrun = $c->model('TestrunDB')->resultset('Testrun')->find($retval);
                }
                $c->stash(testrun => $testrun);
        } else {
                my $select = $form->get_element({type => 'Select', name => 'topic'});
                $select->options($self->get_topic_names());

                $select = $form->get_element({type => 'Select', name => 'owner'});
                $select->options($self->get_owner_names());

                $select = $form->get_element({type => 'Select', name => 'hardwaredb_systems_id'});
                $select->options($self->get_hostnames());
        }

}

sub get_topic_names
{
        my ($self) = @_;
        my @all_topics = model("TestrunDB")->resultset('Topic')->all();
        my @topic_names;
        foreach my $topic (sort {$a->name cmp $b->name} @all_topics) {
                push(@topic_names, [$topic->name, $topic->name." -- ".$topic->description]);
        }
        return \@topic_names;
}

sub get_owner_names
{
        my ($self) = @_;
        my @all_owners = model("TestrunDB")->resultset('User')->all();
        my @owners;
        foreach my $owner (sort {$a->name cmp $b->name} @all_owners) {
                push(@owners, [$owner->login, $owner->name." (".$owner->login.")"]);
        }
        return \@owners;
}

sub get_hostnames
{
        my ($self) = @_;
        my @all_machines = model("HardwareDB")->resultset('Systems')->search({active => 1, scheduled => 1});
        my @machines;
        foreach my $host (sort {$a->systemname cmp $b->systemname} @all_machines) {
                push(@machines, [$host->id, $host->systemname]);
        }
        return \@machines;

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
