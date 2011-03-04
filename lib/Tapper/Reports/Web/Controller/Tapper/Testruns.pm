package Tapper::Reports::Web::Controller::Tapper::Testruns;

use parent 'Tapper::Reports::Web::Controller::Base';
use Cwd;
use Data::DPath 'dpath';
use DateTime::Format::DateParse;
use DateTime;
use File::Basename;
use File::Path;
use Template;

use Tapper::Cmd::Testrun;
use Tapper::Config;
use Tapper::Model 'model';
use Tapper::Reports::Web::Util::Testrun;

use common::sense;
## no critic (RequireUseStrict)

=head2 index

Prints a list of a testruns together with their state, start time and
end time. No options, not return values.

TODO: Too many testruns, takes too long to display. Thus, we need to add
filter facility.

=cut

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
        $c->res->redirect('/tapper/testruns/days/2');
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
                        ($retval->{xen_package}) = grep { m!/data/bancroft/tapper/[^/]+/repository/packages/xen/builds! } @{ $precondition ~~ dpath '/host/preconditions//filename' };
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

        my $cmd = Tapper::Cmd::Testrun->new();
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

        my $cmd = Tapper::Cmd::Testrun->new();
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
                $c->res->redirect('/tapper/testruns/fill_usecase');

        } else {
                my $select = $form->get_element({type => 'Select', name => 'topic'});
                $select->options($self->get_topic_names());

                $select = $form->get_element({type => 'Select', name => 'owner'});
                $select->options($self->get_owner_names());

                $select = $form->get_element({type => 'Select', name => 'requested_hosts'});
                $select->options($self->get_hostnames());

                my @use_cases;
                my $path = Tapper::Config->subconfig->{paths}{use_case_path};
                foreach my $file (glob "$path/*.mpc") {
                        open my $fh, "<", $file or $c->response->body(qq(Can not open $file: $!)), return;
                        my $desc;
                        while (my $line = <$fh>) {
                                ($desc) = $line =~/# (?:tapper[_-])?description:\s*(.+)/;
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
                if ($owner->login eq 'tapper') {
                        unshift(@owners, [$owner->login, $owner->name." (".$owner->login.")"]);
                } else {
                        push(@owners, [$owner->login, $owner->name." (".$owner->login.")"]);
                }
        }
        return \@owners;
}

=head2 get_hostnames

Get an array of all hostnames that can be used for a new testrun.  Note:
The array contains array that contain the hostname twice (i.e. (['host',
'host'], ...) because that is what the template expects.

@return success - ref to array of [ hostname, hostname ]


=cut

sub get_hostnames
{
        my ($self) = @_;
        my @all_machines = model("TestrunDB")->resultset('Host')->search({active => 1});
        my @machines;
 HOST:
        foreach my $host (sort {$a->name cmp $b->name} @all_machines) {

                # if host is bound, is must be bound to
                #  new_testrun_queue (possibly among others)
                if ($host->queuehosts->count()) {
                        my $new_testrun_queue = Tapper::Config->subconfig->{new_testrun_queue};
                        next HOST unless
                          grep {$_->queue->name eq $new_testrun_queue} $host->queuehosts->all;
                }

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

                ($required)   = $line =~/# (?:tapper[_-])?mandatory[_-]fields:\s*(.+)/ if not $required;
                ($optional)   = $line =~/# (?:tapper[_-])?optional[_-]fields:\s*(.+)/ if not $optional;
                ($mpc_config) = $line =~/# (?:tapper[_-])?config[_-]file:\s*(.+)/ if not $mpc_config;
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
                my $use_case_path = Tapper::Config->subconfig->{paths}{use_case_path};
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

@param  Catalyst context
@param  config hash

@return success - list of precondition ids
@return error   - error message

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
                                              Tapper::Config->subconfig->{paths}{package_dir}, $config->{testrun_id}, $name);
                        my $destfile = $destdir."/".$upload->basename;
                        my $error;

                        mkpath( $destdir, {error => \$error} );

                        foreach my $diag (@$error) {
                                my ($dir, $message) = each %$diag;
                                return("Can not create $dir: $message");
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

        open my $fh, "<", $config->{file} or return(qq(Can not open $config->{file}: $!));
        my $mpc = do {local $/; <$fh>};

        my $ttapplied;

        my $tt = new Template ();
        return $tt->error if not $tt->process(\$mpc, \%macros, \$ttapplied);

        my $cmd = Tapper::Cmd::Precondition->new();
        my @preconditions;
        eval {  @preconditions = $cmd->add($ttapplied)};
        return $@ if $@;

        $cmd->assign_preconditions($config->{testrun_id}, @preconditions);
        return \@preconditions;
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
        my $all_testruns : Stash;
        my $position   = $form->get_element({type => 'Submit'});
        my $file       = $c->session->{usecase_file};
        my %macros;
        $c->res->redirect('/tapper/testruns/create') unless $file;

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
                my @testhosts;
                if ( defined ($testrun_data->{requested_hosts})){
                        if ( ref($testrun_data->{requested_hosts}) eq 'ARRAY') {
                                @testhosts = @{$testrun_data->{requested_hosts}};
                        } else {
                                @testhosts = ( $testrun_data->{requested_hosts} );
                        }
                } else {
                        @testhosts = map { $_->[0] } @{get_hostnames()};
                }

                $all_testruns = [];
        HOST:
                for( my $i=0; $i < @testhosts; $i++) {
                        my $host = $testhosts[$i];
                        # we need a copy since we modify the hash before
                        # giving it to Tapper::Cmd and this
                        # modification would be used when the user clicks reload
                        my %testrun_settings     = %$testrun_data;
                        $testrun_settings{queue} = Tapper::Config->subconfig->{new_testrun_queue};

                        $all_testruns->[$i]->{host} = $host;

                        $testrun_settings{requested_hosts} = [ requested_hosts => $host ];
                        my $cmd = Tapper::Cmd::Testrun->new();
                        eval { $config->{testrun_id} = $cmd->add(\%testrun_settings)};
                        if ($@) {
                                $all_testruns->[$i]->{ error } = @_;
                                next HOST;
                        }
                        $all_testruns->[$i]->{id} = $config->{testrun_id};

                        $config->{file} = $file;
                        my $preconditions = $self->handle_precondition($c, $config);
                        if (ref($preconditions) eq 'ARRAY') {
                                $all_testruns->[$i]->{ preconditions } = $preconditions;
                        } else {
                                $all_testruns->[$i]->{ error } = $preconditions;
                        }

                }
        }
}


sub prepare_testrunlists : Private
{
        my ( $self, $c ) = @_;

        my @requested_testrunlists : Stash = ();
        my %groupstats             : Stash = ();

        # requested time period
        my $days : Stash;
        my $lastday = $days ? $days - 1 : 6;
        my $util = Tapper::Reports::Web::Util::Testrun->new();

        # ----- general -----

        my $filter_condition;

        my $testruns = $c->model('TestrunDB')->resultset('Testrun')->search
          (
           $filter_condition,
           { order_by => 'id desc' }
          );


        my $parser = new DateTime::Format::Natural;
        my $today  = $parser->parse_datetime("today at midnight");
        my @day    = ( $today );
        push @day, $today->clone->subtract( days => $_ ) foreach 1..$lastday;

        # ----- today -----
        my $day0_testruns = $testruns->search ( { '-or' => [ { created_at => { '>', $day[0] }}, { starttime_testrun => { '>', $day[0] }}] });
        push @requested_testrunlists, {
                                       day => $day[0],
                                       (testruns => $util->prepare_testrunlist( $day0_testruns ) ),
                                      };
        # ----- last week days -----
        foreach (1..$lastday) {
                my $day_testruns = $testruns->search ({-or => [
                                                               { -and => [ created_at => { '>', $day[$_]     },
                                                                           created_at => { '<', $day[$_ - 1] } ] },
                                                               { -and => [ starttime_testrun => { '>', $day[$_]     },
                                                                           starttime_testrun => { '<', $day[$_ - 1] }  ] }
                                                              ]} );
                push @requested_testrunlists, {
                                               day => $day[$_],
                                               ( testruns => $util->prepare_testrunlist( $day_testruns ) ),
                                              };
        }
}

sub prepare_navi : Private
{
        my ( $self, $c ) = @_;

        my $navi : Stash = [
                            {
                             title  => "Testruns by date",
                             href   => "/tapper/testruns/days/2",
                             active => 0,
                             subnavi => [
                                         {
                                          title  => "today",
                                          href   => "/tapper/testruns/days/1",
                                         },
                                         {
                                          title  => "1 week",
                                          href   => "/tapper/testruns/days/7",
                                         },
                                         {
                                          title  => "2 weeks",
                                          href   => "/tapper/testruns/days/14",
                                         },
                                         {
                                          title  => "3 weeks",
                                          href   => "/tapper/testruns/days/21",
                                         },
                                         {
                                          title  => "1 month",
                                          href   => "/tapper/testruns/days/30",
                                         },
                                         {
                                          title  => "2 months",
                                          href   => "/tapper/testruns/days/60",
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
                                          href   => "/tapper/testruns/create/",
                                         },
                                        ],
                            },
                           ];
}

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Testruns - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index



=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This program is released under the following license: freebsd

=cut

1;
