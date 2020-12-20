package PDF::Builder::Resource::XObject::Image::TIFF_GT;

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
use warnings;

#no warnings 'uninitialized';

# VERSION
my $LAST_UPDATE = '3.021'; # manually update whenever code is changed

use Compress::Zlib;

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Resource::XObject::Image::TIFF::File_GT;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);
#use Graphics::TIFF 7 ':all';  # have already confirmed that this exists
use Graphics::TIFF ':all';  # have already confirmed that this version exists

=head1 NAME

PDF::Builder::Resource::XObject::Image::TIFF_GT - TIFF image support
(Graphics::TIFF enabled)

=head1 METHODS

=over

=item  $res = PDF::Builder::Resource::XObject::Image::TIFF_GT->new($pdf, $file, $name, %opts)

=item  $res = PDF::Builder::Resource::XObject::Image::TIFF_GT->new($pdf, $file, $name)

=item  $res = PDF::Builder::Resource::XObject::Image::TIFF_GT->new($pdf, $file)

Returns a TIFF-image object. C<$pdf> is the PDF object being added to, C<$file>
is the input TIFF file, and the optional C<$name> of the new parent image object
defaults to IxAAA.

If the Graphics::TIFF package is installed, and its use is not suppressed via
the C<-nouseGT> flag (see Builder documentation for C<image_tiff>), the TIFF_GT
library will be used. Otherwise, the TIFF library will be used instead.

Options:

=over

=item -notrans => 1

Ignore any alpha layer (transparency) and make the image fully opaque.

=back

=cut

