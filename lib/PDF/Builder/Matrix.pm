#=======================================================================
#
#   PDF::Builder::Matrix
#   Original Copyright 1995-96 Ulrich Pfeifer.
#   modified by Alfred Reibenschuh <areibens@cpan.org> for PDF::API2
#
#   This library is free software; you can redistribute it
#   and/or modify it under the same terms as Perl itself.
#
#   NOTE: PDF::API2 has completely removed this license statement. I'm
#   not ready to do that yet, until the whole non-LGPL license issue is
#   straightened out!
#
#=======================================================================
package PDF::Builder::Matrix;

use strict;
use warnings;
use Carp;

# VERSION
my $LAST_UPDATE = '3.020'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Matrix - matrix operations library

=cut

sub new {
    my $type = shift();

    my $self = [];
    my $col_count = scalar(@{$_[0]});
    foreach my $row (@_) {
        unless (scalar(@$row) == $col_count) {
	    carp 'Inconsistent column count in matrix';
	    return;
        }
        push(@{$self}, [@$row]);
    }

    return bless($self, $type);
}

# internal routine
sub transpose {
    my $self = shift();

    my @result;
    my $m;

    for my $col (@{$self->[0]}) {
        push @result, [];
    }
    for my $row (@$self) {
        $m = 0;
        for my $col (@$row) {
            push @{$result[$m++]}, $col;
        }
    }

    return PDF::Builder::Matrix->new(@result);
}

# internal routine
sub vector_product {
    my ($a, $b) = @_;
    my $result = 0;

    for my $i (0 .. $#{$a}) {
        $result += $a->[$i] * $b->[$i];
    }

    return $result;
}

# used by Content.pm
sub multiply {
    my $self  = shift();
    my $other = shift->transpose();

    my @result;

    unless ($#{$self->[0]} == $#{$other->[0]}) {
	carp 'Mismatched dimensions in matrix multiplication';
	return;
    }
    for my $row (@$self) {
        my $result_col = [];
        for my $col (@$other) {
            push @$result_col, vector_product($row,$col);
        }
        push @result, $result_col;
    }

    return PDF::Builder::Matrix->new(@result);
}

1;
