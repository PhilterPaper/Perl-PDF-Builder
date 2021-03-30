#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 6;

use PDF::Builder::Basic::PDF::Filter::LZWDecode;

my $filter = PDF::Builder::Basic::PDF::Filter::LZWDecode->new();

my $in = 'BT /F1 24 Tf 100 700 Td (Hello World)Tj ET';
my $out = $filter->outfilt($in);

is $filter->infilt($out), $in, 'LZWDecode test string round-tripped correctly';

my $repeat = 22;
note( 'Test data size: ' . length($in)*$repeat );

$filter = PDF::Builder::Basic::PDF::Filter::LZWDecode->new();
$out = $filter->outfilt($in x $repeat);

note( 'Final bits: '.$filter->{code_length} );

cmp_ok length($out), '<', length($in)*$repeat, "Data compresses smaller";

$filter = PDF::Builder::Basic::PDF::Filter::LZWDecode->new();
is $filter->infilt($out), $in x $repeat, 'Data decompresses unchanged at 10bit boundary';

$in = pack "H*", '8000000014040807050001e100f840fd00e0003fd00ff8a44e2b01';
my $expected = pack "H*", '00000180000003800000078000000f8000003f80e000ff80ffffff80ffffff80';
$filter = PDF::Builder::Basic::PDF::Filter::LZWDecode->new();
$out = $filter->infilt($in);
is $out, $expected, 'decompress binary data';

($in, $expected) = ($expected, $in);
$filter = PDF::Builder::Basic::PDF::Filter::LZWDecode->new();
$out = $filter->outfilt($in);
is $out, $expected, 'compress binary data';

$repeat = 30000;
$in = '';
for (0..$repeat) {$in .= chr(int(rand(256)))}
note( 'Test data size: ' . length($in) );

$filter = PDF::Builder::Basic::PDF::Filter::LZWDecode->new();
$out = $filter->outfilt($in);

note( 'Final bits: '.$filter->{code_length} );

$filter = PDF::Builder::Basic::PDF::Filter::LZWDecode->new();
is $filter->infilt($out), $in, 'Data decompresses unchanged after reaching max code length';
