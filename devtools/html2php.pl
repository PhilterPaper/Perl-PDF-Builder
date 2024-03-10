use strict;
use warnings;

my $base_src = "C:/Users/Phil/Desktop/PDF-Builder/docs";
my $base_dst = "C:/Users/Phil/Desktop/PDF-Builder/docs/PHP";

# A "flat" structure is simpler, even at the cost of redundant path info
# 'keys' entry = ADDITIONAL keywords (comma-separated) after 'documentation'
# 'desc' entry = ADDTIIONAL description after 'PDF::Builder documentation'
# 'title' entry = ADDITIONAL title text after 'PDF::Builder '
# file names are given without .html (input) or .php (output)
my %file_list = (
    'Text::KnuthPlass' => {
       'files' => [ 
	 'Text/KnuthPlass' => { 'desc'=>'top level', },
       ],
    },

    'PDF::Table' => {
      'files' => [ 
        'PDF/Table' => { 'desc'=>'top level', },
        'PDF/Table_index' => { 'desc'=>'master index', 
		               'keys'=>'master,index',
                               'title'=>'Master Index', },
       ],
    },
      
    'PDF::Builder' => {
       'files' => [ 
         'PDF/Builder' => { 'desc'=>'top level', },
         'PDF/Builder_index' => { 'desc'=>'master index', 
		                  'keys'=>'master,index',
                                  'title'=>'Master Index', },
         'PDF/Builder/Annotation' => { },
         'PDF/Builder/Content' => { },
         'PDF/Builder/Docs' => { },
         'PDF/Builder/FontManager' => { 'keys'=>'font,manager' },
         'PDF/Builder/Lite' => { },
         'PDF/Builder/Matrix' => { 'keys'=>'function,library' },
         'PDF/Builder/NamedDestination' => { 'keys'=>'named,destination' },
         'PDF/Builder/Outline' => { 'keys'=>'bookmark' },
         'PDF/Builder/Outlines' => { 'keys'=>'bookmarks' },
         'PDF/Builder/Page' => { },
         'PDF/Builder/Resource' => { },
         'PDF/Builder/UniWrap' => { 'keys'=>'unicode' },
         'PDF/Builder/Util' => { 'keys'=>'utilities' },
         'PDF/Builder/ViewerPreferences' => { 'keys'=>'viewer,preference' },
	 'PDF/Builder/Basic/PDF' => { },
	 'PDF/Builder/Basic/PDF/Array' => { 'keys'=>'array,handling' },
         'PDF/Builder/Basic/PDF/Bool' => { 'keys'=>'boolean,handling' },
         'PDF/Builder/Basic/PDF/Dict' => { 'keys'=>'dictionary,entry,handling' },
         'PDF/Builder/Basic/PDF/File' => { 'keys'=>'file,handling' },
         'PDF/Builder/Basic/PDF/Filter' => { 'keys'=>'compression,filtering' },
         'PDF/Builder/Basic/PDF/Literal' => { 'keys'=>'literal,values' },
         'PDF/Builder/Basic/PDF/Name' => { 'keys'=>'slash,name' },
         'PDF/Builder/Basic/PDF/Null' => { },
         'PDF/Builder/Basic/PDF/Number' => { 'keys'=>'number,handling' },
         'PDF/Builder/Basic/PDF/Objind' => { 'keys'=>'object,index,handling' },
         'PDF/Builder/Basic/PDF/Page' => { },
         'PDF/Builder/Basic/PDF/Pages' => { },
         'PDF/Builder/Basic/PDF/String' => { 'keys'=>'text,string,handling' },
         'PDF/Builder/Basic/PDF/Utils' => { 'keys'=>'utilities' },
         'PDF/Builder/Basic/PDF/Filter/ASCII85Decode' => { },
         'PDF/Builder/Basic/PDF/Filter/ASCIIHexDecode' => { },
         'PDF/Builder/Basic/PDF/Filter/CCITTFaxDecode' => { },
         'PDF/Builder/Basic/PDF/Filter/FlateDecode' => { },
         'PDF/Builder/Basic/PDF/Filter/LZWDecode' => { },
         'PDF/Builder/Basic/PDF/Filter/RunLengthDecode' => { },
         'PDF/Builder/Basic/PDF/Filter/CCITTFaxDecode/Reader' => { },
         'PDF/Builder/Basic/PDF/Filter/CCITTFaxDecode/Writer' => { },
         'PDF/Builder/Content/Hyphenate_basic' => { 'keys'=>'basic,language,independent,hyphenation' },
         'PDF/Builder/Content/Text' => { 'keys'=>'advanced,markup' },
         'PDF/Builder/Resource/BaseFont' => { },
         'PDF/Builder/Resource/CIDFont' => { },
         'PDF/Builder/Resource/Colors' => { },
         'PDF/Builder/Resource/ColorSpace' => { },
         'PDF/Builder/Resource/ExtGState' => { 'keys'=>'extended,graphics,state' },
         'PDF/Builder/Resource/Font' => { },
         'PDF/Builder/Resource/Glyphs' => { },
         'PDF/Builder/Resource/PaperSizes' => { 'keys'=>'paper,sizes' },
         'PDF/Builder/Resource/Pattern' => { },
         'PDF/Builder/Resource/Shading' => { },
         'PDF/Builder/Resource/UniFont' => { },
         'PDF/Builder/Resource/XObject' => { },
         'PDF/Builder/Resource/CIDFont/CJKFont' => { },
         'PDF/Builder/Resource/CIDFont/TrueType' => { },
         'PDF/Builder/Resource/CIDFont/TrueType/FontFile' => { },
	 'PDF/Builder/Resource/ColorSpace/DeviceN' => { },
	 'PDF/Builder/Resource/ColorSpace/Indexed' => { },
	 'PDF/Builder/Resource/ColorSpace/Separation' => { },
	 'PDF/Builder/Resource/ColorSpace/Indexed/ACTFile' => { },
	 'PDF/Builder/Resource/ColorSpace/Indexed/Hue' => { },
	 'PDF/Builder/Resource/ColorSpace/Indexed/WebColor' => { },
	 'PDF/Builder/Resource/Font/BdFont' => { 'keys'=>'adobe,bitmap,distribution,format' },
	 'PDF/Builder/Resource/Font/CoreFont' => { },
	 'PDF/Builder/Resource/Font/Postscript' => { },
	 'PDF/Builder/Resource/Font/SynFont' => { },
	 'PDF/Builder/Resource/Font/CoreFont/bankgothic' => { 'keys'=>'bank,gothic,windows,font' },
	 'PDF/Builder/Resource/Font/CoreFont/courier' => { },
	 'PDF/Builder/Resource/Font/CoreFont/courierbold' => { },
	 'PDF/Builder/Resource/Font/CoreFont/courierboldoblique' => { },
	 'PDF/Builder/Resource/Font/CoreFont/courieroblique' => { },
	 'PDF/Builder/Resource/Font/CoreFont/georgia' => { },
	 'PDF/Builder/Resource/Font/CoreFont/georgiabold' => { },
	 'PDF/Builder/Resource/Font/CoreFont/georgiabolditalic' => { },
	 'PDF/Builder/Resource/Font/CoreFont/georgiaitalic' => { },
	 'PDF/Builder/Resource/Font/CoreFont/helvetica' => { },
	 'PDF/Builder/Resource/Font/CoreFont/helveticabold' => { },
	 'PDF/Builder/Resource/Font/CoreFont/helveticaboldoblique' => { },
	 'PDF/Builder/Resource/Font/CoreFont/helveticaoblique' => { },
	 'PDF/Builder/Resource/Font/CoreFont/symbol' => { },
	 'PDF/Builder/Resource/Font/CoreFont/timesbold' => { },
	 'PDF/Builder/Resource/Font/CoreFont/timesbolditalic' => { },
	 'PDF/Builder/Resource/Font/CoreFont/timesitalic' => { },
	 'PDF/Builder/Resource/Font/CoreFont/timesroman' => { },
	 'PDF/Builder/Resource/Font/CoreFont/trebuchet' => { },
	 'PDF/Builder/Resource/Font/CoreFont/trebuchetbold' => { },
	 'PDF/Builder/Resource/Font/CoreFont/trebuchetbolditalic' => { },
	 'PDF/Builder/Resource/Font/CoreFont/trebuchetitalic' => { },
	 'PDF/Builder/Resource/Font/CoreFont/verdana' => { },
	 'PDF/Builder/Resource/Font/CoreFont/verdanabold' => { },
	 'PDF/Builder/Resource/Font/CoreFont/verdanabolditalic' => { },
	 'PDF/Builder/Resource/Font/CoreFont/verdanaitalic' => { },
	 'PDF/Builder/Resource/Font/CoreFont/webdings' => { },
	 'PDF/Builder/Resource/Font/CoreFont/wingdings' => { },
	 'PDF/Builder/Resource/Font/CoreFont/zapfdingbats' => { 'keys'=>'zapf,dingbats' },
	 'PDF/Builder/Resource/XObject/Form' => { },
	 'PDF/Builder/Resource/XObject/Image' => { },
	 'PDF/Builder/Resource/XObject/Form/BarCode' => { },
	 'PDF/Builder/Resource/XObject/Form/Hybrid' => { },
	 'PDF/Builder/Resource/XObject/Form/BarCode/codabar' => { },
	 'PDF/Builder/Resource/XObject/Form/BarCode/code128' => { },
	 'PDF/Builder/Resource/XObject/Form/BarCode/code3of9' => { },
	 'PDF/Builder/Resource/XObject/Form/BarCode/ean13' => { },
	 'PDF/Builder/Resource/XObject/Form/BarCode/int2of5' => { },
	 'PDF/Builder/Resource/XObject/Image/GD' => { },
	 'PDF/Builder/Resource/XObject/Image/GIF' => { },
	 'PDF/Builder/Resource/XObject/Image/JPEG' => { },
	 'PDF/Builder/Resource/XObject/Image/PNG' => { },
	 'PDF/Builder/Resource/XObject/Image/PNG_IPL' => { },
	 'PDF/Builder/Resource/XObject/Image/PNM' => { },
	 'PDF/Builder/Resource/XObject/Image/TIFF' => { },
	 'PDF/Builder/Resource/XObject/Image/TIFF_GT' => { },
	 'PDF/Builder/Resource/XObject/Image/TIFF/File' => { },
	 'PDF/Builder/Resource/XObject/Image/TIFF/File_GT' => { },
       ],
    },

  );  # end of %file_list

