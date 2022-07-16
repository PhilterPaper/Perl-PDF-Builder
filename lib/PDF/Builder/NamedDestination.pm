package PDF::Builder::NamedDestination;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
use warnings;

use Carp;

# VERSION
my $LAST_UPDATE = '3.024'; # manually update whenever code is changed

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

=item $dest = PDF::Builder::NamedDestination->new($pdf, ...)

Creates a new named destination object. Any optional additional arguments
will be passed on to C<destination>.

=back

=head2 Destination types

=over

=cut

sub new {
    my $class = shift;
    my $pdf = shift;

    $pdf = $pdf->{'pdf'} if $pdf->isa('PDF::Builder');
    my $self = $class->SUPER::new($pdf);
    $pdf->new_obj($self);

    if (@_) { # leftover arguments?
	return $self->destination(@_);
    }

    return $self;
}

# Note: new_api() removed in favor of new():
#   new_api($api, ...)  replace with new($api->{'pdf'}, ...)
# Appears to be added back in, PDF::API2 2.042
sub new_api {
    my ($class, $api2) = @_;
    warnings::warnif('deprecated',
	             'Call to deprecated method new_api, replace with new');

    my $destination = $class->new($api2);
    return $destination;
}

=item $dest->dest($page, $location, @args);

A destination (dest) is a particular view of a PDF, consisting of a page 
object, the
location of the window on that page, and possible coordinate and zoom arguments.

    # The XYZ location takes three arguments
    my $dest1 = PDF::API2::NamedDestination->new($pdf);
    $dest->dest($pdf->open_page(1), 'xyz' => ($x, $y, $zoom));

    # The Fit location doesn't require any arguments
    my $dest2 = PDF::API2::NamedDestination->new($pdf);
    $dest->dest($pdf->open_page(2), 'fit');

The following locations ($location) are available. They may be given with a 
leading hyphen (dash), e.g., '-xyz', or without a hyphen (e.g., 'xyz').
A recent change to PDF::API2 specifies locations I<without> the hyphens, so
for compatibility we allow either.

=over

=item 'fit' => 1

Display the page designated by C<$page>, with its contents magnified just enough
to fit the entire page within the window both horizontally and vertically. If 
the required horizontal and vertical magnification factors are different, use 
the smaller of the two, centering the page within the window in the other 
dimension.

=item 'fith' => $top

Display the page designated by C<$page>, with the vertical coordinate C<$top> 
positioned at the top edge of the window and the contents of the page magnified 
just enough to fit the entire width of the page within the window.

=item 'fitv' => $left

Display the page designated by C<$page>, with the horizontal coordinate C<$left>
positioned at the left edge of the window and the contents of the page magnified
just enough to fit the entire height of the page within the window.

=item 'fitr' => [$left, $bottom, $right, $top]

Display the page designated by C<$page>, with its contents magnified just enough
to fit the rectangle specified by the coordinates C<$left>, C<$bottom>, 
C<$right>, and C<$top> entirely within the window both horizontally and 
vertically. If the required horizontal and vertical magnification factors are 
different, use the smaller of the two, centering the rectangle within the window
in the other dimension.

=item 'fitb' => 1

Display the page designated by C<$page>, with its contents magnified 
just enough to fit its bounding box entirely within the window both horizontally
and vertically. If the required horizontal and vertical magnification factors 
are different, use the smaller of the two, centering the bounding box within the
window in the other dimension.

=item 'fitbh' => $top

Display the page designated by C<$page>, with the vertical coordinate 
C<$top> positioned at the top edge of the window and the contents of the page 
magnified just enough to fit the entire width of its bounding box within the 
window.

=item 'fitbv' => $left

Display the page designated by C<$page>, with the horizontal 
coordinate C<$left> positioned at the left edge of the window and the contents 
of the page magnified just enough to fit the entire height of its bounding box 
within the window.

=item 'xyz' => [$left, $top, $zoom]

Display the page designated by page, with the coordinates C<[$left, $top]> 
positioned at the top-left corner of the window and the contents of the page 
magnified by the factor C<$zoom>. A zero (0) value for any of the parameters 
C<$left>, C<$top>, or C<$zoom> specifies that the current value of that 
parameter is to be retained unchanged.

This is the B<default> fit setting, with position (left and top) and zoom
the same as the calling page's.

=back

B<alternate name:> destination

This method was originally C<dest()>, which PDF::API2 renamed to 
C<destination()>. We are keeping the original name, and for compatibility,
allow C<destination> as an alias.

=cut

