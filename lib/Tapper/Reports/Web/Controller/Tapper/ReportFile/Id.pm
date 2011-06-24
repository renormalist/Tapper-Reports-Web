package Tapper::Reports::Web::Controller::Tapper::ReportFile::Id;

use parent 'Tapper::Reports::Web::Controller::Base';
use HTML::FromANSI ();

use common::sense;
## no critic (RequireUseStrict)

#use HTML::FromANSI (); # avoid exports if using OO

our $ANSI2HTML_PRE  = '<link rel="stylesheet" type="text/css" title="Red" href="/tapper/static/css/style_red.css" /><body style="background: black;">';
our $ANSI2HTML_POST = '</body>';

sub index :Path :CaptureArgs(2)
{
        my ( $self, $c, $file_id, $viewmode ) = @_;
        my $reportfile : Stash = $c->model('ReportsDB')->resultset('ReportFile')->find($file_id);

        if (not $reportfile)
        {
                $c->response->content_type ("text/plain");
                $c->response->header ("Content-Disposition" => 'inline; filename="nonexistent.reportfile.'.$file_id.'"');
                $c->response->body ("Error: File with id $file_id does not exist.");
        }
        elsif (not $reportfile->filecontent)
        {
                $c->response->content_type ("text/plain");
                $c->response->header ("Content-Disposition" => 'inline; filename="empty.reportfile.'.$file_id.'"');
                $c->response->body ("Error: File with id $file_id is empty.");
        }
        else
        {
                my $contenttype = $reportfile->contenttype eq 'plain' ? 'text/plain' : $reportfile->contenttype;
                my $disposition = $contenttype =~ /plain/ ? 'inline' : 'attachment';
                $c->response->content_type ($contenttype || 'application/octet-stream');

                my $filename = $reportfile->filename;
                my @filecontent;
                my $content_disposition;

                if ( $viewmode eq 'ansi2txt' ) {
                        $filename    =~ s,[./],_,g if $disposition eq 'inline';
                        $filename   .=  '.txt';
                        @filecontent =  ansi_to_txt($reportfile->filecontent);

                } elsif ( $viewmode eq 'ansi2html' ) {
                        $filename    =~ s,[./],_,g if $disposition eq 'inline';
                        $filename   .=  '.html';
                        my $a2h = HTML::FromANSI->new(style => '', font_face => '');
                        @filecontent =  $ANSI2HTML_PRE.$a2h->ansi_to_html($reportfile->filecontent).$ANSI2HTML_POST;
                        $c->response->content_type('text/html');
                } else {
                        @filecontent =  $reportfile->filecontent;
                }
                my $filecontent = join '', @filecontent;
                $filecontent    =~ s/ +$//mg if $viewmode eq 'ansi2html' or $viewmode eq 'ansi2txt';
                $c->response->header ("Content-Disposition" => qq($disposition; filename="$filename"));
                $c->response->body ($filecontent);
        }
}

# strip known ANSI sequences and special characters
# usually used in console output
sub ansi_to_txt {
        my ($filecontent) = @_;

        $filecontent =~ s/\e\[?.*?[\@-~](?:\?\d\d[hl])?//g;
        $filecontent =~ s,(?:\n\r)+,\n,g;
        $filecontent =~ s,\r(?!\n), ,g;
        $filecontent =~ s,[]+, ,g;
        return $filecontent;
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
