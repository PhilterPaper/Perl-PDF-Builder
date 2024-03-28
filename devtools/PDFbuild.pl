# build PDF-Builder distribution image
#
# consider copying MYMETA.* over META.* (before committing to GitHub)
# see if attrib +R Makefile.PL (after editing) eliminates Kwalitee warning. NO
#
use File::Path qw(make_path);
 
my $builder = 'Makefile.PL';
my $script  = 'Makefile';
my $hiDir   = 'PDF';
my $product = 'Builder';
my $master  = 'Builder.pm';
my $GHname  = 'PDF-Builder';

print "**** check https://en.wikipedia.org/wiki/Leap_second to see if any
     leap seconds have been added since 12/31/2016. Update $master.\n";
to_continue();
print "**** check README.md list of prereqs needing patching, and check
     whether notice list needs updating (also in Changes).\n";
to_continue();
print "**** build all POD documentation (as HTML into docs/) and check that
     it's clean\n";
to_continue();
print "**** check README.md for copyright year, minimum Perl version, current
     Builder version, current mandatory and optional prerequisites. Copy to
     examples/Column.pl if anything has changed, and test the formatting.\n";
to_continue();

my ($VERSION, $PERL_V, $MAKE_MAKER, $TEST_EXCEPTION, $TEST_MEMORY_CYCLE,
	$COMPRESS_ZLIB, $FONT_TTF, $GRAPHICS_TIFF, $HARFBUZZ_SHAPER,
	$IMAGE_PNG_LIBPNG, $TEXT_MARKDOWN, $HTML_TREEBUILDER, 
	$POD_SIMPLE_XHTML) 
          = read_version("./version");
print "**** file 'version' contains following minimum versions.\n";
print 
"VERSION = $VERSION\n" . 
"PERL_V = $PERL_V\n" . 
"MAKE_MAKER = $MAKE_MAKER\n" . 
"TEST_EXCEPTION = $TEST_EXCEPTION\n" . 
"TEST_MEMORY_CYCLE = $TEST_MEMORY_CYCLE\n" . 
"COMMPRESS_ZLIB = $COMPRESS_ZLIB\n" . 
"FONT_TTF = $FONT_TTF\n" . 
"GRAPHICS_TIFF = $GRAPHICS_TIFF\n" . 
"HARFBUZZ_SHAPER = $HARFBUZZ_SHAPER\n" . 
"IMAGE_PNG_LIBPNG = $IMAGE_PNG_LIBPNG\n" .
"TEXT_MARKDOWN = $TEXT_MARKDOWN\n" .
"HTML_TREEBUILDER = $HTML_TREEBUILDER\n" .
"POD_SIMPLE_XHTML = $POD_SIMPLE_XHTML\n"; 
# PERL_V in format 5.020000
# if needed, create PERL_V_DOT in format 5.20.0
# will auto-update Makefile.PL, .pm, .pl, Builder.pm, META.* files below

print "**** Check Perl version against https://www.cpan.org/src/ Perl latest
     release dates \n";
print "      today-6 years last major release before that date.\n";
to_continue();
# future: 
#   * reformat PERL_V ('5.16.0' -> '5.016000') to read 
#     https://www.cpan.org/src/ Perl release dates, and warn if need to 
#     update minimum Perl version (BEFORE updating Makefile.PL)
#   * reformat PERL_V to something usable in Makefile.PL, (e.g.,
#     '5.16.0' -> '5.016000' and update that file with it, just like VERSION

print "**** have you rebuilt documentation and placed in an appropriate place?\n";
to_continue();

# -------------------------------------- configuration
my $make = 'gmake';  # dmake no longer available
my $desktop = "C:\\Users\\Phil\\Desktop\\";
my $temp = $desktop."temp";

# location of 7-Zip
$sevenZip = "\"C:\\Program Files\\7-Zip\\7z.exe\"";
$cmd7Zip  = $sevenZip . " a -r ";

# location of pod2html
$pod2html = "pod2html";   # should be in PATH

$baseDirSrc = $desktop . "$GHname\\";
#$outputBasename = "PDF-API2-" . substr($dirName, 1);

# --------------------------------------

# check for any files suffixed ~ or .bak (backup files) in source
if (checkForBackups($baseDirSrc)) {
    die "one or more backup or work files found -- remove\n";
}
# top level .pdf, .tmp, .html junk needs to go away

# grep -S  "2018" ..\*.* |grep -v "\~:" |grep -v "\.git" |grep -v "0x2018" |grep -v "\.cmap" |grep -v "\.data"
print "**** What is the current copyright year in various files? At some
     point did you go around and update all file copyrights?\n";
to_continue();
print "**** Anything listed as INFO/DEPRECATED to expire before this month?
     Consider removing deprecated items.\n";
to_continue();
print "**** have you installed any new prerequistes? if so, are the build
     prereqs list in $builder and the optional library module
     exclusion list in t/00-all-usable.t updated?\n";
to_continue();
print "**** are all working (bugfix) directories removed, or moved to
     another place?\n";
to_continue();
print "**** have you removed any old desktop\\temp directory?\n";
to_continue();
print "**** only $master and optional_update.pl should have \$VERSION
     defined (may be updated):\n";
system("findstr /s /c:\"our \$VERSION =\" *.p?");
if_OK();
print "**** Changes should have current date,
      and 'unreleased' notation removed.\n";
system("findstr /c:\"$VERSION\" Changes");
if_OK();
print "**** No file should be Read-Only.\n";
system("attrib /s *.* |grep \" R \" | grep -v \".git\" |more");
to_continue();

