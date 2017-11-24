package PDF::Builder::Resource::XObject::Image::TIFF::File_GT;

use strict;
use warnings;

# VERSION
my $LAST_UPDATE = '3.008'; # manually update whenever code is changed

use IO::File;
use Graphics::TIFF ':all';  # already confirmed to be installed

=head1 NAME

PDF::Builder::Resource::XObject::Image::TIFF::File - support routines for TIFF image library (Graphics::TIFF enabled)

=cut

sub new {
    my ($class, $file) = @_;

    my $self = {};
    bless ($self, $class);
    die "Error: $file not found\n" unless -r $file;
    $self->{'object'} = Graphics::TIFF->Open($file, 'r');
    $self->readTags();

    return $self;
}

sub close { ## no critic
    my $self = shift;

    $self->{'object'}->Close();
    delete $self->{'object'};
    return;
}

sub readTags {
    my $self = shift;

    $self->{'imageWidth'} = $self->{'object'}->GetField(TIFFTAG_IMAGEWIDTH);
    $self->{'imageHeight'} = $self->{'object'}->GetField(TIFFTAG_IMAGELENGTH);
    $self->{'bitsPerSample'} = $self->{'object'}->GetField(TIFFTAG_BITSPERSAMPLE);
    $self->{'SamplesPerPixel'} = $self->{'object'}->GetField(TIFFTAG_SAMPLESPERPIXEL);
    $self->{'ExtraSamples'} = $self->{'object'}->GetField(TIFFTAG_EXTRASAMPLES);

    $self->{'filter'} = $self->{'object'}->GetField(TIFFTAG_COMPRESSION);
    if      ($self->{'filter'} == COMPRESSION_NONE) {
        delete $self->{'filter'};
    } elsif ($self->{'filter'} == COMPRESSION_CCITTFAX3 || $self->{'filter'} == COMPRESSION_CCITT_T4) {
        $self->{'ccitt'} = $self->{'filter'};
        $self->{'filter'} = 'CCITTFaxDecode';
   } elsif ($self->{'filter'} == COMPRESSION_CCITTFAX4 || $self->{'filter'} == COMPRESSION_CCITT_T6) {
        # G4 same code as G3
        $self->{'ccitt'} = $self->{'filter'};
        $self->{'filter'} = 'CCITTFaxDecode';
    } elsif ($self->{'filter'} == COMPRESSION_LZW) {
        $self->{'filter'} = 'LZWDecode';
    } elsif ($self->{'filter'} == COMPRESSION_OJPEG || $self->{'filter'} == COMPRESSION_JPEG) {
        $self->{'filter'} = 'DCTDecode';
    } elsif ($self->{'filter'} == COMPRESSION_ADOBE_DEFLATE || $self->{'filter'} == COMPRESSION_DEFLATE) {
        $self->{'filter'} = 'FlateDecode';
    } elsif ($self->{'filter'} == COMPRESSION_PACKBITS) {
        $self->{'filter'} = 'RunLengthDecode';
    } else {
        die "Unknown/unsupported TIFF compression method with id '".$self->{'filter'}."'.\n";
    }

    $self->{'colorSpace'} = $self->{'object'}->GetField(TIFFTAG_PHOTOMETRIC);
    if      ($self->{'colorSpace'} == PHOTOMETRIC_MINISWHITE) {
        $self->{'colorSpace'} = 'DeviceGray';
        $self->{'whiteIsZero'} = 1;
    } elsif ($self->{'colorSpace'} == PHOTOMETRIC_MINISBLACK) {
        $self->{'colorSpace'} = 'DeviceGray';
        $self->{'blackIsZero'} = 1;
    } elsif ($self->{'colorSpace'} == PHOTOMETRIC_RGB) {
        $self->{'colorSpace'} = 'DeviceRGB';
    } elsif ($self->{'colorSpace'} == PHOTOMETRIC_PALETTE) {
        $self->{'colorSpace'} = 'Indexed';
   #} elsif ($self->{'colorSpace'} == PHOTOMETRIC_MASK) {
   #    $self->{'colorSpace'} = 'TransMask';
    } elsif ($self->{'colorSpace'} == PHOTOMETRIC_SEPARATED) {
        $self->{'colorSpace'} = 'DeviceCMYK';
    } elsif ($self->{'colorSpace'} == PHOTOMETRIC_YCBCR) {
        $self->{'colorSpace'} = 'DeviceRGB';
    } elsif ($self->{'colorSpace'} == PHOTOMETRIC_CIELAB) {
        $self->{'colorSpace'} = 'Lab';
    } else {
        die "Unknown/unsupported TIFF photometric interpretation with id '".$self->{'colorSpace'}."'.\n";
    }

    $self->{'fillOrder'} = $self->{'object'}->GetField(TIFFTAG_FILLORDER);
    $self->{'imageDescription'} = $self->{'object'}->GetField(TIFFTAG_IMAGEDESCRIPTION);
    $self->{'xRes'} = $self->{'object'}->GetField(TIFFTAG_XRESOLUTION);
    $self->{'yRes'} = $self->{'object'}->GetField(TIFFTAG_YRESOLUTION);
    $self->{'resUnit'} = $self->{'object'}->GetField(TIFFTAG_RESOLUTIONUNIT);
    $self->{'imageOffset'} = $self->{'object'}->GetField(TIFFTAG_STRIPOFFSETS);
    $self->{'samplesPerPixel'} = $self->{'object'}->GetField(TIFFTAG_SAMPLESPERPIXEL);
    $self->{'RowsPerStrip'} = $self->{'object'}->GetField(TIFFTAG_ROWSPERSTRIP);
    $self->{'imageLength'} = $self->{'object'}->GetField(TIFFTAG_STRIPBYTECOUNTS);
    $self->{'g3Options'} = $self->{'object'}->GetField(TIFFTAG_GROUP3OPTIONS);
    $self->{'g4Options'} = $self->{'object'}->GetField(TIFFTAG_GROUP4OPTIONS);

    $self->{'colorMapOffset'} = $self->{'object'}->GetField(TIFFTAG_COLORMAP);
    $self->{'colorMapSamples'} = $#{$self->{'colorMapOffset'}}+1;
    $self->{'colorMapLength'} = $self->{'colorMapSamples'}*2; # shorts!

    $self->{'lzwPredictor'} = $self->{'object'}->GetField(TIFFTAG_PREDICTOR);
    $self->{'imageId'} = $self->{'object'}->GetField(TIFFTAG_OPIIMAGEID);

    return $self;
}

1;
