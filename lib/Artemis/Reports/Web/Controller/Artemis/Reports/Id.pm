package Artemis::Reports::Web::Controller::Artemis::Reports::Id;

use strict;
use warnings;

use parent 'Artemis::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $report_id ) = @_;

        my $report : Stash = $c->model('ReportsDB')->resultset('Report')->find($report_id);
#         my $report : Stash;
#         $report = ($c->model('ReportsDB')->resultset('Report')->search
#                    (
#                     { id => $report_id},
#                     {
#                      +select => [ \"length('filecontent')" ],               # " ]
#                      +as     => [ "length" ],
#                     },
#                    )->all)[0];
#         use Data::Dumper;
#         print STDERR Dumper($report);
}

1;
