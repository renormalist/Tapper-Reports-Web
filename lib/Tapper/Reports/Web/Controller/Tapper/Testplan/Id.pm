package Tapper::Reports::Web::Controller::Tapper::Testplan::Id;

use parent 'Tapper::Reports::Web::Controller::Base';

use common::sense;
## no critic (RequireUseStrict)

=head2 index



=cut

sub index :Path :Args(1)
{
        my ( $self, $c, $testplan_id ) = @_;
        return;
}




=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Testplan - Catalyst Controller for test plans

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index



=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 LICENSE

This program is released under the following license: freebsd

=cut

1;
