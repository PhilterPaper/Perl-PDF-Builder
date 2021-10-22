package PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Writer;

use strict;
use warnings;
use Carp;
use Readonly;
Readonly my $BITS_PER_BYTE => 8;

sub new {
    my ($class) = @_;
    my $self = {};
    $self->{data}      = q{};
    $self->{last_byte} = q{};
    return bless $self, $class;
}

sub write {    ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, $data, $bytealign ) = @_;
    my $length = length $data;

    my $pad = $BITS_PER_BYTE -
      ( $length + length( $self->{last_byte} ) ) % $BITS_PER_BYTE;
    if ( $bytealign and $pad != 0 ) {
        $data   = ( '0' x $pad ) . $data;
        $length = length $data;
    }

    if ( $length == $BITS_PER_BYTE and $self->{last_byte} eq q{} ) {
        $self->{data} .= pack 'B*', $data;
        return;
    }

    while ( $length > 0 ) {
        my $buflen = $BITS_PER_BYTE - length $self->{last_byte};
        if ( $length >= $buflen ) {
            $self->{last_byte} .= substr $data, 0, $buflen;
            $length -= $buflen;
            $data = substr $data, $buflen;
            $self->{data} .= pack 'B*', $self->{last_byte};
            $self->{last_byte} = q{};
        }
        else {
            $self->{last_byte} .= $data;

            if ( length( $self->{last_byte} ) == $BITS_PER_BYTE ) {
                $self->{data} .= pack 'B*', $self->{last_byte};
                $self->{last_byte} = q{};
            }

            $length = 0;
        }
    }
    return;
}

sub write_run {
    my ( $self, $data, $length ) = @_;
    if ( $length == 0 ) {
        return;
    }
    $self->write( $data x $length );
    return;
}

sub pad_to_byte_boundary {
    my ($self) = @_;
    if ( length $self->{last_byte} > 0 ) {
        $self->write_run( '0', $BITS_PER_BYTE - length $self->{last_byte} );
    }
    return;
}
1;