my $package = $ARGV[0];
if (!defined $package || $package eq '-h' || $package eq '--help') {
    print "\nhtml2php.pl package_name\n\n";
    print "package_name = PDF::Builder, PDF::Table, or Knuth::Plass\n\n";
    print "see \$base_src and \$base_dst for where .html files are read from\n";
    print "  and .php files are written to.\n";
    exit(1);
}

print "processing '$package' HTML files into PHP files\n";
if (!defined $file_list{$package}) {
    print "package '$package' is not recognized!\n";
    my @list = keys(%file_list);
    print "valid packages are: @list\n";
    exit(2);
}

my $pack = $file_list{$package}; # hash ref 
my $files = $pack->{'files'}; # anon array of hashes, key is path/file
                              #   and fields are extra information

my $base_file;
foreach my $file (@$files) {
    if (ref($file) eq 'HASH') {
	do_convert("$base_src/$base_file.html", "$base_dst/$base_file.php",
		   $package, $base_file, $file);
    } else {
        print "create $file.php from $file.html\n";
	$base_file = $file;
    }
}

# ==================================
# function to read in the HTML file $input and write out PHP file $output,
#   using $package name, base file $base, and partial path $file
sub do_convert {
    my ($input, $output, $package, $base, $file) = @_;
    use File::Path qw(make_path);

    my ($pos, $xdesc, $xkeys, $xtitle);
    my @keylist = keys %$file;
    $xdesc = $xkeys = $xtitle = '';
    if (@keylist) {
        foreach (@keylist) {
	    if      ($_ eq 'desc') {
	        $xdesc = $file->{$_};
	    } elsif ($_ eq 'keys') {
	        $xkeys = $file->{$_};
	    } elsif ($_ eq 'title') {
	        $xtitle = $file->{$_};
	    } else {
		print "\n****** unrecognized extra data '$_' ignored\n";
	    }
        }
    }

    # have $input and $output files, extra data $xdesc, $xkeys, $xtitle
    my $string = slurp($input); # string contains entire file

    # replace end
    $pos = index $string, "<h3>###</h3>";
    if ($pos < 0) {
	print "****** unable to find end HTML to replace!\n";
    } else {
        $string = substr($string, 0, $pos) . 
	  "<?php\n" .
	  "  include_once(\"\$PHP_ROOT/utils/standard_page_bottom.php\");\n" .
	  "?>\n";
    }
    # replace beginning, updating certain fields
    $pos = index $string, "<body>";
    if ($pos < 0) {
	print "****** unable to find <body> in HTML!\n";
    } else {
	# get rid of whole preamble
	$string = substr($string, $pos+6);
	# working backwards, prepend fixed/variable/fixed content
	$string =
"  \$my_ancestor = \"{\$HTML_ROOT}Documentation.html\";
  \$page_style = \"body { margin: 10px; }
h1, h2, h3 { text-align: center; }
.fixedwidth { display: inline-block; width: 2em; }
.dummy {color: #999; }
.errormsg { color: red; }\";

  include_once(\"\$PHP_ROOT/utils/begin_page.php\");

  include_once(\"\$PHP_ROOT/utils/standard_page_top.php\");
  include_once(\"\$PHP_ROOT/utils/standard_page.php\");
?>
" . $string;	

        $string = "  \$my_HTML_name = \"{\$HTML_ROOT}Documentation/$base.html\";\n" . $string;

	if ($xdesc ne '') { $xdesc = ' '.$xdesc; }
	my $name = $base_file;
	$name =~ s#/#::#g;
 	if ($name eq $package) { $name = ''; }
	$name =~ s#^$package\:\:##;
        my $name2 = $name;
        if ($name ne '') { $name = ' '.$name; }
	$string = 
"  \$page_description = \"$package documentation$name$xdesc\";\n" . $string;

        if ($xkeys ne '') { $xkeys = ','.$xkeys; }
	$name2 =~ s#\:\:#,#g;
	$name2 = lc($name2);
        if ($name2 ne '') { $name2 = ','.$name2; }
	$string = 
"  \$page_keywords = \"documentation$name2$xkeys\";\n" . $string;

	if ($xtitle ne '') { $xtitle = ' '.$xtitle; }
	$string = 
"  \$page_title = \"$package$name$xtitle\";\n" . $string;

        my $parents_string = parents($base);
        $string =
"<?php 
  \$file_mtime = \"/../Documentation/$base.php\";
  include_once(\"${parents_string}dir4/utils/appl_top.php\");
  //
  // UPDATING: update Perl POD. new keywords etc. in devtools/html2php.pl
  //           buildDoc.pl creates new HTML, html2php.pl creates PHP, upload
  //

" . $string;
    }

    # build any missing directories
    my $outdir = $output;
    $outdir =~ s#/[^/]+$##;
    if (!-d $outdir) {
	# need to create one or more directories
        make_path($outdir);
    }

    # write back out to PHP output file
    spew($string, $output);
}

# ==================================
# return ../ (repeated) to get to root where dir4 lives
# e.g. $base = 'PDF/Builder/Annotation' returns '../../../'
sub parents {
    my ($base) = @_;

    my $numslashes = $base;
    $numslashes = scalar(split /\//, $base);
    my $output = '';
    for (my $i=0; $i<$numslashes; $i++) {
	$output .= '../';
    }
    return $output;
}

# ==================================
# function to spew a one-string file out to the file
#  after https://perlmaven.com/writing-to-files-with-perl
sub spew {
    my ($string, $fname) = @_;
    open(my $fh, '>', $fname) or die "$fname ERROR  can't open file for output\n";
    # warn if a wide character and give string and offset
    my $first = 1;  # only one dump of string
    for (my $i=0; $i<length($string); $i++) {
	if (ord(substr($string, $i, 1)) > 127) {
	    if ($first) {
		print "String: '$string'\n";
		$first = 0;
	    }
	    print "Wide character ".ord(substr($string, $i, 1))." found at $i\n";
	}
    }
    print $fh $string;
    close $fh;
    return;
}

# ==================================
# function to slurp file into a string, after https://perlmaven.com/slurp
sub slurp {
    my $file = shift;
    open(my $fh, '<', $file) or die "$file ERROR  can't open file for input\n";
    local $/ = undef;
    my $cont = <$fh>;
    close $fh;
    return $cont;
}

