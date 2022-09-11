#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 34;

use PDF::Builder;

my $pdf = PDF::Builder->new('-compress' => 'none');
my $page1 = $pdf->page();
my $page2 = $pdf->page();

my $outlines = $pdf->outlines();
my $outline = $outlines->outline();
$outline->title('Test Outline');
$outline->dest($page2);

like($pdf->to_string, qr{/Dest \[ 6 0 R /XYZ null null null \] /Parent 7 0 R /Title \(Test Outline\)},
     q{Basic outline test});

$pdf = PDF::Builder->new(compress => 0);
$page1 = $pdf->page();
$page2 = $pdf->page();
$outlines = $pdf->outlines();
$outline = $outlines->outline();
$outline->title('Test Outline');
$outline->dest($page2);

is($outlines->count(), 1,
   q{Outline tree has one entry});

$outline->delete();
is($outlines->count(), 0,
   q{Outline tree has no entries after sole entry is deleted});

ok(!$outlines->has_children(),
   q{has_children returns false when the sole item is deleted});

my $aa = $outlines->outline();
my $bb = $outlines->outline();
my $cc = $outlines->outline();

$aa->title('Test Outline');

is($outlines->count(), 3,
   q{Outline tree has three entries});

is($outlines->first(), $aa,
   q{$outlines->first() returns the first item});

is($outlines->first->next(), $bb,
   q{$outlines->first->next() returns the second item});

is($outlines->last(), $cc,
   q{$outlines->last() returns the final item});

is($outlines->last->prev(), $bb,
   q{$outlines->last->prev() returns the second item});

my $dd = $aa->outline();

is($outlines->count(), 4,
   q{Outline count includes grandchild});

my $ee = $dd->outline();

is($outlines->count(), 5,
   q{Outline count includes great-grandchild});

$dd->is_open(0);

is($outlines->count(), 4,
   q{Outline count doesn't include children of closed children});

is($dd->count(), 1,
   q{$outline->count() is still positive when closed});

$dd->count();
is($dd->{'Count'}->val(), -1,
   q{... but the Count key is negative when closed});

$pdf = PDF::Builder->from_string($pdf->to_string());
$outlines = $pdf->outlines();

is($outlines->count(), 4,
   q{Opened PDF returns expected item count});

ok($outlines->first->is_open(),
   q{Opened PDF returns expected is_open result for open item});

ok(!$outlines->first->first->is_open(),
   q{Opened PDF returns expected is_open result for closed item});

is($outlines->first->title(), 'Test Outline',
   q{$outline->title() returns expected value from opened PDF});

$pdf = PDF::Builder->new(compress => 0);
$page1 = $pdf->page();
$page2 = $pdf->page();
$outlines = $pdf->outlines();

$aa = $outlines->outline();
$bb = $outlines->outline();
$cc = $outlines->outline();
$dd = $aa->insert_after();

is($outlines->count(), 4,
   q{3x insert + insert_after = 4 items});

$ee = $cc->insert_before();

is($outlines->count(), 5,
   q{3x insert + insert_after + insert_before = 5 items});

is($aa->next(), $dd,
   q{$insert->insert_after() sets $insert->next()});

is($dd->prev(), $aa,
   q{$insert->insert_after() sets $sibling->prev()});

is($bb->prev(), $dd,
   q{$insert->insert_after() sets $insert->next->prev()});

is($dd->next(), $bb,
   q{$insert->insert_after() sets $sibling->next()});

is($cc->prev(), $ee,
   q{$insert->insert_before() sets $insert->prev()});

is($ee->next(), $cc,
   q{$insert->insert_before() sets $sibling->next()});

is($bb->next(), $ee,
   q{$insert->insert_before() sets $insert->prev->next()});

is($ee->prev(), $bb,
   q{$insert->insert_before() sets $sibling->prev()});

my $ff = $aa->insert_before();

is($aa->prev(), $ff,
   q{$item->insert_before() on first item sets $item->prev()});

is($ff->next(), $aa,
   q{$item->insert_before() on first item sets $sibling->next()});

ok(!$ff->prev(),
   q{$item->insert_before() on first item doesn't set $sibling->prev()});

my $gg = $cc->insert_after();

is($cc->next(), $gg,
   q{$item->insert_after() on last item sets $item->next()});

is($gg->prev(), $cc,
   q{$item->insert_after() on last item sets $sibling->prev()});

ok(!$gg->next(),
   q{$item->insert_after() on last item doesn't set $sibling->next()});

done_testing();

1;
