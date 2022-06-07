#!/usr/bin/perl
# buildDoc.pl builds documentation tree from Perl .pod and .pm files (POD)
#   in case of duplicate names, .pod is used in preference to .pm
# 
# (c) copyright 2018-2022 Catskill Technology Services, LLC
# licensed under license used in PDF::Builder package (LGPL 2.1+)
#
# there is partial code to implement --all to build all PODs, or update an
# existing documentation tree with specific name(s), but the whole process
# is fast enough that it didn't seem worthwhile to do anything but --all
#
# -h or --help or (nothing) for help
# --all if you have no other command line parameters

use strict;
use warnings;
use Getopt::Long;

# VERSION
my $LAST_UPDATE = '3.024'; # manually update whenever code is changed

# =============
# CONFIGURATION  these may be overridden by command-line flags. If reading from
#                an existing index.html TOC file, the stored values will be 
#                used.
#                The default settings assume running buildDoc.pl in the docs/
#                directory of the product.
# --all
my $all = '';  # doing --all by default, but still need in command line (else
               #   thinks it's a help request) if no other flag
# --libtop=s
my $libtop = "../lib"; # source .pm tree e.g., PDF/Builder.pm -> 
                       # ../lib/PDF/Builder.pm
                       # assuming run from within docs/ (current directory)
# --leading=s
my $leading = "PDF";   # optional level(s) below $libtop
                       # / or :: divider between directories
                       # set to '' to omit
# --rootname=s
my $rootname = "Builder";  # e.g., for PDF::Builder, specify Builder.pm as root file
                           # and Builder/ as top directory, in case there are 
			   # other PDF:: entries present. $rootname must NOT
			   # be ''
# --output=s
my $output = ".";  # top of tree where outputting .html files to
                   # $output/$leading/ created under current directory
		   # unless $leading is empty (in which case just use $output)
# --toc=s
my $TOC = "";  # $output/$TOC is table of contents file (set default once
               # $rootname is determined)
#
# --dirsep=s
my $dirsep = '/';  # also works for Windows (but not on command line)
# --absep=s
my $abstract_sep = ' - ';  # PDF::Builder style separator between PM name and
                           # the abstract description in NAME entry
# --flagorphans  to set to 1
my $no_root_link = '0';  # if 1, output info message that no link path from root
                         # very common, and flagged in TOC index.html
# --noignore  to set to 1
my $not_pm = '0';        # if 1, output info message that non-.pm file ignored
# -h or --help to ask for help
my $help = '0';
# =============

my ($i, $fname, $bname, $filename, $dirname);
my @filelist;  # ignored if --all, else is list of files to update existing 
               #   doc tree. may be in file path format or PM format
my @file_list; # complete list of files (in filepath format). array of hashes
               #  fpname => filepath-format name
	       #  ofname => output filepath and name
	       #  pmname => PM format name
	       #  status => status flag  -2 = not processed yet
	       #                         -1 = scheduled for processing
	       #                          0 = no POD (empty .html)
	       #                          1 = good .html from POD
	       #                          2 = POD errors reported in .html
	       #                          3 = errors to stderr (may or may not
	       #                              be an .html file)
	       #  accessible => accessible (from root) flag 0=no 1=yes
	       #  abstract => text  from NAME POD entry
	       #  parents => []  build list of parent(s) chain
	       #  siblings => []  build list of any siblings
	       #  children => []  build list of any children

# command line flags and files
if (scalar(@ARGV) == 0) { help(); exit(1); }
GetOptions( 'all' => \$all,
	    'help' => \$help, 'h' => \$help,
	    'dirsep=s' => \$dirsep,
	    'absep=s' => \$abstract_sep,
	    'flagorphans' => \$no_root_link,
	    'noignore' => \$not_pm,
	    'libtop=s' => \$libtop,
            'leading=s' => \$leading,
	    'rootname=s' => \$rootname,
	    'output=s' =>\$output,
	    'toc=s' => \$TOC,
          );
