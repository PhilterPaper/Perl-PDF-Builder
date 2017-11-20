package PDF::Builder::Resource::XObject::Image::TIFF_GT;

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
use warnings;

no warnings 'uninitialized';

# VERSION
my $LAST_UPDATE = '3.008'; # manually update whenever code is changed

use Compress::Zlib;

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Resource::XObject::Image::TIFF::File_GT;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);
use Graphics::TIFF ':all';  # have already confirmed that this exists

=head1 NAME

PDF::Builder::Resource::XObject::Image::TIFF_GT - TIFF image support
(Graphics::TIFF enabled)

=head1 METHODS

=over

=item  $res = PDF::Builder::Resource::XObject::Image::TIFF_GT->new($pdf, $file, $name)

=item  $res = PDF::Builder::Resource::XObject::Image::TIFF_GT->new($pdf, $file)

Returns a TIFF-image object.

If the Graphics::TIFF package is installed, and its use is not suppressed via
the C<-nouseGT> flag (see Builder documentation for C<image_tiff>), the TIFF_GT
library will be used. Otherwise, the TIFF library will be used instead.

=cut

sub new {
    my ($class, $pdf, $file, $name) = @_;

    my $self;

    my $tif = PDF::Builder::Resource::XObject::Image::TIFF::File_GT->new($file);

    # in case of problematic things
    #  proxy to other modules

    $class = ref($class) if ref $class;

    $self = $class->SUPER::new($pdf, $name || 'Ix'.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    $self->read_tiff($pdf, $tif);

    $tif->close();

    return $self;
}

=item  $mode = $tif->usesLib()

Returns 1 if Graphics::TIFF installed and used, 0 if not installed, or -1 if
installed but not used (-nouseGT option given to C<image_tiff>).

=back

=cut

sub usesLib {
    my ($self) = shift;
    # should be 1 for Graphics::TIFF is installed and used
    return $self->{'usesGT'}->val();
}

sub handle_generic {
    my ($self, $pdf, $tif) = @_;
    my ($i, $stripcount, $buffer);

    $self->filters('FlateDecode');

    $stripcount = $tif->{'object'}->NumberOfStrips();
    $buffer = '';
    for $i (0 .. $stripcount - 1) {
        $buffer .= $tif->{'object'}->ReadEncodedStrip($i, -1);
    }

    if ($tif->{'SamplesPerPixel'} == $tif->{'bitsPerSample'} + 1) {
	if ($tif->{'ExtraSamples'} == EXTRASAMPLE_ASSOCALPHA) {
	    if ($tif->{'bitsPerSample'} == 1) {
		$buffer = sample_greya_to_a($buffer);
            } else {
		warn "Don't know what to do with RGBA image\n";
            }
        } else {
	    warn "Don't know what to do with alpha layer in TIFF\n";
	}
    }
    $self->{' stream'} .= $buffer;

    return $self;
}

sub handle_ccitt {
    my ($self, $pdf, $tif) = @_;
    my ($i, $stripcount);

    $self->{' nofilt'} = 1;
    $self->{'Filter'} = PDFName('CCITTFaxDecode');
    $self->{'DecodeParms'} = PDFDict();
    $self->{'DecodeParms'}->{'K'} = (($tif->{'ccitt'} == 4 || ($tif->{'g3Options'} & 0x1))? PDFNum(-1): PDFNum(0));
    $self->{'DecodeParms'}->{'Columns'} = PDFNum($tif->{'imageWidth'});
    $self->{'DecodeParms'}->{'Rows'} = PDFNum($tif->{'imageHeight'});
    # deprecated Blackls1 (incorrectly named). will be removed 8/2018 or later
    $self->{'DecodeParms'}->{'Blackls1'} = 
    $self->{'DecodeParms'}->{'BlackIs1'} = PDFBool($tif->{'whiteIsZero'} == 1? 1: 0);
    if (defined($tif->{'g3Options'}) && ($tif->{'g3Options'} & 0x4)) {
        $self->{'DecodeParms'}->{'EndOfLine'} = PDFBool(1);
        $self->{'DecodeParms'}->{'EncodedByteAlign'} = PDFBool(1);
    }
    # $self->{'DecodeParms'} = PDFArray($self->{'DecodeParms'});
    $self->{'DecodeParms'}->{'DamagedRowsBeforeError'} = PDFNum(100);

    if (ref($tif->{'imageOffset'})) {
        die "Chunked CCITT G4 TIFF not supported.";
    } else {
	$stripcount = $tif->{'object'}->NumberOfStrips();
	for $i (0 .. $stripcount - 1) {
            $self->{'stream'} .= $tif->{'object'}->ReadRawStrip($1, -1);
	}
    }

    return $self;
}

sub read_tiff {
    my ($self, $pdf, $tif) = @_;

    $self->width($tif->{'imageWidth'});
    $self->height($tif->{'imageHeight'});
    if ($tif->{'colorSpace'} eq 'Indexed') {
        my $dict = PDFDict();
        $pdf->new_obj($dict);
        $self->colorspace(PDFArray(PDFName($tif->{'colorSpace'}), PDFName('DeviceRGB'), PDFNum(255), $dict));
        $dict->{'Filter'} = PDFArray(PDFName('FlateDecode'));
        $tif->{'fh'}->seek($tif->{'colorMapOffset'}, 0);
        my $colormap;
        my $straight;
        $tif->{'fh'}->read($colormap, $tif->{'colorMapLength'});
        $dict->{' stream'} = '';
        $straight .= pack('C', ($_/256)) for unpack($tif->{'short'} . '*', $colormap);
        foreach my $c (0 .. (($tif->{'colorMapSamples'}/3)-1)) {
            $dict->{' stream'} .= substr($straight, $c, 1);
            $dict->{' stream'} .= substr($straight, $c + ($tif->{'colorMapSamples'}/3), 1);
            $dict->{' stream'} .= substr($straight, $c + ($tif->{'colorMapSamples'}/3)*2, 1);
        }
    } else {
        $self->colorspace($tif->{'colorSpace'});
    }

    $self->{'Interpolate'} = PDFBool(1);
    $self->bits_per_component($tif->{'bitsPerSample'});

    if ($tif->{'whiteIsZero'} == 1 && $tif->{'filter'} ne 'CCITTFaxDecode') {
        $self->{'Decode'} = PDFArray(PDFNum(1), PDFNum(0));
    }

    # check filters and handle separately
    if (defined $tif->{'filter'} and $tif->{'filter'} eq 'CCITTFaxDecode') {
        $self->handle_ccitt($pdf, $tif);
    } else {
        $self->handle_generic($pdf, $tif);
    }

    $self->{' tiff'} = $tif;

    return $self;
}

1;
