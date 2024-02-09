#!/usr/bin/perl
#
use warnings;
use strict;
use PDF::Builder;
#use Data::Dumper; # for debugging
# $Data::Dumper::Sortkeys = 1; # hash keys in sorted order

# VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

#my $pdf = PDF::Builder->new();
my $pdf = PDF::Builder->new('compress'=>'none');
my $content;
my ($page, $text, $grfx);

my $name = $0;
$name =~ s/\.pl/.pdf/; # write in examples directory

my $magenta = '#ff00ff';
my $fs = 15;
my ($rc, $next_y, $unused);

print "======================================================= pg 1\n";
print "---- A variety of lists\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

$content = <<"END_OF_CONTENT";
<h2>Unordered (bulleted) lists with various markers</h2>
<ul> <!-- default disc -->
  <li>Unordered 1A, disc and here is a bunch more text to try to cause a spill to a second line. Looks like we need a bit more filler here.</li>
  <li>Unordered 1B
  <ul> <!-- default circle -->
    <li>Unordered 2A, circle</li>
    <li>Unordered 2B and here is a bunch more text to try to cause a spill to a second line. Looks like we need a bit more filler here.
    <ul> <!-- default (filled) square -->
      <li>Unordered 3A, square</li>
      <li>Unordered 3B
      <ul style="list-style-type: box"> <!-- box (open square) -->
        <li>Unordered 4A, box. A &ldquo;box&rdquo; marker is non-standard &mdash; it is an empty square marker. A bit more filler here. How about a <i>lot</i> more, driving it to three lines in all? Oh yeah, that's the ticket!</li>
        <li>Unordered 4B
        <ul style="list-style-type: disc"> <!-- and back to disc -->
          <li>Unordered 5A, disc</li>
          <li>Unordered 5B</li>
	</ul>
	<ul> <!-- default (filled) square) -->
          <li>Unordered 6A, square</li>
          <li>Unordered 6B</li>
	</ul></li>
      </ul></li>
    </ul></li>
  </ul></li>
</ul>

<h2>Ordered (numbered) lists with various markers</h2>
<ol> <!-- default decimal -->
  <li>Ordered 1A, decimal 1., 2.</li>
  <li>Ordered 1B
  <ol style="list-style-type: upper-roman"> <!-- I, II, III, IV -->
    <li>Ordered 2A, upper-roman I., II.</li>
    <li>Ordered 2B
    <ol style="list-style-type: upper-alpha"> <!-- A, B, C, D -->
      <li>Ordered 3A, upper-alpha A., B.</li>
      <li>Ordered 3B
      <ol style="list-style-type: lower-roman"> <!-- i, ii, iii, iv -->
        <li>Ordered 4A, lower-roman i., ii.</li>
        <li>Ordered 4B
        <ol style="list-style-type: lower-alpha"> <!-- a, b, c, d -->
          <li>Ordered 5A lower-alpha a., b.</li>
          <li>Ordered 5B</li>
	</ol>
        <ol> <!-- default decimal -->
          <li>Ordered 6A, decimal 1., 2.</li>
          <li>Ordered 6B</li>
	</ol></li>
      </ol></li>
    </ol></li>
  </ol></li>
</ol>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
if ($rc) {
    print STDERR "list example overflowed column!\n";
}

print "======================================================= pg 2\n";
print "---- More list examples\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

$content = <<"END_OF_CONTENT";
<h2>Mixture of ordered and unordered with default markers</h2>
<ol> <!-- default decimal -->
  <li>Ordered 1A, decimal 1., 2.</li>
  <li>Ordered 1B
  <ul> <!-- default circle -->
    <li>Unordered 2A, circle</li>
    <li>Unordered 2B
    <ol> <!-- default decimal -->
      <li>Ordered 3A, decimal 1., 2.</li>
      <li>Ordered 3B
      <ul> <!-- default (filled) square -->
        <li>Unordered 4A, square</li>
        <li>Unordered 4B
        <ol> <!-- default decimal -->
          <li>Ordered 5A, decimal 1., 2.</li>
          <li>Ordered 5B</li>
	</ol>
        <ul> <!-- default (filled) square -->
          <li>Unordered 6A, square</li>
          <li>Unordered 6B</li>
	</ul></li>
      </ul></li>
    </ol></li>
  </ul></li>
</ol>

<!-- TBD position inside/outside
<h2>list-style-position inside and outside, with multiline li's</h2>
-->
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,450], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
if ($rc) {
    print STDERR "list example overflowed column!\n";
}

# try nesting in Markdown
$content = <<"END_OF_CONTENT";
## Try nested Markdown entries (manually indent items)

1. This is a numbered list unnested.
2. This is another item in the numbered list.
   - This is a first nested level bulleted list.
     - This is a further nested bulleted list.
     - And a second item.
   - Back to first nested level bulleted list
3. One last numbered list item
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,250, 500,200], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
if ($rc) {
    print STDERR "list example overflowed column!\n";
}

# Counting down (reversed) ordered lists
print "======================================================= pg 3\n";
print "---- Count down list examples\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

$content = <<"END_OF_CONTENT";
<h2>Test reversed ordered lists</h2>
<ol reversed="1" start="10">
  <li>ten</li>
  <li>nine</li>
  <li>eight</li>
  <li>seven</li>
  <li>six</li>
  <li>five
  <ol>
    <li>holding</li>
    <li>resume countdown</li>
  </ol></li>
  <li>four</li>
  <li>three</li>
  <li>two</li>
  <li>one</li>
</ol>
<h2>Reversed ordered list run past 1</h2>
<ol reversed="1" start="3">
  <li>three</li>
  <li>two</li>
  <li>one</li>
  <li>zero... blast off!</li>
  <li>minus one... the clock is running</li>
</ol>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,450], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
if ($rc) {
    print STDERR "list example overflowed column!\n";
}

# ---------------------------------------------------------------------------
# end of program
$pdf->saveas($name);
# -----------------------

# pause during debug
sub pause {
    print STDERR "=====> Press Enter key to continue...";
    my $input = <>;
    return;
}

#   restore font and color in case previous column left it in an odd state.
#   the default behavior is to use whatever font and color was left from any
#     previous operation (not necessarily a column() call) unless it was 
#     overridden by various settings.
sub restore_props {
    my ($text, $grfx) = @_;

#   $text->fillcolor('black');
#   $grfx->strokecolor('black');
    # italic and bold get reset to 'normal' anyway on column() entry,
    # but need to fix font face in case it was left something odd
#   $text->font($pdf->get_font('face'=>'default', 'italic'=>0, 'bold'=>0), 12);

    return;
}
