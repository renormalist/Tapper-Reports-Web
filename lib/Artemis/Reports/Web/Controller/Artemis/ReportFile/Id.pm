package Artemis::Reports::Web::Controller::Artemis::ReportFile::Id;

use strict;
use warnings;
use parent 'Artemis::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $file_id ) = @_;
        my $reportfile : Stash = $c->model('ReportsDB')->resultset('ReportFile')->find($file_id);

        if (not $reportfile)
        {
                $c->response->content_type ("plain");
                $c->response->header ("Content-Disposition" => 'inline; filename="nonexistent.reportfile.'.$file_id.'"');
                $c->response->body ("Error: File with id $file_id does not exist.");
        }
        elsif (not $reportfile->filecontent)
        {
                $c->response->content_type ("plain");
                $c->response->header ("Content-Disposition" => 'inline; filename="empty.reportfile.'.$file_id.'"');
                $c->response->body ("Error: File with id $file_id is empty.");
        }
        else
        {
                my $disposition = $reportfile->contenttype =~ /plain/ ? 'inline' : 'attachment';
                $c->response->content_type ($reportfile->contenttype || 'application/octet-stream');
                $c->response->header ("Content-Disposition" => $disposition.'; filename="'.$reportfile->filename.'"');
                $c->response->body (filter($reportfile->filecontent));
        }
}

sub filter
{
        my @retval;
        foreach my $line (@_) {
                $line =~ s/\000//g;
                $line =~ s/\015//g;
                $line =~ s/\033\[.*?[mH]//g;
                $line =~ s/\033\d+/\t/g;
                $line =~ s/\017//g;
                $line =~ s/\033\[\?25h//g;
                push @retval, $line;
        }
        return @retval;
}

1;
