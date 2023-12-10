package PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode;

use strict;
use warnings;

use Carp;
use POSIX;
use PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Reader;
use PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Writer;
use feature 'switch';
no if $] >= 5.018, warnings => 'experimental::smartmatch';
use base 'PDF::Builder::Basic::PDF::Filter::FlateDecode';

# VERSION
our $LAST_UPDATE = '3.027';    # manually update whenever code is changed

sub codeword {
    my ($bits) = @_;
    return oct( '0b' . $bits ), length $bits;
}

use Readonly;
Readonly my $VERT_MODE_MAX_OFFSET => 3;
Readonly my $MAX_MODE_LENGTH      => 7;
Readonly my $BITS_PER_BYTE        => 8;
Readonly my $MAX_CODE_LENGTH      => 14;
Readonly my $MAX_TERMINAL_LENGTH  => 63;
Readonly my $DEFAULT_COLUMNS      => 1728;
Readonly my @EOL                  => codeword('000000000001');

# This produces the warning Binary number > 0b11111111111111111111111111111111
# non-portable, so refactoring
#Readonly my @RTC => codeword('000000000001' x 6);
Readonly my @RTC  => ( '1153203048319815681', 72 );
Readonly my @EOFB => codeword( '000000000001' x 2 );

Readonly my %MODE_ENCODE_TABLE => {
    'P'   => [ codeword('0001') ],
    'H'   => [ codeword('001') ],
    'V0'  => [ codeword('1') ],
    'VR1' => [ codeword('011') ],
    'VR2' => [ codeword('000011') ],
    'VR3' => [ codeword('0000011') ],
    'VL1' => [ codeword('010') ],
    'VL2' => [ codeword('000010') ],
    'VL3' => [ codeword('0000010') ],
};

Readonly my %MODE_DECODE_TABLE =>
  map { $MODE_ENCODE_TABLE{$_}[0] . q{ } . $MODE_ENCODE_TABLE{$_}[1] => $_ }
  keys %MODE_ENCODE_TABLE;

Readonly my %WHITE_TERMINAL_ENCODE_TABLE => {
    0  => [ codeword('00110101') ],
    1  => [ codeword('000111') ],
    2  => [ codeword('0111') ],
    3  => [ codeword('1000') ],
    4  => [ codeword('1011') ],
    5  => [ codeword('1100') ],
    6  => [ codeword('1110') ],
    7  => [ codeword('1111') ],
    8  => [ codeword('10011') ],
    9  => [ codeword('10100') ],
    10 => [ codeword('00111') ],
    11 => [ codeword('01000') ],
    12 => [ codeword('001000') ],
    13 => [ codeword('000011') ],
    14 => [ codeword('110100') ],
    15 => [ codeword('110101') ],
    16 => [ codeword('101010') ],
    17 => [ codeword('101011') ],
    18 => [ codeword('0100111') ],
    19 => [ codeword('0001100') ],
    20 => [ codeword('0001000') ],
    21 => [ codeword('0010111') ],
    22 => [ codeword('0000011') ],
    23 => [ codeword('0000100') ],
    24 => [ codeword('0101000') ],
    25 => [ codeword('0101011') ],
    26 => [ codeword('0010011') ],
    27 => [ codeword('0100100') ],
    28 => [ codeword('0011000') ],
    29 => [ codeword('00000010') ],
    30 => [ codeword('00000011') ],
    31 => [ codeword('00011010') ],
    32 => [ codeword('00011011') ],
    33 => [ codeword('00010010') ],
    34 => [ codeword('00010011') ],
    35 => [ codeword('00010100') ],
    36 => [ codeword('00010101') ],
    37 => [ codeword('00010110') ],
    38 => [ codeword('00010111') ],
    39 => [ codeword('00101000') ],
    40 => [ codeword('00101001') ],
    41 => [ codeword('00101010') ],
    42 => [ codeword('00101011') ],
    43 => [ codeword('00101100') ],
    44 => [ codeword('00101101') ],
    45 => [ codeword('00000100') ],
    46 => [ codeword('00000101') ],
    47 => [ codeword('00001010') ],
    48 => [ codeword('00001011') ],
    49 => [ codeword('01010010') ],
    50 => [ codeword('01010011') ],
    51 => [ codeword('01010100') ],
    52 => [ codeword('01010101') ],
    53 => [ codeword('00100100') ],
    54 => [ codeword('00100101') ],
    55 => [ codeword('01011000') ],
    56 => [ codeword('01011001') ],
    57 => [ codeword('01011010') ],
    58 => [ codeword('01011011') ],
    59 => [ codeword('01001010') ],
    60 => [ codeword('01001011') ],
    61 => [ codeword('00110010') ],
    62 => [ codeword('00110011') ],
    63 => [ codeword('00110100') ],
};

