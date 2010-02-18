package Artemis::Reports::Web::Controller::Artemis::Testruns;

use strict;
use warnings;
use DateTime;
use parent 'Artemis::Reports::Web::Controller::Base';
use Template;
use TryCatch;
use File::Path;
use File::Basename;

use 5.010;

use Artemis::Config;
use Artemis::Cmd::Testrun;
use Artemis::Model 'model';
use DateTime::Format::DateParse;


use Data::Dumper;

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
        my @testruns : Stash;

        my $format = '%T %F';
        my $testrun_search = $c->model('TestrunDB')->resultset('Testrun');
        while (my $this_testrun = $testrun_search->next) {
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

                push @testruns, {id          => $this_testrun->id,
                                 state       => $state,
                                 start_time  => $start_time,
                                 finish_time => $end_time};
        }
        return;
}

# XXX: subject to deletion
sub get_testrun_overview : Private
{
        my ( $self, $c, $testrun ) = @_;

        my $retval = {};

        return $retval unless $testrun;

        foreach ($testrun->ordered_preconditions) {
                my $precondition = $_->precondition_as_hash;
                if ($precondition->{precondition_type} eq 'virt' ) {
                        $retval->{name}  = $precondition->{name} || "Virtualisation Test";
                        $retval->{arch}  = $precondition->{host}->{root}{arch};
                        $retval->{image} = $precondition->{host}->{root}{image} || $precondition->{host}->{root}{name}; # can be an image or copyfile or package
                        push (@{$retval->{test}}, basename($precondition->{host}->{testprogram}{execname})) if $precondition->{host}->{testprogram}{execname};
                        foreach my $guest (@{$precondition->{guests}}) {
                                my $guest_summary;
                                $guest_summary->{arch}  = $guest->{root}{arch};
                                $guest_summary->{image} = $guest->{root}{image} || $guest->{root}{name}; # can be an image or copyfile or package
                                push @{$guest_summary->{test}}, basename($guest->{testprogram}{execname}) if $guest->{testprogram}{execname};
                                push @{$retval->{guests}}, $guest_summary;
                        }
                        # can stop here because virt preconditions usually defines everything we need for a summary
                        return $retval;
                }
                elsif ($precondition->{precondition_type} eq 'image' ) {
                        $retval->{image} = $precondition->{image};
                        if ($retval->{arch}) {
                                $retval->{arch} = $precondition->{arch};
                        } else {
                                if ($precondition->{image} =~ m/(64b)|(x86_64)/) {
                                        $retval->{arch} = 'unknown (probably linux64)';
                                } elsif ($precondition->{image} =~ m/(32b)|(i386)/) {
                                        $retval->{arch} = 'unknown (probably linux32)';
                                } else {
                                        $retval->{arch} = 'unknown';
                                }
                        }
                } elsif ($precondition->{precondition_type} eq 'prc') {
                        if ($precondition->{config}->{testprogram_list}) {
                                foreach my $thisprogram (@{$precondition->{config}->{testprogram_list}}) {
                                        push @{$retval->{test}}, $thisprogram->{program};
                                }
                        } elsif ($precondition->{config}->{test_program}) {
                                push @{$retval->{test}}, $precondition->{config}->{test_program};
                        }
                }
        }
        return $retval;
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
                $c->response->body(qq(Can not delete testrun: $retval));
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
                $c->response->body(qq(Can not rerun testrun));
                return;
        }
        $c->stash(testrun => $c->model('TestrunDB')->resultset('Testrun')->find($retval));
}

sub preconditions : Chained('id') PathPart('preconditions') CaptureArgs(0)
{
        my ( $self, $c ) = @_;
        $c->stash(preconditions => [$c->stash->{testrun}->ordered_preconditions]);
}