print "**** Have you remembered to update LAST_UPDATE everywhere changed?\n";
if_OK();
print "**** Have you 1) compared $GHname/ to /Strawberry, 2) run 1_pc,
     3) run 2_t-tests, 4) run 3_examples, 5) run 4_contrib to thoroughly
     test? Have you 6) built all docs (.html) to check PODs?\n";
to_continue();

system("attrib -R $builder");
update_with_version();
print "**** updated version in $builder (check). $master updated\n";
print "**** \$VERSION -- commit in GitHub.\n";

#print "**** git status, pull/merge, add, commit, push as necessary.\n";
to_continue();

# Builder.pm and t/00-all-usable.t need to update before temp copies made
# Builder.pm: update fields GRAPHICS_TIFF, HARFBUZZ_SHAPER, IMAGE_PNG_LIBPNG,
#                           TEXT_MARKDOWN, HTML_TREEBUILDER, POD_SIMPLE_XHTML
update_Builder();
print "**** $master should have had optionals updated.\n";
if_OK();
# Makefile.PL: update fields VERSION, PERL_V, MAKE_MAKER, TEST_MEMORY_CYCLE, 
#              COMPRESS_ZLIB, FONT_TTF, GRAPHICS_TIFF, HARFBUZZ_SHAPER, 
#              IMAGE_PNG_LIBPNG, TEXT_MARKDOWN, HTML_TREEBUILDER, 
#              POD_SIMPLE_XHTML
update_Makefile();
print "**** $builder should have had updates.\n";
if_OK();
# META.*: update fields VERSION, PERL_V, MAKE_MAKER, TEST_EXCEPTION, 
#         TEST_MEMORY_CYCLE, COMPRESS_ZLIB, FONT_TTF, GRAPHICS_TIFF, 
#         HARFBUZZ_SHAPER, IMAGE_PNG_LIBPNG, TEXT_MARKDOWN, HTML_TREEBUILDER, 
#         POD_SIMPLE_XHTML
update_META();
print "**** META.json and META.yml should have had updates.\n";
if_OK();
# t/00-all-usable.t update fields GRAPHICS_TIFF, HARFBUZZ_SHAPER, 
#                   IMAGE_PNG_LIBPNG, TEXT_MARKDOWN, HTML_TREEBUILDER, 
#                   POD_SIMPLE_XHTML
update_all_usable();  # both library copy t/ and $temp/t/ copy
print "**** t/00-all-usable.t should have had updates.\n";
if_OK();
# optional_update.pl update fields GRAPHICS_TIFF, HARFBUZZ_SHAPER,
#                   IMAGE_PNG_LIBPNG, TEXT_MARKDOWN, HTML_TREEBUILDER, 
#                   VERSION, POD_SIMPLE_XHTML
update_optional();  
print "**** tools/optional_update.pl should have had updates.\n";
if_OK();

print "**** .pl and .pm files update to latest version\n";
system("mkdir $temp");
system("mkdir $temp\\t");
system("mkdir $temp\\INFO");
system("mkdir $temp\\INFO\\old");
system("xcopy /s .\\*.p? $temp");
system("xcopy .\\.gitignore $temp");
system("xcopy .\\CONTRIBUTING.md $temp");
system("xcopy .\\INFO\\CONVERSION $temp\\INFO\\");
system("xcopy .\\INFO\\RoadMap $temp\\INFO\\");
system("xcopy .\\INFO\\old\\*.* $temp\\INFO\\old\\");
system("xcopy .\\t\\*.* $temp\\t\\");
system("xcopy /s .\\examples\\*.* $temp\\examples\\");
#unlink("$desktop\\temp\\$builder");

# all other .pm and .pl files should just have an empty '# VERSION' line
print "calling PDFversion.pl\n";
system("devtools\\PDFversion.pl . $VERSION");

system('for /R %G in (*.pl) do dos2unix "%G"');
system('for /R %G in (*.pm) do dos2unix "%G"');
print "**** If .pl and .pm files now have good VERSION,\n
     and they are in [unix] format, not DOS format.\n";
if_OK();

##system("dos2unix INFO\\old\\dist.ini.old");
system("dos2unix .gitignore");
system("dos2unix CONTRIBUTING.md");
system("dos2unix examples\\*.*");
# consider replacing pod2htmd.temp (no longer produced by Pod::Simple::XHTML)
#   with some other trivial text file
system("dos2unix examples\\resources\\pod2htmd.temp");
system("dos2unix examples\\resources\\sample.txt");
system("dos2unix examples\\Windows\\*.*");
system("dos2unix INFO\\CONVERSION");
system("dos2unix INFO\\RoadMap");
system("dos2unix INFO\\old\\*.*");
system("dos2unix t\\*.*");
print "**** all other text files should now be [unix] format, not DOS format.\n";
if_OK();

print "**** build $script\n";
#system("attrib +R $builder");  # didn't seem to help
system("$builder");
##print "**** edit $script to insert VERSION update (and erase $script~)\n";
##print "(tab)devtools\\PDFversion.pl \$(DISTVNAME) \$(VERSION)\n";
# gzip -> devtools/gzip
update2_Makefile();
print "**** Check $script.\n";
if_OK();

print "**** $make all\n";
system("$make all");
print "**** Check blib, etc.\n";
if_OK();

print "**** run tests\n";
system("$make test");
print "**** Did tests run OK?\n";
if_OK();

print "**** build distribution (.tar.gz)\n";
system("$make dist");
print "**** Is .tar.gz looking all right?\n";
if_OK();

