# Road Map for Future Development of PDF::Builder
### 30 July 2026

In order to encourage others to contribute code and/or algorithms to the effort, I am publishing this road map of where I would like the product to go. Please, no copyrighted code or patented algorithms, unless the owner releases them under an Open Source license! The content of this road map is open to discussion, too, on the GitHub bugs list (feature requests with the "enhancement" label or "general discussion" label). If you have a one-off suggestion, there is a contact page on my site (catskilltech.com), so you don't have to sign up for GitHub to be heard (although, it will be useful in the future to be able to use GitHub's facilities).

_The idea for this extensive list is also, in case I'm hit by a bus or something, to give someone incentive to take over the development of the product, by giving them a bunch of ideas to work on. Most or all of these are Enhancements, rather than outright Bugs (many of the former, and all of the latter, are in GitHub tickets)._

I make no promises that any of the following items _will_ be implemented (or _when_); it depends on how much free time I can come up with, and how many people chip in to help with code and algorithms. I'll be happy to discuss coding specific requirements for money/donations (but the result is still free software).

We are happy to accept well-coded PRs (Pull Requests), or even rough code and algorithms (so long as the thought process is clear). Just _please_ do not start on a project (even if it _is_ listed here) without discussing it with us (such as through a ticket). This can avoid the heartbreak and disappointment of doing a lot of work and then having it rejected because we don't like your coding style or it appears to be buggy, or simply isn't a direction we want to head in.

The assignment to sections is somewhat arbitrary, and an item could move from one section to another. Some of these items are already listed in bug reports, or as feature requests. There is no particular order to these items (i.e., they are not ranked by priority). Items will be removed from the list (and perhaps others added) as they are completed, at each release.

## I. Items to add to the core product

These are things that should be in the base PDF::Builder product, as everyone will need them (or, it would be cleaner to have it in the base rather than as an add-on separate module).

1. Look at examples/HarfBuzz.pl to see some **problems with ligatures**. In some cases, such as "waffle", a PDF Reader can search for and find it even if "ffl" has been replaced by a ligature (single glyph). However, in other cases, such as "strasse", the Reader can NOT find the word when "ss" has been replaced by an eszet. My keyboard doesn't have an eszet, so I can't easily test if it can be searched for. I don't think there's anything in the PDF::Builder code which is substituting eszet for "ss". Interestingly, the "st" ligature in the same word does not present any problem.