Readonly my %WHITE_TERMINAL_DECODE_TABLE => map {
        $WHITE_TERMINAL_ENCODE_TABLE{$_}[0] . q{ }
      . $WHITE_TERMINAL_ENCODE_TABLE{$_}[1] => $_
} keys %WHITE_TERMINAL_ENCODE_TABLE;

Readonly my %BLACK_TERMINAL_ENCODE_TABLE => {
    0  => [ codeword('0000110111') ],
    1  => [ codeword('010') ],
    2  => [ codeword('11') ],
    3  => [ codeword('10') ],
    4  => [ codeword('011') ],
    5  => [ codeword('0011') ],
    6  => [ codeword('0010') ],
    7  => [ codeword('00011') ],
    8  => [ codeword('000101') ],
    9  => [ codeword('000100') ],
    10 => [ codeword('0000100') ],
    11 => [ codeword('0000101') ],
    12 => [ codeword('0000111') ],
    13 => [ codeword('00000100') ],
    14 => [ codeword('00000111') ],
    15 => [ codeword('000011000') ],
    16 => [ codeword('0000010111') ],
    17 => [ codeword('0000011000') ],
    18 => [ codeword('0000001000') ],
    19 => [ codeword('00001100111') ],
    20 => [ codeword('00001101000') ],
    21 => [ codeword('00001101100') ],
    22 => [ codeword('00000110111') ],
    23 => [ codeword('00000101000') ],
    24 => [ codeword('00000010111') ],
    25 => [ codeword('00000011000') ],
    26 => [ codeword('000011001010') ],
    27 => [ codeword('000011001011') ],
    28 => [ codeword('000011001100') ],
    29 => [ codeword('000011001101') ],
    30 => [ codeword('000001101000') ],
    31 => [ codeword('000001101001') ],
    32 => [ codeword('000001101010') ],
    33 => [ codeword('000001101011') ],
    34 => [ codeword('000011010010') ],
    35 => [ codeword('000011010011') ],
    36 => [ codeword('000011010100') ],
    37 => [ codeword('000011010101') ],
    38 => [ codeword('000011010110') ],
    39 => [ codeword('000011010111') ],
    40 => [ codeword('000001101100') ],
    41 => [ codeword('000001101101') ],
    42 => [ codeword('000011011010') ],
    43 => [ codeword('000011011011') ],
    44 => [ codeword('000001010100') ],
    45 => [ codeword('000001010101') ],
    46 => [ codeword('000001010110') ],
    47 => [ codeword('000001010111') ],
    48 => [ codeword('000001100100') ],
    49 => [ codeword('000001100101') ],
    50 => [ codeword('000001010010') ],
    51 => [ codeword('000001010011') ],
    52 => [ codeword('000000100100') ],
    53 => [ codeword('000000110111') ],
    54 => [ codeword('000000111000') ],
    55 => [ codeword('000000100111') ],
    56 => [ codeword('000000101000') ],
    57 => [ codeword('000001011000') ],
    58 => [ codeword('000001011001') ],
    59 => [ codeword('000000101011') ],
    60 => [ codeword('000000101100') ],
    61 => [ codeword('000001011010') ],
    62 => [ codeword('000001100110') ],
    63 => [ codeword('000001100111') ],
};

Readonly my %BLACK_TERMINAL_DECODE_TABLE => map {
        $BLACK_TERMINAL_ENCODE_TABLE{$_}[0] . q{ }
      . $BLACK_TERMINAL_ENCODE_TABLE{$_}[1] => $_
} keys %BLACK_TERMINAL_ENCODE_TABLE;