system("xcopy /s $desktop\\temp\\*.* .");
#system("git checkout $builder");
#print "**** run unVERSION.bat to reverse all the VERSION settings.\n";
print "**** erase Desktop/temp/ if everything is clean in build\n";
print "**** erase $script, etc. new stuff (EXCEPT .tar.gz)\n";
print "**** log on to PAUSE and upload .tar.gz file\n";
print "**** consider removing an old release from CPAN\n";
print "**** update motd.php on website\n";
print "**** copy .tar.gz to releases/ and git rm oldest\n";
print "**** version update\n";
print "**** Changes update next version, add UNRELEASED\n";
print "**** git update with latest changes\n";
print "**** Update Examples on catskilltech.com with any new examples\n";
print "**** Update Documentation on catskilltech.com with fresh copy\n";

# not (yet) generating .html from POD
#print "Proceeding. Ignore error messages \"Cannot find $hiDir::$product...\" in podpath.\n";

# clean out existing output structure, create empty dirs in destination
#prepOutputDirs("$baseDirDst$dirName\\");
#print "**** finished creating empty dest structure\n";

# copy over source/ to dest/code/
#copyToCode($baseDirSrc, "$baseDirDst$dirName");
#print "**** finished copying source to dest\n";

# create documentation .pm -> .html
#makeHTML("$baseDirSrc"."lib\\", "$baseDirDst$dirName\\docs\\lib\\", '');
#print "**** finished making HTML documentation\n";

# create downloads .tar.gz, .zip
#makeDownloads("$baseDirDst$dirName");
#print "**** finished making downloadables\n";

# -----------------------------------------
sub to_continue {
  print "+++++ Press Enter to continue...";
  my $response = <>;
  print "\n";
  return;
}
sub if_OK {
  print "+++++ If OK, press Enter to continue...";
  my $response = <>;
  print "\n";
  return;
}

# -----------------------------------------
# check for any files suffixed ~ or .bak (backup files) in source
#    also .swp, Thumbs.db files
# recursively call this routine for each level down
# returns TRUE if a backup found in this directory
sub checkForBackups {
  my $dir = shift;  # should end with \

  my $entry;
  my $result = 0; # nothing found yet

  # open this directory
  opendir(DIR, $dir) || die "unable to open dir '$dir': $!";

  my @dirList = ();
  my @fileList = ();
  while ($entry = readdir(DIR)) {
    if ($entry eq '.' || $entry eq '..') { next; }
    
    if (-d "$dir$entry") {
      push (@dirList, "$dir$entry");
    } else {
      push (@fileList, "$dir$entry");
    }
  }

  # done reading, so close directory
  closedir(DIR);

  while ($entry = shift(@fileList)) {
    # is a file... examine name
    # want to display all found, so don't quit on first
    if ($entry =~ m/\~$/ || $entry =~ m/\.bak$/ || 
	$entry =~ m/\.swp$/ || $entry eq 'Thumbs.db') {
      print "found backup or other undesirable file: $entry\n";
      $result++;  # local backup file count
    }
    # .html OK in docs\, but not elsewhere. will not be rolled up into build
    if ($entry =~ m/\.tmp$/  || # also check for .tmp
        $entry =~ m/\.pdf$/ && $dir ne $baseDirSrc."t\\resources\\" # also check for .pdf except in t/resources,
                            && $dir ne $baseDirSrc."examples\\resources\\"   # examples/resources
       ) {
      print "found work file or other undesirable file: $entry\n";
      $result++;  # local backup file count
    }
  }

  while ($entry = shift(@dirList)) {
    # is a directory... recursively call
    $result += checkForBackups("$entry\\");
  }

  return $result;
} # end checkForBackups()

# -----------------------------------------
# clean out existing output structure, create empty dirs in destination
sub prepOutputDirs {
  my $dir = shift;  # should end with \

 #my $parent = $dir;
 #$parent =~ s/v\d\.\d{3}\\$//;

  eraseDir($dir);
  # (re)create new directory
  mkdir($dir);

  # create code, docs, and downloads subdirectories
  mkdir($dir."code");
  mkdir($dir."docs");
  mkdir($dir."downloads");
} # end prepOutputDirs()

sub eraseDir {
  my $dir = shift;

  my $entry;

  # if $dir does exist, remove it recursively (must be empty for rmdir)
  if (-d $dir) {

    # open this directory
    opendir(DIR, $dir) || die "unable to open dir '$dir': $!";

    my @dirList = ();
    my @fileList = ();
    while ($entry = readdir(DIR)) {
      if ($entry eq '.' || $entry eq '..') { next; }
    
      if (-d "$dir$entry") {
        push (@dirList, "$dir$entry\\");
      } else {
        push (@fileList, "$dir$entry");
      }
    }

    # done reading, so close directory
    closedir(DIR);

    # erase all files in this dir
    while ($entry = shift(@fileList)) {
      unlink($entry);
    }
    # recursively visit all child directories
    while ($entry = shift(@dirList)) {
      eraseDir($entry);
    }

    # finally, remove THIS directory
    rmdir($dir);
  }
} # end eraseDir()

# -----------------------------------------
# copy over source/ to dest/code/
# inputs: source and destination dirs (/code will be added to dst)
sub copyToCode {
  my ($src, $dst) = @_;

  my $entry;

  $src .= "*.*";
  $dst .= "\\code\\";

  # put dir names in " " because they often have spaces in them
  system("xcopy \"$src\" \"$dst\" /E");

} # end copyToCode()

