package PDF::Builder::Resource::CIDFont::TrueType;

use base 'PDF::Builder::Resource::CIDFont';

use strict;
no warnings qw[ deprecated recursion uninitialized ];

# VERSION
my $LAST_UPDATE = '3.016'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Resource::CIDFont::TrueType::FontFile;
use PDF::Builder::Util;

=head1 NAME

PDF::Builder::Resource::CIDFont::TrueType - TrueType font support

=head1 METHODS

=over

=item $font = PDF::Builder::Resource::CIDFont::TrueType->new($pdf, $file, %options)

=item $font = PDF::Builder::Resource::CIDFont::TrueType->new($pdf, $file)

Returns a font object.

Defined Options:

    -encode ... specify fonts encoding for non-UTF-8 text.

    -nosubset ... disables subsetting. Any value causes the full font to be
                  embedded, rather than only the glyphs needed.

=cut

sub new {
    my ($class, $pdf, $file, @opts) = @_;

    my %opts = ();
    %opts = @opts if (scalar @opts)%2 == 0;
    $opts{'-encode'} ||= 'latin1';
    my ($ff, $data) = PDF::Builder::Resource::CIDFont::TrueType::FontFile->new($pdf, $file, @opts);

    $class = ref $class if ref $class;
#   my $self = $class->SUPER::new($pdf, $data->{'apiname'}.pdfkey().'~'.time());
    my $self = $class->SUPER::new($pdf, $data->{'apiname'}.pdfkey());
    $pdf->new_obj($self) if defined($pdf) && !$self->is_obj($pdf);

    $self->{' data'} = $data;

    my $des = $self->descrByData();

    $self->{'BaseFont'} = PDFName($self->fontname());

    my $de = $self->{' de'};

    $de->{'FontDescriptor'} = $des;
    $de->{'Subtype'} = PDFName($self->iscff()? 'CIDFontType0': 'CIDFontType2');
    ## $de->{'BaseFont'} = PDFName(pdfkey().'+'.($self->fontname()).'~'.time());
    $de->{'BaseFont'} = PDFName($self->fontname());
    $de->{'DW'} = PDFNum($self->missingwidth());
    if ($opts{'-noembed'} != 1) {
    	$des->{$self->data()->{'iscff'}? 'FontFile3': 'FontFile2'} = $ff;
    }
    unless ($self->issymbol()) {
        $self->encodeByName($opts{'-encode'});
        $self->data->{'encode'} = $opts{'-encode'};
        $self->data->{'decode'} = 'ident';
    }

    if ($opts{'-nosubset'}) {
        $self->data()->{'nosubset'} = 1;
    }

    $self->{' ff'} = $ff;
    $pdf->new_obj($ff);

    $self->{'-dokern'} = 1 if $opts{'-dokern'};

    return $self;
}

sub fontfile { 
    return $_[0]->{' ff'};
}

sub fontobj {
    return $_[0]->data()->{'obj'};
}

sub wxByCId {
    my ($self, $g) = @_;

    my $t = $self->fontobj()->{'hmtx'}->read()->{'advance'}[$g];
    my $w;

    if (defined $t) {
        $w = int($t *1000/$self->data()->{'upem'});
    } else {
        $w = $self->missingwidth();
    }

    return $w;
}

sub haveKernPairs {
    my $self = shift;

    return $self->fontfile()->haveKernPairs(@_);
}

sub kernPairCid {
    my $self = shift;

    return $self->fontfile()->kernPairCid(@_);
}

sub subsetByCId {
    my $self = shift;

    return if $self->iscff();
    my $g = shift;
    return $self->fontfile()->subsetByCId($g);
}

sub subvec {
    my $self = shift;

    return 1 if $self->iscff();
    my $g = shift;
    return $self->fontfile()->subvec($g);
}

sub glyphNum {
    return $_[0]->fontfile()->glyphNum();
}

sub outobjdeep {
    my ($self, $fh, $pdf) = @_;

    my $notdefbefore = 1;

    my $wx = PDFArray();
    $self->{' de'}->{'W'} = $wx;
    my $ml;

    foreach my $w (0 .. (scalar @{$self->data()->{'g2u'}} - 1 )) {
        if      ($self->subvec($w) && $notdefbefore == 1) {
            $notdefbefore = 0;
            $ml = PDFArray();
            $wx->add_elements(PDFNum($w), $ml);
        #   $ml->add_elements(PDFNum($self->data()->{'wx'}->[$w]));
            $ml->add_elements(PDFNum($self->wxByCId($w)));
        } elsif ($self->subvec($w) && $notdefbefore == 0) {
            $notdefbefore = 0;
        #   $ml->add_elements(PDFNum($self->data()->{'wx'}->[$w]));
            $ml->add_elements(PDFNum($self->wxByCId($w)));
        } else {
            $notdefbefore = 1;
        }
        # optimization for CJK
        #if ($self->subvec($w) && $notdefbefore == 1 && $self->data()->{'wx'}->[$w] != $self->missingwidth()) {
        #    $notdefbefore = 0;
        #    $ml = PDFArray();
        #    $wx->add_elements(PDFNum($w), $ml);
        #    $ml->add_elements(PDFNum($self->data()->{'wx'}->[$w]));
        #} elsif ($self->subvec($w) && $notdefbefore == 0 && $self->data()->{'wx'}->[$w] != $self->missingwidth()) {
        #    $notdefbefore = 0;
        #    $ml->add_elements(PDFNum($self->data()->{'wx'}->[$w]));
        #} else {
        #    $notdefbefore = 1;
        #}
    }

    return $self->SUPER::outobjdeep($fh, $pdf);
}

=back

=cut

1;
