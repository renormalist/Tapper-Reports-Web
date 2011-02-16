package Artemis::Reports::Web::Controller::Artemis::Testplan::Id;

use parent 'Artemis::Reports::Web::Controller::Base';

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

Artemis::Reports::Web::Controller::Artemis::Testplan - Catalyst Controller for test plans

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index



=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