# force --all for time being
$all = 1;
# asked for help?
if ($help) { help(); exit(2); }
if ($leading eq '""' || $leading eq "''") { $leading = ''; }
if ($leading ne '') { $leading =~ s#::#/#g; }
if ($rootname eq '""' || $rootname eq "''") { $rootname = ''; }

##print "all='$all', help='$help', dirsep='$dirsep', absep='$abstract_sep',\n";
##print "  flagorphans='$no_root_link', noignore='$not_pm', libtop='$libtop',\n";
##print "  leading='$leading', rootname='$rootname', output='$output', toc='$TOC'\n\n"; 

if ($rootname eq '') {
    die "ERROR --rootname must not be empty!\n";
}
if ($TOC eq '') { $TOC = $rootname . "_index.html"; }

# TBD material for processing individual modules to update docs
if (!$all && scalar(@ARGV) >= 1) {
    while ($fname = $ARGV[0]) {
	if ($fname =~ m#^-#) { 
 	    # an UNKNOWN flag to skip over
	    print "$fname WARNING  unknown flag skipped\n";
	    next; 
	} 
        if (index($fname, '::') > -1) {
            # Perl format dir::dir::dir::module
	    $filename = toFP($fname);
	} else {
	    # OS format dir/dir/dir/module.pm
	    $filename = $fname;
	}
	push @filelist, $filename;
    }
}

if ($all) {
    # any stray stuff? ARGV should be empty by now
    foreach (@ARGV) {
	print "WARNING  extra command line content '$_' ignored\n";
    }

    # get complete list of filepaths in @file_list and initialize flags
    @file_list = ();
    # top level name and dir are the start, then everything in that dir
    # $libtop/$leading/$rootname.pm may exist, and be first entry
    #   if doesn't exist, all .pm files in that directory are root
    # then $libtop/$leading/$rootname/ follow all the way down if $rootname
    #   not empty. if it is, all directories in top directory are followed
    $fname = "$libtop/";
    if ($leading ne '') { $fname .= "$leading/"; }
    $fname .= $rootname;

    if (-f "$fname.pod" && -r "$fname.pod") {
        $fname = "$fname.pod";
    } else {
        $fname = "$fname.pm";
    }
    if (!-f $fname) {
        die "$fname ERROR  no $rootname .pod or .pm files found\n";
        ## all top-level .pod, .pm files mark as status -1 (.pod has priority over .pm)
        #@filelist = ();
        #$dirname = $libtop;
        #if ($leading ne '') { $dirname .= "/$leading"; }
        #opendir my $dh, $dirname or die "$dirname ERROR  can't open and read directory\n";
        #while (my $direntry = readdir $dh) {
        #	if ($direntry eq '.' || $direntry eq '..') { next; }
    
        #	$fname = "$dirname/$direntry";
        #	# if it's .pm, check to see if there is a readable .pod of the same name, and if so,
        #	# ignore the .pm file
        #	if (-f $fname) {
        #	    # it's a file. readable if .pod or .pm?
        #	    if ($fname =~ m#\.pm$#) { 
        #	        $bname = $fname;
        #	        $bname =~ s#\.pm$#.pod#;
        #	        if (-f $bname && -r $bname) { next; } # use .pod instead
        #
        #	        if (!-r $fname) {
        #	    	    print "$fname WARNING  top-level .pm file not readable\n";
        #	        } else {
        #		    push @filelist, $fname;
        #	        }
        #	    } 
        #	    if ($fname =~ m#\.pod$#) { 
        #		if (!-r $fname) {
        #		    print "$fname WARNING  top-level .pod file not readable\n";
        #		} else {
        #		    push @filelist, $fname;
        #		}
        #	    } 
        #	}
        #}
        #closedir $dh;
    } else {
        if (!-r $fname) {
	    die "$fname ERROR  $rootname .pod or .pm file not readable\n";
        }
        # just $rootname.pm is starting point
        @filelist = ( $fname );
    }
    foreach (@filelist) {
        push @file_list, { fpname=>$_,       # filepath name (full filepath to 
		                             # .pm/.pod source)
			   ofname=>toOF($_), # output filepath name
	                   pmname=>toPM($_), # PM format name e.g., PDF::Builder
		           status=>-1,       # status -1 ready to read
		           accessible=>1,    # root accessible yes
	   	           abstract=>'',     # no abstract yet
		           parents=>[],      # no parents yet
		           siblings=>[],     # no siblings yet
		           children=>[],     # no children yet
		           depth=>0,         # depth of directory
                         };
    }

    if ($rootname eq '') {  # should NOT see this
        # all subdirectories under $libtop/$leading are to be followed
        @filelist = ();
        $dirname = $libtop;
        if ($leading ne '') { $dirname .= "/$leading"; }
        opendir my $dh, $dirname or die "$dirname ERROR  can't open and read directory\n";
        while (my $direntry = readdir $dh) {
            if ($direntry eq '.' || $direntry eq '..') { next; }
    
            $fname = "$dirname/$direntry";
            if (-d $fname) {
	        # it's a directory, so use it
	        push @filelist, $fname;
            }
        }
        closedir $dh;
    } else {
        # only $libtop/$leading/$rootname is to be followed, if exists
        $dirname = $libtop;
        if ($leading ne '') { $dirname .= "/$leading"; }
        if (-d "$dirname/$rootname") {
	    @filelist = ( "$dirname/$rootname" );
        } else {
	    @filelist = ();
        }
    }
    # build list of the remaining files
    foreach (@filelist) {
        push @file_list, buildList($_, toPM($_));
    }
} else {
    # read in existing index.html, add or reset entries in @file_list
    # as found in @filelist. flags from index.html.
    if (scalar @filelist == 0) { die "no files given to update\n"; }
    # TBD ============ not for now
}

# sort @file_list on hash pmname entry. 
# just a simple bubble sort (list shouldn't be that long).
# sorting after build list, because update might have added a new entry at end
for (my $max_i=$#file_list; $max_i>0; $max_i--) {
    my $swap = 0; # no swaps seen
    for (my $i=0; $i<$max_i; $i++) {
        if ($file_list[$i]{'pmname'} gt $file_list[$i+1]{'pmname'}) {
	    # need to swap records i and i+1
	    # copying one hash to another can be tricky business, so
	    #   we'll do it the hard way
	    # parents, siblings, children arrays s/b empty
	    my %temp;
	    $temp{'pmname'} = $file_list[$i]{'pmname'};
	    $temp{'fpname'} = $file_list[$i]{'fpname'};
	    $temp{'ofname'} = $file_list[$i]{'ofname'};
	    $temp{'status'} = $file_list[$i]{'status'};
	    $temp{'accessible'} = $file_list[$i]{'accessible'};
	    $temp{'abstract'} = $file_list[$i]{'abstract'};
            $temp{'parents'} = $file_list[$i]{'parents'};
            $temp{'siblings'} = $file_list[$i]{'siblings'};
            $temp{'children'} = $file_list[$i]{'children'};
            $temp{'depth'} = $file_list[$i]{'depth'};

	    $file_list[$i]{'pmname'} = $file_list[$i+1]{'pmname'};
	    $file_list[$i]{'fpname'} = $file_list[$i+1]{'fpname'};
	    $file_list[$i]{'ofname'} = $file_list[$i+1]{'ofname'};
	    $file_list[$i]{'status'} = $file_list[$i+1]{'status'};
	    $file_list[$i]{'accessible'} = $file_list[$i+1]{'accessible'};
	    $file_list[$i]{'abstract'} = $file_list[$i+1]{'abstract'};
            $file_list[$i]{'parents'} = $file_list[$i+1]{'parents'};
            $file_list[$i]{'siblings'} = $file_list[$i+1]{'siblings'};
            $file_list[$i]{'children'} = $file_list[$i+1]{'children'};
            $file_list[$i]{'depth'} = $file_list[$i+1]{'depth'};

	    $file_list[$i+1]{'pmname'} = $temp{'pmname'};
	    $file_list[$i+1]{'fpname'} = $temp{'fpname'};
	    $file_list[$i+1]{'ofname'} = $temp{'ofname'};
	    $file_list[$i+1]{'status'} = $temp{'status'};
	    $file_list[$i+1]{'accessible'} = $temp{'accessible'};
	    $file_list[$i+1]{'abstract'} = $temp{'abstract'};
            $file_list[$i+1]{'parents'} = $temp{'parents'};
            $file_list[$i+1]{'siblings'} = $temp{'siblings'};
            $file_list[$i+1]{'children'} = $temp{'children'};
            $file_list[$i+1]{'depth'} = $temp{'depth'};

	    $swap = 1;
        }
    }
    if (!$swap) { last; }
}

# now we have an up-to-date and sorted @file_list of files to process
# loop twice: 1. process all status=-1 and their descendants
#             2. any status=-2 that are left, warn and change to -1 and repeat
my ($any_minus1, $source, $target, $htmlfile, $errorfile);
do {
    $any_minus1 = 0; # haven't set any status -1 this pass
    for (my $i=0; $i<scalar @file_list; $i++) {
        if ($file_list[$i]{'status'} == -1) {
	    # found a status -1 ("ready") to process
	    $any_minus1 = 1;

	    $source = $file_list[$i]{'fpname'};
	    $target = $file_list[$i]{'ofname'};

	    # $target may not exist yet, nor may its path
 	    mkdir_list($target);
	    # assuming no problem with overwriting .html output

	    # run pod2html and produce .html file
	    if (-e "pod2html.stderr") {
	        unlink "pod2html.stderr";
	    }
	    print STDERR "processing $source\n";
	    system("pod2html --podpath=$libtop $source --outfile=$target 2>pod2html.stderr");
	    # always produces pod2html.stderr, hopefully empty

	    if (-e $target) {
	        # will stick any error messages in just-created 
	        #   .html file
	        $htmlfile = slurp($target);
	        $file_list[$i]{'status'} = 1;  # OK (so far)
            } else {
	        # create dummy .html file to hold error messages
	        $htmlfile = empty();
	        $file_list[$i]{'status'} = 3;  # serious error
	    }
	    # always put in a title
	    $htmlfile =~ s#<title></title>#<title>$file_list[$i]{'pmname'}</title>#;
	    # is it empty?
	    if ($htmlfile =~ m#<body>\s*</body>#) {
		print "$source INFO  no POD content\n";
		$file_list[$i]{'status'} = 0;
		$htmlfile =~ s#</body>#No documentation (POD) in this module</body>#;
	    }
	    # POD errors and warnings reported?
	    if ($htmlfile =~ m#id="POD-ERRORS"#) {
		print "$source WARNING  internal POD errors reported by pod2html\n";
		$file_list[$i]{'status'} = 2;
	    }
	    # errors output to STDERR?
	    if (!-z "pod2html.stderr") {
		print "$source ERROR  POD errors reported by pod2html\n";
		$file_list[$i]{'status'} = 3;
		my $errorfile = slurp("pod2html.stderr");
		$htmlfile =~ s#</body>#<h1 id="POD-STDERR">SEVERE ERRORS</h1><pre>$errorfile</pre>\n</body>#;
		# put entry in "index" section, if exists
		if ($htmlfile =~ m#<ul id="index">#) {
		# first end-list at beginning of line
		    $htmlfile =~ s#\n</ul>#\n  <li><a href="\#POD-STDERR">SEVERE ERRORS</a></li>\n</ul>#;
	        }
	    }

	    # examine and modify $htmlfile contents:
	    #
	    # update links (fix href path)

	    # prepare pwd's list of directories, as is reused
	    my $pwd = $target;
	    $pwd =~ s#^$output/##;
	    my @pwd_dirs = split /[\\\/]/, $pwd;
	    # last one is filename, not needed here
	    pop @pwd_dirs;
	    # if first one is empty (was absolute path), discard
	    if (scalar @pwd_dirs > 0 && $pwd_dirs[0] eq '') {
		shift @pwd_dirs;
	    }
	    # if first one is . discard
	    if (scalar @pwd_dirs > 0 && $pwd_dirs[0] eq '.') {
		shift @pwd_dirs;
	    }

	    # go through all links in .html that are not #name
	    #   format & set any that are still status -2 to -1 for 
	    #   processing in next loop (also set $any_minus1 = 1)
	    while ($htmlfile =~ m#<a href="([^"]+)">([^<]+)</a>#g) {
	        my $href = $1;
	        my $linkname = $2;
	        # discard if href is just #name 
	        # (an internal link to a heading) or an
	        # external link (http[s]:// ftp:// etc.)
	        if ($href =~ m/^#/) { next; }
	        if ($href =~ m#^[a-z]+://#i) { next; }
	        # strip off /$libtop/
	        $href =~ s#^/$libtop/##;

		# make list of dirs in target ($href)
		my ($path, $target) = split /#/, $href;
		if (!defined $target) { $target = ''; }
		my @target_dirs = split /[\\\/]/, $path;
		# last one is filename, save
		my $newhref = pop @target_dirs;
		# if first one is empty (was absolute path), discard
		if (scalar @target_dirs > 0 && $target_dirs[0] eq '') {
		    shift @target_dirs;
		}
		# if first one is . discard
		if (scalar @target_dirs > 0 && $target_dirs[0] eq '.') {
		    shift @target_dirs;
		}

		# now we have two arrays. discard matching 
		# elements until mismatch or one or both empty.
		# for each element remaining in pwd_dirs, add
		# a ../ to the front of remaining elements of
		# target_dirs and form newhref.
		my @copy_pwd_dirs = @pwd_dirs;
		while (scalar @copy_pwd_dirs > 0 &&
		       scalar @target_dirs > 0) {
		    if ($copy_pwd_dirs[0] eq $target_dirs[0]) {
			shift @copy_pwd_dirs;
			shift @target_dirs;
		    } else {
			last;
		    }
		}
		if (scalar @target_dirs > 0) {
		    # something left of target dir (href)
		    $newhref = join($dirsep, @target_dirs).$dirsep.$newhref;
		}
		if (scalar @copy_pwd_dirs > 0) {
		    # something left of pwd dir
		    for (my $i=0; $i<scalar @copy_pwd_dirs; $i++) {
			$newhref = '..'.$dirsep.$newhref;
		    }
		}
		# update $htmlfile
		if ($target eq '') {
		    $htmlfile =~ s#/$libtop/$href#$newhref#;
		} else {
		    $htmlfile =~ s%/$libtop/$href%$newhref#$target%;
		}

		# mark link target ($linkname) as status -1
		# (ready) if currently -2 (& set $any_minus1)
		my $found = 0;
		my $linkPM = $linkname;
		if ($linkPM =~ m#^.* ([^ ]+)$#) {
		    $linkPM = $1;
		}
		for (my $j=0; $j<scalar @file_list; $j++) {
		    if ($file_list[$j]{'pmname'} eq $linkPM) {
			if ($file_list[$j]{'status'} == -2) {
			    $file_list[$j]{'status'} = -1;
			    $any_minus1 = 1;
			}
			$found = 1;
			last;
		    }
		}
		if (!$found) {
		    print "$linkname ERROR  does not appear to exist, called from $source\n";
		}
            }
	    # grab any NAME entry for the abstract
	    if ($htmlfile =~ m#<h1 id="NAME">NAME</h1>.*?<p>(.*?)</p>#s) {
		# chop off pmname and any " - "
		my $abstract = $1;
		$abstract =~ s#^[^ ]*##;
		$abstract =~ s#^$abstract_sep##;
		# kill any links in the abstract
		$abstract =~ s#<a href="[^"]+">##g;
		$abstract =~ s#</a>##g;
		$file_list[$i]{'abstract'} = $abstract;
	    }

	    # write $htmlfile back out to its .html file ($target)
	    spew($htmlfile, $target);
            $file_list[$i]{'htmlname'} = $target;

	} # processed a .pod or .pm file into .html (was status -1)
    } # for loop through all entries, looking for status -1

    $any_minus1 = 0;
    # if there are any -2 status left, warn that they are not reachable 
    # from the root, change them all to -1 and their accessible flag to 0, 
    # set $any_minus1 to 1, and go back to process them
    for (my $i=0; $i<scalar @file_list; $i++) {
	if ($file_list[$i]{'status'} == -2) {
	    # found a status -2, means not accessible from root
	    # need flag to suppress this message, as it's so common
	    if ($no_root_link) {
                print "$file_list[$i]{'pmname'} INFO  no link from root for this HTML file\n";
	    }
	    $file_list[$i]{'accessible'} = 0;
	    $file_list[$i]{'status'} = -1;
	    $any_minus1 = 1;
	}
    }

} while($any_minus1); # big do-while loop for multiple passes through status -1

# now we have all the .pod and .pm files' PODs turned into .html files. create 
# a master index file in $output/$TOC (e.g., ./PDF/Builder_index.html) 
# for easy ref.
$fname = $output;
if ($leading ne '') { $fname .= "/$leading"; }

open my $fh, '>', "$fname/$TOC" or 
    die "$fname/$TOC ERROR  unable to open output index file\n";
print $fh "<html>\n<head>\n<title>Master index for $file_list[0]{'pmname'}";
print $fh "</title>\n<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\" />\n";
print $fh "<style>\n";
#print $fh "body { max-width: 50em; margins: 10px; }\n";
print $fh "body { margins: 10px; }\n";
print $fh "h1, h2, h3 { text-align: center; }\n";
print $fh ".fixedwidth { display: inline-block; width: 2em; }\n";
print $fh ".dummy {color: #999; }\n";
print $fh ".errormsg { color: red; }\n";
print $fh "div { display: inline-block; }\n";
print $fh "</style>\n";
print $fh "</head>\n<body>\n";

print $fh "<h1>T A B L E &nbsp; O F &nbsp; C O N T E N T S</h1>\n";
print $fh "X = not accessible from root via chain of links<br/>\n";
print $fh "<span class=\"errormsg\">ERROR</span> = POD errors of some sort reported<br/>\n";
print $fh "(<span class=\"dummy\">no link</span>) = no POD, so empty .html file generated<br/>\n";
print $fh " <br/>\n";

for (my $i=0; $i<scalar @file_list; $i++) {
    # should not have any status -2 or -1 at this point
    if ($file_list[$i]{'status'} < 0) {
	print "$file_list[$i]{'pmname'} ERROR  still has status $file_list[$i]{'status'} at $TOC output!\n";
	next;
    }
    # put 'X' at left margin if not accessible from root, else space
    # with NAVIGATION LINKS, all should be accessible from within
    #if ($file_list[$i]{'accessible'} == 1) {
    #	print $fh "<span class=\"fixedwidth\"> </span>";
    #} else {
    # 	print $fh "<span class=\"fixedwidth\">X</span>";
    #}

    $fname = $file_list[$i]{'ofname'};
    # strip off ./$leading/
    if ($leading ne '') {
	$fname =~ s#\./$leading/##;
    }

    if ($file_list[$i]{'status'} == 0) {
	# no POD at all, empty file. dummy link
	print $fh "<span class=\"dummy\">";
	print $fh $file_list[$i]{'pmname'}."</span>";
    } elsif ($file_list[$i]{'status'} == 1) {
	# normal, error-free .html output (link)
	print $fh "<a href=\"$fname\">$file_list[$i]{'pmname'}</a>";
    } else { # 2 or 3
	# errors reported, output link + ERROR flag
	print $fh "<a href=\"$fname\">$file_list[$i]{'pmname'}</a> - <span class=\"errormsg\">ERROR</span>";
    }
    if ($file_list[$i]{'abstract'} ne '') {
	# would like to have a <div> to right side with wrapped content,
	# rather than one long line that wraps to left side. div with
	# display:inline-block almost does it, but if too long doesn't 
	# wrap, but puts entire div onto next line
       #print $fh " &nbsp; - &nbsp; <div>$file_list[$i]{'abstract'}</div>";
	print $fh " &nbsp; - &nbsp; $file_list[$i]{'abstract'}";
    }
    print $fh "<br/>\n";
}
print $fh "<h3>###</h3>\n";

# TBD within a huge comment <!-- --> write out all the global settings and
#     the @file_list data. if implement running just a few .pod/.pm's rather than
#     --all, would read in global settings and @file_list up at the top to
#     initialize to the point where only revised .pod/.pm's being run get -1 status
#     and are run normally

print $fh "</body>\n</html>\n";
close $fh;

# cleanup
unlink "pod2htmd.tmp";
unlink "pod2html.stderr";

# now that the individual HTML files and the master index are done,
# 1) generate pmnameA array for each entry in @file_list
# 2) generate children, siblings, and parents lists
# 3) go through all HTML files (ex master index) and update with NAVIGATION
if (scalar(@file_list) <= 1) {
    print "Only 0 or 1 file_list entries. Do not create NAVIGATION LINKS.\n";
    exit(0);
}
make_pmnameA();
my ($j, $ref);

process(0, scalar(@file_list));

# entire file_list should have been recursively processed
# we have filled in the 'children' of each node. now give each node its
# parent, and then siblings
do_parents();
# remove duplicate children (grandchildren) AFTER parents set, so that an 
# element may have chain of parents all the way up to the root
remove_grandchildren();
do_siblings();

# update existing HTML files
update_HTML();
exit(0);

# ==================================
sub update_HTML{
    my ($i, $fname, $string, @count, $ref, $pos, $newstring, @list);

    for ($i=0; $i<scalar(@file_list); $i++) {
        # read POD from file $file_list[$i]{'ofname'} 
        # wrote HTML to $file_list[$i]{'htmlname'}     
	$fname = $file_list[$i]{'htmlname'};
	print "Updating NAVIGATION LINKS in $fname\n";

#   print "file_list[$i]: $file_list[$i]{'pmname'}  -  $file_list[$i]{'abstract'}\n";
        # read in HTML into $string, modify 
	$string = slurp($fname);
	if (length $string == 0) {
	    print "ERROR: unable to read in file $fname for Navigation Links update!\n";
	    next;
	}
	@count = (0, 0, 0); # no parents, siblings, or children

	# count of parents
        $ref = $file_list[$i]{'parents'};
        if (defined $ref) { $count[0] = scalar(@$ref); }
	$count[0]++;  # always the master index ./<rootname>_index.html

	# count of siblings
        $ref = $file_list[$i]{'siblings'};
        if (defined $ref) { $count[1] = scalar(@$ref); }

	# count of children
        $ref = $file_list[$i]{'children'};
        if (defined $ref) { $count[2] = scalar(@$ref); }

	# update link directory at top of file
	# guaranteed there's at least one parent entry
	$pos = index $string, '<ul id="index">';
	if ($pos < 0) {
	    print "ERROR: can't find link index in file $fname.\n";
	    next;
	}
	$pos = index $string, "\n</ul>", $pos;
	if ($pos < 0) {
	    print "ERROR: can't find end of link index in file $fname.\n";
	    next;
	}
	# split point is $pos+1 (just before </ul>)
	
        $newstring =  "  <li><a href=\"#NAVIGATION-LINKS\">NAVIGATION LINKS</a>\n" .
	              "    <ul>\n" .
		      "      <li><a href=\"#Up-Parents\">Up (Parents)</a></li>\n";
	if ($count[1]) {
	    $newstring .= 
		      "      <li><a href=\"#Siblings\">Siblings</a></li>\n";
	}
	if ($count[2]) {
	    $newstring .= 
		      "      <li><a href=\"#Down-Children\">Down (Children)</a></li>\n";
	}
	$newstring .= "    </ul>\n" . 
	              "  </li>\n";
	$string = substr($string, 0, $pos+1) . $newstring . substr($string, $pos+1);
	
	# just before </body> will be location of new section
	$pos = index $string, "\n</body>\n";

	$newstring =  "<h1 id=\"NAVIGATION-LINKS\">NAVIGATION LINKS</h1>\n";

        # if parents (should be), output that section
	$newstring .= "\n<h2 id=\"Up-Parents\">Up (Parents)</h2>\n";
	# add ever-present master index entry at same level as [0] entry
	# note: omitting id= because it's not used anywhere
	# emulate a 'simple' (unbulleted) list with definition list empty dd
	$newstring .= "\n<dl>\n\n<dt>" .
	              "<a href=\"".go_up($file_list[$i]{'depth'}-1) .
		      "${rootname}_index.html\">Master Index</a>&nbsp;</dt>\n<dd>\n\n</dd>\n";

        $ref = $file_list[$i]{'parents'};
        if (defined $ref && scalar(@$ref)) {
	    # @$ref is an ordered array of @file_list indice(s)
	    # pointing back to any parents
	    @list = @$ref;
	    foreach (@list) {
	        $newstring .= "<a href=\"".go_up($file_list[$i]{'depth'}) .
		              "$file_list[$_]{'htmlname'}\">$file_list[$_]{'pmname'}</a> -- $file_list[$_]{'abstract'}</dt>\n<dd>\n\n</dd>\n";
            }
        }
	$newstring .= "</dl>\n";

        # if any siblings, output that section
	if ($count[1]) {
            $ref = $file_list[$i]{'siblings'};
            if (defined $ref && scalar(@$ref)) {
	        $newstring .= "\n<h2 id=\"Siblings\">Siblings</h2>\n";
	        # @$ref is an ordered array of @file_list indice(s)
	        # pointing back to any siblings
	        @list = @$ref;
	        foreach (@list) {
	            $newstring .= "<a href=\"".go_up($file_list[$i]{'depth'}) .
		                  "$file_list[$_]{'htmlname'}\">$file_list[$_]{'pmname'}</a> -- $file_list[$_]{'abstract'}</dt>\n<dd>\n\n</dd>\n";
                }
	        $newstring .= "</dl>\n";
            }
        }

        # if any children, output that section
	if ($count[2]) {
            $ref = $file_list[$i]{'children'};
            if (defined $ref && scalar(@$ref)) {
	        $newstring .= "\n<h2 id=\"Down-Children\">Down (Children)</h2>\n";
	        # @$ref is an ordered array of @file_list indice(s)
	        # pointing back to any children
	        @list = @$ref;
	        foreach (@list) {
	            $newstring .= "<a href=\"".go_up($file_list[$i]{'depth'}) .
		                  "$file_list[$_]{'htmlname'}\">$file_list[$_]{'pmname'}</a> -- $file_list[$_]{'abstract'}</dt>\n<dd>\n\n</dd>\n";
                }
	        $newstring .= "</dl>\n";
            }
        }

	# bottom of page mark
	$newstring .= "<p><center>###</center></p>\n";
        # write file back out
	$string = substr($string, 0, $pos+1) . $newstring . substr($string, $pos+1);
	spew($string, $fname);
    }
    return;
}

sub go_up {
    my $depth = shift;
    # take care of pathological cases where unexpected inputs lead to $depth
    # being less than 1 (produces Perl error)
    if ($depth < 1) { return ''; }
    if ($depth == 1) { return ''; }
    return '../' x ($depth-1);
}

# ==================================
# recursively process this range of file_list rows, filling in children array
# handle a subset (initially the whole thing) of file_list
sub process {
    my ($start, $len) = @_;
    # starting element number in file_list, and count of rows

    if ($len <= 1) { return; }  # single element won't have any children

    my ($i, $j, $dir);
    my ($len2, $ref, $refc);
    
    # if $start row's pmnameA is now empty, that means that $start is the 
    # parent of everything else below it
    $ref = $file_list[$start]{'pmnameA'};
    if (scalar(@$ref) == 0) {
	# element $start is parent to all (1..$len-1) other elements
        # we want only DIRECT children (leaves), not nodes (grandchildren),
        #  so later we will remove grandchildren (duplicates)
        $refc = $file_list[$start]{'children'};
        for ($j=1; $j<$len; $j++) {
	    push @$refc, $start+$j;
	}
	# remove first element (empty pmnameA) from further consideration
	process($start+1, $len-1);
	return;
    }

    # strip first element from each pmnameA if ALL are duplicates
    LOOP: while (1) {
	$ref = $file_list[$start]{'pmnameA'};
	last if !scalar(@$ref[0]); # first element is empty?
	$dir = @$ref[0];
	for ($i=1; $i<$len; $i++) {
	    last LOOP if @{ $file_list[$start+$i]{'pmnameA'} }[0] ne $dir;
	}
	# if we got to here, entire section's [0] element is the same
	# so remove it
        for ($i=0; $i<$len; $i++) {
	    shift @{ $file_list[$start+$i]{'pmnameA'} };
        }

	process($start, $len);
	return;
    }

    # now break up remainder into two subranges (first pmnameA element
    # is NOT the same in all rows) 
    $len2 = 0;
    for ($i=$start; $i<$start+$len; $i++) {
	$ref = $file_list[$i]{'pmnameA'};
        if ($len2 == 0) {
            # should NOT see an empty pmnameA for element start!
	    $dir = @$ref[0];
	    $len2++;
	    next;
        }

        if (@$ref[0] eq $dir) {
	    # still a match
	    $len2++;
	    next;

        } else {
	    # no longer a match. len2 always at least a run of 1
	    process($start, $len2);
            # $len2 .. end is remainder, process it
            process($start+$len2, $len-$len2);
    
            return;
        }
    } # for loop through file_list section, first level of chunking
    
    return;  # probably never hit this
}

# ==================================
# remove an element's grandchildren from its children list
sub remove_grandchildren {
    my ($start, $ref, $refs, $ele, $i, $j);

    for ($start=1; $start<scalar(@file_list); $start++) {
	# if this element has children, check 0..start-1 for duplicate
	# children (who are actually grandchildren) and remove them from there
	$refs = $file_list[$start]{'children'};
	if (!defined $refs) { next; }
	if (!scalar(@$refs)) { next; }  # no children for this element

	for ($ele=0; $ele<$start; $ele++) {
	    $ref = $file_list[$ele]{'children'};
	    if (!defined $ref) { next; }
            if (!scalar(@$ref)) { next; }  # no children for this element

	    # remove duplicates (grandchildren) from $ele's children
            for ($i=0; $i<scalar(@$refs); $i++) {
		for ($j=0; $j<scalar(@$ref); $j++) {
		    if (@$ref[$j] == @$refs[$i]) {
			# $j is a grandchild, so remove it
			splice(@$ref, $j, 1);
		    }
		}
	    }
        }
    }

    return;
}

# ==================================
# follow children links to set their parents
sub do_parents {
    my ($i, @children, $child);
    for ($i=0; $i<scalar(@file_list); $i++) {
	if (!defined $file_list[$i]{'children'}) { next; }
	@children = @{ $file_list[$i]{'children'} };
	if (!scalar(@children)) { next; }  # no children?

	while (scalar(@children)) {
	    $child = shift @children;
	    push @{ $file_list[$child]{'parents'} }, $i;
	}
    }

    return;
}

# ==================================
# find siblings from children of a given node
sub do_siblings {
    my ($i, $j, $k, $refs, @children, $child);
    for ($i=0; $i<scalar(@file_list); $i++) {
	if (!defined $file_list[$i]{'children'}) { next; }
	@children = @{ $file_list[$i]{'children'} };

	# no children, or a lonely only child? it has no siblings
	if (scalar(@children) <= 1) { next; }

	for ($j=0; $j<scalar(@children); $j++) {
	    $child = $children[$j];
	    $refs = $file_list[$child]{'siblings'};
	    # this child's siblings is the entire children list except itself
	    for ($k=0; $k<scalar(@children); $k++) {
	        push @$refs, $children[$k] if $children[$k] != $child;
	    }
	}
    }

    return;
}

# ==================================
# split up pmname into pmnameA, and while here, set depth
sub make_pmnameA {
    my (@tempA, $i, $j);
    for ($i=0; $i<scalar(@file_list); $i++) {
	@tempA = split /::/, $file_list[$i]{'pmname'};
	$file_list[$i]{'depth'} = scalar(@tempA);
	# if single level of directory, need to adjust depth
#print "make_pmnameA depth=".(scalar @tempA)."\n";	

	$file_list[$i]{'pmnameA'} = [];
	for ($j=0; $j<scalar(@tempA); $j++) {
            @{$file_list[$i]{'pmnameA'}}[$j] = $tempA[$j];
	}
    }

  return;
}

# ==================================
# function to spew a one-string file out to the file
#  after https://perlmaven.com/writing-to-files-with-perl
sub spew {
    my ($string, $fname) = @_;
    open(my $fh, '>', $fname) or die "$fname ERROR  can't open file for output\n";
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

# ==================================
# create (for .html output files) the chain of directories 
sub mkdir_list {
	my $target = $_[0];
	my @dirlist = split /[\\\/]/, $target;

	my $dirstring = '';
	for (my $i=0; $i<$#dirlist; $i++) { # note skips last element, which is filename.html
		# build cumulative string, one directory at a time
		if ($dirstring eq '') {
			$dirstring = $dirlist[$i];
		} else {
			$dirstring .= '/'.$dirlist[$i];
		}
		if ($dirlist[$i] eq '.' || $dirlist[$i] eq '..') { next; }  # assume exist

		if (!-d $dirstring) {
			# doesn't exist yet
			mkdir $dirstring;
		}
	}
	return;  # directory string should exist now for output tree
}

# ==================================
# return list of hashes of filepath name, PM format name, status -2, 
#   accessible yes (so far), abstract '' (so far)
# for input directory plus recursively built list for all subdirectories
sub buildList {
    my ($dirname, $PMname) = @_;
    my @list; # list of hashes to return

    # build list of files in this directory in @list
    # explore each subdirectory and append its returned list to @list
    opendir my $dh, $dirname or die "$dirname ERROR  can't open and read directory\n";
    while (my $direntry = readdir $dh) {
	# one child directory, or file, at a time
	if ($direntry eq '.' || $direntry eq '..') { next; }
	if (-f "$dirname/$direntry") {
	    # it's a file. readable?
	    if (!-r "$dirname/$direntry") { die "$dirname/$direntry ERROR  unreadable file\n"; }
	    if ($direntry !~ m#\.pm$# && $direntry !~ m#\.pod$#) { 
	        if ($not_pm) {
		    print "$dirname/$direntry INFO  not .pod or .pm, ignored\n"; 
	        }
	        next; 
            }
	    push @list, { fpname=>"$dirname/$direntry", 
		          ofname=>toOF("$dirname/$direntry"),
		          pmname=>toPM("$dirname/$direntry"), 
			  status=>-2, 
			  accessible=>1, 
			  abstract=>'', 
			  parents=>[], 
			  siblings=>[], 
			  children=>[], 
			  depth=>0
		        };
	} else {
	    # it should be a directory. recursively process it
	    if (!-d "$dirname/$direntry") { print "$dirname/$direntry WARNING  is not a directory or file, ignored\n"; next; }
	    push @list, buildList("$dirname/$direntry", "$PMname${direntry}::");
	}
    }
    closedir $dh;

    return @list;  # unsorted
}

# ==================================
# toPM(filepath name) convert name (as filepath) to a PM string
# e.g. ../lib/PDF/Builder/Content.pm to PDF::Builder::Content
sub toPM {
    my $fname = $_[0];

    # strip off .pod or .pm
    $fname =~ s#\.pod$##;
    $fname =~ s#\.pm$##;
    # strip off $libtop + /  e.g. ../lib/
    $fname =~ s#^$libtop/##;
    # convert dir separator \ or / to ::
    $fname =~ s#[\\/]#::#g;

    return $fname;
}

# ==================================
# toOF(filename) convert raw input .pm or .pod input filepath and name
# e.g. $libtop/PDF/Builder/Content.pod to $output/PDF/Builder/Content.html
sub toOF {
    my $fname = $_[0];

    $fname =~ s#$libtop#$output#;
    $fname =~ s#\.(pm|pod)$#.html#;

    return $fname;
}

# ==================================
# toFP(PM name) convert name (as PM string) to a filepath
# e.g. PDF::Builder::Content to ../lib/PDF/Builder/Content.pm
# preferably a .pod instead of a .pm for a given entry
sub toFP {
    my $fname = $_[0];
    my $filename;

    # strip off $leading
    substr($fname, 0, length($leading)+2) = '';
    # convert :: to / 
    $filename = $fname;
    $filename =~ s/::/$dirsep/g;
    # append .pod (if file exists), else .pm
    if (-f "$filename.pod" && -r "$filename.pod") {
	$filename .= ".pod";
    } else {
	$filename .= '.pm';
    }

    return $filename;
}

# ==================================
sub help {
    my $message = <<"END_OF_TEXT";

buildDoc.pl: build, using pod2html utility, all the .html documentation files
  for a package, from all the .pm (or .pod) files in the package.

Using buildDoc.pl

  input files from <libtop>/<leading>/<rootname>.pm
                                      <rootname>/*.pm
	<leading> may be empty string
  output files to <output>/<rootname>/*.html

buildDoc.pl -h

  **NOTE** When running on Windows, it is possible in some cases for a
           directory separator / on the command line to be mistaken for an
	   option (flag). In such cases, surround the term with quotation
	   marks ".

  --help   this help text

  --all   process all .pod and .pm files at and below current directory.
          this is the default, but is needed if no other command
	  line options are given

  --dirsep=string  default: "/" directory separator. As Windows
          accepts the Unixy /, you should not have to change this
	  (except on the command line, where / means "option")

  --absep=string  default: " - ", the abstract separator found between
          the module name and its abstract (description) in the POD NAME 
          section (as implemented for PDF::Builder)

  --flagorphans  default: off. If 'on', a warning will be given during 
          processing that the module appears to be unreachable from the "root" 
          .pod or .pm file. However, it can always be accessed from the TOC 
          index file

  --noignore  default: off. If 'on', a warning is given when a file
          without a .pod or .pm filetype is encountered (and skipped).
          This can help you to clean out junk like editor backup files.

  --libtop=string  default: "../lib". This is the directory path to get to the 
          top of the .pod/.pm source tree from wherever you are running this 
          documentation program. For PDF::Builder, the default is that you are 
          running this program in docs/, which is a sibling to the lib/PDF/ 
          tree.

  --leading=string  default: "PDF" for PDF::Builder. This is the OPTIONAL top 
          module (and directory) name. It will be omitted (= '') if there is 
          only one name of interest for some package, or it is the top part 
          of a multipart name (e.g., PDF for PDF::Builder). For example, there 
          are several PDF:: products and --rootname is used to distinguish 
          among them. If a package name includes three or more parts (A::B::C, 
          etc.), give --leading either in the form of Perl style (A::B) or as
          directories (A/B, in this case).
	 
          Note that "leading" is pronounced "leeding", as in "up front". Do not
          confuse it with typographic leading, pronounced "ledding", which is
          the space between text baselines. 

  --rootname=string  default: "Builder" for PDF::Builder. --rootname must be 
          given (not an empty string). For example, there are also PDF::API2 
          and PDF::Report, among others. 

  --output=string  default: "." for PDF::Builder. It is the location of the new 
          <leading>/ directory, under docs/ in this case (./PDF/) as this 
          program is typically run under docs/. All HTML files will be in the 
          <output>/<leading>/ directory, unless leading is empty '', in which 
          case output is to <output>/<rootname>/.

  --toc=string  default: "<rootname>_index.html" for most applications. This 
          is the name of the master index (table of contents) file that will 
          be written to with links to all modules, in the top level output 
          directory (e.g., PDF/).

EXAMPLES:

  To build PDF::Builder's documentation, in Builder/docs just run

    buildDoc.pl --all

  All the defaults are set up for building PDF::Builder's documentation from
docs/. '-all' is the default, but no entries at all is interpreted as a
request for help.

  To build the documentation directory 'SVG' under docs, from an installation
in Strawberry Perl, with the .pm/.pod files under lib/. Naturally, if you
are building from an installed Perl package, your --libtop would point to
the directory /Strawberry/perl/site/lib/SVG/lib (or wherever):

    buildDoc.pl --leading='' --libtop=/Strawberry/perl/site/lib -rootname=SVG

**CAUTION** If there are multiple packages under SVG (e.g., not only ./SVG.pm 
and its children under SVG/, but also SVG::Parser and SVG::Reader packages), 
buildDoc may become confused and attempt to build all of them under SVG, 
resulting in spurious error messages and misorganized .html files (as it 
processes everything under SVG/). In this care, it is better to either manually 
copy just SVG's .pm and .pod file structure to a temporary directory, or 
obtain a temporary copy of just the desired package from a repository such as 
CPAN or GitHub. See the following example:

  To build package SVG's documentation, from a Desktop directory 'SVG-2.87', 
in Builder/docs (also on the Desktop), run

    buildDoc.pl --leading='' --libtop=../../SVG-2.87/lib -rootname=SVG

  The .pod or .pm file(s) are fed to pod2html utility (usually part of Perl 
installation) to produce .html files stored in the current directory or below 
(see configuration section). .html files with any links in them (L<> tag) are 
fixed up to correct the href (path) to the referenced HTML files.

If there are both .pod and .pm versions of a given filename, the .pod version
will be preferably used. Presumably it has the documentation in it.

If the resulting .html file has no content, it has a line added to inform anyone
looking at it that there is no documentation for that module (rather than a 
blank page).

If all .pod and .pm files are being processed, an attempt will be made to check 
that .html target files actually exist (cross reference check). In addition, a 
check will be made that some other file links to this one so that there is a 
chain of links from the root.

References to other packages via L<> may result in error messages ("does not
appear to exist" or even a Severe Error), and will have to be manually cleaned 
up to either eliminate the bogus links (<a>Bad::Package</a>) or point them to 
the correct place.

Messages:

  <PMname> INFO  no link from root for this HTML file
     There does not appear to be a chain of links from the root down to this 
     file. It is still usable and can be accessed explicitly, and possibly via 
     other non-root paths, but it may be an orphan. You might want to add an 
     L<> link from another module. All HTML files are still accessible from the 
     master Table of Contents (docs/index.html). As this is such a common event,
     by default the message is suppressed. The --flagorphans flag will show it
     during processing.
  <filename> INFO  no POD content
     There was no POD content in the .pod or .pm input file, so there is no 
     documentation in the file. A grayed-out dummy link will be given in the
     master index file.
  <filename> INFO  not .pod or .pm, ignored
     The file found is not a Perl Documentation (.pod) or Module (.pm) file, 
     so it is ignored. This message is suppressed by the --noignore flag.

  <item> WARNING  extra command line content ignored
     The indicated item was on the command line, but its purpose is not known,
     and it has been skipped over. Invalid flags or options get their own
     error message: Unknown option: <flag>.
  <flag> WARNING  unknown flag skipped
     A flag (command line item) starting with - or -- was seen, but not
     recognized as a valid flag. It is skipped over.
  <filename> WARNING  top-level .pod or .pm file not readable
     One or more of the top level .pod or .pm files (<rootname> .pod or .pm) 
     was missing or not readable.
  <filename> WARNING  internal POD errors reported by pod2html
     At the end of the .html file, problems are listed. You should examine them 
     and attempt to correct the issue(s). Usually these are formatting issues.
  <filename> WARNING  is not a directory or file, ignored
     This program tried to process a directory entry that wasn't a regular
     file or a subdirectory. It is skipped over.

  ERROR --rootname must not be empty!
     The <rootname> is the top level name of the package being documented,
     and cannot be an empty string. It must be a name.
  <filename> ERROR  no <rootname> .pod or .pm files found
     The specified file(s) were not found.
  <filename> ERROR  POD errors reported by pod2html
     One or more error messages were written to STDERR. You should examine them 
     and attempt to correct the issue(s).
  <PMname> ERROR  does not appear to exist, called from <sourcefile>
     You have a L<> link to a target .html file that does not appear to exist. 
  <filename> ERROR  <rootname> .pod or .pm file not readable
     The input file could not be read, the output file could not be created or
     written, the output directory could not be created, etc. Check for 
     filesystem (disk) full, and incorrectly set permissions.
  <PMname> ERROR  still has status <n> at <TOCfile> output!
     A .pod or .pm file got through the process and to the point of output to 
     the TOC (index.html) file still having a status of -2 or -1, when it 
     should be 0 or higher by this point.
  <TOC index file> ERROR  unable to open output index file
     There was an error trying to open the output <TOC>.html to write out the
     master index page.
  <filename> ERROR  can't open file for output
     Can't open the file to write it out. This is usually seen with an .html
     file to be written back out after modifications. Check permissions.
  <filename> ERROR  can't open file for input
     Can't open the file to read it in. This is usually seen with an .html file
     to be read in for modifications. Check permissions.
  <dirname> ERROR  can't open and read directory
     While exploring the file tree, the program was unable to open a directory
     in order to read its contents (files and subdirectories). Check 
     permissions.
  <dirname/direntry> ERROR  unreadable file
     While exploring the file tree, the program found a file that it wants to
     read, but is unable to do so. Check permissions.
     
END_OF_TEXT
    # TBD later, if implement individual file builds
    #                OR
    #	    path/filename.pod/.pm or path::filename   native directory/filename or Perl-style name

    print $message;
    return;
}

# ================
# empty HTML file (no POD in a module)
sub empty {
    my $content = <<"END_OF_TEXT";
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:" />
</head>

<body>




</body>

</html>




END_OF_TEXT

    return $content;
}
