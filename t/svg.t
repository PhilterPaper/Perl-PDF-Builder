#!/usr/bin/perl
use warnings;
use strict;
use English qw( -no_match_vars );
use IPC::Cmd qw(can_run run);
use File::Spec;
use File::Temp;
use version;
use Test::More tests => 1;

use PDF::Builder;
my $diag = '';
my $failed;

my $pdf = PDF::Builder->new('-compress' => 'none'); # common $pdf all tests
my $has_SVG = 0; # global flag for all tests that need to know if SVGPDF
my ($page, $img, $example, $expected);
$has_SVG = $pdf->LA_SVG();

# 1
SKIP: {
    skip "SVGPDF is not available.", 1 unless $has_SVG;

# ----------
#$pdf = PDF::Builder->new(-file => $pdfout);
#$page = $pdf->page();
#$page->mediabox($width, $height);
#$gfx = $page->gfx();
#$img = $pdf->image_tiff($tiff_f, -nouseGT => $noGT);
#$gfx->image($img, 0, 0, $width, $height);
#$pdf->save();
#$pdf->end();
$example = $expected = ' '; # dummy run

is($example, $expected, 'dummy SVG check');
}

##############################################################
# cleanup. all tests involving these files skipped?

# check non-Perl utility versions
sub check_version {
    my ($cmd, $arg, $regex, $min_ver) = @_;

    # was the check routine already defined (installed)?
    if (defined $cmd) {
	# should match dotted version number
        my $output = `$cmd $arg`;
        $diag .= $output;
	if ($output =~ m/$regex/) {
	    if (version->parse($1) >= version->parse($min_ver)) {
		return $cmd;
	    }
	}
    }
    return; # cmd not defined (not installed) so return undef
}

# exclude specified non-Perl utility versions
# do not call if don't have one or more exclusion ranges
sub exclude_version {
    my ($cmd, $arg, $regex, $ex_ver_r) = @_;

    my (@ex_ver, $my_ver);
    if (defined $ex_ver_r) {
	@ex_ver = @$ex_ver_r;
    } else {
	return; # called w/o exclusion list: fail
    }
    # need 2, 4, 6,... dotted versions
    if (!scalar(@ex_ver) || scalar(@ex_ver)%2) {
	return; # called with zero or odd number of elements: fail
    }

    if (defined $cmd) {
	# dotted version number should not fall into an excluded range
        my $output = `$cmd $arg`;
        $diag .= $output;
	if ($output =~ m/$regex/) {
	    $my_ver = version->parse($1);
	    for (my $i=0; $i<scalar(@ex_ver); $i+=2) {
	        if ($my_ver >= version->parse($ex_ver[$i  ]) &&
		    $my_ver <= version->parse($ex_ver[$i+1])) {
		    return; # fell into one of the exclusion ranges
	        }
	    }
	    return $cmd; # didn't hit any exclusions, so OK
	}
    }
    return; # cmd not defined (not installed) so return undef
}

sub show_diag { 
   #$failed = 0;
    $failed = 1;
    return;
}

if ($failed) { diag($diag) }