2. **Unification of font support:** including character set and encoding support improvements (see #81 and #47) to make more commonality between using UTF-8 and single byte encodings, across all the font types (core, TrueType, Type1/PS, etc.). One problem with core fonts is, even though most core fonts are already TrueType, that only the Latin-1 glyph set has widths defined, and only single byte encodings are possible (similar for Type1/PS fonts). To support UTF-8 for core and PS, the font might have to be built on the fly for a page (like a synthetic font), with translations to single bytes for all glyphs. If the resulting font exceeds 256 characters, something would have to be done to split the page internally into two or more sections, each with their own embedded virtual font. Glyph widths would have to be available for all characters. If the actual font is in TrueType/OpenType, you should be able to list all the glyphs (e.g., with examples/022\_truefonts) and copy over their widths into the core or T1 font tables. To be honest, you're best off moving over to TrueType for everything, but sometimes a font is only available in some other format.

    A possibility is to start a subfont with the ASCII set and empty top 128 slots. Add new chars to it as needed by the text (from x80 to xFF) as single byte glyphs (not matching any standard encoding) and use this new subfont. When it fills up and more characters are needed on a page, start another subfont and switch to it. This way, each page will have one or more custom single byte fonts to use. You only want to switch fonts a minimal number of times, so you would build a number of new font tables and just switch once between them.

    See Text::Layout 0.037 commit c05baf7 to map requested core fonts to "decent" FreeFont or TeX-Gyre TTF fonts, thereby permitting UTF-8, font embed, HarfBuzz::Shaper use, etc. for free (since core/PS mapped to TTF). See #213 for more discussion.

3. **Improved documentation, possibly even a book** giving detailed explanations and examples, as both a reference and a tutorial. Needless to say, there would have to be sufficient interest to warrant the time and expense of writing/editing and publishing (in any format) a book to be sold! In the meantime, there is the POD (and formatted online at catskilltech.com) and examples.

4. PDF/A (**archival document management**, #52, ISO-19005): this might be more than throwing a few flags/overriding flags to force font embedding (forbid 'noembed') and no encryption/passwords. There may be other stuff such as auto-add XMP stuff, creator/dates entries, that needs to be done to achieve recognition as a proper archival format (and there are apparently several archival formats).

5. **JPEG2000/JPEG2/JBIG** image file support (#97), WebP image file support, and support for other random image formats. I don't know if this is worth it, as there seems to be very little demand, but if someone is interested, have at it... any other newish image formats that PDF can support? There is an Image package that calls other packages (PDF::API2::Resource::XObject::Image::Imager) that might be adapted to Builder, if it can unpack images into an acceptable (to PDF) format. There is also an Image::BMP package.

6. Fix **Bar Code generation** (#48 and #123): I have been playing with the idea of a new Barcode library that outputs SVG format, to be released as its own package (Barcode::SVG), and usable by the SVG image support in Builder (as well as numeric and matrix lists). There are many barcode packages out there that produce bar codes in various formats. You would install the bar code package(s) you need. I think this would be better than trying to build all the various bar codes into Builder itself, which would bloat the code too much. Also, `column()` might be extended to directly place bar codes on a page. If not, a wrapper function to output a given code at a specific place on the page (probably better, as one would rarely want to put a bar code in-line with text).

    Bar codes do not print well on my low-end laser printer, and display even worse on my laptop (merging lines into blobs), but that may be more a function of my hardware and its supporting software. Warn users that they _may_ have to print bar codes larger than they like, in order to have crisp, distinct lines.

7. **Fix Small Caps** (and capitalization/uppercasing in general) for ligatures (#79): some ligatures given in Unicode or single byte encodings don't get properly uppercased. The probable solution would be to decompose ligatures to their individual letters before capitalization or Small/Petite Caps (if an uppercase version doesn't exist in the font, or use HarfBuzz::Shaper processing to recreate a ligature from the capital letters, if there is one). As Perl doesn't seem to handle capitalizing ligatures properly, a "capitals" function would need to be offered, as well as improvements to the Small Caps in "synfonts". Various non-Latin single characters (e.g., Greek terminal/nonterminal sigma, dotless i and j, German eszett, long s) also may need proper handling for capitalization.

8. **Fallback glyphs** (#56) when a desired glyph is not found in one font, but can be found in another. This is similar to HTML when you give a font family list in CSS. Be sure to integrate comma-separated font family list into `column()` and FontManager font family handling. Also, if list of fonts is exhausted without finding the glyph, output a "tofu" character (see also #214).

9. **Support for tagged structure** (#76). At the least, don't corrupt an existing tagged PDF file when extracting pages.

10. **Adding comment fields to any object** (and possibly standalone comments as their own objects). An example would be an image object with a comment ahead of it, giving the source image file, for debugging purposes). In a stream, it may be sufficent to start with %% and end with a newline.

11. **Tab support** of some sort, for both low-level functions and `column()` (including \\t and \\v embedded in text), and maybe \\n while we're at it. Note that tabs bring up some issues. First, a tab by character count (the traditional way, e.g., to the next n8-th column) is useful only for monospaced fonts, and no changes in font size in the line. Thus, tab stops would be more useful when defined by some absolute dimension (e.g., inches or mms) of column position, rather than character counts. Second, tabbing is usually done to get text columns (sub columns), which involves a lot of manual setup and twiddling of text. Consider using a TABLE within the column or page to get text organized into the desired format (at some point, implementing `<table>` in `column()`).

12. Determine what it is about **"CJK" fonts** (.ttf and .otf) that makes them incompatible with synfont (#104) and embedding (#105), and fix if possible. Are separate CJK fonts even necessary these days? Also note that many CJK fonts refuse to "subset" when embedded (the entire font gets embedded, even if you only use a handful of glyphs!).

13. Add **decorative rectangular box effects** around sections of text. With or without border (allow rounded corners) and background color, drop shadows (3D effect), etc. The box is drawn at given dimensions and location, and the text written over it in the usual manner. Content clipping might also be supported. See PDF::Table for drawing rules (and borders) for ideas, as well as block background colors (gfx\_bg object before text object). Extend `column()` with **border** settings for tags, especially `<div>`s.

14. Look into using TeX::Hyphen or Text::Hyphen to **split words properly**, both for low-level routines (e.g., `paragraph()`) and in `column()`. It may be better to brew up a derivative package Text::KnuthLiang that allows the easy addition of additional languages, and the specification of which language to use in splitting words. Extend `column()` with `<foreign lang="fr">` tag of some sort so that foreign words and phrases can be properly hyphenated when embedded within another language's text. Eventually need means to override built-in hyphenation (e.g., force 're-cord' or 'rec-ord', per context), similar to ligature control. One way would be to insert soft-hyphen &amp;SHY; as a hint to the hyphenation library. Use any place where a string is flowed into multiple lines, and eventually for complete paragraph shaping. Retain camelCase and punctuation/numeric splitting as fallback for non-words.

15. **TTF/OTF font embedding:** consider -forceASCII and -forceLatin1 options to make the entire ASCII alphabet (or the entire Latin-1 alphabet) embedded, not just what subset of characters (and glyphs) were used in text. This might be useful in fillable forms and any other situation where an end user gets to type in text. There is already the ability to embed the entire font, but that's often overkill. Additional glyphs or whole single-byte encodings might be specified, not just full ASCII or Latin-1.

16. **Roll printer** (one long PDF page) output support (#229). There are roll printers that effectively have no fixed page media height, used for various specialty purposes. For Builder, this would mean outputting to a page of indefinite height, which in turn means that Y-coordinate values as input would have to be updated to the new, extended page. Many calls to Builder routines involve x-y coordinates on the (fixed size) page, as opposed to a continuous print-at-the-bottom model. Perhaps start with a normal fixed size (minimum) page and allow Y-coordinates to go negative, and fix them all up at the end before or during render to the file? Also remember that beyond 200 inches in height, support in readers and tools will vary in non-standard ways. Possibly the page can be output to an arbitrary maximum size media, keeping all Y coordinates positive (and starting out very large), and the `cm` PDF command used to move the finished page to its final top coordinate (size). Content to be at the bottom of a page (footnotes, etc., _not necessarily_ on a roll printer, see V.13) might use a similar mechanism to be moved to right after the primary content.

17. **Extend the pageLabel()** call to not only label the reader's thumb, but also place the SAME page label text somewhere on the page. This might be combined with header() and footer() calls, possibly to call pageLabel() when the page numbering field is encountered (if flag set to do both). The idea is to minimize labor and ensure a consistent page numbering between the paper and the reader's thumb _and_ any cross references and bookmarks. `header()` and `footer()` might be placed in the top and bottom margins, leaving it to the user not to write into these areas. See #171 for pageLabel() enhancements. Also, page label for outlines/bookmarks should be consistent with the thumb and what's printed on the page. A manual page number call to put the page label on an arbitrary place (such as centered in the outside margin) would be good.

18. Consider PCF (**bitmapped font format**) font support, in a manner similar to the more primitive BDF support. PCF fonts are common on some systems (X11 used them extensively), but it's unlikely that there would be much interest to widely use them today.  See https://fontforge.org/docs/techref/pcf-format.html

19. Add calls to insert **Javascript actions** for various objects. Not all Readers may support the same Javascript level, so be careful. There are many actions and many triggers that are supported. There may be some overlap with annotation links (such as opening files or links on a click).

20. Per #187, some PDF Writers produce **PDFs with /StructTreeRoot**. Check to see if this item is properly handled (not lost or corrupted) by Builder. Issue was PDF::API2 accused of producing bad PDF, but turned out to be referencing a /StructTreeRoot but that object was missing (or was in an object stream) so apparently not a bug in API2 or Builder). See if newly-created PDF should include a STR, or at least check if it is referenced but not present (in general, check if any referenced object does not exist).

    There is also the matter of **object streams**, which consolidate multiple objects within one object's stream to increase the amount of content which gets compressed. This is PDF 1.5+, so should we just unpack object streams into regular objects? This gets into #191 checking for missing objects.

21. Per API2 #41, check behavior of `->new('file'=>existing_file)` if it immediately overwrites (and destroys) the existing file, (at least) document if overwrites even w/o save operation (warning). Add check if file already exists, and issue run-time warning (with flag to suppress this warning, and optionally to make it fatal). Might as well also check that existing file is R/W (see open() with "update").

22. Per #198, have already patched object number handling so numbers with leading 0 don't get misinterpreted as octal values. Need to look around some more for **any places where an integer starting with 0 (and digits 0-7) could be seen as octal.**

23. Per #196, consider **control of precision of x and y coordinates**, default to 2 decimal places.

24. Per API2 #48, look into **opening password-protected (encrypted) docs**, or at least fail gracefully.

25. In examples, **demonstrate dropping into Perl for unit conversions**, such as `"It is ".dist(3.3, 'mi', 'km', 1)." from the intersection to my house."` yields `"It is 3.3 mi (5.3 km) from the intersection to my house."` `"Slide Mountain, ".dist(4208, 'ft', 'm', 0).", is the highest Catskill peak."` yields `"Slide Mountain, 4208 ft (1283 m), is the highest Catskill peak."` Could give some sample unit conversion code, but user would be ultimately responsible for this. The user Perl program is building the text on-the-fly, rather than Builder trying to do it. A specific list of units would be accepted (e.g., ft vs feet, m vs metres) and watch out for singular/plural versions (1 foot vs X feet).

26. **Background color for text** (must wrap at end of line), possibly with rounded corners, as for `<mark>`, `<var>`, etc. Should this be done with single-stream text object (exit to graphics, draw background, return to text) or just recommend that the graphics object be defined first (see single-stream discussion). Text underlines/strike-throughs/overlines and possibly other stuff that does graphics within a text stream are affected. Don't forget to fill a general page background color (or pattern) before div background before text background.

27. FontManager **register a Font::TTF::Font object**. This _may_ work already (file 'name' is an object rather than a name string), needs testing to confirm. We may want to store object separately with just a flag/link in the file name field, so dump of font data doesn't output a huge object.

## II. Items to add to a separate area (new module or sub-module)

These are things that not everyone will require, and so should be split out
into possibly a separate module (dependent on PDF::Builder). Some of these
things are getting into the realm of support for markup languages and word
processing.

1. **Hyphenation and paragraph shaping:** including #183 (Hyphenation) and #95 (pseudo page objects). The idea is to use Knuth et al.'s line-splitting and paragraph shaping algorithms to flow text into a space in a visually pleasing manner, while obeying widows and orphans constraints (as well as not orphaning heading(s) on the previous page or column). See also item I.14 above.

2. **Virtual pages:** this would be related to item #1 (paragraph shaping), where PDF code would not be immediately written to an output page, but would be buffered, and output only later. See #189. This permits easier paragraph shaping and other rearrangements across columns and pages, where the starting location of a line of text is in the buffer, and it can be updated when moving the line around. Even individual words might be tagged (location and hyphenation points) so that lines could be broken at will. Even a limited amount of virtuality (virtual line output) could be useful for resetting a baseline to accommodate a change in font size -- this might involve tagging a word or block of words of the same height. See also #95 pseudo page objects.

    PDF::Table product (or table functionality within Builder) could make use of virtual printing to "print" to a mini-page within a cell (fixed width, min/max height). If it doesn't fit on the page, decide where to split row to avoid widows and orphans. Also knowing cell height and row height, can vertically align a cell's contents.

3. **General text flowing capability** in `column()`, to fill irregularly shaped columns (such as with intruding inserts or margin notes) in a balanced manner, including spanning headings across all columns, where appropriate. This would also include flowing text around images, tables, or other inserts to avoid leaving large empty sections of pages (e.g., have a large table that floats to the next page, with text after it that could easily come before it on the original page). Something to handle cross references would be handy here, to output "see table X above" or "below", "on the previous page"/"on the next page", "on page X", etc. in a prescribed and consistent manner.  Note that it might be good to notify the user during processing that such a move has been done, so that it can be inspected. Columns could be any shape, drawn with lines, polylines, arcs, circles, splines, etc. Text baselines don't necessarily have to be horizontal. Clip baselines to the "column" shape to get the line length and starting point for each line of text. There may have to be some iterations to reshape a line if its height results in a shift of the baseline into a wider or narrower area.

4. **Prepress production markup:** convenience functions to place a watermark or draft notice on all (or selected) pages, crop marks (based on trimbox), temporarily draw page bounding boxes, temporarily draw object limit boxes, color dots/bars for color printing alignment, instructions to the (human) printer.

5. **Page background color or pattern** that should extend to the full size of the page (also to indicated subarea, such as a `<div>`) and not end when content ends part way down the page. Remind users that most printers will not print all the way to the edge, and will likely need the paper to be trimmed. See Boxes.pl example.

6. Consider **Optional Content Groups (Layers)**, per 32000-2008 section 8.11.
This permits drawings to be shown by layer, or a watermark/copyright layer
to show only on printing.

## III. A new architecture, in a new package

These are things that would be useful in being able to handle page design in a higher-level manner. This would almost certainly be another package, such as PDF::Builder::Environments.

1. Introduce the concept of **environments**, which take care of handling much of the busy-work of laying out a page. Some of these map to various "high level" HTML tags.

    - page -- including margins (define the work area); page numbering, outline, and slider thumb consistent page numbers; headings/footings. Also odd/even page layouts, odd-only, or single page (roll printer) layout column(s) -- define single or multiple columns, not necessarily of rectangular outline or of the same width or height. Lower level environments can modify the initial outline (eat away at it). Balanced columns could be done.
    - heading -- per column or per page, keep together along with first two lines of following paragraph.
    - footnote -- per column or per page, grows up from the bottom and can spill to the next page. Mostly for keeping track of the bottom of the usable area.
    - margin note -- a minipage eating into a column and margin, limited to column height. Must be defined before filling column.
    - inset -- usually rectangular (but could be any shape) that eats into
the space for one or two columns. Put a short quote or exerpt there. Would define starting Y value, width, and position relative to column(s), output its content and get its final size, adjust column outlines.
    - floats -- per column or per page, for images, etc., may float left or right (but not cause a hole in the middle of a column).
    - table -- per column or per page, somewhat like PDF::Table, but probably only fixed width columns, and content fill left to author. Perhaps full `<table>` in `column()` would be better?

    The idea is that you start an environment (either implicitly or explicitly) and are responsible for all the content. At the start, you are told the position of the upper left corner (not necessarily a baseline), the allowed width, and the maximum height on this page. You fill in the content as you wish. At the end, you close the environment. The current PDF::Builder is only used for low-level stuff (primitives); the higher-level structure is in this package. This overlaps to some degree `column()`.

    The purpose is to allow you to put any kind of content anywhere, such as another list within a list item, or another table within a table cell (as well as a table within a list or a list within a table cell). The current PDF::Table severely limits your content to (currently) simple text of constant font, font size, color, etc. It is up to you to obey the limits of the extent of your content (no checks for overflow). Some environments (e.g., insets) will eat into the real estate defined for their parents, so they will have to be fully defined and filled before you start filling their parents.

    A table row would need to be defined (filled) before ink can be put down, so there may also need to be a table row environment. To handle vertical alignment, or decide where to split a row across a page break, the table environment needs to know the height of each row. This may need a means of tentatively writing a virtual row, moving part to a new page (or down their cell) if necessary, and commanding that the ink be put down. It may even be necessary to move the entire row to the next page (e.g., a cell's content is an image). Note that a new page is handled by the top-level program, rather than having one automatically created -- unlike PDF::Table, permitting more control over the layout and appearance.

    Balanced columns could be done. If the columns are purely rectangular (no insets, floats, etc.) and of the same width (not necessarily the same height), we could fill in the same order as they are read and if not completely filled, move already-formatted lines one at a time until balanced. Columns which do not meet these criteria would be more difficult. An estimate could be made of where to cut the columns by tracking the "area" used by the longer column(s), and redistributing it to the short column(s), then refilling the columns to the new height limit. This would be expensive, particularly if using Knuth-Plass paragraph shaping, as it might have to be done several times per page. Likewise, fixing widows and orphans by changing leading would be much more expensive in non-rectangular columns.

2. Keep an eye on _PDF::Make_ and related packages. It is apparently a Perl wrapper around a C library of PDF-creation tools, sort of like the "Lite" library of PDF::Builder, but possibly oriented towards interactive PDF features. Maybe could pick up a few ideas from it. I haven't tried it yet, but (as it is newly written and maintained) it sounds like it _could_ be a close competitor to Builder Lite in terms of basic functionality (i.e., it covers a lot of stuff that Builder currently doesn't).

## IV. Wishlist entries

1. Per #238 and #216, **clean up PDFs with junk** (usually HTML) after the final EOF, usually the result of a corrupted download process. Could add a "don't do cleanup" switch if there might be a reason that a user would want to _keep_ the junk part around.

2. Per #238 and #228, support **font collections** (TTC and OTC) by specifying not only the file name, but also the font name within it. Perhaps something like `Sitka.ttc(Titling)`. FontManager must work with this.

3. Per #238, #227, and #228, **support 24 and 32 bit glyph IDs**, including mixed in with 16 bit. These are starting to show up in the wild, and need to be supported. This may deal with #236, too.

4. Per #238, #213, and #214, **rationalize and complete Font Manager** font handling, including default script font (differs by operating system), and what to do about missing variants (e.g., regular and italic only ones supplied -- what do you do when bold or bold-italic is requested? User control of mapping to say, regular and italic respectively?). Might invoke `synfont()` on the fly, or "poor man's bold" by double-printing with offset (and slanting for italic). Also think about small/petite caps, stretch (expanded/condensed), optical sizes, etc. axes in addition to slant and weight axes, and multiple flavors of each (not just two), if a font supplies different ones. HarfBuzz::Shaper may be useful to see if a font includes these variants. Generalized "file" setting that permits an existing font and variant to be used by another font definition, such as default-script falling back to Times-Italic if no specified list of script files found. Check if default-constant (Courier) is working. Note that this is "indirect" description of a font or variant by referring to an already-existing font entry, e.g., default-script maps to Times-Italic (if no common script types exist). Missing variants of "script" would still have to be mapped to something.

5. Per #238 and #192 and #215, see if anything can be done for **underlines that don't intersect glyph descenders**. Ditto for overlines. Strike-throught _should_ intersect the characters. If PDF Reader's type engine can't do it (as most HTML browsers _can_), consider a thicker underline intermediate in color between the type and the background, drawn first, and possibly partially translucent. CSS has `text-decoration-skip-ink` type properties to allow or avoid collisions.

6. Per #238 and #80, be able to **embed core and T1 fonts** (and possibly others) just like TTF/OTF. Might involve translating non-TTF font to T3 or something else we know how to embed. Considering that T1 is no longer supported by Adobe, and core is deprecated (use TTF instead), it is questionable if this is worth the effort. If it turns out to be fairly quick and simple, it may be worth it.

7. Per #238 and #81, **consistent font handling** with support for UTF-8 in core and T1 fonts. Embedding see IV.6. May overlap I.2, involving on-the-fly single byte subfonts.

8. Per #238 and #225, consider **flattening updated PDFs**. The idea is to delete obsolete objects and shrink down a PDF to just the current active objects. As there are utilities to do this already, it may not be worthwhile. In a related vein, promote and consolidate common resources (such as fonts) to document level, to save space. This could be tricky.

9. Per #238 and #36, **properly handle PDF splitting**. Would need to turn some internal links into external links, and duplicate shared common resources into the new PDF. Again, this could be quite tricky.

10. Per #238 and #78, **add ability to reuse objects** in other PDFs. Presumably this means saving a PDF-ready object into a file or library system, and being able to pull it in as needed in a new PDF. Other than saving some processing time creating an already-done object, I'm not sure what's gained. The programmer creating the new PDF would have to know where to find existing objects, although that burden might be eased with an appropriate indexing/keyword system in a library. The original request was because a user wanted to create a large document as many small ones and combine them, and possibly the intent was to avoid duplication of resources (see 9).

11. Per #238 and #34, **avoid slurping entire PDF into memory**. API2 does something with sparse reads to bring in only what's needed. I suspect this may be involved with several difficult bugs (#166, #170, and #220), and am leery of duplicating virtual memory functions. Since it is reported that operations are considerably sped up by doing this, it's still worth considering.

12. Per #238, when doing real typesetting using HarfBuzz::Shaper to change certain letters to ligatures, **when to use ligatures** and when not to? Ligatures were invented for a practical reason, to reduce breakage of the overhanging hook on "f" slugs. "ff", "fi", "fl", "ffi" and "ffl" are common, but many other ligatures exist for mostly decorative reasons. Just for consistency, it would then be desirable to _always_ use a given ligature. However, there are rules about not tying together separate morphemes with a ligature, which to me, makes a document look inconsistent. I'm not sure _what_ is best practice, or what HarfBuzz::Shaper does about it.

13. Per #200, **Content::matrix** both input and output a vector of six settings.

14. Per SVGPDF #2, replace all `$obj->isa("kind")` with `UNIVERSAL::isa($obj, "kind")`, as it will handle simple scalars correctly without blowing up ("isa" against an unblessed object). Document UNIVERSAL package is used (_is_ CORE).

15. In addition to 'tofu' glyph, provide some **built-in glyphs for font-independent use**, such as "chain link" for cross references with no target text found, "backlink" up+left arrow for user-defined "back link". PDFBicons built-in font, include tofu at 'A', chain link at 'B' within rounded box, backlink up_left arrow in rounded box at 'C'. Available for user to use, but normally used by system (column()). Nothing built into Symbols or Zapf Dingbats that's usable for this.

16. **Print only mode** support to suppress anything interactive, and optionally grayscale only. This might suppress certain features, or "dumb them down" for print-only. Note that live footnote links and the like could be handled this way.

17. **Optimize output (cache PDF commands)** by consolidating state changes (position, fill and stroke colors, font, size, etc.) and only outputting the latest change when ink is about to be put to paper. The idea is to reduce file size by omitting unnecessarily repeated common commands.

18. New FontManager element: '`indirect=Times|bold=0|italic==1` which simply maps to a call like 'face=Times, bold=0, italic=1'. If italic set to 0 or bold to 1? bold=1 could be handled with Times-bold-italic, but italic MUST be 1 (note the '==' for mandatory). Initial bold=0, but can be overridden; initial italic==1 and CAN NOT be overridden. '|' notation permits future use of other font settings (stretch, etc.).

19. Consistent appearance and formatting of **020\_corefonts** to have Ipsum Lorem text on last page, like TT and PS.

20. SVG processing may produce multiple `<svg>` elements. By default **choose first SVG**, but if multiple, allow user to select one or more to be output in combined object.

21. Per #211, look into **more efficient page adding**. Currently there may be a linear search through all pages to determine where to insert a new page -- should be able to globally track where last page currently is.

22. **Support interchangeable font weight names and numbers**, font stretch (expand/condense) names and numbers. Map name to number, and then select appropriate value based on availability. Also heavier/lighter, tighter/looser. This is beyond "on/off" 1/0 flags for bold and italic in FontManager.

    font-weight: 1-1000, higher is heavier. arbitrary weights may be available. 'lighter' and 'bolder' are legal as relative terms.

    | numeric | name | lighter | bolder |
    | :---: | :--- | :---: | :---: |
    | 100 | thin/hairline | 100 | 400 |
    | 200 | extra-light/ultra-light | 100 | 400 |
    | 300 | light | 100 | 400 |
    | 400 | normal/regular | 100 | 700 |
    | 500 | medium | 400 | 700 |
    | 600 | semi-bold/demi-bold | 400 | 900 |
    | 700 | bold | 400 | 900 |
    | 800 | extra-bold/ultra-bold | 700 | 900 |
    | 900 | black/heavy | 700 | 950 |
    | 950 | extra-black/ultra-black | 900 | 950 |

    Translate named to numeric, then find appropriate supported variant file, closest to requested. Later: synfont() create arbitrary weight.

    font-stretch: name or arbitrary xx% value, use hscale() or synfont(). See if CSS addresses 'tighter' and 'looser' relative terms.

    | name | numeric % | tighter | looser |
    | :--- | :---: | :---: | :---: |
    | ultra-condensed | 50 | 50 | 75 |
    | extra-condensed | 62.5 | 50 | 75 |
    | condensed       | 75 | 50 | 100 |
    | semi-condensed  | 87.5 | 50 | 100 |
    | normal          | 100 | 75 | 125 |
    | semi-expanded   | 112.5 | 75 | 125 |
    | expanded        | 125 | 100 | 150 |
    | extra-expanded  | 150 | 125 | 200 |
    | ultra-expanded  | 200 | 150 | 200 |

23. Consider **avoiding compressing a stream** if the net savings do NOT exceed the extra "/Filter" entry added. This should take care of compressing 0-length streams, which are longer than uncompressed!

24. Consider **single object (stream) design**, rather than separate graphics and text objects. Many systems mix text and graphics within one object. Is there an advantage to doing this? Remember that the entire graphics object will be run through first, and then the entire text object (following by any additional graphics object). In contrast, a single object per page might be easier to understand the state at any given time, although care must be taken with ET and BT resetting some things!

25. Per #227 optimize tounicode tables (at least) possibly other >64k glyphs stuff bfrange->bfchar et al. See if this fixes any other ticket.

26. FontManager to **accept common but invalid names** per SVGPDF #6. E.g., FontManager to accept Times-BoldItalic and properly      handle it as face=Times, italic=1, bold=1. If contradictory options are explicitly given (e.g., italic=>0), override with those. Effectively use the face name to default bold and italic, and override with any explicit settings. For core fonts only, lookup table is of manageable size.

## V. Continued development of column() text processing (see #195)

1. Support **image processing** `<img>` and possibly other related tags. Make sure SVG handled as an image. Vertical positioning relative to baseline, keep as CSS-compatible as possible, but may have to extend it. Alignment to top of ascenders, to bottom of descenders, to baseline for image top, bottom, or center. Also permit floating of an image to left or right edge.

2. Support **whitespace control per CSS** (CSS `white-space` and `<pre>`, `<br>`, `<nobr>`, others? &amp;nbsp; like space, but NOBREAK forced.

3. Support **semantic font control** tags `<cite>`, `<q>`, `<kbd>`, `<samp>`, and `<var>`.

4. Support **arbitrary paragraph shapes** (outlines), not just rectangles. Make a closed, non-self-intersecting polygon of lines, arcs, elliptical arcs, splines, etc. Turn into a polyline, and use to determine baseline extents at arbitrary Y values. Note that various page sections and figures (such as images) will be put down first, and then eat out pieces of any columns defined for the main text. Dropped caps may be handled the same way.

5. Support **definition lists** `<dl>`, `<dt>`, `<dd>`. May need extensions to control how a dd line breaks depending on the size of the dt and the gutter (always, never, % of line left, etc.). Also, how far left multiline dd's go (how much indentation from left edge of list) -- fixed amount or align with start of dd.

6. Full **table tag support** `<table>`, `<thead>`, `<tbody>`, `<tfoot>`, `<tr>`, `<th>`, `<td>`, `<rowspan>`, and `<colspan>`. Also extensions to control whether to repeat `<thead>` and `<tfoot>` at column breaks, and table caption (`<tcap>`). Consider incorporating table extensions from PDF::Table. Borders, padding, and possibly margins for cells.

7. Support **basic hyphenation** for word splitting, at least at '-', &amp;SHY;, camelCase, non-word split at letter/digit, etc. and emergency splitting when word will not fit on entire line. Allow for future Text::KnuthLiang proper language-sensitive word splits, and proper Knuth-Plass paragraph shaping.

8. Support **super- and sub-scripts** `<sup>` and `<sub>`. Also vulgar fraction creation and isotope nomenclature (right-justified superscript above right-justified subscript on element symbol).

9. Support **centering** (both CSS text align and HTML `<center>` tag). CSS margins "auto" may be useful here.

10. Support **rough font size control** with `<big>`, `<bigger>`, `<smaller>`, and `<small>`.

11. Support **CSS text-transform**, such as uppercasing and lowercasing (various flavors).

12. Consider **HTML predefined page areas** `<abstract>`, `<summary>`, `<article>`, `<aside>`, `<section>`, et al. These and intercolumn inserts will be placed on the page first, eating into any columns then defined. There could also be defined subcolumns that can be floated around and centered horizontally while keeping their own vertical alignment. See troff "display" feature to define a preformatted block of text.

13. Support **proper footnotes** (on-page, end-of-chapter, own-appendix, bibliography entries, etc.). This will need a clean way to build content from the bottom of the page upwards, possibly doing something with `cm` to float a subpage down to the bottom (still need to track size to prevent collision with main body, see I.16). If document will be used primarily online, allow dynamic (pop-up) footnotes?

14. Support **barcodes and QR codes** on a page, although this may be best treated as an absolute placement on a page that eats a piece of one or more columns.

15. Both CSS and `<sc>`/`<pc>` **small caps and petite caps.** Include "turn off/early end" settings so that you can force small caps text to end at the end of the line, rather than continue onto the next line to the end tag. Use HarfBuzz::Shaper font predefined small/petite caps, or invoke synfont(), or inline 80% height + 88% width (sc) or 1ex height, expand 120% (pc). FontManager might have a new axis for such resized caps. If using HarfBuzz::Shaper, can it tell us whether SC/PC is available in a font? If not, what is best way to implement, short of running synfont() to synthesize a SC/PC font? Insert `<span style=font-size; font-stretch;>` for runs of lowercase letters? Be sure to properly handle ligatures (break into letters) and accented characters. Perhaps a remap (per font) of glyph IDs?

16. **Drop caps** `<dc>` multiple lines indented to fit huge letters, which may stick out left and up. Might need a column outline indentation. Don't forget to check if the extra vertical space needed forces end of column.

17. **Overline** `<ovl>` similar to underline and strike-through, but near the top of the text. As with underlines, avoiding collisions with glyph strokes would be nice.

18. **Character by character kerning control** (_microkerning_, apply _after_ any font built-in kerning). Can build text logos such as LaTeX. Normally you would not want to manually kern characters, but might want it for special effects.

19. **Widow and orphan handling**. Would need some way to detect that one line was left at the bottom of one column (including headings) or at the top of the next, and back out one or more lines and so something about it. This might include making the first column one line short (move line to next column), or making the column one line longer (under user control), or repositioning lines in the first column to stretch leading to move one line to the next, or shrink it to fit that last line. This will likely require pseudo objects or virtual pages (see II.2), and even that may still require reprocessing some input if columns are not rectangular (lines cannot be simply moved from one column to another)!

20. A way to **force early end to a column** based on some criteria, such as less than a certain amount of space remaining. It is more desirable to let the system figure this out (e.g., to prevent a widow line), but at least as an interim measure this may be useful. Remember to forbid hyphenation on this line, as it is the end of a column.

21. Some way to **keep material together vertically** (`<vkeep>`), such as headings and paragraph text, or grouping material **not** to be split between columns. This may involve allowing the section to "sink" to the next column, or "rise" into the previous column by flowing other content around it (requires fences to limit amount reflowed).

22. **Combined font size and leading**, such as `font-size: 14/12pt;`.

23. **Leading as a dimension** rather than only as a ratio.

24. Proper **Knuth-Liang hyphenation**, even if we're not yet doing proper Knuth-Plass paragraph shaping. Can at least do "greedy" paragraph filling (plus basic hyphenation per I.14 and V.7).

25. **Low level hyphenation control** overriding whatever Knuth-Liang says. `<hyph>` could give desired split point if needed (or use &amp;SHY;?) and `<nohyph>` could forbid word splitting over a range.

26. **Low level ligature control** for specific fonts -- forbid ligature in a range with `<nolig>`, request a specific ligature here with `<lig>`. Also alternate glyph forms such as swashes, with `<alt>` or `<swash>`. All this requires intimate knowledge of what's available in a specific font.

27. Full sections for **Table of Contents, Index, Bibliography, Glossary, et al.** beyond generic cross references. Cross references that adjust text "above", "below", "on facing page", "on previous page", and "on next page", in addition to standard "on page NN". Requires ability to change text per language. Note that as documents are re-run to settle them down, changes to such text may cause page assignments to _not_ ever settle down! Also, consider what "above" and "below" mean if there are side-by-side columns on a single page (logically above versus physically above on the page). Be able to suppress this special text and just use the generic "on page NN".

28. **Tag-level sectioning:** book, chapter, section, subsection, etc. with different rules applied to each (whether to start on right hand page, what sort of header, whether to use drop cap, whether to use some sort of divider, etc.). How to handle skipped pages (page number, headers, "This page is intentionally left blank", etc.), remembering that `column()` is called _within_ a page.

29. **More control over book style left/right pages**. "bind" margin, "inside" and "outside" positioning, different header and footer formats for left and right hand pages. Equation numbers on outside rather than right, other asides and margin notes on outside rather than a fixed left or right.

30. **Heading prefix and suffix**, often a formatted counter value. Also "run-in" headings that continue the text on the same line.

31. **Full bidirectional text support:** `<bdi>`, `<bdo>`, and anything else for RTL languages. Positioning "left" and "right" (as well as "inside" and "outside") may vary. I have no idea what to do when mixing LTR and RTL languages in one paragraph -- how word splitting will be handled, etc.

32. **Glosses and Ruby** in between lines, and two columns vertically aligned by paragraph starts (e.g., multiple languages/translations).

33. Any legal tag **ignored for now** (e.g., `<img>`) _document_ and silently ignore (treat as `<span>`?). Don't flag a tag as unknown unless it's also NOT in the `ele=1` list of user-defined tags. E.g., style `spc { font-style: italic; }` (species tag) then can use `<spc>H. Sapiens</spc>` without being flagged as unknown/invalid. Keep in mind that an end tag may be automatically generated for "invalid" tags (may have to remove!). Add new HTML tags and attributes per list of current and deprecated HTML tags.

    If encounter an unsupported tag, if it has no attributes and appears to otherwise be an **email address or URL**, treat as such (including the angle brackets). At least, that's better than giving an error message.

34. Support /* */ **CSS comments**.

35. Investigate **`<hx>` without child text**, to be able to put dingbats, rules, etc. instead of fixed text. Maybe just change font and put the char in? If rule is involved, new CSS for that. e.g., `<h6 />` just outputs a dingbat centered in column. See how self-closing tags handled by HTML processing -- might have to do `<h6></h6>`. Or, a new CSS property to ignore any child text and just use the rules and dingbats.

36. Handle **more advanced CSS selectors**. Comma-separated list can make multiple links to one target, or just duplicate N times. Descendants... need to climb up stack of active tags to find parent and grandparents, and whether a class or ID is applying to any of them. Pseudo-tags always applicable?

37. Consider **stacking font vertical extents** so can back out changes (extension up or down) if need to ditch some text.

38. Look at **marooned text** where e.g., ( on one line and rest of text (due to font change) on next line. If no whitespace between text elements, should not break between them, even if font etc., changes. Sort of a forced `<nobr>`?

39. `<ul>` support images as markers (**CSS list-style-image: url()**). Will be drawing an image (graphics) at the text position, requiring img support.

40. Extend column **ordered lists to inherit parent (enclosing) ordered list marker.** `inherit="."` says that the marker for this list        will be _marker-before above-list-marker-content inherit-glue-char normal-marker-text-at-this-level _marker-after. E.g., 

        <ol inherit=".">;  <!-- children will inherit -->
            <li>First Section
                <ol>
                    <li>First subsection</li>
                    <li>Second subsection</li>
                </ol>
            </li>
            <li>Second Section
                <ol>
                    <li>First subsection</li>
                </ol>
            </li>
        </ol>

    Produces

        1. First Section
            1.1. First subsection ("1" inherited from above)
            1.2. Second subsection ("1" inherited, "." is glue)
        2. Second Section
            2.1. First subsection ("2" inherited, "." is glue)

    Need to stack "last used marker text at this level" so can pop out. Also transfer from one column to the next in the middle of processing. How handle 'start' value that isn't numeric, or would we use a new "inherit_start" attribute? Much simpler to use than official CSS `column-reset`, `column-increment`. Remember to update `examples/Column_lists.pl` with many examples.

41. Extend headings (<hX>) to have **heading number counters**, formatted just like ordered lists (V.40), including inherited markers. need "start" value specified somewhere. Paragraph counters, too? In left or right margin? Line counters, too (every X lines).

42. **Full `<div>` support**, so can e.g., center a block or line of complex text (not just simple text). Like troff "display text". Treat as mini-column? In future, can do asides and margin notes and footnotes in a similar way.

43. **Proper Knuth-Plass paragraph shaping**. Text::KnuthPlass will need updating to handle annotated text fragments (font changes and size changes), non-rectangular columns, and a better Knuth-Liang hyphenation library.

44. **Conditional HTML code inclusion** as new HTML "if" tags. One use would be to rearrange content on-the-fly, for example, a large image doesn't fit at the bottom of a column, but two smaller ones do. Swap order of images to move large image to next column. Admittedly this could get quite messy, and may be better done externally with Perl code. In general, the **ability to rearrange content** to best fill a page or column would be useful. Allow reflowing of text upward around an image or table that is too large to fit in _this_ column, and avoid large empty spaces. Note that this complicates cross references which may move from below an image to logically above it, even in a different column.

45. **Paragraph continuation tag** `<pcont>` to _resume_ a paragraph after some sort of interruption such as a list, table, or image. Avoid unwanted indentation or whatever is done at the start of a paragraph.

46. **List continuation tag** of some sort to avoid resetting list counters, etc. after some sort of interruption such as a paragraph or table that doesn't fit into a `<li>`. First, see if `start=` attribute will do the job for ordered lists, and whether unordered lists lose their level setting.

47. For <q> find clean way to use Symbols \x7D } for **fat opening quotation mark** "prefix-text" as stylistic alternative to prefix &ldquo; suffix &rdquo;.

48. **Remove dead PDF code** at the end of a column (remove code back to last text output), as setup will be repeated at next column call. The intent is to remove unnecessary PDF code and shrink the file size.

## VI. Fun Fridays entries

These are projects which sort of "stand alone" and might cleanly be done as small independent activities, or handed off to someone interested as a side project.

1. Per #191 (see I.20), **deal with object streams**, at least for the purpose of checking for missing objects. Probably need to unpack an object stream into discrete objects, at least for the missing objects check. Might be good to do it for other purposes. When saving a PDF, might be able to put those objects _back_ into an object stream, and compress it. PDF level should be at least 1.5.

2. Create a new package **MathJax::SVG** to use code given by Davide Cervone of MathJax to invoke a MathJax processor (running on .Net or equivalent, such as Mono, and Node.js) to turn (La)TeX style equation markup into SVG, which Builder's SVG image display (SVGPDF) can then incorporate into a PDF. In addition to TeX style equation markup, MathML and some other formats are supposedly possible. Builder would have routines to accept an equation markup and return an image object ready to put down, and would also extend `column()` to support `<eqn>` and `<deqn>` tags for inline and display equations. Note that SVGPDF does not support nested `<svg>` tags, so display equation numbers have to be extracted and handled separately. See if latest MathJax supports built-in inline equation splitting at good points, or if user will have to split up long equations manually, specifying any markup to add at line break (such as a \cdot).

3. **Fonts and images full support of file, string, and web sources.** Look at SVGPDF for ideas on implementing. "filepath" in FontManager should also permit this, not just local files.

4. **Circular baselines for text**, and a framework for more general curves per #232. Put in Content::Text (`$text->arc_baseline()` and `$text->text_curved_baseline()`), including new text_curve() to draw. Could this be general enough to release as own package? What kind of font library interface (dimensions, etc.) is needed? Circular arcs are easy, and possibly ellipses, but general curves (e.g., splines) and especially combinations of curves and lines is a tough nut to crack. Likely convert general curves to polylines first.

5. Provide example code for use of **MultiMarkdown, MediaWiki, and other markup languages** as input for text processing in `column()`. This would be in lieu of building in native support for these other formats, although there might be a generic external format routine to invoke in Builder. Any library which converts a format to HTML (beyond the basic text and Markdown) could be usable. Remove partial MultiMarkdown example in examples/Column.pl and column.pm. POD, man pages/troff markup, among others, can be supported this way. Note that some may require additional HTML tag support (e.g., `<mark>` needed for Markdown "highlight", which in turn uses background color). Some tags have unusual usage, such as Markdown images using "srcset". It may be that after converting to HTML, user code may need to do some cleanup to change HTML code to something that Builder can understand. Possibly put in `xtxmp/` directory.

6. Provide example code for use of **GNUplot** in creating temporary JPEG or SVG files, to be incorporated into a PDF in the usual way. Put in `xtxmp/` directory. Likewise, example code for **ABCSVG** (music notation).

7. Investigate why Builder PDF files are noticeably larger than API2 PDFs. There seems to be extra font information included which may not be necessary. Start with core font width etc. tables.

8. Add **rotated ellipses and elliptical bogens**. See SVGPDF source (contrib/) for elliptical bogens, possibly rotated ellipses in SVGPDF are just using the transform matrix. Will need new examples/bogens.pl (pull existing circular bogens out of content.pl), and add rotated ellipses to examples/content.pl.

9. Make sure **dashed option names** are permitted (will deprecate them soon), and _silently_ converted to undashed versions, using a common utility (convert all dashed names at once at any user entry point). Eventually could give warning that dashed names are deprecated, and _possibly_ eventually only accept undashed names. Don't forget to update t-tests and examples to use undashed names.

10. Look into **automatically carrying over global settings** such as font, font-size, colors, etc. from page to page, in a manner compatible with `column()`.
