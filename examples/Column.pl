use warnings;
use strict;
use PDF::Builder;

my $name = 'Column';
my $pdf = PDF::Builder->new();
my $content;
my ($page, $text, $grfx);

my $magenta = '#ff00ff';
my $fs = 15;
my ($rc, $next_y, $unused);

print STDERR "======================================================= pg 1\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

print STDERR "single string entries";
$text->column($text, $grfx, 'none', 
	      "This is a single string text.\n\nWith two paragraphs.", 
	      'rect'=>[50,750, 500,50], 'outline'=>$magenta);

$text->column($text, $grfx, 'md1', 
	      "This is a _single string_ **MD** text.\n\nIt should have two paragraphs.", 
	      'rect'=>[50,650, 500,50], 'outline'=>$magenta);

$text->column($text, $grfx, 'html', 
	      "<p>This is a <i>single <b>string</b></i> HTML text.</p><p>With two paragraphs.</p>", 
	      'rect'=>[50,550, 500,50], 'outline'=>$magenta);

print STDERR "array of string entries\n";
# should be two paragraphs, as a new array element starts a new paragraph
$text->column($text, $grfx, 'none', 
	      ["This is an array.","Of single string texts. Two paragraphs."], 
	      'rect'=>[50,450, 500,50], 'outline'=>$magenta);

$text->column($text, $grfx, 'md1', 
	      ["This is an **array**\n \n","Of single _string_ MD texts, two paragraphs."], 
	      'rect'=>[50,350, 500,50], 'outline'=>$magenta);

$text->column($text, $grfx, 'html', 
	      ['<p>This is an <b>array</b></p>','<p>of single <i>string</i> HTML texts. Two paragraphs.</p>'], 
	      'rect'=>[50,250, 500,50], 'outline'=>$magenta);

print STDERR "pre array of hashes\n";
$text->column($text, $grfx, 'pre', [
	{'text'=>'', 'tag'=>'style' }, # dummy style tag
	{'text'=>'', 'tag'=>'p'},
	{'text'=>'This is an array', 'tag'=>''},
	{'text'=>'', 'tag'=>'/p'},
	{'text'=>'', 'tag'=>'p'},
	{'text'=>'of single string hashes.', 'tag'=>''},
	{'text'=>'', 'tag'=>'/p'},
	{'text'=>'', 'tag'=>'p'},
	{'text'=>'With ', 'tag'=>''},
	{'text'=>'', 'tag'=>'b'},
	{'text'=>'some ', 'tag'=>''},
	{'text'=>'', 'tag'=>'/b'},
	{'text'=>'', 'tag'=>'i'},
	{'text'=>'markup', 'tag'=>''},
	{'text'=>'', 'tag'=>'b'},
	{'text'=>'!', 'tag'=>''},
	{'text'=>'', 'tag'=>'/b'},
	{'text'=>'', 'tag'=>'/i'},
	{'text'=>'', 'tag'=>'/p'},
], 'rect'=>[50,150, 500,50], 'outline'=>$magenta);

# larger font size and narrower columns to force line wraps
print STDERR "======================================================= pg 2\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

print STDERR "single string entries\n";
multicol($text, $grfx, 'none', 
	 "This is a single string text.\n\nWith two paragraphs.", 
	 [50,750, 50,50], $magenta, $fs);

multicol($text, $grfx, 'md1', 
	 "This is a _single string_ **MD** text.\n\nIt should have two paragraphs.", 
	 [50,650, 50,50], $magenta, $fs);

multicol($text, $grfx, 'html', 
	 "<p>This is a <i>single <b>string</b></i> HTML text.</p><p>Two paragraphs.</p>", 
	 [50,550, 50,50], $magenta, $fs);

print STDERR "array of string entries\n";
# should be two paragraphs, as a new array element starts a new paragraph
multicol($text, $grfx, 'none', 
         ["This is an array","Of single string texts. Two paragraphs."], 
	 [50,450, 50,50], $magenta, $fs);

# would be glued together into one line, except there is a blank line in middle
multicol($text, $grfx, 'md1', 
         ["This is an **array**\n\n","Of single _string_ MD texts. Two paragraphs.\n"], 
	 [50,350, 50,50], $magenta, $fs);

