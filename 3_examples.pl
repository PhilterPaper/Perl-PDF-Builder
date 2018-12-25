#!/usr/bin/perl
# run examples test suite
# roughly equivalent to examples.bat
#   you will need to update the %args list before running
# author: Phil M Perry

use strict;
use warnings;

# VERSION
my $LAST_UPDATE = '3.013'; # manually update whenever code is changed

# command line:
# 

my @example_list = qw(
  011_open_update
  012_pages
  020_corefonts
  020_textrise
  020_textunderline
  021_psfonts 
  021_synfonts
  022_truefonts
  022_truefonts_diacrits_utf8
  023_cjkfonts
  024_bdffonts
  025_unifonts
  026_unifont2
  030_colorspecs
  031_color_hsv
  032_separation
  040_annotation
  041_annot_fileattach
  050_pagelabels
  055_outlines
  060_transparency
  BarCode.pl
  Bspline.pl
  Content.pl
  ContentText.pl
  ShowFont.pl Helvetica
                     );
# run with perl examples/<file> [args]
# "027_winfont" has been removed (put in Windows directory for now)

my %args;
# if you do not define a file for a test (leave it EMPTY ''), it will be skipped
#
# 021_psfonts needs T1 glyph and metrics files (not included)
# assuming metrics file (.afm or .pfm) is in same directory
  $args{'021_psfonts'} = "/Users/Phil/T1fonts/URWPalladioL-Roma.pfb";
# 022_truefonts needs a TTF or OTF font to do its thing
  $args{'022_truefonts'} = "/WINDOWS/fonts/times.ttf";
# 022_truefonts_diacrits_utf8 needs a TTF or OTF font that includes a
# diacritic (combining accent mark) to do its thing
  $args{'022_truefonts_diacrits_utf8'} = "/WINDOWS/fonts/tahoma.ttf";
# 024_bdffonts needs a sample BDF (bitmapped font), which is not
# included with the distribution
  $args{'024_bdffonts'} = "../old PDF-APIx/work-PDF-Builder/codec/codec.bdf";

# some warnings:
if ('023_cjkfonts' ~~ @example_list) {
    print "023_cjkfonts: to display the resulting PDFs, you may need to install\n";
    print "  East Asian fonts for your PDF reader.\n";
}
if ('025_unifonts' ~~ @example_list) {
    print "025_unifonts will fail with error messages about a bad UTF-8 character\n";
    print "  Don't worry about it.\n";
}

print STDERR "\nStarting example runs...";

my $arg;
foreach my $file (@example_list) {
    if (defined $args{$file}) {
	$arg = $args{$file};
	if ($arg eq '') {
	    print "test examples/$file skipped at your request\n";
	    next;
	}
    } else {
        $arg = '';
    }
    print "\n=== Running test examples/$file $arg\n";
    system("perl examples/$file $arg");
}

print STDERR "\nAfter examining files (results), do NOT erase files \n";
print STDERR "  examples/011_open_update.BASE.pdf\n";
print STDERR "  examples/012_pages.pdf\n";
print STDERR "  examples/011_open_update.UPDATED.pdf\n";
print STDERR "if you are going to run 4_contrib.pl\n";
print STDERR "\nAll other examples output PDF files may be erased.\n";
