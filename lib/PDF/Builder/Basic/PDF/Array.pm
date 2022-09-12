#=======================================================================
#
#   THIS IS A REUSED PERL MODULE, FOR PROPER LICENCING TERMS SEE BELOW:
#
#   Copyright Martin Hosken <Martin_Hosken@sil.org>
#
#   No warranty or expression of effectiveness, least of all regarding
#   anyone's safety, is implied in this software or documentation.
#
#   This specific module is licensed under the Perl Artistic License.
#   Effective 28 January 2021, the original author and copyright holder, 
#   Martin Hosken, has given permission to use and redistribute this module 
#   under the MIT license.
#
#=======================================================================
package PDF::Builder::Basic::PDF::Array;

use base 'PDF::Builder::Basic::PDF::Objind';

use strict;
use warnings;

# VERSION
my $LAST_UPDATE = '3.024'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Basic::PDF::Array - Corresponds to a PDF array. 
Inherits from L<PDF::Builder::Basic::PDF::Objind>

=head1 METHODS

=over

=item PDF::Array->new($parent, @values)

Creates an array with the given storage parent and an optional list of values to
initialise the array with.

=cut

sub new {
    my ($class, @values) = @_;
    my $self = {};

    $self->{' val'} = [@values];
    $self->{' realised'} = 1;
    bless $self, $class;
    return $self;
}

=item $a->outobjdeep($fh, $pdf)

Outputs an array as a PDF array to the given filehandle.

=cut

sub outobjdeep {
    my ($self, $fh, $pdf) = @_;

    $fh->print('[ ');
    foreach my $obj (@{$self->{' val'}}) {
        $obj->outobj($fh, $pdf);
        $fh->print(' ');
    }
    $fh->print(']');
    return;
}

=item $a->elements()

Returns the contents of the array.

Formerly called C<elementsof>, which is now B<deprecated>.

=cut

sub elementsof { return elements(@_); }

sub elements {
    my $self = shift();
    return @{$self->{' val'}};
}

=item $a->add_elements(@elements)

Appends the given elements to the array. An element is only added if it
is defined.

=cut

sub add_elements {
    my $self = shift();

    foreach my $element (@_) {
	    next unless defined $element;
        push @{$self->{' val'}}, $element;
    }
    return $self;
}

=item $a->remove_element($element)

Removes all occurrences of an element from an array.

Formerly called C<removeobj>, which is now B<deprecated> and will be removed.

=cut

# not listed as deprecated, not used internally, should not have been
# used in external code. remove after July 2021.
sub removeobj { return remove_element(@_); }

sub remove_element {
    my ($self, $element) = @_;

    $self->{' val'} = [ grep { $_ ne $element } @{$self->{' val'}} ];
    return $self;
}

=item $a->val()

Returns a reference to the contents of the array.

=cut

sub val {
    return $_[0]->{' val'};
}

=item $a->copy($pdf)

Copies the array with deep-copy on elements which are not full PDF objects
with respect to a particular $pdf output context.

=cut

sub copy {
    my ($self, $pdf) = @_;

    my $res = $self->SUPER::copy($pdf);

    $res->{' val'} = [];
    foreach my $e (@{$self->{' val'}}) {
        if (ref($e) and $e->can('is_obj') and not $e->is_obj($pdf)) {
            push @{$res->{' val'}}, $e->copy($pdf);
        } else {
            push @{$res->{' val'}}, $e;
        }
    }
    return $res;
}

=back

=cut

1;
