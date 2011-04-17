package Tapper::Reports::Web::Controller::Tapper::Overview;

use parent 'Tapper::Reports::Web::Controller::Base';
use DateTime;

use common::sense;
## no critic (RequireUseStrict)

sub auto :Private
{
        my ( $self, $c ) = @_;
        $c->forward('/tapper/overview/prepare_navi');
}


# Filter suite list so that only recently used suites are given.
# 
# @param suite result set - unfiltered suites
# @param int/string       - duration
#
# @return suite result set - filtered suites
#
sub recently_used_suites
{
        my ($self, $suite_rs, $duration) = @_;
        my $timeframe;
        if ($duration) {
                return $suite_rs if lc($duration) eq 'all';
                $timeframe = DateTime->now->subtract(weeks => $duration);
        } else {
                $timeframe = DateTime->now->subtract(weeks => 12);
        }
        $suite_rs  = $suite_rs->search({'reports.created_at' => {'>=' => $timeframe}});
        return $suite_rs;
}


sub index :Path :Args()
{
        my ( $self, $c, $type, $options ) = @_;
        my $overviews : Stash;
        given ($type){
                when ('suite') {
                        my $suite_rs = $c->model('ReportsDB')->resultset('Suite')->search({},
                                                                                          {prefetch => ['reports']}
                                                                                         );
                        $suite_rs = $self->recently_used_suites($suite_rs, $options);
                        $overviews = { map{$_->name, '/tapper/reports/suite/'.$_->id } $suite_rs->all };
                }
                when ('host')  {
                        my $reports = $c->model('ReportsDB')->resultset('Report')->search({},
                                                                                          { columns => [ qw/machine_name/ ],
                                                                                            distinct => 1});
                        $overviews = { map{$_->machine_name, '/tapper/reports/host/'.$_->machine_name} $reports->all };
                }
        }
}

sub prepare_navi : Private
{
        my ( $self, $c ) = @_;

        my $navi : Stash = [{
                            title => 'Overview of',
                            subnavi => [
                                        {
                                         title => 'Suites',
                                         href  => "/tapper/overview/suite",
                                        },
                                        {
                                         title => 'Hosts',
                                         href  => "/tapper/overview/host",
                                        },
                                       ],
                            
                           },
                           {
                            title => 'Suites used in the last..',
                            subnavi => [
                                        {
                                         title => '1 week',
                                         href  => "/tapper/overview/suite/1",
                                        },
                                        {
                                         title => '2 weeks',
                                         href  => "/tapper/overview/suite/2",
                                        },
                                        {
                                         title => '6 weeks',
                                         href  => "/tapper/overview/suite/6",
                                        },
                                        {
                                         title => '12 weeks',
                                         href  => "/tapper/overview/suite/12",
                                        },
                                       ],
                            
                           },
                           {
                            title => 'All suites',
                            href  => '/tapper/overview/suite/all',
                           }
                          ];
}

1;