# -----------------------------------------
# inputs: source and destination base dirs, extra path built up
# create documentation .pm -> .html
# any .pm file found, see if looks like POD in it, if so run pod2html
# called recursively for each directory
#### unused
sub makeHTML {
  my ($src, $dst, $extra) = @_;
  # intially .../lib/, .../docs/lib/, ''. extra will change

  my ($entry, $input, $output, $isPOD, $outfile);
  # $podBase set up at top

  # open this directory for reading
  opendir(SRC, "$src$extra") || die "unable to open dir '$src$extra': $!";

  my @dirList = ();
  my @fileList = ();
  my @outputList = ();

  while ($entry = readdir(SRC)) {
    if ($entry eq '.' || $entry eq '..') { next; }
    
    if (-d "$src$extra$entry") {
      push (@dirList, $entry);
    } else {
      if ($entry !~ m/\.pm$/) { next; }

      # .pm file. does it contain =cut or =item?
      $isPOD = `grep -c -E "^=cut|^=item" "$src$extra$entry"`;
      if (substr($isPOD, 0, 1) ne '0') {
        push (@fileList, "$src$extra$entry");

        $entry =~ s/\.pm/.html/;
        push (@outputList, "$dst$extra$entry");
      }
    }
  }

  # done reading, so close directory
  closedir(SRC);

  while ($input = shift(@fileList)) {
    $output = shift(@outputList);

    # is a .pm file with POD content
    # $input is full file path and name
    # $output is full file path and name
    # if dir for output doesn't exist yet, mkdir it
    $outpath = $output;
    $outpath =~ s/^[a-z]://i;   # strip off drive
    $outpath =~ s/\\[^\\]+$//;
    if (!-d $outpath."\\") {
      make_path($outpath);
    }

    # --podroot and --podpath don't seem to work, so backpatch links
    # after creating the .html file
    $outfile = `pod2html \"$input\"`;  # string with HTML file
    while ($outfile =~ m#<a>(.*?)</a>#) {
      # outfile $output contains <a> in need of fixup
      # presumably we won't find orphan <a>'s with </a> on next line
      $href = $1;
      $href =~ s#::#/#g;  # globally change :: to /
      # expect href to start with PDF/, so podBase is /Free.SW...lib/
      $href = 'href="' . $podBase . $href . '.html"';  # absolute path, .html fileext
      $outfile =~ s/<a>/<a $href>/;
    }
    # write modified outfile to $output file
    unless (open(OUT, ">$output")) { die "Unable to open POD output file '$output': $!\n"; }
    print OUT $outfile;
    close(OUT); 

  } # process a .pm file found in a directory

  while ($entry = shift(@dirList)) {
    # is a directory... recursively call
    makeHTML($src, $dst, "$extra$entry\\");
  }

} # end makeHTML()

# -----------------------------------------
# create downloads .tar.gz, .zip
#### unused
sub makeDownloads {
  my ($dst) = shift;
  
  # dst/code is the source directory, and dst/downloads is the target directory
  # $outputBasename is like "$GHname-3.001"

  # also build dst/downloads/.downloads control file
  unless (open(OUT, ">$dst\\downloads\\.downloads")) {
    die "Unable to open output .downloads control file to write! $!\n";
  }

  # produce outputBasename.tar from dst/code
  system("$cmd7Zip $dst\\downloads\\$outputBasename.tar $dst\\code\\*");
  
  # produce dst/downloads/outputBasename.tar.gz from outputBasename.tar
  system("$cmd7Zip $dst\\downloads\\$outputBasename.tar.gz $dst\\downloads\\$outputBasename.tar");
   
  # erase outputBasename.tar
  unlink("$dst\\downloads\\$outputBasename.tar");
  print OUT "$outputBasename.tar.gz\n";
  print OUT "The complete package in GNU-zipped tarball.\n";
   
  # product dst/downloads/outputBasename.zip from dst/code
  system("$cmd7Zip $dst\\downloads\\$outputBasename.zip $dst\\code\\*");
  print OUT "$outputBasename.zip\n";
  print OUT "The complete package in Windows ZIP format.\n";
    
  close(OUT);

} # end makeDownloads()

# -----------------------------------------
# insert $VERSION into dist.ini, Makefile.PL, META.json, META.yml
# also dist.ini.old, although it is not currently used ## FOR TIME BEING, IGNORE
# Makefile.PL is no longer R/O
sub update_with_version {
    my ($f, $line);

    my $outtemp = 'xxxxx.temp';
#   my @name = ($builder, 'dist.ini', 'META.json', 'META.yml');
#   my @pattern = ('^(  "VERSION" => ")\d\.\d{3}(",\s)$',
#           '^(version = )\d\.\d{3}(\s)$', 
#           '^(   "version" : ")\d\.\d{3}(",\s)$',
#           '^(version: \')\d\.\d{3}(\'\s)$'
#          );
##  my @name = ($builder, "lib\\$hiDir\\$master", 'INFO\\old\\dist.ini.old');
##  my @pattern = ('^(\s*my \$version\s*=\s*\')\d\.\d{3}(\';.*)$',
##  		   '^(our \$VERSION = \')\d\.\d{3}(\'; # VERSION)',
##	           '^(version = )\d\.\d{3}(\s)$');
    my @name = ($builder,
                "lib\\$hiDir\\$master",
                "README.md",
               );
    my @pattern = ('^(\s*my \$version\s*=\s*\')\d\.\d{3}(\';.*)$',
    		   '^(our \$VERSION = \')\d\.\d{3}(\'; # VERSION)',
                   '^(# $hiDir::$product release )\d\.\d{3}(.*)$',
                  );

    foreach $f (0 .. $#name) {
       #if ($f == 0) { system("attrib -R $name[0]"); }
        unless (open(IN, "<$name[$f]")) { 
            die "Unable to update $name[$f] with version\n";
        }
        unless (open(OUT, ">$outtemp")) { 
            die "Unable to open temporary output file $outtemp\n";
        }
   
        while ($line = <IN>) {
            $line =~ s/$pattern[$f]/$1$VERSION$2/;
	   #if ($ourLAST) {
	   #    $line =~ s/^my \$LAST_UPDATE/our \$LAST_UPDATE/;
	   #}
	    print OUT $line;
        }
   
        close(IN);
        close(OUT);
	system("copy $outtemp $name[$f]");

	system("dos2unix $name[$f]");

       #if ($f == 0) { system("attrib +R $name[0]"); }
    }
    system("erase $outtemp");
}