Readonly my %WHITE_MAKEUP_ENCODE_TABLE => {
    64   => [ codeword('11011') ],
    128  => [ codeword('10010') ],
    192  => [ codeword('010111') ],
    256  => [ codeword('0110111') ],
    320  => [ codeword('00110110') ],
    384  => [ codeword('00110111') ],
    448  => [ codeword('01100100') ],
    512  => [ codeword('01100101') ],
    576  => [ codeword('01101000') ],
    640  => [ codeword('01100111') ],
    704  => [ codeword('011001100') ],
    768  => [ codeword('011001101') ],
    832  => [ codeword('011010010') ],
    896  => [ codeword('011010011') ],
    960  => [ codeword('011010100') ],
    1024 => [ codeword('011010101') ],
    1088 => [ codeword('011010110') ],
    1152 => [ codeword('011010111') ],
    1216 => [ codeword('011011000') ],
    1280 => [ codeword('011011001') ],
    1344 => [ codeword('011011010') ],
    1408 => [ codeword('011011011') ],
    1472 => [ codeword('010011000') ],
    1536 => [ codeword('010011001') ],
    1600 => [ codeword('010011010') ],
    1664 => [ codeword('011000') ],
    1728 => [ codeword('010011011') ],

    1792 => [ codeword('00000001000') ],
    1856 => [ codeword('00000001100') ],
    1920 => [ codeword('00000001101') ],
    1984 => [ codeword('000000010010') ],
    2048 => [ codeword('000000010011') ],
    2112 => [ codeword('000000010100') ],
    2176 => [ codeword('000000010101') ],
    2240 => [ codeword('000000010110') ],
    2340 => [ codeword('000000010111') ],
    2368 => [ codeword('000000011100') ],
    2432 => [ codeword('000000011101') ],
    2496 => [ codeword('000000011110') ],
    2560 => [ codeword('000000011111') ],
};

Readonly my %WHITE_MAKEUP_DECODE_TABLE => map {
        $WHITE_MAKEUP_ENCODE_TABLE{$_}[0] . q{ }
      . $WHITE_MAKEUP_ENCODE_TABLE{$_}[1] => $_
} keys %WHITE_MAKEUP_ENCODE_TABLE;

Readonly my %BLACK_MAKEUP_ENCODE_TABLE => {
    64   => [ codeword('0000001111') ],
    128  => [ codeword('000011001000') ],
    192  => [ codeword('000011001001') ],
    256  => [ codeword('000001011011') ],
    320  => [ codeword('000000110011') ],
    384  => [ codeword('000000110100') ],
    448  => [ codeword('000000110101') ],
    512  => [ codeword('0000001101100') ],
    576  => [ codeword('0000001101101') ],
    640  => [ codeword('0000001001010') ],
    704  => [ codeword('0000001001011') ],
    768  => [ codeword('0000001001100') ],
    832  => [ codeword('0000001001101') ],
    896  => [ codeword('0000001110010') ],
    960  => [ codeword('0000001110011') ],
    1024 => [ codeword('0000001110100') ],
    1088 => [ codeword('0000001110101') ],
    1152 => [ codeword('0000001110110') ],
    1216 => [ codeword('0000001110111') ],
    1280 => [ codeword('0000001010010') ],
    1344 => [ codeword('0000001010011') ],
    1408 => [ codeword('0000001010100') ],
    1472 => [ codeword('0000001010101') ],
    1536 => [ codeword('0000001011010') ],
    1600 => [ codeword('0000001011011') ],
    1664 => [ codeword('0000001100100') ],
    1728 => [ codeword('0000001100101') ],

    1792 => [ codeword('00000001000') ],
    1856 => [ codeword('00000001100') ],
    1920 => [ codeword('00000001101') ],
    1984 => [ codeword('000000010010') ],
    2048 => [ codeword('000000010011') ],
    2112 => [ codeword('000000010100') ],
    2176 => [ codeword('000000010101') ],
    2240 => [ codeword('000000010110') ],
    2340 => [ codeword('000000010111') ],
    2368 => [ codeword('000000011100') ],
    2432 => [ codeword('000000011101') ],
    2496 => [ codeword('000000011110') ],
    2560 => [ codeword('000000011111') ],
};