#sub _array {
#    my $page = shift();
#    my $location = shift();
#    return PDFArray($page, PDFName($location),
#                    map { defined($_) ? PDFNum($_) : PDFNull() } @_);
#}
#
#sub _destination {
#    my ($page, $location, @args) = @_;
#    return _array($page, 'XYZ', undef, undef, undef) unless $location;
#
#    my %arg_counts = (
#        xyz   => 3,
#        fit   => 0,
#        fith  => 1,
#        fitv  => 1,
#        fitr  => 4,
#        fitb  => 0,
#        fitbh => 1,
#        fitbv => 1,
#    );
#    my $arg_count = $arg_counts{$location};
#    croak "Invalid location $location" unless defined $arg_count;
#
#    if      ($arg_count == 0 and @args) {
#        croak "$location doesn't take any arguments";
#    } elsif ($arg_count == 1 and @args != 1) {
#        croak "$location requires one argument";
#   #} elsif ($arg_count == 2 and @args != 2) {
#   #    croak "$location requires two arguments";
#    } elsif ($arg_count == 3 and @args != 3) {
#        croak "$location requires three arguments";
#    } elsif ($arg_count == 4 and @args != 4) {
#        croak "$location requires four arguments";
#    }
#
#    return _array($page, 'XYZ', @args) if $location eq 'xyz';
#    $location =~ s/^fit(.*)$/'Fit' . uc($1 or '')/e;
#    return _array($page, $location, @args);
#}
#
#sub destination {
#    my ($self, $page, $location, @args) = @_;
#    $self->{'D'} = _destination($page, $location, @args);
#    return $self;
#}

sub destination { return dest(@_); } ## no critic

# deprecated by PDF::API2, allowed here for compatibility
# expand to make leading - (dash) optional
sub dest {
    my $self = shift();
    my $page = shift();
    my %opts;
    if      (scalar(@_) == 1) {
	# just one name. if [-]fit[b], assign a value of 1
	if ($_[0] =~ m/^-?fitb?$/) {
	    $opts{$_[0]} = 1;
	} else {
	    # don't know what to do with it
	    croak "Unknown location value ";
	}
    } elsif (scalar(@_)%2) {
	# odd number 3+, presumably just 'fit' or 'fitb'. add a value
	# assuming first element is fit name without value, remainder = options
	$opts{$_[0]} = 1;
	shift();
	# probably shouldn't be additional items (options), but just in case...
	while(@_) {
	    $opts{$_[0]} = $_[1];
	    shift(); shift();
	}
    } else {
	# even number, presumably the %opts hash
	%opts = @_;  # might be empty!
    }

    if (ref($page)) {
	# should be only one 'fit' hash value? other options in hash?
	# TBD: check that single values are scalars, not ARRAYREFs?
        if      (defined $opts{'-fit'} ||
	         defined $opts{'fit'}) {  # 1 value, ignored
            $self->{'D'} = PDFArray($page, PDFName('Fit'));
        } elsif (defined $opts{'-fith'}) {  # 1 value
	    croak "Expecting scalar value for -fith entry "
	        unless ref($opts{'-fith'}) eq '';
            $self->{'D'} = PDFArray($page, PDFName('FitH'), 
		                    PDFNum($opts{'-fith'}));
        } elsif (defined $opts{ 'fith'}) {
	    croak "Expecting scalar value for fith entry "
	        unless ref($opts{'fith'}) eq '';
            $self->{'D'} = PDFArray($page, PDFName('FitH'), 
		                    PDFNum($opts{'fith'}));
        } elsif (defined $opts{'-fitb'} ||
	         defined $opts{'fitb'}) {  # 1 value, ignored
            $self->{'D'} = PDFArray($page, PDFName('FitB'));
        } elsif (defined $opts{'-fitbh'}) {  # 1 value
	    croak "Expecting scalar value for -fitbh entry "
	        unless ref($opts{'-fitbh'}) eq '';
            $self->{'D'} = PDFArray($page, PDFName('FitBH'), 
		                    PDFNum($opts{'-fitbh'}));
        } elsif (defined $opts{'fitbh'}) {
	    croak "Expecting scalar value for fitbh entry "
	        unless ref($opts{'fitbh'}) eq '';
            $self->{'D'} = PDFArray($page, PDFName('FitBH'),
		                    PDFNum($opts{'fitbh'}));
        } elsif (defined $opts{'-fitv'}) {  # 1 value
	    croak "Expecting scalar value for -fitv entry "
	        unless ref($opts{'-fitv'}) eq '';
            $self->{'D'} = PDFArray($page, PDFName('FitV'), 
		                    PDFNum($opts{'-fitv'}));
        } elsif (defined $opts{'fitv'}) {
	    croak "Expecting scalar value for fitv entry "
	        unless ref($opts{'fitv'}) eq '';
            $self->{'D'} = PDFArray($page, PDFName('FitV'), 
		                    PDFNum($opts{'fitv'}));
        } elsif (defined $opts{'-fitbv'}) {  # 1 value
	    croak "Expecting scalar value for -fitbv entry "
	        unless ref($opts{'-fitbv'}) eq '';
            $self->{'D'} = PDFArray($page, PDFName('FitBV'), 
		                    PDFNum($opts{'-fitbv'}));
        } elsif (defined $opts{'fitbv'}) {
	    croak "Expecting scalar value for fitbv entry "
	        unless ref($opts{'fitbv'}) eq '';
            $self->{'D'} = PDFArray($page, PDFName('FitBV'), 
		                    PDFNum($opts{'fitbv'}));
        } elsif (defined $opts{'-fitr'}) {  # anon array length 4
            croak "Insufficient parameters to ->dest(page, -fitr => []) " 
	        unless ref($opts{'-fitr'}) eq 'ARRAY' &&
		       scalar @{$opts{'-fitr'}} == 4;
            $self->{'D'} = PDFArray($page, PDFName('FitR'), 
		                    map {PDFNum($_)} @{$opts{'-fitr'}});
        } elsif (defined $opts{'fitr'}) {
            croak "Insufficient parameters to ->dest(page, fitr => []) " 
	        unless ref($opts{'fitr'}) eq 'ARRAY' &&
		       scalar @{$opts{'fitr'}} == 4;
            $self->{'D'} = PDFArray($page, PDFName('FitR'), 
		                    map {PDFNum($_)} @{$opts{'fitr'}});
        } elsif (defined $opts{'-xyz'}) {  # anon array length 3
            croak "Insufficient parameters to ->dest(page, -xyz => []) " 
	        unless ref($opts{'-xyz'}) eq 'ARRAY' &&
		       scalar @{$opts{'-xyz'}} == 3;
            $self->{'D'} = PDFArray($page, PDFName('XYZ'), 
		map {defined $_ ? PDFNum($_) : PDFNull()} @{$opts{'-xyz'}});
        } elsif (defined $opts{'xyz'}) {
            croak "Insufficient parameters to ->dest(page, xyz => []) " 
	        unless ref($opts{'xyz'}) eq 'ARRAY' &&
		       scalar @{$opts{'xyz'}} == 3;
            $self->{'D'} = PDFArray($page, PDFName('XYZ'), 
		map {defined $_ ? PDFNum($_) : PDFNull()} @{$opts{'xyz'}});
	} else {
	    # no "fit" option found. use default of xyz.
            $opts{'xyz'} = [undef,undef,undef];
            $self->{'D'} = PDFArray($page, PDFName('XYZ'), 
		map {defined $_ ? PDFNum($_) : PDFNull()} @{$opts{'xyz'}});
        }
    }

    return $self;
}

