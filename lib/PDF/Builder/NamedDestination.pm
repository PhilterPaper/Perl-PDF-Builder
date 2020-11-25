package PDF::Builder::NamedDestination;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
no warnings qw[ recursion uninitialized ];

# VERSION
my $LAST_UPDATE = '3.020'; # manually update whenever code is changed

# TBD: do -rect and -border apply to Named Destinations (link, url, file)? 
#      There is nothing to implement these options. Perhaps the code was copied 
#      from Annotations and never cleaned up? Disable mention of these options 
#      for now (in the POD). Only link handles the destination page fit option.

use Encode qw(:all);

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::NamedDestination - Add named destination shortcuts to a PDF

=head1 METHODS

=over

=item $dest = PDF::Builder::NamedDestination->new($pdf)

Returns a named destination object.

=back

=head2 Destination types

=over

=cut

sub new {
    my ($class, $pdf) = @_;

    my ($self);

    $class = ref $class if ref $class;
    $self = $class->SUPER::new($pdf);

    $pdf->new_obj($self) unless $self->is_obj($pdf);

    return $self;
}

# Note: new_api() removed in favor of new():
#   new_api($api, ...)  replace with new($api->{'pdf'}, ...)

=item $dest->link($page, %opts)

=item $dest->link($page)

Defines the destination as launch-page with page C<$page> and
options %opts for target page fit.

=cut

sub link {
    my ($self, $page, %opts) = @_;

    $self->{'S'} = PDFName('GoTo');
    $self->dest($page, %opts);

    return $self;
}

=item $dest->url($url, %opts)

=item $dest->url($url)

Defines the destination as launch-url with url C<$url> and
page-fit options %opts.

=cut

sub url {
    my ($self, $url, %opts) = @_;

    $self->{'S'} = PDFName('URI');
    $self->{'URI'} = PDFString($url, 'u');

    return $self;
}

=item $dest->file($file, %opts)

=item $dest->file($file)

Defines the destination as launch-file with filepath C<$file> and
page-fit options %opts.

=cut

sub file {
    my ($self, $url, %opts) = @_;

    $self->{'S'} = PDFName('Launch');
    $self->{'F'} = PDFString($url, 'u');

    return $self;
}

=item $dest->pdf_file($pdffile, $pagenum, %opts)

=item $dest->pdf_file($pdffile, $pagenum)

Defines the destination as a PDF-file with filepath C<$pdffile>, on page
C<$pagenum>, and options %opts (same as dest()).

=cut

sub pdf_file {
    my ($self, $url, $pnum, %opts) = @_;

    $self->{'S'} = PDFName('GoToR');
    $self->{'F'} = PDFString($url, 'u');

    $self->dest(PDFNum($pnum), %opts);

    return $self;
}

=item $dest->dest($page, -fit => 1)

Display the page designated by C<$page>, with its contents magnified just enough
to fit the entire page within the window both horizontally and vertically. If 
the required horizontal and vertical magnification factors are different, use 
the smaller of the two, centering the page within the window in the other 
dimension.

=item $dest->dest($page, -fith => $top)

Display the page designated by C<$page>, with the vertical coordinate C<$top> 
positioned at the top edge of the window and the contents of the page magnified 
just enough to fit the entire width of the page within the window.

=item $dest->dest($page, -fitv => $left)

Display the page designated by C<$page>, with the horizontal coordinate C<$left>
positioned at the left edge of the window and the contents of the page magnified
just enough to fit the entire height of the page within the window.

=item $dest->dest($page, -fitr => [$left, $bottom, $right, $top])

Display the page designated by C<$page>, with its contents magnified just enough
to fit the rectangle specified by the coordinates C<$left>, C<$bottom>, 
C<$right>, and C<$top> entirely within the window both horizontally and 
vertically. If the required horizontal and vertical magnification factors are 
different, use the smaller of the two, centering the rectangle within the window
in the other dimension.

=item $dest->dest($page, -fitb => 1)

Display the page designated by C<$page>, with its contents magnified 
just enough to fit its bounding box entirely within the window both horizontally
and vertically. If the required horizontal and vertical magnification factors 
are different, use the smaller of the two, centering the bounding box within the
window in the other dimension.

=item $dest->dest($page, -fitbh => $top)

Display the page designated by C<$page>, with the vertical coordinate 
C<$top> positioned at the top edge of the window and the contents of the page 
magnified just enough to fit the entire width of its bounding box within the 
window.

=item $dest->dest($page, -fitbv => $left)

Display the page designated by C<$page>, with the horizontal 
coordinate C<$left> positioned at the left edge of the window and the contents 
of the page magnified just enough to fit the entire height of its bounding box 
within the window.

=item $dest->dest($page, -xyz => [$left, $top, $zoom])

Display the page designated by page, with the coordinates C<[$left, $top]> 
positioned at the top-left corner of the window and the contents of the page 
magnified by the factor C<$zoom>. A zero (0) value for any of the parameters 
C<$left>, C<$top>, or C<$zoom> specifies that the current value of that 
parameter is to be retained unchanged.

This is the B<default> fit setting, with position (left and top) and zoom
the same as the calling page's.

=cut

sub dest {
    my ($self, $page, %opts) = @_;

    if (ref $page) {
        if      (defined $opts{'-fit'}) {
            $self->{'D'} = PDFArray($page, PDFName('Fit'));
        } elsif (defined $opts{'-fith'}) {
            $self->{'D'} = PDFArray($page, PDFName('FitH'), PDFNum($opts{'-fith'}));
        } elsif (defined $opts{'-fitb'}) {
            $self->{'D'} = PDFArray($page, PDFName('FitB'));
        } elsif (defined $opts{'-fitbh'}) {
            $self->{'D'} = PDFArray($page, PDFName('FitBH'), PDFNum($opts{'-fitbh'}));
        } elsif (defined $opts{'-fitv'}) {
            $self->{'D'} = PDFArray($page, PDFName('FitV'), PDFNum($opts{'-fitv'}));
        } elsif (defined $opts{'-fitbv'}) {
            $self->{'D'} = PDFArray($page, PDFName('FitBV'), PDFNum($opts{'-fitbv'}));
        } elsif (defined $opts{'-fitr'}) {
            die "Insufficient parameters to ->dest(page, -fitr => []) " unless scalar @{$opts{'-fitr'}} == 4;
            $self->{'D'} = PDFArray($page, PDFName('FitR'), map {PDFNum($_)} @{$opts{'-fitr'}});
        } elsif (defined $opts{'-xyz'}) {
            die "Insufficient parameters to ->dest(page, -xyz => []) " unless scalar @{$opts{'-xyz'}} == 3;
            $self->{'D'} = PDFArray($page, PDFName('XYZ'), map {defined $_ ? PDFNum($_) : PDFNull()} @{$opts{'-xyz'}});
	} else {
	    # no "fit" option found. use default.
            $opts{'-xyz'} = [undef,undef,undef];
            $self->{'D'} = PDFArray($page, PDFName('XYZ'), map {defined $_ ? PDFNum($_) : PDFNull()} @{$opts{'-xyz'}});
        }
    }

    return $self;
}

=back

=cut

1;
