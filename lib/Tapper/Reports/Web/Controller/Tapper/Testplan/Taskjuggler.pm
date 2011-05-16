package Tapper::Reports::Web::Controller::Tapper::Testplan::Taskjuggler;

use parent 'Tapper::Reports::Web::Controller::Base';
use Tapper::Testplan::Reporter;
use Tapper::Testplan::Plugins::Taskjuggler;
use Tapper::Config;
use Hash::Merge 'merge';

use common::sense;
## no critic (RequireUseStrict)

=head2 index

Generate data for /tapper/testplan/taskjuggler/.

=cut

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
        my $taskjuggler = Tapper::Testplan::Plugins::Taskjuggler->new(cfg => Tapper::Config->subconfig->{testplans}{reporter}{plugin});
        my $reporter    = Tapper::Testplan::Reporter->new();
        my $platforms : Stash = $taskjuggler->prepare_task_data();
        return;
}





=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Testplan::OSRC - Show testplans for OSRC project planning

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
