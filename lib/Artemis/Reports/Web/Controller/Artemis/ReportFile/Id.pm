package Artemis::Reports::Web::Controller::Artemis::ReportFile::Id;

use parent 'Artemis::Reports::Web::Controller::Base';
use Directory::Scratch;

use common::sense;

#use HTML::FromANSI (); # avoid exports if using OO

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
                        @filecontent =  ansi2txt($reportfile->filecontent);

                } elsif ( $viewmode eq 'ansi2html' ) {
                        $filename    =~ s,[./],_,g if $disposition eq 'inline';
                        $filename   .=  '.html';
                        @filecontent =  ansi2html($reportfile->filecontent);
                        $c->response->content_type('text/html');
                } else {
                        @filecontent =  $reportfile->filecontent;
                }

                $c->response->header ("Content-Disposition" => qq($disposition; filename="$filename"));
                $c->response->body (@filecontent);
        }
}

sub ansi2html {
        my @content = @_;
        my $ansi2txt = 'ansi2txt';
        qx(ansi2txt /dev/null);
        if ( $? != 256 ) {  # ansi2txt returns exit code 1 on /dev/null but exists
                print STDERR "ansi2txt not installed";
                return @content;
        }

        my $temp  = Directory::Scratch->new(TEMPLATE => 'ARW_XXXXXXXXXXXX');
        my $dir   = $temp->mkdir("ansi2txt");
        my $fname = "section/foo.txt";
        $temp->touch($fname, join("", @content));
        my $html = qx!$ansi2txt -html $temp/$fname!;
        $html =~ s!^</b><b style="color: #000000; background: #000000;">[ \t\n]+</b>!</b>!msg;
        $temp->cleanup;
        return $html;
}

sub ansi2txt {
        my @content = @_;
        my $ansi2txt = 'ansi2txt';
        qx(ansi2txt /dev/null);
        if ( $? != 256 ) {  # ansi2txt returns exit code 1 on /dev/null but exists
                print STDERR "ansi2txt not installed";
                return @content;
        }

        my $temp  = Directory::Scratch->new(TEMPLATE => 'ARW_XXXXXXXXXXXX');
        my $dir   = $temp->mkdir("ansi2txt");
        my $fname = "section/foo.txt";
        $temp->touch($fname, join("", @content));
        my $html = qx!$ansi2txt $temp/$fname!;
        $temp->cleanup;
        return $html;
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
