package Tapper::Reports::Web::Controller::Tapper::Reports::IdList;

use 5.010;

use strict;
use warnings;

use parent 'Tapper::Reports::Web::Controller::Base';

#

sub prepare_idlist : Private
{
        my ( $self, $c, $ids ) = @_;

        my $reportlist : Stash = ();

        use Data::Dumper;
        my @idfilter = map { ("me.id" => $_) } @$ids;
        my $reports  = $c->model('ReportsDB')->resultset('Report')->search
            (
             { -or => [ @idfilter ] },
             {  order_by  => 'me.id desc',
                columns   => [ qw( id
                                   machine_name
                                   created_at
                                   success_ratio
                                   successgrade
                                   reviewed_successgrade
                                   total
                                   peerport
                                   peeraddr
                                   peerhost
                                )],
                join      => [ 'reportgrouparbitrary',              'reportgrouptestrun', 'suite' ],
                '+select' => [ 'reportgrouparbitrary.arbitrary_id', 'reportgrouparbitrary.primaryreport', 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport', 'suite.id', 'suite.name', 'suite.type', 'suite.description' ],
                '+as'     => [ 'rga_id',                            'rga_primary',                        'rgt_id',                        'rgt_primary',                      'suite_id', 'suite_name', 'suite_type', 'suite_description' ],
             }
            );
        my $util_report = Tapper::Reports::Web::Util::Report->new();
        $reportlist = $util_report->prepare_simple_reportlist($c,  $reports);
}

sub index :Path :Args(1)
{
        my ( $self, $c, $idlist ) = @_;

        my $filter_condition : Stash = {};

        print STDERR "idlist = <$idlist>\n";
        my @ids = split (qr/, */, $idlist);

        $c->forward('/tapper/reports/idlist/prepare_idlist', [ \@ids ]);
}

1;
