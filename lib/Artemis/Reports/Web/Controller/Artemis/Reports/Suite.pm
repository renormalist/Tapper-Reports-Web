package Artemis::Reports::Web::Controller::Artemis::Reports::Suite;

use 5.010;

use strict;
use warnings;

use parent 'Catalyst::Controller::BindLex';
__PACKAGE__->config->{bindlex}{Param} = sub { $_[0]->req->params };



sub index :Path :Args(1)
{
        my ( $self, $c, $suite_id ) = @_;

        my $main_condition = { suite_id => $suite_id };

        # ----- general -----

        my $reports = $c->model('ReportsDB')->resultset('Report')->search
            (
             $main_condition,
             { order_by => 'id desc' },
            );

        my $parser    = new DateTime::Format::Natural;
        my $today     = $parser->parse_datetime("today at midnight");
        my $yesterday = $parser->parse_datetime("yesterday at midnight");


        # ----- today -----

        my $today_reports = $reports->search
            (
             {
              created_at => { '>', $today },
             },
            );
        my $today_reportlist : Stash = $c->forward('/artemis/reports/prepare_simple_reportlist', [ $today_reports ]);



        # ----- yesterday -----

        my $yesterday_reports = $reports->search
            (
             {
              -and => [
                       created_at => { '>', $yesterday },
                       created_at => { '<', $today     },
                      ],
             },
            );
        my $yesterday_reportlist : Stash = $c->forward('/artemis/reports/prepare_simple_reportlist', [ $yesterday_reports ]);

}

1;
