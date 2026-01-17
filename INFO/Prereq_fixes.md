Sometimes fixes or patches are needed for **required** or **optional** 
prerequisites. At the time of release of PDF::Builder 3.029, the following 
fixes or patches are known to be needed. As the libraries are updated, this 
list will be modified as necessary:

-----------------------

* **HTML and Markdown support:** A prereq for HTML::TreeBuilder, HTML::Tagset 
(version 3.20 or earlier), needs 
a fix for `<ins>` and `<del>` tags to be handled correctly. If not fixed, these
tags cause undesired paragraph breaks, such as in the examples/Column.pl sample.
Once installed, in \Strawberry\perl\vendor\lib\HTML\Tagset.pm (location of
Tagset.pm will vary on other Perls and OS's):

    1. Find  %isPhraseMarkup = map {; $\_ => 1 } qw(
    2. Below that find     b i u s tt small big
    3. Add a new line below that:   ins del

This adds `<ins>` and `<del>` to the list of inline ("phrase") tags. It is quite
possible that other HTML tags may misbehave, and further updates are needed.
If you experience such problems, please open a ticket against PDF::Builder to
report it.

**HTML::Tagset 3.22 has this fix in it. The easiest course of action is simply
to check if your copy of HTML::Tagset is at least 3.22. If you can't update it,
you will need to follow the above instructions.**

-----------------------

* **Building libtiff for Graphics::TIFF optional prerequisite**, 
some users may encounter problems with not being able to install the optional
Graphics::TIFF package due to the libtiff library not being successfully built 
(by Alien::libtiff). We have no information on other operating systems and 
Perls, but this has been successfully worked around on Windows with Strawberry Perl:

* This is due to the package Alien::MSYS not installing, which in turn prevents Alien::libtiff from building
* Bring up the DOS Command Prompt (command line window)
* > \strawberry-5.xx\portableshell.bat (\Strawberry-5.xx is the Perl level you're using)
* >> cpanm -i Alien::MSYS
* >> exit  (from portableshell)
* > exit  (from the Command Prompt shell)
* Now you should be able to install Graphics::TIFF in the usual manner, which will in turn build the libtiff library

-----------------------

* **Running on older Macs:** It has been reported that some versions of Mac 
Perl systems have a 'convert' utility that is missing the default Arial font, 
and thus will fail (see ticket 223). You may need to install the Arial font on
some Mac systems in order to properly test during installation.

-----------------------

* **HarfBuzz::Shaper install or upgrade:** HarfBuzz::Shaper, an optional package
for PDF::Builder, will not install or upgrade version 0.032 (and possibly later) 
on Perl 5.28 on Windows systems (tested with Strawberry Perl). Note that while
'cpan' will attempt to install the latest (0.032) HarfBuzz:Shaper, it is possible
to manually install 0.031, which PDF::Builder will happily run on.

* At cpan.org, go to HarfBuzz::Shaper
* Select a different version, pick 0.031
* Download to your PC desktop as HarfBuzz-Shaper-0.031.tar.gz
* Unpack .tar.gz file to .tar, using 7-Zip or similar
* Unpack .tar to a directory, using 7-Zip or similar
* In a command prompt window (DOS shell), cd to the HarfBuzz-Shaper-0.031 directory you just created
* cpan .

Your version 0.031 HarfBuzz::Shaper should be properly installed. If it doesn't
install, try setting the environment variable (in @ENV) 'INCHS' to the value '1': 

* Windows Start > Settings > env
* Edit the system environment variables > Environment Variables
* In "User variables for ..." click "New..."
* Variable name: INCHS  Variable value: 1
* OK > OK > OK

Now INCHS is "permanently" in the system (until you remove it). You will
need to close the already-opened commmand prompt window, as it likely will
not have INCHS set. You can test with `perl -e "print $ENV{'INCHS'}"`. If 
it does not return "1", it's not set.

* Go back to point where you have the unpacked directory on your desktop 
* Open the command prompt window and repeat the cd and `cpan .`

Once HarfBuzz::Shaper 0.031 is successfully installed, you can remove INCHS:

* repeat steps to get to "User variables for ..."
* select INCHS entry
* click Delete > OK > OK
