package Artemis::Reports::Web::View::Mason;

use strict;
use warnings;

use Artemis::Reports::Web;

use base 'Catalyst::View::Mason';

__PACKAGE__->config( use_match          => 0      );
__PACKAGE__->config( template_extension => '.mas' );
__PACKAGE__->config( use_match          => 0      );
__PACKAGE__->config( dynamic_comp_root  => 1      );
__PACKAGE__->config( comp_root          => [
                                            [ artemisroot => Artemis::Reports::Web->config->{root}.'' ],
                                           ]
                   );
__PACKAGE__->config( default_escape_flags => [ 'h' ]);
__PACKAGE__->config( escape_flags => {
                                      url => \&my_url_filter,
                                      h   => \&HTML::Mason::Escapes::basic_html_escape,
                                     }
                   );

sub my_url_filter
{
        my $text_ref = shift;
        my $kopie     = $$text_ref;
        Encode::_utf8_off($kopie); # weil URI::URL mit utf8-Flag das falsche macht
        $$text_ref = URI::URL->new($kopie)->as_string;
        $$text_ref =~ s,/,%2F,g;
}

=head1 NAME

Artemis::Reports::Web::View::Mason - Mason View Component

=head1 SYNOPSIS

    Very simple to use

=head1 DESCRIPTION

Very nice component.

=head1 AUTHOR

Clever guy

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;

# Local Variables:
# buffer-file-coding-system: utf-8
# End:
