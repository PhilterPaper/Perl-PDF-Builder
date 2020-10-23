#!/usr/bin/perl
use warnings;
use strict;
use English qw' -no_match_vars ';
use IPC::Cmd qw(can_run);
use Test::More tests => 11;

use PDF::Builder;

# Filename 3 tests
# tests 1 and 3 will mention TIFF_GT if Graphics::TIFF is installed and
# usable, otherwise they will display just TIFF. you can use this information
# if you are not sure about the status of Graphics::TIFF.

my $pdf = PDF::Builder->new('-compress' => 'none'); # common $pdf all tests
my $has_GT; # global flag for all tests that need to know if Graphics::TIFF

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
open my $fh, '<', 't/resources/1x1.tif';
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
my $width = 568;
my $height = 1000;
$tiff = 'test.tif';
my $pdfout = 'test.pdf';

SKIP: {
    skip "This is still buggy, and we don't currently have an alternative tool which deals with the alpha layer properly", 1;
system(sprintf"convert -depth 1 -gravity center -pointsize 78 -size %dx%d caption:'Lorem ipsum etc etc' %s", $width, $height, $tiff);
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page();
$page->mediabox($width, $height);
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff);
$gfx->image($img, 0, 0, $width, $height);
$pdf->save();
$pdf->end();

my $example = `convert $pdfout -depth 1 -resize 1x1 txt:-`;
my $expected = `convert $tiff -depth 1 -resize 1x1 txt:-`;

is($example, $expected, 'alpha');
}

##############################################################
# tiffcp, convert and Graphics::TIFF not available on all systems.

SKIP: {
    skip "PDF::Builder cannot handle G3/4 compressed TIFFs without Graphics::TIFF", 1 unless $OSNAME eq 'linux' and can_run('convert') and can_run('tiffcp') and $has_GT;
system(sprintf "convert -depth 1 -gravity center -pointsize 78 -size %dx%d caption:'Lorem ipsum etc etc' -background white -alpha off %s", $width, $height, $tiff);
system("tiffcp -c g3 $tiff tmp.tif && mv tmp.tif $tiff");
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page();
$page->mediabox($width, $height);
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff);
$gfx->image($img, 0, 0, $width, $height);
$pdf->save();
$pdf->end();

my $example = `convert $pdfout -depth 1 -colorspace gray -alpha off -resize 1x1 txt:-`;
my $expected = `convert $tiff -depth 1 -resize 1x1 txt:-`;

is($example, $expected, 'G3 (not converted to flate)');
}

##############################################################
# tiffcp and convert not available on all systems.

SKIP: {
    skip "convert and tiffcp utilities not available on all systems", 1 unless $OSNAME eq 'linux' and can_run('convert') and can_run('tiffcp');
system(sprintf"convert -depth 1 -gravity center -pointsize 78 -size %dx%d caption:'Lorem ipsum etc etc' -background white -alpha off %s", $width, $height, $tiff);
system("tiffcp -c lzw $tiff tmp.tif && mv tmp.tif $tiff");
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page;
$page->mediabox( $width, $height );
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

my $example = `convert $pdfout -depth 1 -colorspace gray -alpha off -resize 1x1 txt:-`;
my $expected = `convert $tiff -depth 1 -resize 1x1 txt:-`;

is($example, $expected, 'lzw (converted to flate)');
}

##############################################################
# cleanup. all tests involving these files skipped?

unlink $pdfout, $tiff;

##############################################################

1;
