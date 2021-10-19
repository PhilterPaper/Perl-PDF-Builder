package PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Reader;

use strict;
use warnings;
use Carp;
use Readonly;
Readonly my $BITS2BYTES_SHIFT => 3;
Readonly my $BITS_PER_BYTE    => 8;

sub new {
    my ( $class, $data ) = @_;
    my $self = {};
    $self->{data} = $data;
    ( $self->{byte_ptr}, $self->{bit_ptr} ) = ( 0, 0 );
    return bless $self, $class;
}

sub reset {    ## no critic (ProhibitBuiltinHomonyms)
    my ($self) = @_;
    ( $self->{byte_ptr}, $self->{bit_ptr} ) = ( 0, 0 );
    return;
}

sub eod_p {
    my ($self) = @_;
    use Data::Dumper;
    return $self->{byte_ptr} >= length $self->{data};
}

sub size {
    my ($self) = @_;
    return length( $self->{data} ) << $BITS2BYTES_SHIFT;
}

sub pos {    ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, $bits ) = @_;

    # getter
    if ( not defined $bits ) {
        return ( $self->{byte_ptr} << $BITS2BYTES_SHIFT ) + $self->{bit_ptr};
    }

    # setter
    if ( $bits > $self->size ) {
        croak 'Pointer position out of data';
    }

    my $pbyte = $bits >> $BITS2BYTES_SHIFT;
    my $pbit  = $bits - ( $pbyte << $BITS2BYTES_SHIFT );
    ( $self->{byte_ptr}, $self->{bit_ptr} ) = ( $pbyte, $pbit );
    return;
}

sub peek {
    my ( $self, $length ) = @_;
    if ( $length <= 0 ) {
        croak 'Invalid read length';
    }
    elsif ( ( $self->pos + $length ) > $self->size ) {
        croak 'Insufficient data';
    }

    my $n = 0;
    my ( $byte_ptr, $bit_ptr ) = ( $self->{byte_ptr}, $self->{bit_ptr} );

    while ( $length > 0 ) {
        my $byte = ord substr $self->{data}, $byte_ptr, 1;

        if ( $length > $BITS_PER_BYTE - $bit_ptr ) {
            $length -= $BITS_PER_BYTE - $bit_ptr;
            $n |= ( $byte & ( ( 1 << ( $BITS_PER_BYTE - $bit_ptr ) ) - 1 ) )
              << $length;

            $byte_ptr += 1;
            $bit_ptr = 0;
        }
        else {
            $n |= ( $byte >> ( $BITS_PER_BYTE - $bit_ptr - $length ) ) &
              ( ( 1 << $length ) - 1 );
            $length = 0;
        }
    }
    return $n;
}

sub read {    ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, $length ) = @_;
    my $n = $self->peek($length);
    $self->pos += $length;
    return $n;
}

1;
