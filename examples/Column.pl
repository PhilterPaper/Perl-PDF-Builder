#!/usr/bin/perl
#
use warnings;
use strict;
use PDF::Builder;
#use Data::Dumper; # for debugging
# $Data::Dumper::Sortkeys = 1; # hash keys in sorted order

# VERSION
our $LAST_UPDATE = '3.024_002'; # manually update whenever code is changed

my $use_Table = 1; # if 1, use PDF::Table for table example

my $pdf = PDF::Builder->new();
my $content;
my ($page, $text, $grfx);

my $name = $0;
$name =~ s/\.pl/.pdf/; # write in examples directory

my $magenta = '#ff00ff';
my $fs = 15;
my ($rc, $next_y, $unused);

#if (0) { ###############
print "======================================================= pg 1\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

print "single string entries\n";
$text->column($page, $text, $grfx, 'none', 
	      "This is a single string text.\n\nWith two paragraphs.", 
	      'rect'=>[50,750, 500,50], 'outline'=>$magenta);

restore_props($text, $grfx);
$text->column($page, $text, $grfx, 'md1', 
	      "This is a _single string_ **MD** text.\n\nIt should have two paragraphs.", 
	      'rect'=>[50,650, 500,50], 'outline'=>$magenta);

restore_props($text, $grfx);
$text->column($page, $text, $grfx, 'html', 
	      "<p>This is a <i>single <b>string</b></i> HTML text.</p><p>With two paragraphs.</p>", 
	      'rect'=>[50,550, 500,50], 'outline'=>$magenta);

print "array of string entries\n";
# should be two paragraphs, as a new array element starts a new paragraph
restore_props($text, $grfx);
$text->column($page, $text, $grfx, 'none', 
	      ["This is an array.","Of single string texts. Two paragraphs."], 
	      'rect'=>[50,450, 500,50], 'outline'=>$magenta);

restore_props($text, $grfx);
$text->column($page, $text, $grfx, 'md1', 
	      ["This is an **array**\n \n","Of single _string_ MD texts, two paragraphs."], 
	      'rect'=>[50,350, 500,50], 'outline'=>$magenta);

restore_props($text, $grfx);
$text->column($page, $text, $grfx, 'html', 
	      ['<p>This is an <b>array</b></p>','<p>of single <i>string</i> HTML texts. Two paragraphs.</p>'], 
	      'rect'=>[50,250, 500,50], 'outline'=>$magenta);

