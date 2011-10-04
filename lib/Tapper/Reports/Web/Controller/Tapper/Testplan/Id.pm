package Tapper::Reports::Web::Controller::Tapper::Testplan::Id;

use parent 'Tapper::Reports::Web::Controller::Base';

use common::sense;
## no critic (RequireUseStrict)
use Tapper::Model 'model';
use Tapper::Reports::Web::Util::Testrun;

use Data::DPath 'dpath';
use File::Basename 'basename';
use YAML::Syck 'Load';

=head2 parse_testrun

Generate an overview of a testplan element from testrun description.

@param hash ref  - describes testrun

@return hash ref - overview of testrun

=cut

sub parse_testrun
{
        my ($self, $testrun) = @_;
        my $description = $testrun->{description};
        my %testrun;
        $testrun{image}     = $description ~~ dpath '/preconditions/*/mount[value eq "/"]/../image';
        $testrun{kernel}    = $description ~~ dpath '/preconditions/*/filename[ value =~ /linux-.*2.6/]';
        $testrun{test}      = [ map { basename($_) } @{$description ~~
                                                         dpath '/preconditions/*/precondition_type[ value eq "testprogram"]/../program'} ];
        $testrun{shortname} = $description->{shortname};
        return \%testrun;
}


=head2 gen_testplan_overview

Generate an overview from evaluated testplan.

@param string - plan as YAML text

@return array ref - overview of all testplan elements

=cut

sub gen_testplan_overview
{
        my ($self, $yaml) = @_;
        my $error : Stash;
        my @plans;
        eval {
                @plans = Load($yaml);
        };
        if ($@) {
                $error = "Broken YAML in testplan: $@";
                return [];
        }
        my @testplan_elements;

        foreach my $plan (@plans) {
                given ($plan->{type})
                {
                        when(['multitest', 'testrun'])  { push @testplan_elements, $self->parse_testrun($plan) }
                }
        }
        return \@testplan_elements;
}


=head2 index

=cut

sub index :Path :Args(1)
{
        my ( $self, $c, $instance_id ) = @_;
        my $instance : Stash;
        my $error    : Stash;
        $c->stash->{title} = "Testplan id $instance_id";

        my $inst_res = model('TestrunDB')->resultset('TestplanInstance')->find($instance_id);
        if (not $inst_res) {
                $error = "No testplan with id $instance_id";
                return;
        }
        my $util = Tapper::Reports::Web::Util::Testrun->new();
        my $testruns = $inst_res->testruns;
        my $testrunlist = $util->prepare_testrunlist($testruns);

        $instance->{id}       = $inst_res->id;
        $instance->{name}     = $inst_res->name || '[no name]';
        $instance->{testruns} = $testrunlist;
        $instance->{plan}     = $inst_res->evaluated_testplan;
        $instance->{plan}     =~ s/^\n+//m;
        $instance->{plan}     =~ s/\n+/\n/m;
        $instance->{path}     = $inst_res->path;
        $instance->{overview} = $self->gen_testplan_overview($instance->{plan});
        $c->stash->{title} = "Testplan id $instance_id, ".$instance->{name};
        return;
}




=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Testplan - Catalyst Controller for test plans

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index



=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 LICENSE

This program is released under the following license: freebsd

=cut

1;