=item $dest->goto($page, $location, @args);

A go-to action changes the view to a specified destination (page, location, and
magnification factor).

Parameters are as described in C<destination>.

B<alternate name:> link

Originally this method was C<link>, but recently PDF::API2 changed the name
to C<goto>. "link" is retained for compatibility.

=cut

sub link { return goto(@_); } ## no critic

sub goto {
    my $self = shift();
    $self->{'S'} = PDFName('GoTo');
    return $self->dest(@_);
}

=item $dest->uri($page, $location, @args);

Defines the destination as launch-url with uri C<$url> and
page-fit options %opts.

B<alternate name:> url

Originally this method was C<url>, but recently PDF::API2 changed the name
to C<uri>. "url" is retained for compatibility.

=cut

sub url { return uri(@_); } ## no critic

sub uri {
    my ($self, $uri, %opts) = @_;

    $self->{'S'} = PDFName('URI');
    $self->{'URI'} = PDFString($uri, 'u');

    return $self;
}

=item $dest->launch($file, %opts)

Defines the destination as launch-file with filepath C<$file> and
page-fit options %opts.

B<alternate name:> file

Originally this method was C<file>, but recently PDF::API2 changed the name
to C<launch>. "file" is retained for compatibility.

=cut

sub file { return launch(@_); } ## no critic

sub launch {
    my ($self, $file, %opts) = @_;

    $self->{'S'} = PDFName('Launch');
    $self->{'F'} = PDFString($file, 'u');

    return $self;
}

=item $dest->pdf($pdffile, $pagenum, %opts)

Defines the destination as a PDF-file with filepath C<$pdffile>, on page
C<$pagenum>, and options %opts (same as dest()).

B<alternate names:> pdf_file, pdfile

Originally this method was C<pdfile>, and had been earlier renamed to 
C<pdf_file>, but recently PDF::API2 changed the name to C<pdf>. "pdfile" and 
"pdf_file" are retained for compatibility.

=cut

sub pdf_file { return pdf(@_); } ## no critic
# deprecated and removed earlier, but still in PDF::API2
sub pdfile { return pdf(@_); } ## no critic

sub pdf{
    my ($self, $file, $pnum, %opts) = @_;

    $self->{'S'} = PDFName('GoToR');
    $self->{'F'} = PDFString($file, 'u');

    $self->dest(PDFNum($pnum), %opts);

    return $self;
}

=back

=cut

1;