restore_props($text, $grfx);
print "pre array of hashes\n";
$text->column($page, $text, $grfx, 'pre', [
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
print "======================================================= pg 2\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

print "single string entries\n";
 
restore_props($text, $grfx);
multicol($page, $text, $grfx, 'none', 
	 "This is a single string text.\n\nWith two paragraphs.", 
	 [50,750, 50,50], $magenta, $fs);

restore_props($text, $grfx);
multicol($page, $text, $grfx, 'md1', 
	 "This is a _single string_ **MD** text.\n\nIt should have two paragraphs.", 
	 [50,650, 50,50], $magenta, $fs);

restore_props($text, $grfx);
multicol($page, $text, $grfx, 'html', 
	 "<p>This is a <i>single <b>string</b></i> HTML text.</p><p>Two paragraphs.</p>", 
	 [50,550, 50,50], $magenta, $fs);

print "array of string entries\n";
 
# should be two paragraphs, as a new array element starts a new paragraph
restore_props($text, $grfx);
multicol($page, $text, $grfx, 'none', 
         ["This is an array","Of single string texts. Two paragraphs."], 
	 [50,450, 50,50], $magenta, $fs);

# would be glued together into one line, except there is a blank line in middle
restore_props($text, $grfx);
multicol($page, $text, $grfx, 'md1', 
         ["This is an **array**\n\n","Of single _string_ MD texts. Two paragraphs.\n"], 
	 [50,350, 50,50], $magenta, $fs);

# explicitly have two paragraphs
 
restore_props($text, $grfx);
multicol($page, $text, $grfx, 'html', 
	 ["<p>This is an <b>array</b></p>\n","<p>Of single <i>string</i> HTML texts. Two paragraphs.</p>\n"], 
	 [50,250, 50,50], $magenta, $fs);

print "pre array of hashes\n";
 
restore_props($text, $grfx);
multicol($page, $text, $grfx, 'pre', [
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
print "======================================================= pg 3\n";
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

print "Lorem Ipsum array of string entries\n";
# default paragraph indent and top margin
restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'none', \@ALoremIpsum, 
	          'rect'=>[50,750, 500,300], 'outline'=>$magenta );
if ($rc) { 
    print STDERR "Lorem Ipsum array overflowed the column!\n";
}
print "Lorem Ipsum string entry\n";
# no indent, extra top margin
restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'none', $SLoremIpsum, 
	          'rect'=>[50,350, 500,300], 'outline'=>$magenta, 
		  'para'=>[ 0, 5 ] );
if ($rc) { 
    print STDERR "Lorem Ipsum string overflowed the column!\n";
}
#} ###############

#if (1) { ###############
# customer sample Markdown
print "======================================================= pg 4\n";
print "Customer sample Markdown and Table\n";
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

Show that [another link](https://www.catskilltech.com) on the same page works.

Show some <ins>inserted</ins> text and <u>underlined</u> text that display 
underlines. Show some <del>deleted</del> text, <strike>strike-out</strike> text,
and <s>s'd out</s> text that show line-throughs. Currently, overlines are not
enabled. More than <span style="text-decoration: 'underline line-through'">one
at a time</span> are possible.

Then we need some styling features in tables as shown in the table below. There is no need to support this in text blocks, although it would be a nice feature (colored text is already available in text blocks using its options).
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', 
	          $content, 
		  'rect'=>[50,750, 500,708], 'outline'=>$magenta, 
		  'para'=>[ 0, 5 ] );
if ($rc) { 
    print STDERR "Sample Markdown overflowed the column!\n";
}

# customer sample HTML
$next_y -= 20; # gap to table

if ($use_Table) {
    # use PDF::Table to draw a table, inheriting font from above
    # you need to be careful to end a cell with font, etc. restored
    #   this only works if PDF::Table installed!

    use PDF::Table;
    my $table = PDF::Table->new();
    my $table_data = [
        # row 1, solid color lines
    	[   
 	    [ 'html', '<font color="red">This is some red text</font>',
	      { 'font_size' => 12, 'para' => [ 0, 0 ] } ], 
            [ 'html', "<span style=\"color:green\">This is some green text</span>",
	      { 'font_size' => 12, 'para' => [ 0, 0 ] } ], 
	], 

        # row 2, special symbols, colored
	[
    	    [ 'html', 'This is a red cross: <font face="ZapfDingbats" color="red">8</font>.', 
	      { 'font_size' => 12, 'para' => [ 0, 0 ] } ], 
    	    [ 'html', "This is a green tick: <span style=\"font-family:ZapfDingbats; color:green\">4</span>.", 
	      { 'font_size' => 12, 'para' => [ 0, 0 ] } ], 
        ],

        # row 3, like row 2, but using macro substitutions
	[
    	    [ 'html', "This is a red cross substitute: %cross%.", 
	      { 'font_size'=>12, 'para'=>[ 0, 0 ], 
    		'substitute'=>[
    		    ['%cross%','<font face="ZapfDingbats" color="red">', '8', '</font>'],
    		    ['%tick%','<span style="font-family: ZapfDingbats; color: green;">', '4', '</span>'] ]
	      } 
            ],
    	    [ 'html', "This is a green tick substitute: %tick%.", 
    	      { 'font_size'=>12, 'para'=>[ 0, 0 ], 
    		'substitute'=>[
    		    ['%cross%','<font face="ZapfDingbats" color="red">', '8', '</font>'],
    		    ['%tick%','<span style="font-family: ZapfDingbats; color: green;">', '4', '</span>'] ]
	      }
            ],
	],

        # row 4, non-markup text
	[ 'Plain old text', 
	  'More plain text'
        ],
	             ];

    my $size = '* *'; # two equal columns
    $table->table(
        $pdf, $page, $table_data,
        'x'      => 50,
        'y'      => $next_y,
        'w'      => 500,
        'h'      => $next_y-42,
        'next_y' => 750,
        'next_h' => 708,
        'size'   => $size,
        # global markups (can be overridden for row, column, or cell)
        'padding' => 4.5,
    );

} else {
    # fake a table so that PDF::Table is not required within PDF::Builder 
    # examples! 
    # "table" 2 columns width 500, padding 5, font size 12, draw borders 
    # and rules
    # we will show a number of different techniques
    # do 6 cells as 6 small columns in 3x2 grid
    my $table_rows = 4;
    my $table_cols = 2;
    my $cell_height = 20;
    my $row_num = 0;
    # 
 
    # row 1, simple color text
    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'html', 
	          '<font color="red">This is some red text</font>', 
		  'rect'=>[55,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ] );

    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'html', 
	          '<span style="color:green">This is some green text</span>', 
		  'rect'=>[305,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ] );
    $row_num++;

    # row 2, show a tick and cross, changed color, font and span tags
    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'html', 
	          'This is a red cross: <font face="ZapfDingbats" color="red">8</font>.', 
		  'rect'=>[55,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ] );
 
    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'html', 
	          "This is a green tick: <span style=\"font-family:ZapfDingbats; color:green\">4</span>.", 
		  'rect'=>[305,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ] );
    $row_num++;
 
    # row 3, like 2 but illustrate text/HTML substitution
    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'md1', 
	          "This is a red cross substitute: %cross%.", 
		  'rect'=>[55,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ], 
		  'substitute'=>[
		      ['%cross%','<font face="ZapfDingbats" color="red">', '8', '</font>'],
		      ['%tick%','<span style="font-family: ZapfDingbats; color: green;">', '4', '</span>']
	          ]);
 
    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'html', 
	          "This is a green tick substitute: %tick%.", 
		  'rect'=>[305,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ], 
		  'substitute'=>[
		      ['%cross%','<font face="ZapfDingbats" color="red">', '8', '</font>'],
		      ['%tick%','<span style="font-family: ZapfDingbats; color: green;">', '4', '</span>']
	          ]);
    $row_num++;

    # row 4, non-markup text
    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'none', 
	          "Plain old text",
		  'rect'=>[55,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ], 
	         );

    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'none', 
	          "More plain text",
		  'rect'=>[305,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ], 
	         );
    $row_num++;

    # draw border and rules
    $grfx->poly(50,$next_y, 550,$next_y, 550,$next_y-($table_rows*20), 50,$next_y-($table_rows*20), 50,$next_y);
    # horizontal dividers between rows
    for (my $r = 1; $r < $table_rows; $r++) {
        $grfx->move(50,$next_y-($r*20));
        $grfx->hline(550);
    }
    # vertical divider between columns
    $grfx->move(300,$next_y);
    $grfx->vline($next_y-60);
    # draw it all
    $grfx->strokecolor('black');
    $grfx->stroke();
}
#} ###############

