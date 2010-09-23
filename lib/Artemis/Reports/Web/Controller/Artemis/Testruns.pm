package Artemis::Reports::Web::Controller::Artemis::Testruns;

use parent 'Artemis::Reports::Web::Controller::Base';
use Cwd;
use Data::DPath 'dpath';
use DateTime::Format::DateParse;
use DateTime;
use File::Basename;
use File::Path;
use Template;

use Artemis::Cmd::Testrun;
use Artemis::Config;
use Artemis::Model 'model';

use common::sense;

=head2 index

Prints a list of a testruns together with their state, start time and
end time. No options, not return values.

TODO: Too many testruns, takes too long to display. Thus, we need to add
filter facility.

=cut

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
        $c->res->redirect('/artemis/testruns/days/2');
        return;
}


=head2 get_testrun_overview

This function reads and parses all precondition of a testrun to generate
a summary of the testrun which will then be shown as an overview. It
returns a hash reference containing:
* name
* arch
* image
* test

@param testrun result object

@return hash reference

=cut

sub get_testrun_overview : Private
{
        my ( $self, $c, $testrun ) = @_;

        my $retval = {};

        return $retval unless $testrun;

        $retval->{shortname} = $testrun->shortname;

        foreach ($testrun->ordered_preconditions) {
                my $precondition = $_->precondition_as_hash;
                if ($precondition->{precondition_type} eq 'virt' ) {
                        $retval->{name}  = $precondition->{name} || "Virtualisation Test";
                        $retval->{arch}  = $precondition->{host}->{root}{arch};
                        $retval->{image} = $precondition->{host}->{root}{image} || $precondition->{host}->{root}{name}; # can be an image or copyfile or package
                        ($retval->{xen_package}) = grep { m!/data/bancroft/artemis/[^/]+/repository/packages/xen/builds! } @{ $precondition ~~ dpath '/host/preconditions//filename' };
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
                $c->response->content_type ('text/plain');
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

=head2 new_create

This function handles the form for the first step of creating a new
testrun.

=cut

sub new_create : Chained('base') :PathPart('create') :Args(0) :FormConfig
{
        my ($self, $c) = @_;
        my $form = $c->stash->{form};

        if ($form->submitted_and_valid) {
                my $data = $form->input();
                $c->session->{testrun_data} = $data;
                $c->session->{valid} = 1;
                $c->session->{usecase_file} = $form->input->{use_case};
                $c->res->redirect('/artemis/testruns/fill_usecase');

        } else {
                my $select = $form->get_element({type => 'Select', name => 'topic'});
                $select->options($self->get_topic_names());

                $select = $form->get_element({type => 'Select', name => 'owner'});
                $select->options($self->get_owner_names());

                $select = $form->get_element({type => 'Select', name => 'requested_hosts'});
                $select->options($self->get_hostnames());

                my @use_cases;
                my $path = Artemis::Config->subconfig->{paths}{use_case_path};
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
        my @all_machines = model("TestrunDB")->resultset('Host')->search({active => 1});
        my @machines;
        foreach my $host (sort {$a->name cmp $b->name} @all_machines) {
                # TODO: check queue bindings
                next if $host->name =~ /^billjones|fasolt|incubus|uruk$/;
                push(@machines, [ $host->name, $host->name ]);
        }
        return \@machines;

}


=head2 parse_macro_precondition

Parse the given file as macro precondition and return a has ref
containing required, optional and mcp_config fields.

@param catalyst context
@param string - file name

@return success - hash ref
@return error   - string

=cut

sub parse_macro_precondition :Private
{
        my ($self, $c, $file) = @_;
        my $config;
        my $home = $c->path_to();


        open my $fh, "<", $file or return "Can not open use case description $file:$!";
        my ($required, $optional, $mpc_config) = ('', '', '');

        while (my $line = <$fh>) {
                $config->{description_text} .= "$1\n" if $line =~ /^### ?(.*)$/;

                ($required)   = $line =~/# (?:artemis[_-])?mandatory[_-]fields:\s*(.+)/ if not $required;
                ($optional)   = $line =~/# (?:artemis[_-])?optional[_-]fields:\s*(.+)/ if not $optional;
                ($mpc_config) = $line =~/# (?:artemis[_-])?config[_-]file:\s*(.+)/ if not $mpc_config;
        }

        my $delim = qr/,+\s*/;
        foreach my $field (split $delim, $required) {
                my ($name, $type) = split /\./, $field;
                $type = 'Text' if not $type;
                push @{$config->{required}}, {type => ucfirst($type),
                                              name => $name,
                                              label => $name,
                                              constraints => [ 'Required' ]
                                             }
        }

        foreach my $field (split $delim, $optional) {
                my ($name, $type) = split /\./, $field;
                $type = 'Text' if not $type;
                push @{$config->{optional}},{type => ucfirst($type),
                                             name => $name,
                                             label => $name,
                                            };
        }

        if ($mpc_config) {
                my $use_case_path = Artemis::Config->subconfig->{paths}{use_case_path};
                $mpc_config = "$use_case_path/$mpc_config"
                  unless substr($mpc_config, 0, 1) eq '/';

                # configs with relative paths are searched in FormFu's
                # config_file_path which is somewhere in root/forms. We
                # want our own config_path which starts at cwd when
                # being a relative path
                $mpc_config = getcwd()."/$mpc_config" if $mpc_config !~ m'^/'o;

                if (not -r $mpc_config) {
                        $c->stash(error => qq(Config file "$mpc_config" does not exists or is not readable));
                        return;
                }
                $config->{mpc_config} = $mpc_config;
        }
        return $config;
}


=head2 handle_precondition

Check whether each required precondition has a value, uploads files and
so on.

@param

@return

=cut

sub handle_precondition
{
        my ($self, $c, $config) = @_;
        my $form = $c->stash->{form};
        my %macros;
        my %all_form_elements = %{$c->request->{parameters}};

        foreach my $element (@{$config->{required}}, @{$config->{optional}}) {
                my $name = $element->{name};
                next if not defined $all_form_elements{$name};

                if (lc($element->{type}) eq 'file') {
                        my $upload = $c->req->upload($name);
                        my $destdir = sprintf("%s/uploads/%s/%s",
                                              Artemis::Config->subconfig->{paths}{package_dir}, $config->{testrun_id}, $name);
                        my $destfile = $destdir."/".$upload->basename;
                        my $error;

                        mkpath( $destdir, {error => \$error} );

                        foreach my $diag (@$error) {
                                my ($dir, $message) = each %$diag;
                                $c->response->body("Can not create $dir: $message");
                        }
                        $upload->copy_to($destfile);
                        $macros{$name} = $destfile;
                        delete $all_form_elements{$name};
                }

                if (defined($all_form_elements{$name})) {
                        $macros{$name} = $all_form_elements{$name};
                        delete $all_form_elements{$name};
                } else {
                        # TODO: handle error
                }

        }

        foreach my $name (keys %all_form_elements) {
                next if $name eq 'submit';
                # checkboxgroups return an array but since you don't
                # know its order in advance its easier to access a hash
                if (ref $all_form_elements{$name} ~~ 'ARRAY') {
                        foreach my $element (@{$all_form_elements{$name}}) {
                                $macros{$name}->{$element} = 1;
                        }
                } else {
                        $macros{$name} = $all_form_elements{$name};
                }
        }

        open my $fh, "<", $config->{file} or $c->response->body(qq(Can not open $config->{file}: $!)), return;
        my $mpc = do {local $/; <$fh>};

        my $ttapplied;

        my $tt = new Template ();
        if (not $tt->process(\$mpc, \%macros, \$ttapplied) ) {
                $c->stash(error => $tt->error());
                return;
        }

        my $cmd = Artemis::Cmd::Precondition->new();
        my @preconditions;
        eval {  @preconditions = $cmd->add($ttapplied)};
        $c->stash(error => $@) if $@;

        $cmd->assign_preconditions($config->{testrun_id}, @preconditions);
        $c->stash->{testrun_id} = $config->{testrun_id};
        $c->stash->{preconditions} = \@preconditions;
        return;
}

=head2 fill_usecase

Creates the form for the last step of creating a testrun. When this form
is submitted and valid the testrun is created based on the gathered
data. The function is used directly by Catalyst which therefore cares
for params and returns.

=cut

sub fill_usecase : Chained('base') :PathPart('fill_usecase') :Args(0) :FormConfig
{
        my ($self, $c) = @_;
        my $form       = $c->stash->{form};
        my $description_text : Stash;
        my $position   = $form->get_element({type => 'Submit'});
        my $file       = $c->session->{usecase_file};
        my %macros;
        $c->res->redirect('/artemis/testruns/create') unless $file;

        my $config = $self->parse_macro_precondition($c, $file);

        # adding these elements to the form has to be done both before
        # and _after_ submit. Otherwise FormFu won't see the constraint
        # (required) in the form
        $description_text = $config->{description_text};
        foreach my $element (@{$config->{required}}) {
                $element->{label} .= '*'; # mark field as required
                $form->element($element);
        }

        foreach my $element (@{$config->{optional}}) {
                $element->{label} .= ' ';
                $form->element($element);
        }

        if ($config->{mpc_config}) {
                $form->load_config_file( $config->{mpc_config} );
        }

        $form->elements({type => 'Submit', name => 'submit', value => 'Submit'});
        $form->process();


        if ($form->submitted_and_valid) {
                my $testrun_data = $c->session->{testrun_data};
                if (defined ($testrun_data->{requested_hosts}) and
                    not ref($testrun_data->{requested_hosts}) eq 'ARRAY') {
                        # Artemis::Cmd expects a list
                        $testrun_data->{requested_hosts} = [ $testrun_data->{requested_hosts} ];
                }
                my $cmd = Artemis::Cmd::Testrun->new();
                eval { $config->{testrun_id} = $cmd->add($testrun_data)};
                if ($@) {
                        $c->stash(error => $@);
                        return;
                }

                $config->{file} = $file;
                $self->handle_precondition($c, $config);

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