# -----------------------------------------
# update all .pm or .pl files in a directory
#### no longer called
sub update_VERSION {
    my $src = shift;  # single directory to work in for this call
    my $ro_flag = shift;  # true if expect R/O file

    my ($entry, $name, $entry, $line);
    my $pattern = '^# VERSION';
    my $newVer  = "our \$VERSION = '$VERSION'; # VERSION";

    my $outtemp = 'xxxxx.temp';

    # open this directory for reading
    opendir(SRC, "$src") || die "unable to open dir '$src': $!";

    my @dirList = ();
    my @fileList = ();

    while ($entry = readdir(SRC)) {
        if ($entry eq '.' || $entry eq '..') { next; }
    
        if (-d "$src$entry") {
            push (@dirList, "$src$entry/");
        } else {
            if ($entry !~ m/\.p[lm]$/) { next; }

            # .pm or .pl file
            push (@fileList, "$src$entry");

        }
    }

    # done reading, so close directory
    # have list of files and subdirectories within this one
    closedir(SRC);

    while ($name = shift(@fileList)) {

        # $name is a .pm file and is expected to be Read-Only
	# OR $name is a .pl file and is expected to be Read-Write
        # $name is full file path and name

	# make Read-Write
	if ($ro_flag) { system("attrib -R $name"); }

        unless (open(IN, "<$name")) { 
            die "Unable to update $name with version\n";
        }
        unless (open(OUT, ">$outtemp")) { 
            die "Unable to open temporary output file $outtemp\n";
        }
   
        while ($line = <IN>) {
            $line =~ s/$pattern/$newVer/;
	    print OUT $line;
        }
   
        close(IN);
        close(OUT);
        $outtemp =~ s#/#\\#g;
        $name =~ s#/#\\#g;
	system("copy $outtemp $name");
        system("erase $outtemp");

	# restore Read-Only
	if ($ro_flag) { system("attrib +R $name"); }
    } # process a .pm file found in a directory

    while ($entry = shift(@dirList)) {
        # is a directory... recursively call
        update_VERSION($entry, $ro_flag);
    }

}

#--------------
# read version file to get various versions and settings
# return as strings, not numbers! e.g., don't turn '1.10' into '1.1'
sub read_version {
    my $filename = shift();

    my @var_list = qw(version perl_v make_maker test_exception test_memory_cycle compress_zlib font_ttf graphics_tiff harfbuzz_shaper image_png_libpng text_markdown html_treebuilder pod_simple_xhtml);

    my $VER;  # file handle for version input
    unless (open($VER, "<version")) {
      die "Unable to open input 'version' control file $filename to read! $!\n";
    }
   
    # read a line, strip off comments (#) and leading/trailing blanks
    # anything left? should be name (UC) and value
    my (%entries, $line);
    # will read each value into hash $entries{lc(name)}, 
    # return in specific order

    while ($line = <$VER>) {
	chomp($line);
        $line =~ s/#(.*)$//;   # strip any comment
	$line =~ s/^\s+//;     # strip any leading spaces
	$line =~ s/\s+$//;     # strip any trailing spaces
        if ($line eq '') { next; }

        my @list = split /\s+/, $line;  # should be name, value string pair
	if (@list != 2) {
	    die "'version' line '$line' unexpected format\n";
	}
	$entries{lc($list[0])} = "v$list[1]";
    }
    close ($VER);

    # assign to local list in order of @var_list, removing from hash.
    # if anything missing or left over, give error
    my @local_list;
    foreach my $name (@var_list) {
	if (!defined $entries{$name}) {
	    die "Expected entry '".uc($name)."' in version file, but not found!\n";
        }
	# trim off leading 'v', hopefully string not converted to number
	push @local_list, substr("$entries{$name}",1);
	delete $entries{$name};
    }
    # at this point, %entries should be empty
    if (!scalar(keys %entries)) {
        return (@local_list);
    }
    # not empty, complain
    print "Extra entries found in version file:\n";
        foreach my $name (keys %entries) {
	    print "  $name = $entries{$name}\n";
	}
    die "Failed!\n";

} # end read_version()