sub as_yaml : Chained('preconditions') PathPart('yaml') Args(0)
{
        my ( $self, $c ) = @_;

        my $id = $c->stash->{testrun}->id;

        my @preconditions;
        foreach my $precondition (@{$c->stash->{preconditions}}) {
                push @preconditions, $precondition->precondition;
        }
        if (@preconditions) {
                $c->response->content_type ('plain');
                $c->response->header ("Content-Disposition" => 'inline; filename="precondition-'.$id.'.yml"');
                $c->response->body ( join "", @preconditions);
        } else {
                $c->response->body ("No preconditions assigned");
        }
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
                my $data = $form->input();
                $c->session->{testrun_data} = $data;
                $c->res->redirect("/artemis/testruns/add_usecase/");

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
        my @all_machines = model("HardwareDB")->resultset('Systems')->search({active => 1, current_owner => {'like', '%artemis%'}});
        my @machines;
        foreach my $host (sort {$a->systemname cmp $b->systemname} @all_machines) {
                push(@machines, [$host->id, $host->systemname]);
        }
        return \@machines;

}


sub add_usecase : Chained('base') :PathPart('add_usecase') :Args(0) :FormConfig
{
        my ($self, $c) = @_;
        my $form = $c->stash->{form};
        $c->session->{valid} = 1;

        if ($form->submitted_and_valid) {
                $c->session->{usecase_file} = $form->input->{use_case};
                $c->res->redirect('/artemis/testruns/fill_usecase');
        } else {

                my @use_cases;
                my $path = Artemis::Config->subconfig->{paths}{config_path}."/use_cases/";
                foreach my $file (<$path/*.mpc>) {
                        open my $fh, "<", $file or $c->response->body(qq(Can not open $file: $!)), return;
                        my $desc;
                        while (my $line = <$fh>) {
                                ($desc) = $line =~/# (?:artemis[_-])?description:\s*(.+)/;
                                last if $desc;
                        }

                        my ($shortfile, undef, undef) = File::Basename::fileparse($file, ('.mpc'));
                        push @use_cases, [$file, "$shortfile - $desc"];

                }
                my $select = $form->get_element({type => 'Radiogroup', name => 'use_case'});
                $select->options(\@use_cases);
        }
}

sub fill_usecase : Chained('base') :PathPart('fill_usecase') :Args(0) :FormConfig
{
        my ($self, $c) = @_;
        my $home = $c->path_to();
        my $form = $c->stash->{form};
        my $position   = $form->get_element({type => 'Submit'});
        my $file       = $c->session->{usecase_file};
        my %macros;

        open my $fh, "<", $file or $c->forward('/artemis/testruns/create');   # can't read file most often means we are not in a session
        my ($required, $optional, $mpc_config) = ('', '', '');
        while (my $line = <$fh>) {
                ($required)   = $line =~/# (?:artemis[_-])?mandatory[_-]fields:\s*(.+)/ if not $required;
                ($optional)   = $line =~/# (?:artemis[_-])?optional[_-]fields:\s*(.+)/ if not $optional;
                ($mpc_config) = $line =~/# (?:artemis[_-])?config[_-]file:\s*(.+)/ if not $mpc_config;

                last if $required and $optional and $mpc_config;
        }

        my $delim = qr/,+\s*/;
        no warnings 'uninitialized';
        foreach my $field (split $delim, $required) {
                my ($name, $type) = split /\./, $field;

                $type = 'Text' if not $type;

                my $element = $form->element({type => ucfirst($type), name => $name, label => $name.'*', constraints => [ 'Required' ]});
        }

        foreach my $field (split $delim, $optional) {
                my ($name, $type) = split /\./, $field;
                $type = 'Text' if not $type;

                my $element = $form->element({type => ucfirst($type), name => $name, label => $name.' '});
        }


        if ($mpc_config) {
                $mpc_config = "$home/$mpc_config" if not substr($mpc_config, 0, 1) eq '/';
                if (not -r $mpc_config) {
                        $c->stash(error => qq(Config file "$mpc_config" does not exists or is not readable));
                        return;
                }
                $form->load_config_file( $mpc_config );
        }
        use warnings;
        $form->elements({type => 'Submit', name => 'submit', value => 'Submit'});

        $form->process();

        if ($form->submitted_and_valid) {



                my $testrun_data = $c->session->{testrun_data};
                $testrun_data->{starttime_earliest} = DateTime->new(year => $testrun_data->{starttime_year},
                                                                    month => $testrun_data->{starttime_month},
                                                                    day => $testrun_data->{starttime_day},
                                                                    hour => $testrun_data->{starttime_hour},
                                                                    minute => $testrun_data->{starttime_minute},
                                                                   );
                my $testrun;


                my $cmd = Artemis::Cmd::Testrun->new();
                my $testrun_id;
                try {  $testrun_id = $cmd->add($testrun_data);}
                  catch ($exception) {
                          $c->stash(error => $exception->msg);
                          return;
                  }

                my %remaining = %{$form->input};

                foreach my $field (split $delim, "$required,$optional") {
                        next if not $field; # happens if $required is empty
                        my ($name, $type) = split /\./, $field;
                        next if not defined $form->input->{$name};
                        if (defined($form->input->{$name})) {
                                delete $remaining{$name};
                                $macros{$name} = $form->input->{$name};
                        }
                        if ($type eq 'file') {
                                my $upload = $c->req->upload($name);
                                my $destdir = sprintf("%s/uploads/%s/%s", Artemis::Config->subconfig->{paths}{package_dir}, $testrun_id, $name);
                                my $destfile = $destdir."/".$upload->basename;
                                my $error;
                                mkpath( $destdir, {error => \$error} );

                                foreach my $diag (@$error) {
                                        my ($dir, $message) = each %$diag;
                                        $c->response->body("Can not create $dir: $message");
                                }
                                $upload->copy_to($destfile);
                                $macros{$name} = $destfile;
                        }
                }

                foreach my $name (keys %remaining) {
                        next if $name eq 'submit';
                        # checkboxgroups return an array but since you don't
                        # know its order in advance its easier to access a hash
                        if (ref $form->input->{$name} ~~ 'ARRAY') {
                                foreach my $element (@{$form->input->{$name}}) {
                                        $macros{$name}->{$element} = 1;                
                                }
                        } else {
                                $macros{$name} = $form->input->{$name};
                        }
                }


                $c->session->{macros} = \%macros;

                open $fh, "<", $file or $c->response->body(qq(Can not open $file: $!)), return;
                my $mpc = do {local $/; <$fh>};

                my $ttapplied;

                my $tt = new Template ();
                if (not $tt->process(\$mpc, \%macros, \$ttapplied) ) {
                        $c->stash(error => $tt->error());
                        return;
                }

                $cmd = Artemis::Cmd::Precondition->new();
                my @preconditions;
                try {  @preconditions = $cmd->add($ttapplied);}
                  catch ($exception) {
                          $c->stash(error => $exception->msg);
                          return;
                  }
                $cmd->assign_preconditions($testrun_id, @preconditions);
                $c->stash->{testrun_id} = $testrun_id;
                $c->stash->{preconditions} = \@preconditions;
        }
}

sub prepare_testrunlist : Private
{
        my ( $self, $c, $testruns ) = @_;

        # Mnemonic:
        #           rga = ReportGroup Arbitrary
        #           rgt = ReportGroup Testrun

        my @testruns;
        my %rgt;
        my %rga;
        my %rgt_prims;
        my %rga_prims;
        foreach my $testrun ($testruns->all)
        {
                my %cols = $testrun->get_columns;
                print STDERR Dumper(\%cols);
                my $suite_name        = $cols{suite_name} || 'unknownsuite';
                my $suite_id          = $cols{suite_id}   || '0';
                my $created_at_ymd_hm = $testrun->created_at;
                $created_at_ymd_hm    =~ s/:\d\d$//;

                my $tr = {
                          rgt_testrun_id        => $testrun->rgt_testrun_id,
                          rgts_success_ratio    => $testrun->rgts_success_ratio,
                          primary_report_id     => $testrun->primary_report_id,

                          suite_name            => $suite_name,
                          suite_id              => $suite_id,
                          machine_name          => $testrun->machine_name || 'unknownmachine',
                          created_at_ymd_hms    => $testrun->created_at, #$testrun->created_at->ymd('-')." ".$testrun->created_at->hms(':'),
                          created_at_ymd_hm     => $created_at_ymd_hm,
                          created_at_ymd        => $testrun->created_at, #$testrun->created_at->ymd('-'),
                         };
                push @testruns, $tr;
        }

        return {
                testruns => \@testruns,
               };
}

sub prepare_testrunlists : Private
{
        my ( $self, $c ) = @_;

        my @requested_testrunlists : Stash = ();
        my %groupstats             : Stash = ();

        # requested time period
        my $days : Stash;
        my $lastday = $days ? $days - 1 : 6;

        # ----- general -----

        my $filter_condition = {
                                # "me.id" => { '>=', 22530 }
                               };

        my $testruns = $c->model('ReportsDB')->resultset('View020TestrunOverview')->search
            (
             $filter_condition,
             { order_by => 'rgt_testrun_id desc' }
            );


        # TODO: change this to a while loop, currently not working. Bug? Related to group-by?
        while (my $tr = $testruns->next) {
                my %cols = $tr->get_columns;
        }

        # HIER WEITER:
        # - IN-Bedingung zum Laufen bekommen, notfalls mit manuellem Array
        # - dann in Template den Hash %groupstats aus Stash nutzen für rgts_success_ratio
        # - dann in Template wieder (%%) zu <%%> machen
        # - Liste überprüfen, könnte damit alles gewesen sein.

        my $parser = new DateTime::Format::Natural;
        my $today  = $parser->parse_datetime("today at midnight");
        my @day    = ( $today );
        push @day, $today->clone->subtract( days => $_ ) foreach 1..$lastday;

        # ----- today -----
        my $day0_testruns = $testruns->search ( { created_at => { '>', $day[0] } } );
        push @requested_testrunlists, {
                                       day => $day[0],
                                       %{ $c->forward('/artemis/testruns/prepare_testrunlist', [ $day0_testruns ]) }
                                      };

        # ----- last week days -----
        foreach (1..$lastday) {
                my $day_testruns = $testruns->search ({ -and => [ created_at => { '>', $day[$_]     },
                                                                  created_at => { '<', $day[$_ - 1] } ] });
                push @requested_testrunlists, {
                                               day => $day[$_],
                                               %{ $c->forward('/artemis/testruns/prepare_testrunlist', [ $day_testruns ]) }
                                              };
        }
}

sub prepare_navi : Private
{
        my ( $self, $c ) = @_;

        my $navi : Stash = [
                            {
                             title  => "Testruns by date",
                             href   => "/artemis/testruns/days/2",
                             active => 0,
                             subnavi => [
                                         {
                                          title  => "today",
                                          href   => "/artemis/testruns/days/1",
                                         },
                                         {
                                          title  => "1 week",
                                          href   => "/artemis/testruns/days/7",
                                         },
                                         {
                                          title  => "2 weeks",
                                          href   => "/artemis/testruns/days/14",
                                         },
                                         {
                                          title  => "3 weeks",
                                          href   => "/artemis/testruns/days/21",
                                         },
                                         {
                                          title  => "1 month",
                                          href   => "/artemis/testruns/days/30",
                                         },
                                         {
                                          title  => "2 months",
                                          href   => "/artemis/testruns/days/60",
                                         },
                                        ],
                            },
                            {
                             title  => "Control",
                             href   => "",
                             active => 0,
                             subnavi => [
                                         {
                                          title  => "Create new Testrun",
                                          href   => "/artemis/testruns/create/",
                                         },
                                        ],
                            },
                           ];
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
