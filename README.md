# WORK IN PROGRESS - DO NO USE YET

---

# CPYSCN2SVG

Convert the output of IBM i command STRCPYSCN to svg files in the IFS.

## Usage

Create a file with "screenshots" with the IBM i command STRCPYSCN.

Now do in this session what you want to document.

The typical use cases are:

* screenshots to document how to use a 5250 program
* screenshots to document how to recreate an error

Every screen you see now is written to the table you stated on the STRCPYSCN command.

When you're ready, use command ENDCPYSCN to end copying screens to the table.

Use command CPYSCN2SVG from this repo to convert the database records to svg files in an IFS directory of your choice.

The created svg files can be used

* online in html or markdown pages (like this one)
* in documents (Word, Excel, ...)
* in mails
* and many more

### Why do i not use ACS screenshots?

To make documents like user manuals look consistent, all users creating screenshots would have to use the same color settings. Which is rather hard to achieve in real life.

They are quite big in file size, although they contain mainly letters and minimal graphics.

Resizing these screenshots can be a nightmare on it's own.

### known issues

* As the screenshots created by STRCPYSCN contain only character data, subfile bars and other graphical enhancements (some emulators can be set to display function buttons as real clickable buttons) are not recreated. (Although logic could be added to draw boxes around function keys, I don't see a solution for the other things.)

* water marks aren't included. Svg could be used to create powerful watermarks; but in most use cases, these would be annoying, so i didn't include any logic for that.

### further ideas

* [ ] parameters for from and to record in the outfile created by STRCPYSCN
* [ ] Search/replace to change system / user names to other values
* [ ] exit programs for further manipulations

## svg

The created svg files can use any font as every character is positioned on the "screen", so it hasn't to be a monospace font, where every character has the same width, but i'd recommend using one.

As all svg commands have classes, the appearance can be changed via CSS (Cascading Style Sheets).

You can select whether CPYSCN2SVG shall

* create inline svg (the default)
* create a separate css-file and refer to this file in the svg-files
* add up to 5 additional css files in the svg files

A traditional 5250 session uses green characters on a black background.

Although "dark mode" is now in fashion (Ha! We knew we were right all the time!) nobody will print green on black on paper, as it is hard to read and costs a lot of ink / toner. But what do i know.

So i assume these svg files will be used mainly on a white background. So i had to change colors, as DSPATR(HI) results in white on a 5250 color screen and that would be invisible on a white background.

The mapping is done in CSS; so you could use the same svg files in dark mode on one html page, and in light mode on another. To make this work, use relative paths for the css file or embed the style in the html file(s).

## Samples

## how to create

Download the repo to your IBM i, e.g. to /OSS/CPYSCN2SVG.