Readonly my %BLACK_MAKEUP_DECODE_TABLE => map {
        $BLACK_MAKEUP_ENCODE_TABLE{$_}[0] . q{ }
      . $BLACK_MAKEUP_ENCODE_TABLE{$_}[1] => $_
} keys %BLACK_MAKEUP_ENCODE_TABLE;
Readonly my @MAKEUP_KEYS => reverse sort { $a <=> $b }
  keys %BLACK_MAKEUP_ENCODE_TABLE;    # white has the same keys

sub new {
    my ( $class, $params ) = @_;

    # defaults - group3, 0 rows, 1728 columns, etc.
    my $params_copy;
    $params_copy->{K} =
      defined $params->{K}
      ? $params->{K}{val}
      : 0
      ;   # could replace with // operator if we overloaded dict for comparisons
    $params_copy->{Rows} = defined $params->{Rows} ? $params->{Rows}{val} : 0;
    $params_copy->{Columns} =
      defined $params->{Columns} ? $params->{Columns}{val} : $DEFAULT_COLUMNS;
    $params_copy->{EndOfLine} =
      defined $params->{EndOfLine} ? $params->{EndOfLine}{val} : 0;
    $params_copy->{EncodedByteAlign} =
      defined $params->{EncodedByteAlign}
      ? $params->{EncodedByteAlign}{val}
      : 0;
    $params_copy->{EndOfBlock} =
      defined $params->{EndOfBlock} ? $params->{EndOfBlock}{val} : 1;
    $params_copy->{BlackIs1} =
      defined $params->{BlackIs1} ? $params->{BlackIs1}{val} : 0;
    $params_copy->{DamagedRowsBeforeError} =
      defined $params->{DamagedRowsBeforeError}
      ? $params->{DamagedRowsBeforeError}{val}
      : 0;
    my $self = { params => $params_copy };
    return bless $self, $class;
}

sub infilt {
    my ( $self, $data ) = @_;
    if ( $self->{params}{K} == 0 ) {
        return $self->_decode_group3($data);
    }
    return $self->_decode_group4($data);
}

sub outfilt {
    my ( $self, $data ) = @_;
    if ( $self->{params}{K} == 0 ) {
        return $self->_encode_group3($data);
    }
    return $self->_encode_group4($data);
}

sub _encode_group3 {
    my ( $self, $stream ) = @_;
    my $bytealign = $self->{params}{EncodedByteAlign};
    $bytealign = 1;    # FIXME: this overwrites the value passed to the sub
    my $rows = $self->{params}{Rows};
    $stream = unpack 'B*', $stream;
    my ( $white, $black ) = ( 0, 1 );
    if ( $self->{params}{BlackIs1} ) {
        ( $white, $black ) = ( 0, 1 );
    }
    my $bitw = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Writer->new();
    my $pos  = 0;
    my $rowend = 0;
    while ( $rows > 0 ) {

        my $pad = $pos % $BITS_PER_BYTE;
        if ( $pad > 0 ) {
            $pos += $BITS_PER_BYTE - ( $pad % $BITS_PER_BYTE );
        }
        $rowend = $pos + $self->{params}{Columns};
        my $color = $white;
        $bitw->write( sprintf( "%0$EOL[1]b", $EOL[0] ), $bytealign );

        while ( $pos < $rowend ) {
            ( my $code, $pos ) =
              encode_color_bits( $stream, $pos, $rowend, $color, $white );
            $bitw->write($code);
            $color ^= 1;
        }
        $rows -= 1;
    }
    $bitw->pad_to_byte_boundary;
    return $bitw->{data};
}

