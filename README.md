# CPYSCN2SVG

Convert the output of IBM i command STRCPYSCN to svg files in the IFS.

## Use cases - reason for creating this tool

The IBM i command STRCPYSCN is a powerful tool to document what one has done.

I always wanted to use it's *OUTFILE output to help in these use cases:

* screenshots to document how to use a 5250 program
* screenshots to document how to recreate an error

This tool creates svg files from the database file created by STRCPYSCN.

The created svg files can be used

* online in html or markdown pages (like this one)
* in documents (Word, Excel, ...)
* in mails
* and many more

### Why do i not use ACS screenshots?

To make documents like user manuals look consistent, all users creating screenshots would have to use the same color settings. Which is rather hard to achieve in real life.

Also ACS screenshots are bitmap images (png, jpg, ...). When included in documents, these images don't scale well, so resizing these screenshots can be a nightmare on it's own.

The svg files contain `preserveAspectRatio="xMinYMin meet"`, so they scale well in every direction without distortion.

### Recent Improvements (v0.3.0)

* **Optimized underline rendering**: Consecutive underlined characters are now rendered with a single line instead of individual lines per character, significantly reducing file size and improving rendering performance.

* **Character grouping**: Consecutive characters with the same display attributes are now grouped into single `<text>` elements, reducing the number of SVG elements and file size while maintaining precise positioning.

### known issues

