#!/usr/bin/perl
use warnings;
use strict;
use English qw( -no_match_vars );
use IPC::Cmd qw(can_run run);
use File::Spec;
use Test::More tests => 12;

use PDF::Builder;

# Filename 3 tests
# tests 1 and 3 will mention TIFF_GT if Graphics::TIFF is installed and
# usable, otherwise they will display just TIFF. you can use this information
# if you are not sure about the status of Graphics::TIFF.

my $pdf = PDF::Builder->new('-compress' => 'none'); # common $pdf all tests
my $has_GT = 0; # global flag for all tests that need to know if Graphics::TIFF

# -silent shuts off one-time warning for rest of run
my $tiff = $pdf->image_tiff('t/resources/1x1.tif', -silent => 1);
if ($tiff->usesLib() == 1) {
    $has_GT = 1;
    isa_ok($tiff, 'PDF::Builder::Resource::XObject::Image::TIFF_GT',
        q{$pdf->image_tiff(filename)});
} else {
    isa_ok($tiff, 'PDF::Builder::Resource::XObject::Image::TIFF',
        q{$pdf->image_tiff(filename)});
}

is($tiff->width(), 1,
   q{Image from filename has a width});

my $gfx = $pdf->page()->gfx();
$gfx->image($tiff, 72, 144, 216, 288);
like($pdf->stringify(), qr/q 216 0 0 288 72 144 cm \S+ Do Q/,
     q{Add TIFF to PDF});

# Filehandle (old library only)  2 tests

$pdf = PDF::Builder->new();
open my $fh, '<', 't/resources/1x1.tif' or
   die "Couldn't open file t/resources/1x1.tif";
$tiff = $pdf->image_tiff($fh, -nouseGT => 1);
isa_ok($tiff, 'PDF::Builder::Resource::XObject::Image::TIFF',
    q{$pdf->image_tiff(filehandle)});

is($tiff->width(), 1,
   q{Image from filehandle has a width});

close $fh;

# LZW Compression  2 tests

$pdf = PDF::Builder->new('-compress' => 'none');

my $lzw_tiff = $pdf->image_tiff('t/resources/1x1-lzw.tif');
if ($lzw_tiff->usesLib() == 1) {
    isa_ok($lzw_tiff, 'PDF::Builder::Resource::XObject::Image::TIFF_GT',
        q{$pdf->image_tiff(), LZW compression});
} else {
    isa_ok($lzw_tiff, 'PDF::Builder::Resource::XObject::Image::TIFF',
        q{$pdf->image_tiff(), LZW compression});
}

$gfx = $pdf->page()->gfx();
$gfx->image($lzw_tiff, 72, 360, 216, 432);

like($pdf->stringify(), qr/q 216 0 0 432 72 360 cm \S+ Do Q/,
     q{Add TIFF to PDF});

# Missing file  1 test

$pdf = PDF::Builder->new();
eval { $pdf->image_tiff('t/resources/this.file.does.not.exist') };
ok($@, q{Fail fast if the requested file doesn't exist});

##############################################################
# common data for remaining tests
my $width = 1000;
my $height = 100;
$tiff = 'test.tif';
my $pdfout = 'test.pdf';

# NOTE: following 3 tests use the utilities imagemagick
# They may require software installation on
# your system, and will be skipped if the necessary
# software is not found.

##############################################################
# convert not available on all systems. PDF::Builder itself
# doesn't seem to work well with this, so skip for time being.

my $convert = 'magick';
if (not can_run($convert)) {
    if ($OSNAME eq 'linux') {
        $convert = 'convert'
    }
    elsif ($OSNAME eq 'MSWin32') {
        $convert = File::Spec->catfile($ENV{PROGRAMFILES}, 'ImageMagick', 'convert');
    }
}
SKIP: {
    skip "Further work is needed on PDF::Builder and the test process to handle the alpha layer properly.", 1;
#    skip "Non-Linux system, or no 'convert' utility", !(
#      $OSNAME eq 'linux'
#        and can_run('convert')
#    );
# ----------
run( command => [$convert, qw(-depth 1 -gravity center -pointsize 78 -size), $width.'x'.$height, 'caption:Lorem ipsum etc etc', $tiff], verbose => 0 );
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page();
$page->mediabox($width, $height);
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff);
$gfx->image($img, 0, 0, $width, $height);
$pdf->save();
$pdf->end();

# ----------
my $example = `$convert $pdfout -depth 1 -resize 1x1 txt:-`;
my $expected = `$convert $tiff -depth 1 -resize 1x1 txt:-`;
# ----------

is($example, $expected, 'alpha');
}

##############################################################
# convert and Graphics::TIFF not available on all systems.
# Graphics::TIFF needed or you get message "Chunked CCITT G4 TIFF not supported"
#  from PDF::Builder's TIFF processing library.

SKIP: {
    skip "no 'convert'", 1 unless $has_GT and can_run($convert);
# ----------
if ($convert !~ /convert/) { $convert .= ' convert' }
run( command => [$convert, qw(-depth 1 -gravity center -pointsize 78 -size), $width.'x'.$height, 'caption:Lorem ipsum etc etc', qw(-background white -alpha off -compress Group4), $tiff], verbose => 0 );
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page();
$page->mediabox($width, $height);
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff);
$gfx->image($img, 0, 0, $width, $height);
$pdf->save();
$pdf->end();

# ----------
my $example = `$convert $pdfout -depth 1 -colorspace gray -alpha off -resize 1x1 txt:-`;
my $expected = `$convert $tiff -depth 1 -resize 1x1 txt:-`;
# ----------

is($example, $expected, 'G4 (not converted to flate)');
}

##############################################################
# convert not available on all systems.
# Graphics::TIFF not needed for this test

SKIP: {
    skip "no 'convert'", 1 unless can_run($convert);
# ----------
run( command => [$convert, qw(-depth 1 -gravity center -pointsize 78 -size), $width.'x'.$height, 'caption:Lorem ipsum etc etc', qw(-background white -alpha off -compress lzw), $tiff], verbose => 0 );
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page;
$page->mediabox( $width, $height );
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
my $example = `$convert $pdfout -depth 1 -colorspace gray -alpha off -resize 1x1 txt:-`;
my $expected = `$convert $tiff -depth 1 -resize 1x1 txt:-`;
# ----------

is($example, $expected, 'lzw (converted to flate)');
}

##############################################################
# convert not available on all systems.
# Graphics::TIFF needed for this test

SKIP: {
    skip "Non-Linux system, or no 'convert'", 1 unless
      $has_GT and $OSNAME eq 'linux'
         and can_run($convert);
# .png file is temporary file (output, input, erased)
system("$convert rose: -type palette -depth 2 colormap.png");
system("$convert colormap.png $tiff");
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page;
$page->mediabox( $width, $height );
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();
pass 'successfully read TIFF with colormap';
}

##############################################################
# cleanup. all tests involving these files skipped?

unlink $pdfout, $tiff, 'colormap.png';

##############################################################

1;
