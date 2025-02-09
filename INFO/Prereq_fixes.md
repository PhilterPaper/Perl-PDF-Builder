Sometimes fixes or patches are needed for **required** or **optional** 
prerequisites. At the time of release of PDF::Builder 3.027, the following 
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