sub _encode_group4 {
    my ( $self, $stream ) = @_;
    my $columns   = $self->{params}{Columns};
    my $rows      = $self->{params}{Rows};
    my $bytealign = $self->{params}{EncodedByteAlign};
    $stream = unpack 'B*', $stream;
    my ( $white, $black ) = ( 0, 1 );
    if ( $self->{params}{BlackIs1} ) {
        ( $white, $black ) = ( 0, 1 );
    }
    my $bitw = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Writer->new();
    my $padded_columns = $columns;
    my $pad            = $columns % $BITS_PER_BYTE;
    if ( $pad > 0 ) {
        $padded_columns += $BITS_PER_BYTE - $pad;
    }
    my $row = 0;
    my $ref = $white x ( $columns + 1 )
      ;    # including the imaginary white pixel at the beginning of the line
    while ( $row < $rows ) {
        if ($bytealign) {
            $bitw->pad_to_byte_boundary;
        }
        my $color = $white;
        my $a0    = 0;
        my $line  = $white . substr $stream, $row * $padded_columns, $columns
          ;   # including the imaginary white pixel at the beginning of the line
        while ( $a0 <= $columns ) {
            my $a1 = $self->find_next_changing_bit( $line, $a0 );
            my ( $b1, $b2 ) = get_b12( $a0, $ref, $color );
            if ( $b2 < $a1 ) {    # pass mode
                $bitw->write( encode_word( 'P', \%MODE_ENCODE_TABLE ) );
                $a0 = $b2;
                $color ^= 1;
            }
            elsif ( abs( $b1 - $a1 ) > $VERT_MODE_MAX_OFFSET )
            {                     # horizontal mode
                $bitw->write( encode_word( 'H', \%MODE_ENCODE_TABLE ) );
                my $runlen = $a1 - $a0;
                if ( $a0 == 0 ) {
                    $runlen -= 1;
                }
                my $code = encode_color_run( $runlen, $color, $white );
                $bitw->write($code);
                $color ^= 1;
                my $a2 = $self->find_next_changing_bit( $line, $a1 );
                $code = encode_color_run( $a2 - $a1, $color, $white );
                $bitw->write($code);
                $a0 = $a2;
            }
            else {    # vertical mode
                my $code = 'V';
                if ( $a1 == $b1 ) {
                    $code .= '0';
                }
                elsif ( $a1 < $b1 ) {
                    $code .= sprintf 'L%d', $b1 - $a1;
                }
                else {
                    $code .= sprintf 'R%d', $a1 - $b1;
                }
                $bitw->write( encode_word( $code, \%MODE_ENCODE_TABLE ) );
                $a0 = $a1;
            }
            $color ^= 1;
        }
        $row += 1;
        $ref = $line;
    }
    $bitw->write( sprintf "%0$EOFB[1]b", $EOFB[0] );
    $bitw->pad_to_byte_boundary;
    return $bitw->{data};
}

# FIXME: this should call find_next_changing_bit()
sub encode_color_bits {
    my ( $stream, $pos, $rowend, $color, $white ) = @_;

    my $run = $pos;
    while ( $run < length $stream and $run < $rowend ) {
        if ( substr( $stream, $run, 1 ) ne $color or $run == $rowend ) {
            last;
        }
        ++$run;
    }
    return encode_color_run( $run - $pos, $color, $white ), $run;
}

sub encode_color_run {
    my ( $runlen, $color, $white ) = @_;
    my ( $makeup_words, $term_words );
    if ( $color == $white ) {
        $makeup_words = \%WHITE_MAKEUP_ENCODE_TABLE;
        $term_words   = \%WHITE_TERMINAL_ENCODE_TABLE;
    }
    else {
        $makeup_words = \%BLACK_MAKEUP_ENCODE_TABLE;
        $term_words   = \%BLACK_TERMINAL_ENCODE_TABLE;
    }
    return encode_run( $runlen, $makeup_words, $term_words );
}

sub encode_run {
    my ( $runlen, $makeup_words, $term_words ) = @_;
    my $retval = q{};
    while ( $runlen > $MAX_TERMINAL_LENGTH ) {
        my $makeuplen;
        for my $len (@MAKEUP_KEYS) {
            if ( $len <= $runlen ) {
                $makeuplen = $len;
                last;
            }
        }
        $retval .= encode_word( $makeuplen, $makeup_words );
        $runlen -= $makeuplen;
    }
    $retval .= encode_word( $runlen, $term_words );
    return $retval;
}

sub encode_word {
    my ( $key, $table ) = @_;
    if ( not defined $key ) {
        croak 'Cannot encode undefined word';
    }
    if ( not defined $table->{$key} ) {
        croak "Word '$key' not in table";
    }
    my ( $code, $len ) = @{ $table->{$key} };
    return sprintf "%0$len" . 'b', $code;
}