sub new {
    my ($class, $pdf, $file, $name, %opts) = @_;

    my $self;

    my $tif = PDF::Builder::Resource::XObject::Image::TIFF::File_GT->new($file);

    # in case of problematic things
    #  proxy to other modules

    $class = ref($class) if ref $class;

    $self = $class->SUPER::new($pdf, $name || 'Ix'.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    # set up dict stream for any Alpha channel to be split out from $buffer
    my $dict = PDFDict();

    $self->read_tiff($pdf, $tif, %opts);

    $tif->close();

    return $self;
}

=item  $mode = $tif->usesLib()

Returns 1 if Graphics::TIFF installed and used, 0 if not installed, or -1 if
installed but not used (-nouseGT option given to C<image_tiff>).

B<Caution:> this method can only be used I<after> the image object has been
created. It can't tell you whether Graphics::TIFF is available in
advance of actually using it, in case you want to use some functionality
available only in TIFF_GT. See the <PDF::Builder> LA_GT() call if you
need to know in advance.

=back

=cut

sub usesLib {
    my ($self) = shift;
    # should be 1 for Graphics::TIFF is installed and used
    return $self->{'usesGT'}->val();
}

sub handle_generic {
    my ($self, $pdf, $tif, %opts) = @_;
    my ($stripcount, $buffer);

    $self->filters('FlateDecode');

    $stripcount = $tif->{'object'}->NumberOfStrips();
    $buffer = '';
    for my $i (0 .. $stripcount - 1) {
        $buffer .= $tif->{'object'}->ReadEncodedStrip($i, -1);
    }
    my $alpha;

    # handle any Alpha channel/layer
    my $h = $tif->{'imageHeight'};  # in pixels
    my $w = $tif->{'imageWidth'};
#print STDERR "image size $w x $h pixels\n";
    my $samples = 1; # fallback

    # code common to associated and unassociated alpha
    if (defined $tif->{'ExtraSamples'} &&
	($tif->{'ExtraSamples'} == EXTRASAMPLE_ASSOCALPHA ||
	 $tif->{'ExtraSamples'} == EXTRASAMPLE_UNASSALPHA)) {
#print STDERR "This file has Alpha layer\n";
    }

    if      (defined $tif->{'ExtraSamples'} &&
	     $tif->{'ExtraSamples'} == EXTRASAMPLE_ASSOCALPHA) {
	# Gray or RGB pre-multiplication will likely have to be backed out
        if      ($tif->{'colorSpace'} eq 'DeviceGray') {
	    # Gray or Bilevel (pre-multiplied) + Alpha 
	    $samples = 1;
        } elsif ($tif->{'colorSpace'} eq 'DeviceRGB') {
	    # RGB (pre-multiplied) + Alpha 
	    $samples = 3;
	} else {
	    warn "Invalid TIFF file, requested Alpha for $tif->{'colorSpace'}".
	         ", PDF will likely be defective!\n";
	}
	($buffer, $alpha) = split_alpha($buffer, $samples, $tif->{'bitsPerSample'}, $w*$h);
	$buffer = descale($buffer, $samples, $tif->{'bitsPerSample'}, $alpha, $w*$h);
    } elsif (defined $tif->{'ExtraSamples'} &&
	     $tif->{'ExtraSamples'} == EXTRASAMPLE_UNASSALPHA) {
	# Gray or RGB at full value, no adjustment needed
        if      ($tif->{'colorSpace'} eq 'DeviceGray') {
	    # Gray or Bilevel + Alpha 
	    $samples = 1;
        } elsif ($tif->{'colorSpace'} eq 'DeviceRGB') {
	    # RGB + Alpha 
	    $samples = 3;
	} else {
	    warn "Invalid TIFF file, requested Alpha for $tif->{'colorSpace'}".
	         ", PDF will likely be defective!\n";
	}
	($buffer, $alpha) = split_alpha($buffer, $samples, $tif->{'bitsPerSample'}, $w*$h);
    }

    $self->{' stream'} .= $buffer;
    # suppress any transparency (alpha layer)?
    if (defined $opts{'-notrans'} && $opts{'-notrans'} == 1) {
	$alpha = undef;
    }
    # TBD ignoring alpha for the moment
#print "alpha = '$alpha'\n";

    return $self;
}

# split alpha from buffer (both strings)
# bps = width of a sample in bits, samples 1 (G) or 3 (RGB)
# returns $buffer and $alpha strings
# TBD: fill order or other directional issues?
sub split_alpha {
    my ($inbuf, $samples, $bps, $count) = @_;
    my $outbuf = '';
    my $alpha = '';
 
    # this could be pretty slow. test of concept. TBD
    # COULD have different number of bits per sample, unless GT prevents this
    if      ($bps == 16) {
        # full double bytes to work with (not sure if 16bps in TIFF)
        for (my $i=0; $i<$count; $i++) {
 	    substr($outbuf, $i*$samples*2, $samples*2) =
	        substr($inbuf, $i*($samples+1)*2, $samples*2);
 	    substr($alpha, $i*2, 2) =
	        substr($inbuf, $i*($samples+1)*2+2, 2);
        }
    } elsif ($bps == 8) {
        # full bytes to work with
        for (my $i=0; $i<$count; $i++) {
 	    substr($outbuf, $i*$samples, $samples) =
	        substr($inbuf, $i*($samples+1), $samples);
 	    substr($alpha, $i, 1) =
	        substr($inbuf, $i*($samples+1)+1, 1);
        }
    } else {
        # fractional bytes (bps < 8) possible to have not 2**N?
        my $strideBits = $bps*($samples+1);
	my @inBits = ();    # bits from inbuf string
	my @outBits = ();   # bits to outbuf string (starts empty)
	my @outABits = ();  # build alpha string (starts empty)
	my $inByte = 0;
	my $outByte = 0;
	my $outAByte = 0;
        for (my $i=0; $i<$count; $i++) {
	    # i-th pixel is next 2 or more bits in inBits
	    # build up enough bits in inBits
	    while (scalar(@inBits) < $strideBits) {
		push @inBits, split(//, unpack('B8', substr($inbuf, $inByte++, 1)));
	    }
	    # now have enough bits in inBits array for adding to output buffer
	    push @outBits, splice(@inBits, 0, $samples*$bps);
	    # now have enough bits in inBits array for adding to alpha buffer
	    push @outABits, splice(@inBits, 0, $bps);
	    # do we have at least one full byte to output to outbuf?
	    while (scalar(@outBits) >= 8) {
		substr($outbuf, $outByte++, 1) = pack('B8', join('', splice(@outBits, 0, 8)));
	    }
	    # do we have at least one full byte to output to alpha?
	    while (scalar(@outABits) >= 8) {
		substr($alpha, $outAByte++, 1) = pack('B8', join('', splice(@outABits, 0, 8)));
	    }
	    # there may be leftover bits (for next pixel) in inBits
	    # outBits and outABits may also have partial content yet to write
        }
	# got to the end. anything not yet written in @outBits and @outABits?
	if (scalar(@outBits)) {
            # pad out to 8 bits in length (should be no more than 7)
            while (scalar(@outBits) < 8) {
                push @outBits, 0;
            }
	    substr($outbuf, $outByte++, 1) = pack('B8', join('', @outBits));
        }
	if (scalar(@outABits)) {
            # pad out to 8 bits in length (should be no more than 7)
            while (scalar(@outABits) < 8) {
                push @outABits, 0;
            }
	    substr($alpha, $outAByte++, 1) = pack('B8', join('', @outABits));
        }
    }

    return ($outbuf, $alpha);
} # end of split_alpha()

# bps = width of a sample in bits, samples 1 (G) or 3 (RGB)
# return updated buffer    TBD
sub descale {
    my ($inbuf, $samples, $bps, $alpha, $count) = @_;
    my $outbuf = '';
    $outbuf = $inbuf; # for now...
    # 1. assuming alpha is 0.0 fully transparent to 1.0 fully opaque
    # 2. sample has already been multiplied by alpha (0 if fully transparent)
    # 3. if alpha is 0, leave sample as 0. otherwise...
    # 4. convert sample and alpha to decimal 0.0..1.0
    # 5. sample = sample/alpha
    # 6. round, integerize, and clamp sample to 0..max val range

    return $outbuf;
} # end of descale()

sub handle_ccitt {
    my ($self, $pdf, $tif, %opts) = @_;
    my ($stripcount);

    $self->{' nofilt'} = 1;
    $self->{'Filter'} = PDFArray(PDFName('CCITTFaxDecode'));
    my $decode = PDFDict();
    $self->{'DecodeParms'} = PDFArray($decode);
    # DecodeParms.K 0 if G3 or there are G3 options with bit 0 set, -1 for G4
    $decode->{'K'} = (($tif->{'ccitt'} == 4 || (defined $tif->{'g3Options'} && $tif->{'g3Options'} & 0x1))? PDFNum(-1): PDFNum(0));
    $decode->{'Columns'} = PDFNum($tif->{'imageWidth'});
    $decode->{'Rows'} = PDFNum($tif->{'imageHeight'});
    # not sure why whiteIsZero needs to be flipped around???
    $decode->{'BlackIs1'} = PDFBool($tif->{'whiteIsZero'} == 0? 1: 0);
    $decode->{'DamagedRowsBeforeError'} = PDFNum(100);

    # g3Options       bit 0 = 0 for 1-Dimensional, = 1 for 2-Dimensional MR
    #  aka T4Options  bit 1 = 0 (compressed data only)
    #                 bit 2 = 0 non-byte-aligned EOLs, = 1 byte-aligned EOLs
    # g4Options       bit 0 = 0 MMR 2-D compression
    #  aka T6Options  bit 1 = 0 (compressed data only)
    #  aka Group4Options
    if (defined($tif->{'g3Options'}) && ($tif->{'g3Options'} & 0x4)) {
        $decode->{'EndOfLine'} = PDFBool(1);
        $decode->{'EncodedByteAlign'} = PDFBool(1);
    }
    # TBD currently nothing to look at for g4Options

    if (ref($tif->{'imageOffset'})) {
        die "Chunked CCITT G3/G4 TIFF not supported.";
    } else {
	$stripcount = $tif->{'object'}->NumberOfStrips();
	for my $i (0 .. $stripcount - 1) {
            $self->{' stream'} .= $tif->{'object'}->ReadRawStrip($i, -1);
	}
        # if bit fill order in data is opposite of PDF spec (Lsb2Msb), need to 
	# swap each byte end-for-end: x01->x80, x02->x40, x03->xC0, etc.
	#
	# a 256-entry lookup table could probably do just as well and build
	# up the replacement string rather than constantly substr'ing.
	if ($tif->{'fillOrder'} == 2) { # Lsb first, PDF is Msb
	    my ($oldByte, $newByte);
	    for my $j ( 0 .. length($self->{' stream'}) ) {
	        # swapping j-th byte of stream
		$oldByte = ord(substr($self->{' stream'}, $j, 1));
		if ($oldByte == 0 || $oldByte == 255) { next; }
		$newByte = 0;
		if ($oldByte & 0x01) { $newByte |= 0x80; }
		if ($oldByte & 0x02) { $newByte |= 0x40; }
		if ($oldByte & 0x04) { $newByte |= 0x20; }
		if ($oldByte & 0x08) { $newByte |= 0x10; }
		if ($oldByte & 0x10) { $newByte |= 0x08; }
		if ($oldByte & 0x20) { $newByte |= 0x04; }
		if ($oldByte & 0x40) { $newByte |= 0x02; }
		if ($oldByte & 0x80) { $newByte |= 0x01; }
                substr($self->{' stream'}, $j, 1) = chr($newByte);
	    }
        }
    }

    return $self;
}

sub read_tiff {
    my ($self, $pdf, $tif, %opts) = @_;

    # not sure why blackIsZero needs to be flipped around???
    if (defined $tif->{'blackIsZero'}) {
        $tif->{'blackIsZero'} = $tif->{'blackIsZero'} == 1? 0: 1;
        $tif->{'whiteIsZero'} = $tif->{'blackIsZero'} == 1? 0: 1;
    }

    $self->width($tif->{'imageWidth'});
    $self->height($tif->{'imageHeight'});
    if ($tif->{'colorSpace'} eq 'Indexed') {
        my $dict = PDFDict();
        $pdf->new_obj($dict);
        $self->colorspace(PDFArray(PDFName($tif->{'colorSpace'}), PDFName('DeviceRGB'), PDFNum(2**$tif->{'bitsPerSample'}-1), $dict));
        $dict->{'Filter'} = PDFArray(PDFName('FlateDecode'));
        my ($red, $green, $blue) = @{$tif->{'colorMap'}};
        $dict->{' stream'} = '';
        for my $i (0 .. $#{$red}) {
            $dict->{' stream'} .= pack('C', ($red->[$i]/256));
            $dict->{' stream'} .= pack('C', ($green->[$i]/256));
            $dict->{' stream'} .= pack('C', ($blue->[$i]/256));
        }
    } else {
        $self->colorspace($tif->{'colorSpace'});
    }

    $self->{'Interpolate'} = PDFBool(1);
    $self->bits_per_component($tif->{'bitsPerSample'});

    if (($tif->{'whiteIsZero'}||0) == 1 &&
	($tif->{'filter'}||'') ne 'CCITTFaxDecode') {
        $self->{'Decode'} = PDFArray(PDFNum(1), PDFNum(0));
    }

#foreach (sort keys %$tif) {
# if (defined $tif->{$_}) {
#  print "\$tif->{'$_'} = '$tif->{$_}'\n";
# } else {
#  print "\$tif->{'$_'} = ?\n";
# }
#}
    # check filters and handle separately
    if (defined $tif->{'filter'} and $tif->{'filter'} eq 'CCITTFaxDecode') {
        $self->handle_ccitt($pdf, $tif, %opts);
    } else {
        $self->handle_generic($pdf, $tif, %opts);
    }

    $self->{' tiff'} = $tif;

    return $self;
}

1;