# explicitly have two paragraphs
multicol($text, $grfx, 'html', 
	 ["<p>This is an <b>array</b></p>\n","<p>Of single <i>string</i> HTML texts. Two paragraphs.</p>\n"], 
	 [50,250, 50,50], $magenta, $fs);

print STDERR "pre array of hashes\n";
multicol($text, $grfx, 'pre', [
	{'text'=>'', 'tag'=>'style' }, # dummy style tag
	{'text'=>'', 'tag'=>'p'},
	{'text'=>'This is an array', 'tag'=>''},
	{'text'=>'', 'tag'=>'/p'},
	{'text'=>'', 'tag'=>'p'},
	{'text'=>'Of single string hashes.', 'tag'=>''},
	{'text'=>'', 'tag'=>'/p'},
	{'text'=>'', 'tag'=>'p'},
	{'text'=>'With ', 'tag'=>''},
	{'text'=>'', 'tag'=>'b'},
	{'text'=>'some ', 'tag'=>''},
	{'text'=>'', 'tag'=>'/b'},
	{'text'=>'', 'tag'=>'i'},
	{'text'=>'markup', 'tag'=>''},
	{'text'=>'', 'tag'=>'b'},
	{'text'=>'!', 'tag'=>''},
	{'text'=>'', 'tag'=>'/b'},
	{'text'=>'', 'tag'=>'/i'},
	{'text'=>'', 'tag'=>'/p'},
    ], [50,150, 50,50], $magenta, $fs);

# let's try some large sample MD and HTML
print STDERR "======================================================= pg 3\n";
#
# Lorem Ipsum text ('none') in mix of single string and array
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

# as an array of strings
my @ALoremIpsum = (
"Sed ut perspiciatis, unde omnis iste natus error sit 
voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, 
quae ab illo inventore veritatis et quasi architecto beatae vitae dicta 
sunt, explicabo. Nemo enim ipsam voluptatem, quia voluptas sit, aspernatur 
aut odit aut fugit, sed quia consequuntur magni dolores eos, qui ratione 
dolor sit, voluptatem sequi nesciunt, neque porro quisquam est, qui dolorem 
ipsum, quia amet, consectetur, adipisci velit, sed quia non numquam eius 
modi tempora incidunt, ut labore et dolore magnam aliquam quaerat 
voluptatem.
",
"Ut enim ad minima veniam, quis nostrum exercitationem ullam 
corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? 
Quis autem vel eum iure reprehenderit, qui in ea voluptate velit esse, quam 
nihil molestiae consequatur, vel illum, qui dolorem eum fugiat, quo voluptas 
nulla pariatur?

At vero eos et accusamus et iusto odio dignissimos ducimus, 
qui blanditiis praesentium voluptatum deleniti atque corrupti, quos dolores 
et quas molestias excepturi sint, obcaecati cupiditate non provident, 
similique sunt in culpa, qui officia deserunt mollitia animi, id est laborum 
et dolorum fuga.


",
"Et harum quidem rerum facilis est et expedita distinctio. 
Nam libero tempore, cum soluta nobis est eligendi optio, cumque nihil 
impedit, quo minus id, quod maxime placeat, facere possimus, omnis voluptas 
assumenda est, omnis dolor repellendus.

",  	 
"Temporibus autem quibusdam et aut 
officiis debitis aut rerum necessitatibus saepe eveniet, ut et voluptates 
repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur 
a sapiente delectus, ut aut reiciendis voluptatibus maiores alias 
consequatur aut perferendis doloribus asperiores repellat.
"
);
my $SLoremIpsum = join("\n",@ALoremIpsum);

print STDERR "Lorem Ipsum array of string entries\n";
# default paragraph indent and top margin
($rc, $next_y, $unused) =
    $text->column($text, $grfx, 'none', \@ALoremIpsum, 'rect'=>[50,750, 500,300], 'outline'=>$magenta );
if ($rc) { 
    print STDERR "Lorem Ipsum array overflowed the column!\n";
}
print STDERR "Lorem Ipsum string entry\n";
# no indent, extra top margin
($rc, $next_y, $unused) =
    $text->column($text, $grfx, 'none', $SLoremIpsum, 'rect'=>[50,350, 500,300], 'outline'=>$magenta, 'para'=>[ 0, 5 ] );