# ---------------------
# Builder.pm: update fields GRAPHICS_TIFF, HARFBUZZ_SHAPER, IMAGE_PNG_LIBPNG,
#                           TEXT_MARKDOWN, HTML_TREEBUILDER, POD_SIMPLE_XHTML
#             VERSION should already be updated by update_with_version()
# also my $LAST_UPDATE to our $LAST_UPDATE if necessary
sub update_Builder {
    # file should be ./lib/PDF/Builder.pm
    my @pattern = ("(\\\$GrTFversion\\s*=\\s*)[\\d]+", 
                   "(\\\$HBShaperVer\\s*=\\s*)[\\d.]+",
	           "(\\\$LpngVersion\\s*=\\s*)[\\d.]+",
                   "(\\\$TextMarkdown\\s*=\\s*)[\\d.]+",
                   "(\\\$HTMLTreeBldr\\s*=\\s*)[\\d.]+",
                   "(\\\$PodSimpleXHTML\\s*=\\s*)[\\d.]+",
	          );
    my @newpat  = ("$GRAPHICS_TIFF",
		   "$HARFBUZZ_SHAPER",
	           "$IMAGE_PNG_LIBPNG",
		   "$TEXT_MARKDOWN",
		   "$HTML_TREEBUILDER",
		   "$POD_SIMPLE_XHTML",
		  );

    my $infile = "lib\\$hiDir\\$master";
    my $outtemp = "xxxx.tmp";
    unless (open(IN, "<$infile")) {
	die "Unable to read $infile for update\n";
    }
    unless (open(OUT, ">$outtemp")) {
	die "Unable to write temporary output file for $infile update\n";
    }

    my ($line, $i, @frags);
    while ($line = <IN>) {
	# $line still has line-end \n
	for ($i=0; $i<scalar(@pattern); $i++) {
            if ($line =~ m/$pattern[$i]/) {
		@frags = split /[\d.]+/, $line;
	        $line = $frags[0].$newpat[$i].$frags[1];
		last;
            }
	}
       #if ($ourLAST) {
       #    $line =~ s/^my \$LAST_UPDATE/our \$LAST_UPDATE/;
       #}
	print OUT $line;
    }

    close(IN);
    close(OUT);
    system("copy $outtemp $infile");
    unlink($outtemp);
} # end update_Builder()

# ---------------------
# Makefile.PL: update fields PERL_V, MAKE_MAKER, TEST_EXCEPTION, 
#              TEST_MEMORY_CYCLE, COMPRESS_ZLIB, FONT_TTF, GRAPHICS_TIFF, 
#              HARFBUZZ_SHAPER, IMAGE_PNG_LIBPNG, TEXT_MARKDOWN, 
#              HTML_TREEBUILDER, POD_SIMPLE_XHTML
#              VERSION should already be updated by update_with_version()
sub update_Makefile {
    # file should be ./Makefile.PL
    my @pattern = (
		   "^use \\d\\.\\d{6};",
		   "^use ExtUtils::MakeMaker\\s+[\\d.]+",
		   "\\\$PERL_version\\s*=\\s*'\\d\\.\\d{6}'",
		   "\\\$MakeMaker_version\\s*=\\s*'[\\d.]+'",
		   # version should already be handled
                   "\"Test::Exception\"\\s*=>\\s*[\\d.]+",
                   "\"Test::Memory::Cycle\"\\s*=>\\s*[\\d.]+",
                   "\"Compress::Zlib\"\\s*=>\\s*[\\d.]+",
                   "\"Font::TTF\"\\s*=>\\s*[\\d.]+",
	           "\"Graphics::TIFF\"\\s*=>\\s*[\\d.]+,", 
	           "\"Image::PNG::Libpng\"\\s*=>\\s*[\\d.]+,",
                   "\"HarfBuzz::Shaper\"\\s*=>\\s*[\\d.]+,",
                   "\"Text::Markdown\"\\s*=>\\s*[\\d.]+,",
                   "\"HTML::TreeBuilder\"\\s*=>\\s*[\\d.]+,",
                   "\"Pod::Simple::XHTML\"\\s*=>\\s*[\\d.]+,",
	          );
    my @newpat  = (
		   "$PERL_V",
		   "$MAKE_MAKER",
		   "$PERL_V",
		   "$MAKE_MAKER",
		   # version should already be handled
		   "$TEST_EXCEPTION",
		   "$TEST_MEMORY_CYCLE",
		   "$COMPRESS_ZLIB",
		   "$FONT_TTF",
	           "$GRAPHICS_TIFF",
	           "$IMAGE_PNG_LIBPNG",
		   "$HARFBUZZ_SHAPER",
		   "$TEXT_MARKDOWN",
		   "$HTML_TREEBUILDER",
		   "$POD_SIMPLE_XHTML",
		  );

    my $infile = $builder;
    my $outtemp = "xxxx.tmp";
    unless (open(IN, "<$infile")) {
	die "Unable to read $infile for update\n";
    }
    unless (open(OUT, ">$outtemp")) {
	die "Unable to write temporary output file for $infile update\n";
    }

    my ($line, $i, @frags);
    while ($line = <IN>) {
	# $line still has line-end \n
	for ($i=0; $i<scalar(@pattern); $i++) {
	    if ($line =~ m/$pattern[$i]/) {
	        @frags = split /[\d.]+/, $line;
	        $line = $frags[0].$newpat[$i].$frags[1];
		last;
	    }
	}
       #if ($ourLAST) {
       #    $line =~ s/^my \$LAST_UPDATE/our \$LAST_UPDATE/;
       #}
	print OUT $line;
    }

    close(IN);
    close(OUT);
    system("copy $outtemp $infile");
    unlink($outtemp);
} # end update_Makefile()

