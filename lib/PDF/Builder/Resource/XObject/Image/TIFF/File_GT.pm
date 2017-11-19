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

sub readTag {
    my $self = shift;

    my $fh = $self->{'fh'};
    my $buf;
    $fh->read($buf, 12);
    my $tag = unpack($self->{'short'}, substr($buf, 0, 2));
    my $type = unpack($self->{'short'}, substr($buf, 2, 2));
    my $count = unpack($self->{'long'}, substr($buf, 4, 4));
    my $len = 0;

    $len = ($type == 1? $count  : # byte
            $type == 2? $count  : # char2
            $type == 3? $count*2: # int16
            $type == 4? $count*4: # int32
            $type == 5? $count*8: # rational: 2 * int32
            $count);

    my $off = substr($buf, 8, 4);

    if ($len > 4) {
        $off = unpack($self->{'long'}, $off);
    } else {
        $off = ($type == 1? unpack($self->{'byte'},  $off):
                $type == 2? unpack($self->{'long'},  $off):
                $type == 3? unpack($self->{'short'}, $off):
                $type == 4? unpack($self->{'long'},  $off):
                unpack($self->{'short'}, $off) );
    }

    return ($tag, $type, $count, $len, $off);
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
        $self->{'filter'} = 'CCITTFaxDecode';
        $self->{'ccitt'} = $self->{filter};
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
