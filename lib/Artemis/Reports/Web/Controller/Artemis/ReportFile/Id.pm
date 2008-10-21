package Artemis::Reports::Web::Controller::Artemis::ReportFile::Id;

use strict;
use warnings;
use parent 'Artemis::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $report_id ) = @_;
        my $reportfile : Stash = $c->model('ReportsDB')->resultset('ReportFile')->find($report_id);

        if ($reportfile) {
                $c->response->content_type ($reportfile->contenttype || 'application/octet-stream');
                $c->response->header ("Content-Disposition" => 'attachment; filename="'.$reportfile->filename.'"');
                $c->response->body ($reportfile->filecontent);
        }
}

1;
