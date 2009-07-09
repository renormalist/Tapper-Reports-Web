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
                $c->response->body ($reportfile->filecontent);
        }
}

1;