sub update2_Makefile {
    # file should be ./Makefile
    # gzip --best --> devtools\gzip --best
    my @pattern = (
		   "gzip --best",
	          );
    my @newpat  = (
		   "devtools\\gzip --best",
	          );

    my $infile = $script;
    my $outtemp = "xxxx.tmp";
    unless (open(IN, "<$infile")) {
	die "Unable to read $infile for update\n";
    }
    unless (open(OUT, ">$outtemp")) {
	die "Unable to write temporary output file for $infile update\n";
    }

    my ($line, $i, @frags);
    while ($line = <IN>) {
	# $line still has line-end \n
	for ($i=0; $i<scalar(@pattern); $i++) {
	    if ($line =~ m/$pattern[$i]/) {
	        $line =~ s/$pattern[$i]/$newpat[$i]/;
		last;
	    }
	}
	print OUT $line;
    }

    close(IN);
    close(OUT);
    system("copy $outtemp $infile");
    unlink($outtemp);
} # end update2_Makefile()

# ---------------------
# META.*: update fields VERSION, PERL_V, MAKE_MAKER, TEST_EXCEPTION, 
#         TEST_MEMORY_CYCLE, COMPRESS_ZLIB, FONT_TTF, GRAPHICS_TIFF, 
#         HARFBUZZ_SHAPER, IMAGE_PNG_LIBPNG, TEXT_MARKDOWN, HTML_TREEBUILDER, 
#         POD_SIMPLE_XHTML
sub update_META {
    # files should be ./META.json and ./META.yml
    # META.json
    my @Jpattern = (
		    # MM will be tripped twice, first time 0 is OK
		    "\"ExtUtils::MakeMaker\"\\s*:\\s*\"[\\d.]+\"",
                    "\"Compress::Zlib\"\\s*:\\s*\"[\\d.]+\"",
                    "\"Font::TTF\"\\s*:\\s*\"[\\d.]+\"",
	            "\"perl\"\\s*:\\s*\"\\d\\.\\d{6}\"",
                    "\"Test::Exception\"\\s*:\\s*\"[\\d.]+\"",
                    "\"Test::Memory::Cycle\"\\s*:\\s*\"[\\d.]+\"",
	            "\"Graphics::TIFF\"\\s*:\\s*\"[\\d.]+\"", 
                    "\"HarfBuzz::Shaper\"\\s*:\\s*\"[\\d.]+\"",
	            "\"Image::PNG::Libpng\"\\s:\\s*\"[\\d.]+\"",
	            "\"Text::Markdown\"\\s:\\s*\"[\\d.]+\"",
	            "\"HTML::TreeBuilder\"\\s:\\s*\"[\\d.]+\"",
	            "\"Pod::Simple::XHTML\"\\s:\\s*\"[\\d.]+\"",
		    # meta-spec version has no "" around value, no update
	            "\"version\"\\s*:\\s*\"\\d\\.\\d{3}\"",
	           );
    my @Jnewpat  = (
		    "$MAKE_MAKER",
		    "$COMPRESS_ZLIB",
		    "$FONT_TTF",
	            "$PERL_V",
		    "$TEST_EXCEPTION",
		    "$TEST_MEMORY_CYCLE",
	            "$GRAPHICS_TIFF",
		    "$HARFBUZZ_SHAPER",
	            "$IMAGE_PNG_LIBPNG",
		    "$TEXT_MARKDOWN",
		    "$HTML_TREEBUILDER",
		    "$POD_SIMPLE_XHTML",
	            "$VERSION",
	 	   );
    # META.yml
    my @Ypattern = (
		    # MM will be tripped twice, first time 0 is OK
		    "ExtUtils::MakeMaker:\\s*'[\\d.]+'",
                    "Test::Exception:\\s*'[\\d.]+'",
                    "Test::Memory::Cycle:\\s*'[\\d.]+'",
	            "Graphics::TIFF:\\s*'[\\d.]+'", 
                    "HarfBuzz::Shaper:\\s*'[\\d.]+'",
	            "Image::PNG::Libpng:\\s*'[\\d.]+'",
	            "Text::Markdown:\\s*'[\\d.]+'",
	            "HTML::TreeBuilder:\\s*'[\\d.]+'",
	            "Pod::Simple::XHTML:\\s*'[\\d.]+'",
                    "Compress::Zlib:\\s*'[\\d.]+'",
                    "Font::TTF:\\s*'[\\d.]+'",
	            "perl:\\s*'\\d\\.\\d{6}'",
	            # there is meta-spec version: which is indented, no update
	            "^version:\\s*'\\d\\.\\d{3}'",
	           );
    my @Ynewpat  = (
		    "$MAKE_MAKER",
		    "$TEST_EXCEPTION",
		    "$TEST_MEMORY_CYCLE",
	            "$GRAPHICS_TIFF",
		    "$HARFBUZZ_SHAPER",
	            "$IMAGE_PNG_LIBPNG",
	            "$TEXT_MARKDOWN",
	            "$HTML_TREEBUILDER",
	            "$POD_SIMPLE_XHTML",
		    "$COMPRESS_ZLIB",
		    "$FONT_TTF",
	            "$PERL_V",
	            "$VERSION",
                   );
    my @infiles = ('META.json', 'META.yml');
    my ($i, $infile);
    my $outtemp = "xxxx.tmp";
    for ($i=0; $i<scalar(@infiles); $i++) {
	$infile = $infiles[$i];
        unless (open(IN, "<$infile")) {
	    die "Unable to read $infile for update\n";
        }
        unless (open(OUT, ">$outtemp")) {
	    die "Unable to write temporary output file for $infile update\n";
        }

        my ($line, $j, @frags);
        while ($line = <IN>) {
	    # $line still has line-end \n
	    if ($i == 0) {
	        for ($j=0; $j<scalar(@Jpattern); $j++) {
		    if ($line =~ m/$Jpattern[$j]/) {
			@frags = split /[\d.]+/, $line;
	                $line = $frags[0].$Jnewpat[$j].$frags[1];
		        last;
		    }
	        }
	    } else {
	        for ($j=0; $j<scalar(@Ypattern); $j++) {
		    if ($line =~ m/$Ypattern[$j]/) {
			@frags = split /[\d.]+/, $line;
	                $line = $frags[0].$Ynewpat[$j].$frags[1];
		        last;
		    }
	        }
	    }
           #if ($ourLAST) {
           #    $line =~ s/^my \$LAST_UPDATE/our \$LAST_UPDATE/;
           #}
	    print OUT $line;
        }

        close(IN);
        close(OUT);
        system("copy $outtemp $infile");
        unlink($outtemp);
    } # loop through META files
} # end update_META()

