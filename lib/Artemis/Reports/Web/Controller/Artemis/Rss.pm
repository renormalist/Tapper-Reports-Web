package Artemis::Reports::Web::Controller::Artemis::Rss;

use strict;
use warnings;
use XML::Feed;
use DateTime;
use Artemis::Reports::Web::Util::Filter;

use 5.010;

use parent 'Catalyst::Controller';

=head2 index

Controller for RSS feeds of results reported to Artemis Reports
Framework. The function expectes an unrestricted number of arguments
that are interpreted as filters. Thus, the arguments need to be in pairs
of $filter_type/$filter_value. Since index is a catalyst function the
typical catalyst arguments $self and $c do not occur in the API doc.

@param array - filter arguments

=cut 

sub index :Path :Args()
{
        my ($self,$c, @args) = @_;

        my $filter = Artemis::Reports::Web::Util::Filter->new(context => $c);


        my $feed = XML::Feed->new('RSS');
        $feed->title( ' RSS Feed' );
        $feed->link( $c->req->base ); # link to the site.
        $feed->description('Artemis Reports'); 

        my $feed_entry;
        my $title;

        
        my $filter_condition;
        my $now = DateTime->now();
        
        $now->subtract(days => 2);
        $filter_condition->{created_at} = {'>' => $now};

        $filter_condition = $filter->parse_filters(\@args);
        if ( defined $filter_condition->error ) {
                $feed_entry  = XML::Feed::Entry->new('RSS');
                $feed_entry->title( $filter_condition->error );
                $feed_entry->issued( DateTime->now );
                $feed->add_entry($feed_entry);
        }

        my $date = DateTime->now;
        $date = $date->subtract(weeks => 1);
        my $reports = $c->model('ReportsDB')->resultset('Report')->search
          ( 
           $filter_condition,              
           { 
            columns   => [ qw( id
                               suite_id
                               created_at
                               machine_name
                               created_at
                               success_ratio
                               successgrade
                               reviewed_successgrade
                               total
                            )],
           }
           );

        # Process the entries
        foreach my $report ($reports->all) {
                $feed_entry  = XML::Feed::Entry->new('RSS');
                $title       = $report->successgrade;
                $title      .= " ".$report->success_ratio."%";
                $title      .= " ".$report->suite->name;
                $title      .= " @ ";
                $title      .= $report->machine_name || 'unknown machine';
                $feed_entry->title( $title );
                $feed_entry->link( $c->req->base->as_string.'/artemis/reports/id/'.$report->id );
                $feed_entry->issued( $report->created_at );
                $feed->add_entry($feed_entry);
        }

        $c->res->body( $feed->as_xml );
}

1;

__END__

=head1 NAME

Artemis::Reports::Web::Controller::Artemis::Hardware - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