# FIXME: this should probably be in Reader and merged with get_next_changing_bit()
sub find_next_changing_bit {
    my ( $self, $line, $pos ) = @_;
    my $color = substr $line, $pos, 1;
    while ( $pos < length $line and substr( $line, $pos, 1 ) eq $color ) {
        ++$pos;
    }
    return $pos;
}

sub _decode_group3 {
    my ( $self, $stream ) = @_;
    my $bytealign = $self->{params}{EncodedByteAlign};
    $bytealign = 1;    # FIXME: this overwrites the value passed to the sub
    my $rows = $self->{params}{Rows};

    my ( $white, $black ) = ( 0, 1 );
    if ( $self->{params}{BlackIs1} ) {
        ( $white, $black ) = ( 0, 1 );
    }
    my $bitr =
      PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Reader->new($stream);
    my $bitw = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Writer->new();

    while ( not( $bitr->eod_p() or $rows == 0 ) ) {
        my $color = $white;
        if (    $self->{params}{EndOfBlock}
            and $bitr->pos + $RTC[1] <= $bitr->size
            and $bitr->peek( $RTC[1] ) == $RTC[0] )
        {
            $bitr->pos += $RTC[1];
            last;
        }

        my $peek_size = $EOL[1];
        if ($bytealign) {
            $peek_size +=
              $BITS_PER_BYTE - ( ( $bitr->pos + $peek_size ) % $BITS_PER_BYTE );
        }
        if ( $bitr->peek($peek_size) == $EOL[0] ) {
            $bitr->pos( $bitr->pos + $peek_size );
        }
        else {
            if ( $self->{params}{EndOfLine} ) {
                croak 'No end-of-line pattern found (at bit pos ', $bitr->pos,
                  q{/}, $bitr->size, ')';
            }
        }

        my $line_length = 0;
        while ( $line_length < $self->{params}{Columns} ) {
            my $bit_length = $self->decode_color_bits( $bitr, $color, $white );
            if ( not defined $bit_length ) {
                croak 'Unfinished line (at bit pos ', $bitr->pos, q{/},
                  $bitr->size, ") , $bitw->{data}";
            }
            $line_length += $bit_length;
            if ( $line_length > $self->{params}{Columns} ) {
                croak "Line is too long (at bit pos $bitr->pos/$bitr->size)";
            }

            $bitw->write_run( $color, $bit_length );

            $color ^= 1;
        }

        $rows -= 1;
        $bitw->pad_to_byte_boundary;
    }
    return $bitw->{data};
}

sub _decode_group4 {
    my ( $self, $stream ) = @_;
    my $columns   = $self->{params}{Columns};
    my $rows      = $self->{params}{Rows};
    my $bytealign = $self->{params}{EncodedByteAlign};

    my ( $white, $black ) = ( 0, 1 );
    if ( $self->{params}{BlackIs1} ) {
        ( $white, $black ) = ( 0, 1 );
    }
    my $bitr =
      PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Reader->new($stream);
    my $bitw = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Writer->new();

    my $ref = $white x ( $columns + 1 )
      ;    # including the imaginary white pixel at the beginning of the line
    my $next_ref = q{};

    while ( not( $bitr->eod_p() or $rows == 0 ) ) {
        if ($bytealign) {
            my $pos = $bitr->pos;
            my $pad = $pos % $BITS_PER_BYTE;
            if ( $pos > 0 and $pad > 0 ) {
                $bitr->pos( $pos + $BITS_PER_BYTE - $pad );
            }
        }
        my $color = $white;
        my $a0    = 0;
        my $a1    = 1;
        my $a2;
        while ( $a1 <= $columns ) {
            my ( $b1, $b2 ) = get_b12( $a0, $ref, $color );
            my $bit_length;
            my $mode = $self->decode_mode($bitr);
            given ($mode) {
                when ('P') {
                    if ( $color != $white ) {
                        croak 'pass mode + black not supported';
                    }
                    $bit_length = $b2 - $a0;
                    $a1         = $a0 + $bit_length;
                }
                when ('H') {
                    $bit_length =
                      $self->decode_color_bits( $bitr, $color, $white );
                    if ( $bit_length > 0 )
                    {   # $bit_length could be zero at the beginning of the line
                        $next_ref .= $color x $bit_length;
                    }
                    $a1 = $a0 + $bit_length;
                    if ( $a0 == 0 ) {
                        $a1 += 1;
                    }
                    $color ^= 1;
                    $bit_length =
                      $self->decode_color_bits( $bitr, $color, $white );
                    $a2 = $a1 + $bit_length;
                }
                when (/V([LR]?)([0-3])/xsm) {
                    if ( defined $1 and $1 eq 'L' ) {
                        $a1 = $b1 - $2;
                    }
                    else {
                        $a1 = $b1 + $2;
                    }
                    $bit_length = $a1 - $a0;
                }
            }

            if ( not defined $bit_length ) {
                croak 'Unfinished line (at bit pos ', $bitr->pos, q{/},
                  $bitr->size, ") , $bitr->{data}";
            }
            if ( $mode eq 'H' ) {
                $a0 = $a2;
                $a1 = $a2;
            }
            else {
                if ( $a0 == 0 ) {
                    $bit_length -= 1;
                }
                $a0 = $a1;
            }

            $next_ref .= $color x $bit_length;

            if ( $mode ne 'P' ) { $color ^= 1 }
        }

        $rows -= 1;
        $bitw->write($next_ref);
        $bitw->pad_to_byte_boundary;
        $ref      = $white . $next_ref;
        $next_ref = q{};
    }
    return $bitw->{data};
}

