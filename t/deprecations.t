#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;

use PDF::Builder;
my ($pdf, $page, $pdf2, $pdf_string);

#### TBD when a deprecated interface is removed, keep the test for the new
####     replacement here, while commenting out the old interface

## new_api  -- removed from PDF::Builder, deprecated in PDF::API2
#use PDF::Builder::Resource::XObject::Image::JPEG;
#$pdf = PDF::Builder->new();
#my $image = PDF::Builder::Resource::XObject::Image::JPEG->new_api($pdf, 't/resources/1x1.jpg');
#ok($image, q{new_api still works});
# TBD need test for replacement call

# create a dummy PDF (as string) for further tests
$pdf = PDF::Builder->new();
$pdf->page()->gfx()->fillcolor('blue');
$pdf_string = $pdf->stringify();

## openScalar() -> open_scalar()
#  removed from PDF::Builder, deprecated in PDF::API2
#$pdf = PDF::Builder->openScalar($pdf_string);
#is(ref($pdf), 'PDF::Builder',
#   q{openScalar still works});
$pdf = PDF::Builder->open_scalar($pdf_string);
is(ref($pdf), 'PDF::Builder',
   q{open_scalar replacement for openScalar IS available});

## importpage() -> import_page()
#  removed from PDF::Builder, deprecated in PDF::API2
$pdf2 = PDF::Builder->new();
#$page = $pdf2->importpage($pdf, 1);
#is(ref($page), 'PDF::Builder::Page',
#   q{importpage still works});
$page = $pdf2->import_page($pdf, 1);
is(ref($page), 'PDF::Builder::Page',
   q{import_page replacement for importpage IS available});

# openpage  -- replaced by open_page in API2
$pdf2 = PDF::Builder->open_scalar($pdf_string);
$page = $pdf2->openpage(1);
is(ref($page), 'PDF::Builder::Page',
   q{openpage still works});
#$page = $pdf2->open_page(1);   not yet implemented in PDF::Builder
#is(ref($page), 'PDF::Builder::Page',
#   q{new open_page IS available});

# PDF::Builder-specific cases to ADD tests for (deprecated but NOT yet removed):
#
# scheduled to be REMOVED 8/2021
#  elementsof() -> elements()
#  removeobj() -> (gone)
#  get_mediabox() -> mediabox()   $pdf and $page
#  get_cropbox() -> cropbox()
#  get_bleedbox() -> bleedbox()
#  get_trimbox() -> trimbox()
#  get_artbox() -> artbox()
#
# scheduled to be REMOVED 10/2022
#  PDFStr() -> PDFString()   t/string.t, Utils.pm
#  PDFUtf() -> PDFString()   Utils.pm
#
# scheduled to be REMOVED 3/2023
#  lead() -> leading()   many examples/, some .pm
#  textlead() -> textleading()   Lite.pm only

# if nothing left to check...
#is(ref($pdf), 'PDF::Builder',
#    q{No deprecated tests to run at this time});
1;
