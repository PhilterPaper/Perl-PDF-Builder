#!/usr/bin/perl
use warnings;
use strict;

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode;
use Test::More tests => 26;

# group 3, 1 row, 6 columns
my $filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    {
        Rows     => PDFNum(1),
        Columns  => PDFNum(6),
        K        => PDFNum(0),
        BlackIs1 => PDFBool(1)
    }
);
my $in = pack( 'B*', '10101000' );
my $out =
  pack( 'B*', '00000000000000010011010101000011101000011101000011100000' );
# runlengths   |Pad|   EOL    || 0W   |1B|| 1W |1B|| 1W |1B|| 1W ||Pad|
# byte markers        |       |       |       |       |       |       |
is unpack( 'B*', $filter->infilt($out) ), unpack( 'B*', $in ),
  '1 row of CCITTFaxDecode group 3 decoded correctly';    #1
is unpack( 'B*', $filter->outfilt($in) ), unpack( 'B*', $out ),
  '1 row of CCITTFaxDecode group 3 encoded correctly';    #2

# group 3, 2 rows, 6 columns
$filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    {
        Rows     => PDFNum(2),
        Columns  => PDFNum(6),
        K        => PDFNum(0),
        BlackIs1 => PDFBool(1)
    }
);
$in = pack( 'B*', '1010100001010100' );
#                  |  r1  ||  r2  |
$out = pack( 'B*',
'000000000000000100110101010000111010000111010000111000000000000100011101000011101000011101000000'
);
# runlengths
#|Pad|   EOL    || 0W   |1B|| 1W |1B|| 1W |1B|| 1W |P|   EOL    || 1W |1B|| 1W |1B|| 1W |1B|pad |
# byte markers
#       |       |       |       |       |       |       |       |       |       |       |       |
is $filter->infilt($out), $in,
  '2 rows of CCITTFaxDecode group 3 decoded correctly';    #3
is $filter->outfilt($in), $out,
  '2 rows of CCITTFaxDecode group 3 encoded correctly';    #4

# group 4, 1 row, 6 columns
$filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    {
        Rows     => PDFNum(1),
        Columns  => PDFNum(6),
        K        => PDFNum(-1),
        BlackIs1 => PDFBool(1)
    }
);
$in  = pack( 'B*', '10101000' );
$out = pack( 'B*',
    '0010011010101000100011101000001001010000000000010000000000010000' );
#    |H|| 0W   |1B||H|| 1W |1B||VL2 |VL1V0       EOFB           |pad|
# byte markers
#           |       |       |       |       |       |       |       |
is unpack( 'B*', $filter->infilt($out) ), unpack( 'B*', $in ),
  '1 row of CCITTFaxDecode group 4 decoded correctly';    #5
is unpack( 'B*', $filter->outfilt($in) ), unpack( 'B*', $out ),
  '1 row of CCITTFaxDecode group 4 encoded correctly';    #6

# group 4, 2 rows, 6 columns
$filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    {
        Rows     => PDFNum(2),
        Columns  => PDFNum(6),
        K        => PDFNum(-1),
        BlackIs1 => PDFBool(1)
    }
);
$in  = pack( 'B*', '1010100001010100' );
$out = pack( 'B*',
'00100110101010001000111010000010010101101001001001010000000000010000000000010000'
);
#|H|| 0W   |1B||H|| 1W |1B||VL2 |VL1VVR1VL1VL1VL1VL1V|       EOFB           |pad|
#                                   0               0
# byte markers
#       |       |       |       |       |       |       |       |       |       |
#|           row 1                  ||   row 2       |
is unpack( 'B*', $filter->infilt($out) ), unpack( 'B*', $in ),
  '2 rows of CCITTFaxDecode group 4 decoded correctly';    #7
is unpack( 'B*', $filter->outfilt($in) ), unpack( 'B*', $out ),
  '2 rows of CCITTFaxDecode group 4 encoded correctly';    #8

$filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    {
        Rows     => PDFNum(1),
        Columns  => PDFNum(2429),
        K        => PDFNum(0),
        BlackIs1 => PDFBool(1)
    }
);
$in  = pack( 'B*', '1' x 2429 . '000' );
$out = pack( 'B*', '000000000000000100110101000000011100000001011010' );
# runlengths        |pad|   EOL    || 0W   ||  MU2368  ||  61B     |
# byte markers             |       |       |       |       |       |
is $filter->infilt($out), $in,  'g3 make-up codes decoded correctly';
is $filter->outfilt($in), $out, 'g3 make-up codes encoded correctly';

$filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    {
        Rows     => PDFNum(1),
        Columns  => PDFNum(192),
        K        => PDFNum(0),
        BlackIs1 => PDFBool(1)
    }
);
$in  = pack( 'B*', '0' x 192 );
$out = pack( 'B*', '00000000000000010101110011010100' );

# runlengths        |pad|   EOL    |MU192|  0W   |pad
# byte markers             |       |       |       |
is unpack( 'B*', $filter->infilt($out) ), unpack( 'B*', $in ),
  'g3 make-up codes + zero-length run decoded correctly';    #11
is unpack( 'B*', $filter->outfilt($in) ), unpack( 'B*', $out ),
  'g3 make-up codes + zero-length run encoded correctly';    #12

$filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    {
        Rows     => PDFNum(2),
        Columns  => PDFNum(1648),
        K        => PDFNum(-1),
        BlackIs1 => PDFBool(1)
    }
);
$in = pack( 'B*',
    '0' x 13 . '1' . '0' x ( 1634 + 14 + 1193 ) . '1' x 84 . '0' x 357 );
$out = pack( 'B*',
'0010000110101000100101101011100101010000000111100001101000100000000000100000000000100000'
);
#|H|| 13W|1B|V|P ||H||MU1152 ||  41W ||  MU64  ||  20B    |V|     EOFB             ||pad|
#|   row 1   ||                      row 2                 |
is unpack( 'B*', $filter->infilt($out) ), unpack( 'B*', $in ),
  'pass mode decoded correctly';    #13
is unpack( 'B*', $filter->outfilt($in) ), unpack( 'B*', $out ),
  'pass mode encoded correctly';    #14

$filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    {
        Rows     => PDFNum(2),
        Columns  => PDFNum(1648),
        K        => PDFNum(-1),
        BlackIs1 => PDFBool(1)
    }
);
$in = pack( 'B*',
        '0' x ( 128 + 60 )
      . '1' x 6
      . '0' x ( 512 + 16 )
      . '1' x 22
      . '0' x ( 256 + 14 )
      . '1' x 9
      . '0' x ( 256 + 8 )
      . '1' x 40
      . '0' x 8
      . '1' x 2
      . '0' x 36
      . '1' x 13
      . '0' x 47
      . '1' x 4
      . '0' x ( 64 + 27 )
      . '1' x 17
      . '000010'
      . '1' x 14
      . '0' x 83
      . '0' x ( 128 + 55 )
      . '1' x 7
      . '0' x ( 512 + 31 )
      . '1' x 20
      . '0' x 256
      . '1' x 8
      . '0' x ( 256 + 8 )
      . '1' x 39
      . '0' x 15 . '11'
      . '0' x 36
      . '1' x 19
      . '0' x 44 . '1111'
      . '0' x ( 64 + 19 )
      . '1' x 11
      . '0' x 27
      . '1' x 7
      . '0' x 80 );
$out = pack(
    'B*',
'0011001001001011001000101100101101010000001101110010110111110100000100001011011110011000001101100001100111100100010101000001000010000101001100111011010010000000110000011011010001000111000001111'
      .
#|H|| MU128 60W ||6B||H|| MU512 16W  ||  22B    ||H|| MU256 14W || 9B ||H|| MU256 8W ||    40B   ||H|| 8W2B|H||  36W  || 13B  ||H||  47W |4B||H|| MU64 27W ||   17B  ||H||4W|1B||H|| 1W | 14B   |V
'0011001001011000000110010110010100011010000011010000010110111001101010001010010110111100110000110101111110010000110011100101101000001100111011000110000001010001001010000001110000000000010000000000010'
);
#|H|| MU128 55W ||7B ||H|| MU512 31W    ||  20B    ||H|| MU256 0W    || 8B ||H|| MU256 8W ||    39B   |VVV|H||   19B   || 44W  | VR3  ||H|| MU64 19W || 11B |pass|H||11W||7B |V|EOFB                  |pad
is unpack( 'B*', $filter->infilt($out) ), unpack( 'B*', $in ),
  'horizontal after vertical decoded correctly';    #15
is unpack( 'B*', $filter->outfilt($in) ), unpack( 'B*', $out ),
  'horizontal after vertical encoded correctly';    #16

$filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    {
        Rows     => PDFNum(1),
        Columns  => PDFNum(2429),
        K        => PDFNum(-1),
        BlackIs1 => PDFBool(1)
    }
);
$in = pack( 'B*',
        '00011'
      . '0' x ( 1920 + 57 ) . '11111'
      . '0' x 11 . '111'
      . '0' x ( 64 + 36 ) . '1111'
      . '0' x 38 . '1111'
      . '0' x 282 );
$out = pack( 'B*',
'00110001100100000001101010110100011001010001000111011000101010110010001011101110000000000010000000000010'
);

#|H||3W|2B|H|| MU1920  |  57W  ||5B||H||11W|3B|H|MU64|| 36W  |4B||H|| 38W  |4B|V|EOFB                  |pad
is unpack( 'B*', $filter->infilt($out) ), unpack( 'B*', $in ),
  'makeup 1920 decoded correctly';    #17
is unpack( 'B*', $filter->outfilt($in) ), unpack( 'B*', $out ),
  'makeup 1920 encoded correctly';    #18

# group 3, 2 rows, 6 columns
$filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    { Rows => PDFNum(2), Columns => PDFNum(6), K => PDFNum(0) } );
$in  = pack( 'B*', '0101010010101000' );
$out = pack( 'B*',
'000000000000000100011101000011101000011101000000000000010011010101000011101000011101000011100000'
);
is unpack( 'B*', $filter->infilt($out) ), unpack( 'B*', $in ),
  '2 rows of CCITTFaxDecode group 3 min-is-black decoded correctly';    #19
is unpack( 'B*', $filter->outfilt($in) ), unpack( 'B*', $out ),
  '2 rows of CCITTFaxDecode group 3 min-is-black encoded correctly';    #20

# group 4, min-is-black, 2 rows, 6 columns
$filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    { Rows => PDFNum(2), Columns => PDFNum(6), K => PDFNum(-1) } );
$in  = pack( 'B*', '0101010010101000' );
$out = pack( 'B*',
    '001000111010000001000001001010100100100100100101000000000001000000000001'
);
is unpack( 'B*', $filter->infilt($out) ), unpack( 'B*', $in ),
  '2 rows of CCITTFaxDecode group 4 min-is-black decoded correctly';    #21
is unpack( 'B*', $filter->outfilt($in) ), unpack( 'B*', $out ),
  '2 rows of CCITTFaxDecode group 4 min-is-black encoded correctly';    #22

$filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    { Rows => PDFNum(2), Columns => PDFNum(2429), K => PDFNum(-1) } );
$in = pack(
    'B*',
    '100' . ( '1' x 2426 ) . '000' .    # 3-char pad
      '1100' . ( '1' x 2425 ) . '000'
);                                      # 3-char pad
$out = pack( 'B*',
'00100110101010001011100000001110000000101100110110111000000000001000000000001000'
);
#|H||  0W  |1B||H||2W| MU2368     58B        |VVR1VR1V|EOFB                  |pad
#|              row 1                        |  row2 |
is unpack( 'B*', $filter->infilt($out) ), unpack( 'B*', $in ),
  'vertical mode after 3-bit pad decoded correctly';    #23
is unpack( 'B*', $filter->outfilt($in) ), unpack( 'B*', $out ),
  'vertical mode after 3-bit pad encoded correctly';    #24

# This is assumed from the PDF spec, but have not found any PDFs with EncodedByteAlign to test
# group 4, 2 rows, 6 columns, EncodedByteAlign
$filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new(
    {
        Rows             => PDFNum(2),
        Columns          => PDFNum(6),
        K                => PDFNum(-1),
        BlackIs1         => PDFBool(1),
        EncodedByteAlign => PDFBool(1)
    }
);
$in  = pack( 'B*', '1010100001010100' );
$out = pack( 'B*',
'00100110101010001000111010000010010100000110100100100101000000000001000000000001'
);
#|H|| 0W   |1B||H|| 1W |1B||VL2 |VL1Vpad|VR1VL1VL1VL1VL1V|       EOFB           |
is unpack( 'B*', $filter->infilt($out) ), unpack( 'B*', $in ),
  'group 4 EncodedByteAlign decoded correctly';    #25
is unpack( 'B*', $filter->outfilt($in) ), unpack( 'B*', $out ),
  'group 4 EncodedByteAlign encoded correctly';    #26