sub decode_color_bits {
    my ( $self, $bitr, $color, $white ) = @_;
    my ( $makeup_words, $term_words );
    if ( $color == $white ) {
        $makeup_words = \%WHITE_MAKEUP_DECODE_TABLE;
        $term_words   = \%WHITE_TERMINAL_DECODE_TABLE;
    }
    else {
        $makeup_words = \%BLACK_MAKEUP_DECODE_TABLE;
        $term_words   = \%BLACK_TERMINAL_DECODE_TABLE;
    }
    for my $i ( 2 .. $MAX_CODE_LENGTH ) {
        my $codeword     = $bitr->peek($i);
        my $makeup_value = $makeup_words->{"$codeword $i"};
        if ( defined $makeup_value ) {
            $bitr->pos( $bitr->pos + $i );
            return $makeup_value +
              $self->decode_color_bits( $bitr, $color, $white );
        }
        my $term_value = $term_words->{"$codeword $i"};
        if ( defined $term_value ) {
            $bitr->pos( $bitr->pos + $i );
            return $term_value;
        }
    }
    return;
}

sub decode_mode {
    my ( $self, $bitr ) = @_;
    for my $i ( 1 .. $MAX_MODE_LENGTH ) {
        my $codeword = $bitr->peek($i);
        my $mode     = $MODE_DECODE_TABLE{"$codeword $i"};
        if ( defined $mode ) {
            $bitr->pos( $bitr->pos + $i );
            return $mode;
        }
    }
    croak 'Unable to decode mode';
}

sub get_b12 {
    my ( $a0, $ref, $color ) = @_;
    my $b1 = get_next_changing_bit( $a0, $ref, $color );
    $color ^= 1;
    my $b2 = get_next_changing_bit( $b1, $ref, $color );
    return $b1, $b2;
}

sub get_next_changing_bit {
    my ( $pos, $ref, $color ) = @_;
    while (
        ++$pos < length $ref
        and (  substr( $ref, $pos - 1, 1 ) ne $color
            or substr( $ref, $pos, 1 ) eq $color )
      )
    {
    }
    return $pos;
}

1;

__END__

=encoding utf8

=head1 NAME

PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode - Compress and uncompress stream filters for CCITTFax - NOT FULLY IMPLEMENTED

Filters as defined by https://tools.ietf.org/pdf/rfc804.pdf

Inherits from L<PDF::Builder::Basic::PDF::Filter::FlateDecode>

See also
https://www.itu.int/rec/T-REC-T.4-200307-I/en
https://www.itu.int/rec/T-REC-T.6-198811-I/en
https://www.itu.int/rec/T-REC-T.563-199610-I
