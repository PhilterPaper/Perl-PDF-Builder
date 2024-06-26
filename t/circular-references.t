#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use PDF::Builder;
use Scalar::Util qw(isweak);
use Test::Memory::Cycle;

# RT #56681: Devel::Cycle throws spurious warnings since 5.12
local $SIG{'__WARN__'} = sub { warn $_[0] unless $_[0] =~ /Unhandled type: GLOB/ };

# (1) Read a simple PDF

my $pdf = PDF::Builder->open('t/resources/sample.pdf');
memory_cycle_ok($pdf, q{Open sample.pdf});

# TODO: Create a sample PDF that uses as much PDF::Builder functionality as
# possible (outlines and annotations in particular) to build confidence that all
# circular references have been removed.

# Check pagestack weakened status

my $page = $pdf->page();
ok(isweak($pdf->{'pagestack'}->[-1]),
   q{An appended page is marked as weakened in the page stack});

$page = $pdf->page(1);
ok(isweak($pdf->{'pagestack'}->[0]),
   q{A prepended page is marked as weakened in the page stack});

$page = $pdf->page(1);
ok(isweak($pdf->{'pagestack'}->[1]),
   q{A spliced page is marked as weakened in the page stack});

# Font out of scope

{
    $pdf->corefont('Helvetica');
}

lives_ok(sub { $pdf->to_string() }, 'Font added inside a block is still present on save');

done_testing();

1;
