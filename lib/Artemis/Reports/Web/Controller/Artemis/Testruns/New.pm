package Artemis::Reports::Web::Controller::Artemis::Testruns::New;

=head1 NAME

Artemis::Reports::Web::Controller::Artemis::Testruns::New - Controller for creating new testruns, data collection part

=head1 SYNOPSIS

Used as part of Catalyst project Artemis::Reports::Web.

=cut

use strict;
use warnings;
use File::Basename;

use parent 'Artemis::Reports::Web::Controller::Base';

=head2 log_and_exec

Index method is called by default. It has no return values but provides
information to the caller though stash variables.

=cut


sub index :Path
{
        my ( $self, $c ) = @_;
}


1;

=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 BUGS

None.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Artemis::Reports::Web::Controller::Artemis::Testruns::New

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 OSRC SysInt Team, all rights reserved.

This program is released under the following license: restrictive