# ---------------------
# t/00-all-usable.t update fields GRAPHICS_TIFF, HARFBUZZ_SHAPER, 
#                   IMAGE_PNG_LIBPNG, TEXT_MARKDOWN, HTML_TREEBUILDER, 
#                   POD_SIMPLE_XHTML
# both library copy and temp copy
sub update_all_usable {
    # file should be ./t/00-all-usable.t 
    my @pattern = ("\\\$GrTFversion\\s*=\\s*[\\d.]+", 
	           "\\\$LpngVersion\\s*=\\s*[\\d.]+",
                   # (dummy update for future use)
                   "\\\$HBShaperVer\\s*=\\s*[\\d.]+",
                   "\\\$TextMarkdown\\s*=\\s*[\\d.]+",
                   "\\\$HTMLTreeBldr\\s*=\\s*[\\d.]+",
                   "\\\$PodSimpleXHTML\\s*=\\s*[\\d.]+",
	          );
    my @newpat  = ("$GRAPHICS_TIFF",
	           "$IMAGE_PNG_LIBPNG",
                   # (dummy update for future use)
		   "$HARFBUZZ_SHAPER",
		   "$TEXT_MARKDOWN",
		   "$HTML_TREEBUILDER",
		   "$POD_SIMPLE_XHTML",
		  );

    my $infile = "t\\00-all-usable.t";
    my $outtemp = "xxxx.tmp";
    unless (open(IN, "<$infile")) {
	die "Unable to read $infile for update\n";
    }
    unless (open(OUT, ">$outtemp")) {
	die "Unable to write temporary output file for $infile update\n";
    }

    my ($line, $i, @frags);
    while ($line = <IN>) {
	# $line still has line-end \n
	for ($i=0; $i<scalar(@pattern); $i++) {
	    if ($line =~ m/$pattern[$i]/) {
		@frags = split /[\d.]+/, $line;
	        $line = $frags[0].$newpat[$i].$frags[1];
	        last;
	    }
	}
       #if ($ourLAST) {
       #    $line =~ s/^my \$LAST_UPDATE/our \$LAST_UPDATE/;
       #}
	print OUT $line;
    }

    close(IN);
    close(OUT);
    system("copy $outtemp $infile");
    unlink($outtemp);
} # end update_all_usable()

# ---------------------
# optional_update.pl
sub update_optional {
    # file should be optional_update.pl
    my @pattern = ("\"Graphics::TIFF\",\\s*\"[\\d.]+\"", 
	           "\"Image::PNG::Libpng\",\\s*\"[\\d.]+\"",
                   "\"HarfBuzz::Shaper\",\\s*\"[\\d.]+\"",
                   "\"Text::Markdown\",\\s*\"[\\d.]+\"",
                   "\"HTML::TreeBuilder\",\\s*\"[\\d.]+\"",
                   "\"Pod::Simple::XHTML\",\\s*\"[\\d.]+\"",
	          );
    my @newpat  = ("$GRAPHICS_TIFF",
	           "$IMAGE_PNG_LIBPNG",
		   "$HARFBUZZ_SHAPER",
		   "$TEXT_MARKDOWN",
		   "$HTML_TREEBUILDER",
		   "$POD_SIMPLE_XHTML",
		  );

    my $infile = "tools/optional_update.pl";
    my $outtemp = "xxxx.tmp";
    unless (open(IN, "<$infile")) {
	die "Unable to read $infile for update\n";
    }
    unless (open(OUT, ">$outtemp")) {
	die "Unable to write temporary output file for $infile update\n";
    }

    my ($line, $i, @frags);
    while ($line = <IN>) {
	# $line still has line-end \n
	for ($i=0; $i<scalar(@pattern); $i++) {
	    if ($line =~ m/$pattern[$i]/) {
		# note that unlike other updates, this has two number values
		@frags = split /[\d.]+/, $line;
	        $line = $frags[0].($i+1).$frags[1].$newpat[$i].$frags[2];
	        last;
	    }
	}
       #if ($ourLAST) {
       #    $line =~ s/^my \$LAST_UPDATE/our \$LAST_UPDATE/;
       #}
	# whether ^# VERSION or already expanded our $VERSION, rewrite
	if ($line =~ m/# VERSION/) {
	    $line = "our \$VERSION = '$VERSION'; # VERSION\n";
	}
	print OUT $line;
    }

    close(IN);
    close(OUT);
    $infile =~ s#/#\\#g;
    system("copy $outtemp $infile");
    unlink($outtemp);
} # end update_optional()