if ($rc) { 
    print STDERR "Lorem Ipsum string overflowed the column!\n";
}

# customer sample Markdown
print STDERR "======================================================= pg 4\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();
$content = <<"END_OF_CONTENT";
Example of Markdown that needs to be supported in document text blocks. There is no need to support this within tables, although it would be a "nice" feature.

Firstly just some simple styling: *italics*, **bold** and ***both***.

There should also be support for _alternative italics_

Then a bulleted list:

* Unordered item
* Another unordered item

And a numbered list:

1. Item one
2. Item two

# We will need a heading

## And a subheading

Finally we&#x92;ll need some [external links](https://duckduckgo.com).

Then we need some styling features in tables as shown in the table below. There is no need to support this in text blocks, although it would be a nice feature (colored text is already available in text blocks using its options).
END_OF_CONTENT

#print STDERR "Customer sample MD + table\n";
($rc, $next_y, $unused) =
    $text->column($text, $grfx, 'md1', 
	          $content, 
		  'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>[ 0, 5 ] );
if ($rc) { 
    print STDERR "Sample Markdown overflowed the column!\n";
}

# customer sample HTML
# fake a table so that PDF::Table is not required within PDF::Builder examples!
# "table" 2 x 2 width 500, padding 5, font size 12, draw borders and rules
$next_y -= 25; # gap to table
# do 6 cells as 6 small columns in 2x3 grid
    $text->column($text, $grfx, 'html', 
	          "<font color=\"red\">This is some red text</font>", 
		  'rect'=>[55,$next_y-5, 240,20], 'para'=>[ 0, 0 ], 
		  'font_size'=>12, 'para'=>[ 0, 0 ] );
    $text->column($text, $grfx, 'html', 
	          "<span style=\"color:green\">This is some green text</span>", 
		  'rect'=>[305,$next_y-5, 240,20], 'para'=>[ 0, 0 ], 
		  'font_size'=>12, 'para'=>[ 0, 0 ] );
    $text->column($text, $grfx, 'html', 
	          "This is a cross: <font face=\"ZapfDingbats\" color=\"red\">&#56;</font>.", 
		  'rect'=>[55,$next_y-25, 240,20], 'para'=>[ 0, 0 ], 
		  'font_size'=>12, 'para'=>[ 0, 0 ] );
    $text->column($text, $grfx, 'html', 
	          "This is a tick: <span style=\"font-family:ZapfDingbats; color:green\">&#52;</span>.", 
		  'rect'=>[305,$next_y-25, 240,20], 'para'=>[ 0, 0 ], 
		  'font_size'=>12, 'para'=>[ 0, 0 ] );
    # illustrate text/HTML substitution
    $text->column($text, $grfx, 'md1', 
	          "This is a red cross: |cross|.", 
		  'rect'=>[55,$next_y-45, 240,20], 'para'=>[ 0, 0 ], 
		  'font_size'=>12, 'para'=>[ 0, 0 ], 
		  'substitute'=>[['|cross|','<font face="ZapfDingbats" color="red">', '8', '</font>'],['|tick|','<span style="font-family: ZapfDingbats; color: green;">', '4', '</font>']]);
    $text->column($text, $grfx, 'html', 
	          "This is a green tick: |tick|.", 
		  'rect'=>[305,$next_y-45, 240,20], 'para'=>[ 0, 0 ], 
		  'font_size'=>12, 'para'=>[ 0, 0 ], 
		  'substitute'=>[['|cross|','<font face="ZapfDingbats" color="red">', '8', '</font>'],['|tick|','<span style="font-family: ZapfDingbats; color: green;">', '4', '</font>']]);

# draw border and rules
$grfx->poly(50,$next_y, 550,$next_y, 550,$next_y-60, 50,$next_y-60, 50,$next_y);
$grfx->move(50,$next_y-20);
$grfx->hline(550);
$grfx->move(50,$next_y-40);
$grfx->hline(550);
$grfx->move(300,$next_y);
$grfx->vline($next_y-60);
$grfx->strokecolor('black');
$grfx->stroke();

# more pages with more extensive MD
print STDERR "======================================================= pg 5+\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();
#  might need two or even three pages
$content = <<"END_OF_CONTENT";
# PDF::Builder

`A Perl library to facilitate &#x74;he creation and <span style="color: red;">modification</span> of PDF files`

This archive contains &#x74;he <span style="color: green;">distribution</span> PDF::Builder.
See **Changes** file for the version.

## Obtaining the Package

The installable Perl package may be obtained from
"https://metacpan.org/pod/PDF::Builder", or via a CPAN installer package. If
you install this product, only the run-time modules will be installed. Download
the full `.tar.gz` file and unpack it (hint: on Windows,
**7-Zip File Manager** is an excellent tool) to get utilities, test buckets,
example usage, etc.

Alternatively, you can obtain the full source files from
"https://github.com/PhilterPaper/Perl-PDF-Builder", where the ticket list
(bugs, enhancement requests, etc.) is also kept. Unlike the installable CPAN
version, this will have to be manually installed (copy files; there are no XS
compiles at this time).

Note that there are several "optional" libraries (Perl modules) used to extend
and improve PDF::Builder. Read about the list of optional libraries in
PDF::Builder::Docs, and decide whether or not you want to install any of them.
By default, all are installed (as "recommended", so failure to install will
not fail the overall PDF::Builder installation). You may choose which ones to
install by modifying certain installation files with 
"tools/optional\_update.pl".

## Requirements

### Perl

**Perl 5.24** or higher. It will likely run on somewhat earlier versions, but
the CPAN installer may refuse to install it. The reason this version was
chosen was so that LTS (Long Term Support) versions of Perl going back about
6 years are officially supported (by PDF::Builder), and older versions are not
supported. The intent is to not waste time and effort trying to fix bugs which
are an artifact of old Perl releases.

#### Older Perls

If you MUST install on an older (pre 5.24) Perl, you can try the following for
Strawberry Perl (Windows). NO PROMISES! Something similar MAY work for other
OS's and Perl installations:

1. Unpack installation file (`.tar.gz`, via a utility such as 7-Zip) into a directory, and cd to that directory
1. Edit META.json and change 5.024000 to 5.016000 or whatever level desired
1. Edit META.yml and change 5.024000 to 5.016000 or whatever level desired
1. Edit Makefile.PL and change `use 5.024000;` to `use 5.016000;`, change `\$PERL_version` from `5.024000` to `5.016000`
1. `cpan .`

Note that some Perl installers MAY have a means to override or suppress the
Perl version check. That may be easier to use. Or, you may have to repack the
edited directory back into a `.tar.gz` installable. YMMV.

If all goes well, PDF::Builder will be installed on your system. Whether or
not it will RUN is another matter. Please do NOT open a bug report (ticket)
unless you're absolutely sure that the problem is not a result of using an old
Perl release, e.g., PDF::Builder is using a feature introduced in Perl 5.008
and you're trying to run Perl 5.002!

### Libraries used

These libraries are available from CPAN.

#### REQUIRED

These libraries should be automatically installed...

* Compress::Zlib
* Font::TTF
* Test::Exception (needed only for installation tests)
* Test::Memory::Cycle (needed only for installation tests)

#### OPTIONAL

These libraries are _recommended_ for improved functionality and performance.
The default behavior is to attempt to install all of them during PDF::Builder
installation. If you use tools/optional\_update.pl to _not_ to install any of
them, or they fail to install automatically, you can always manually install 
them later.

* Graphics::TIFF (recommended if using TIFF image functions)
* Image::PNG::Libpng (recommended for enhanced PNG image function processing)
* HarfBuzz::Shaper (recommended for Latin script ligatures and kerning, as well as for any complex script such as Arabic, Indic scripts, or Khmer)

Other than an installer for standard CPAN packages (such as 'cpan' on
Strawberry Perl for Windows), no other tools or manually-installed prereqs are
needed (worst case, you can unpack the `.tar.gz` file and copy files into
place yourself!). Currently there are no compiles and links (Perl extensions)
done during the install process, only copying of .pm Perl module files.

## Manually building

As is the usual practice with building such a package (from the command line), 
the steps are:

1. perl Makefile.PL
1. make
1. make test
1. make install

If you have your system configured to run Perl for a .pl/.PL file, you may be 
able to omit "perl" from the first command, which creates a Makefile. "make" 
is the generic command to run (it feeds on the Makefile), but your system may 
have it under a different name, such as dmake (Strawberry Perl on Windows), 
gmake, or nmake.

PDF::Builder does not currently compile and link anything, so gcc, g++, etc.
will not be used. The build process merely copies .pm files around.

## Copyright

This software is Copyright (c) 2017-2022 by Phil M. Perry.

Previous copyrights are held by others (Steve Simms, Alfred Reibenschuh, et al.). See The HISTORY section of the documentation for more information.

## License

This is free software, licensed under:

`The GNU Lesser General Public License, Version 2.1, February 1999`

EXCEPT for some files which are explicitly under other, compatible, licenses
(the Perl License and the MIT License). You are permitted (at your option) to
redistribute and/or modify this software (those portions under LGPL) at an
LGPL version greater than 2.1. See INFO/LICENSE for more information on the
licenses and warranty statement.

## See Also

* INFO/RoadMap file for the PDF::Builder road map
* CONTRIBUTING file for how to contribute to the project
* LICENSE file for more on the license term
* INFO/SUPPORT file for information on reporting bugs, etc. via GitHub Issues 
* INFO/DEPRECATED file for information on deprecated features
* INFO/KNOWN\_INCOMP file for known incompatibilities with PDF::API2
* INFO/CONVERSION file for how to convert from PDF::API2 to PDF::Builder
* INFO/Changes\* files for older change logs
* INFO/PATENTS file for information on patents

`INFO/old/` also has some build and test tool files that are not currently used.

## Documentation

To build the full HTML documentation (all the POD), get the full installation
and go to the `docs/` directory. Run `buildDoc.pl --all` to generate the full
tree of documentation. There's a lot of additional information in the
PDF::Builder::Docs module (it's all documentation).

We admit that the documentation is a bit light on "how to" task orientation.
We hope to more fully address this in the future, but for now, get the full
installation and look at the `examples/` and `contrib/` directories for sample
code that may help you figure out how to do things. The installation tests in
the `t/` directory might also be useful to you.
END_OF_CONTENT

($rc, $next_y, $unused) =
    $text->column($text, $grfx, 'md1', $content, 'rect'=>[50,750, 500,700], 'outline'=>$magenta, 'para'=>[ 0, 0 ] );
while ($rc) { 
    # new page
    $page = $pdf->page();
    $text = $page->text();
    $grfx = $page->gfx();

    ($rc, $next_y, $unused) =
        $text->column($text, $grfx, 'pre', $unused, 'rect'=>[50,750, 500,700], 'outline'=>$magenta, 'para'=>[ 0, 0 ] );
}

sub multicol {
    my ($text, $grfx, $markup, $content, $rect, $outline, $fs) = @_;

    my ($rc, $start_y);

if (ref($content) eq '') {
print STDERR "multicol has 1 array elements ($content) to column\n";
} else {
print STDERR "multicol has ".(@$content)." array elements to column\n";
}
    ($rc, $start_y, $content) = 
        $text->column($text, $grfx, $markup, $content, 'rect'=>$rect, 'outline'=>$magenta, 'font_size'=>$fs);
print STDERR "    first column ends with rc=$rc, start_y=$start_y, content size=".(@$content)."\n";
    while ($rc == 1) { # ran out of column, do another
print STDERR "  ran out of column, do another\n";
#pause();
	$rect->[0] += 50+$rect->[2];
        ($rc, $start_y, $content) = 
            $text->column($text, $grfx, 'pre', $content, 'rect'=>$rect, 'outline'=>$magenta, 'font_size'=>$fs);
print STDERR "    next column ends with rc=$rc, start_y=$start_y, content size=".(@$content)."\n";
    }
}

$pdf->saveas("$name.pdf");

# pause during debug
sub pause {
    print STDERR "=====> Press Enter key to continue...";
    my $input = <>;
    return;
}