* As the screenshots created by STRCPYSCN contain only character data, subfile bars and other graphical enhancements (some emulators can be set to display function buttons as real clickable buttons) are not recreated. (Although logic could be added to draw boxes around function keys, I don't see a solution for the other things.)

* water marks aren't included. Svg could be used to create powerful watermarks; but in most use cases, these would be annoying, so i didn't include any logic for that.

### further ideas

* [ ] parameters for from and to record (or from and to date/time) in the outfile created by STRCPYSCN
* [ ] Search/replace to change system / user names to other values
* [ ] exit programs for further manipulations

## svg

The created svg files can use any font as every character is positioned on the "screen", so it hasn't necessarily to be a monospace font, where every character has the same width, but i'd recommend using one, as most other fonts just look weird.

As all svg commands have classes, the appearance can be changed via CSS (Cascading Style Sheets).

You can select whether CPYSCN2SVG shall

* create inline svg (the default)
* create a separate css-file and refer to this file in the svg-files
* add up to 5 additional css files in the svg files

A traditional 5250 session uses green characters on a black background.

Although "dark mode" is now in fashion (Ha! We knew we were right all the time!) nobody will print green on black on paper, as it is hard to read and costs a lot of ink / toner. But what do i know.

So i assume these svg files will be used mainly on a white background. So i had to change colors, as DSPATR(HI) results in white on a 5250 color screen and that would be invisible on a white background.

The mapping is done in CSS; so you could use the same svg files in dark mode on one html page, and in light mode on another. To make this work, use relative paths for the css file or embed the style in the html file(s).

Update as of release 0.2.0:

There's a feature in css to define different styles for "light mode" and "dark mode". So the created svg files now contain css definitions for both modes.
If the svg file is displayed on a page that uses dark mode, the dark mode styles will be applied automatically and vice versa.

Although this seems to be not working Word documents, everything is black and white there.

## Samples

MAIN menu of <https://pub400.com> (24 lines x 80 characters)

![cpyscn01-002.svg](samples/cpyscn01-002.svg)

Working with IFS-directory with command DSPF (27 lines x 132 characters)

![cpyscn01-002.svg](samples/cpyscn01-014.svg)

## how to create

Download the repo to your IBM i, e.g. to /OSS/CPYSCN2SVG.

In a bash shell, make this directory your current directory and run "make" to compile the source code. You can and should override the OBJLIB to create the command and the program in a library of your choice.

```bash
cd /OSS/CPYSCN2SVG
make OBJLIB=MYLIB
```

If you don't have bash and gnu make installed, your can run the compile commands manually:

```cl
CRTCMD CMD(MYLIB/CPYSCN2SVG) PGM(MYLIB/CPYSCN2SVG) SRCSTMF('QCMDSRC/CPYSCN2SVG.CMD') PRDLIB(MYLIB)

CRTSQLRPGI OBJ(MYLIB/CPYSCN2SVG) SRCSTMF('QRPGLESRC/CPYSCN2SVG.SQLRPGLE') INCDIR('./') RPGPPOPT(*LVL2) COMPILEOPT('TGTCCSID(*JOB)') DBGVIEW(*LIST)
```

## how to use

Start "recording" all your screens to a database file with command STRCPYSCN.

```cl
STRCPYSCN SRCDEV(*REQUESTER)
          OUTDEV(*NONE)
          OUTFILE(MYLIB/MYSCNCPY)
```

Answer the message "Cause . . . . . :   Start copy screen has been requested with output to *NONE. Reply C to prevent copy screen or G to allow it. (C G)" with "G".

Now all your screens are recorded to the database file MYLIB/MYSCNCPY. (So don't type anything that shouldn't be visible to others.)

When you're done, end the recording with command ENDCPYSCN.

```cl
ENDCPYSCN
```

Wait for the message "Copy Screen Image from YOURSCREEN has ended."

```cl
CPYSCN2SVG FILE(MYLIB/MYSCNCPY)
           PATH(myscncpy)
           SVGNAME(screen *NO *NO 3 '-')
           OUTPUT(*HTML *MD)
           CSS(*WEB *INLINE *NONE *NONE *NONE)
```

This will create svg files in the IFS directory "myscncpy" (will be created, if it doesn't exist) with names like screen-001.svg, screen-002.svg, ...

### Command Parameters

#### FILE

Qualified name of the database file created by STRCPYSCN command.

* Format: `FILE(library/filename)`
* Library can be: `*LIBL`, `*CURLIB`, `*USRLIBL`, `*ALL`, `*ALLUSR`, or a specific library name

#### PATH

IFS path where SVG files will be created. Directory will be created if it doesn't exist.

* Format: `PATH('path/to/directory')`
* Case-sensitive, mixed case allowed

#### SVGNAME - SVG Filename Structure

Controls how SVG filenames are generated. This is a compound parameter with 5 elements:

1. **Prefix** (default: 'cpyscn2svg')

   * Base name for all generated files
   * Example: `PREFIX(myscreen)` → myscreen-001.svg

2. **Date Format** (default: *ISO)

   * `*NO` - Don't include date
   * `*ISO` - Include date as YYYY-MM-DD
   * `*ISO0` - Include date as YYYYMMDD (no separators)

3. **Time Format** (default: *HHMMSS)

   * `*NO` - Don't include time
   * `*HHMMSS` - Include time as HHMMSS
   * `*HHMM` - Include time as HHMM
   *-* `*HH-MM-SS` - Include time as HH-MM-SS

4. **Counter Digits** (default: *NONE)

   * `*NONE` or `0` - No counter
   * `1` to `5` - Number of digits for sequential counter

5. **Separator Character** (default: '_')

   * Character to separate filename components
   * `*NONE` or `''` - No separator
   * Any single character like '-', '_', etc.

Example: `SVGNAME('screen' *ISO *HHMM 3 '-')` produces: screen-2026-02-06-1430-001.svg

#### OUTPUT

Controls generation of HTML and/or Markdown index files.

* `*NONE` - No index files
* `*HTML` - Generate HTML index file
* `*MD` - Generate Markdown index file
* Can specify both: `OUTPUT(*HTML *MD)`

#### CSS - Cascading Style Sheet Options

Controls CSS generation and styling. This is a compound parameter with 5 elements:

1. **CSS Mode** (default: *WEB)

   * `*NONE` - No CSS styling
   * `*WEB` - Automatic light/dark mode support using CSS `light-dark()` function
   * `*LIGHT` - Light mode only (black text on white background)
   * `*DARK` - Dark mode only (green text on black background, traditional 5250 style)

2. **CSS Location** (default: *INLINE)

   * `*INLINE` - Embed CSS directly in each SVG file (recommended)
   * `*NONE` - No CSS file generation
   * `'filename.css'` - Create external CSS file and reference it from SVG files

   **Note**: External CSS files only work when viewing SVG files directly. When embedded in HTML/Markdown, the external CSS won't be loaded.

3. **External CSS URLs** (default: *NONE)
   * Up to 5 additional external CSS file URLs to include in SVG files
   * Format: `'https://example.com/custom.css'` or `'../styles/custom.css'`
   * Use `*NONE` for unused slots

4. **Border** (default: *NONE)
   * `*NONE` - No border
   * `*YES` - Default border color
   * Any CSS color value: `'#000000'`, `'black'`, `'rgb(0,0,0)'`, etc.

5. **Background** (default: *NONE)
   * `*NONE` - Transparent background
   * `*YES` - Default background color
   * `*LIGHT` - Light background
   * `*DARK` - Dark background
   * Any CSS color value: `'#ffffff'`, `'white'`, `'rgb(255,255,255)'`, etc.

Examples:

```cl
# Simple inline CSS with light/dark mode support
CSS(*WEB *INLINE *NONE *NONE *NONE)

# External CSS file
CSS(*WEB 'mystyles.css' *NONE *NONE *NONE)

# With custom styling and border
CSS(*WEB *INLINE *NONE '#cccccc' '#f5f5f5')

# Include external CSS libraries
CSS(*WEB *INLINE 'https://example.com/theme.css' *NONE 'black' 'white')
```

### File name parameters

You can choose to include the creation date and time, that is stored in the database file by STRCPYSCN, in the file names.
You can also include a counter in the file names.

### HTML

OUTPUT(*HTML) will create a html file with embedding &lt;img&gt; tags for all created svg files.

It contains also a simple css style to display the svg files with a border.

### Markdown

OUTPUT(*MD) will create a markdown file with embedding &excl;&#91;&#93;() tags for all created svg files. (Like in this README.md above.)

### CSS

By default, all style information is included in the svg files (*INLINE).
This is the recommended setting for most use cases, as the embedded css will be respected everywhere.

You can choose to create a separate css file by specifying it's path/name and have the svg files refer to this file. But bear in mind, that this will work only when you display the svg file on it's own; if you embed it in an html or markdown file, the css file won't be loaded!

You can also include up to 5 additional css files in the svg files.
