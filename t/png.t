#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 6;

use PDF::Builder;

# Filename

my $pdf = PDF::Builder->new('-compress' => 'none');

my $png = $pdf->image_png('t/resources/1x1.png');
isa_ok($png, 'PDF::Builder::Resource::XObject::Image::PNG',
       q{$pdf->image_png(filename)});

is($png->width(), 1,
   q{Image from filename has a width});

my $gfx = $pdf->page->gfx();
$gfx->image($png, 72, 144, 216, 288);
like($pdf->stringify(), qr/q 216 0 0 288 72 144 cm \S+ Do Q/,
     q{Add PNG to PDF});

# Filehandle

$pdf = PDF::Builder->new();
open my $fh, '<', 't/resources/1x1.png';
$png = $pdf->image_png($fh);
isa_ok($png, 'PDF::Builder::Resource::XObject::Image::PNG',
       q{$pdf->image_png(filehandle)});

is($png->width(), 1,
   q{Image from filehandle has a width});

close $fh;

# Missing file

$pdf = PDF::Builder->new();
eval { $pdf->image_png('t/resources/this.file.does.not.exist') };
ok($@, q{Fail fast if the requested file doesn't exist});

1;
