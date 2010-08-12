package Artemis::Reports::Web::Controller::Artemis::Overview;


use parent 'Artemis::Reports::Web::Controller::Base';

use common::sense;


sub auto :Private
{
        my ( $self, $c ) = @_;
        $c->forward('/artemis/overview/prepare_navi');
}



sub index :Path :Args()
{
        my ( $self, $c, $type ) = @_;
        my $overviews : Stash;
        given ($type){
                when ('suite') {
                        my $suite_rs = $c->model('ReportsDB')->resultset('Suite');
                        $overviews = { map{$_->name, '/artemis/reports/suite/'.$_->id } $suite_rs->all };
                }
                when ('host')  {
                        my $reports = $c->model('ReportsDB')->resultset('Report')->search({},
                                                                                          { columns => [ qw/machine_name/ ],
                                                                                            distinct => 1});
                        $overviews = { map{$_->machine_name, '/artemis/reports/host/'.$_->machine_name} $reports->all };
                }
        }
}

sub prepare_navi : Private
{
        my ( $self, $c ) = @_;

        my $nav : Stash = {
                           Suites => "/artemis/overview/suite",
                           Hosts  => "/artemis/overview/host",
                          };
}

1;
