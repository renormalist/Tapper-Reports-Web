package Artemis::Reports::Web::Controller::Artemis::ReportFile::Id;

use strict;
use warnings;
use parent 'Artemis::Reports::Web::Controller::Base';
use Directory::Scratch;

#use HTML::FromANSI (); # avoid exports if using OO

sub index :Path :CaptureArgs(2)
{
        my ( $self, $c, $file_id, $viewmode ) = @_;
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
                my @filecontent =
                    $viewmode eq "inline"
                        ? filter($reportfile->filecontent)
                        : $viewmode eq 'ansi2txt'
                            ? ansi2txt($reportfile->filecontent)
                                : $viewmode eq 'ansi2html'
                                    ? ansi2html($reportfile->filecontent)
                                    : $reportfile->filecontent;
                $c->response->body (@filecontent);
        }
}

sub ansi2html {
        my @content = @_;
        my $temp  = new Directory::Scratch (TEMPLATE => 'ARW_XXXXXXXXXXXX', CLEANUP  => 1);
        my $dir   = $temp->mkdir("ansi2txt");
        my $fname = "section/foo.txt";
        $temp->touch($fname, join("", @content));
        my $ansi2txt = "ansi2txt";
        my $html = qx!$ansi2txt -html $temp/$fname!;
        $html =~ s!^</b><b style="color: #000000; background: #000000;">[ \t\n]+</b>!</b>!msg;
        return $html;
}

sub ansi2txt {
        my @content = @_;
        my $temp  = new Directory::Scratch (TEMPLATE => 'ARW_XXXXXXXXXXXX', CLEANUP  => 1);
        my $dir   = $temp->mkdir("ansi2txt");
        my $fname = "section/foo.txt";
        $temp->touch($fname, join("", @content));
        my $ansi2txt = "ansi2txt";
        my $html = qx!$ansi2txt $temp/$fname!;
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