#if (0) { ###############
# more pages with more extensive MD
print "======================================================= pg 5+\n";
print "A README.md file for PDF::Builder\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();
#  might need two or even three pages
$content = <<"END_OF_CONTENT";
# PDF::Builder

`A Perl library to facilitate the creation and modification of PDF files`

This archive contains the distribution PDF::Builder.
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
The default behavior is **NOT** to attempt to install all of them during 
PDF::Builder installation.

* Graphics::TIFF (recommended if using TIFF image functions)
* Image::PNG::Libpng (recommended for enhanced PNG image function processing)
* HarfBuzz::Shaper (needed for Latin script ligatures and kerning, as well as for any complex script such as Arabic, Indic scripts, or Khmer)
* HTML::TreeBuilder (needed for 'md1' and 'html' markup)
* Text::Markdown (needed for 'md1' markup)

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

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
while ($rc) { 
    # new page
    $page = $pdf->page();
    $text = $page->text();
    $grfx = $page->gfx();

    ($rc, $next_y, $unused) =
        $text->column($page, $text, $grfx, 'pre', $unused, 
		      'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		      'para'=>[ 0, 0 ] );
}
#} ###############

# ---------------------------------------------------------------------------
# end of program
$pdf->saveas($name);
# -----------------------

sub multicol {
    my ($page, $text, $grfx, $markup, $content, $rect, $outline, $fs) = @_;

    my ($rc, $start_y);

    ($rc, $start_y, $content) = 
        $text->column($page, $text, $grfx, $markup, $content, 
		      'rect'=>$rect, 'outline'=>$outline, 'font_size'=>$fs);
    while ($rc == 1) { # ran out of column, do another
	$rect->[0] += 50+$rect->[2];
        ($rc, $start_y, $content) = 
            $text->column($page, $text, $grfx, 'pre', $content, 
		          'rect'=>$rect, 'outline'=>$outline, 'font_size'=>$fs);
    }
    return;
}

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

    $text->fillcolor('black');
    $grfx->strokecolor('black');
    # italic and bold get reset to 'normal' anyway on column() entry,
    # but need to fix font face in case it was left something odd
    $text->font($pdf->get_font('face'=>'default', 'italic'=>0, 'bold'=>0), 12);

    return;
}
