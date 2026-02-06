**FREE
Ctl-Opt MAIN(MAIN) DECEDIT('0.') OPTION(*NODEBUGIO:*SRCSTMT:*NOUNREF)
        ACTGRP('CPYSCN2SVG')
        TEXT('Converts the output of STRCPYSCN to svg');
// -----------------------------------------------------------------------------
// Converts the output of STRCPYSCN to svg files
//
// https://github.com/AG1965/CPYSCN2SVG
// -----------------------------------------------------------------------------
Dcl-PR MAIN EXTPGM('CPYSCN2SVG');
   qualSCNCPY          LIKEDS(qualObj_T);
   IFS_Path              CHAR(128);
   SVGfilenameStruct   LIKEDS(SVGfilename_structure_T);
   Output              LIKEDS(list_Output_T);
   // CSS                   CHAR(128);
   CSS                 LIKEDS(list_CSS_T);
   // CSS_externals       LIKEDS(list_externals_T);
End-PR;

Dcl-DS qualObj_T QUALIFIED TEMPLATE;
   Name  CHAR(10);
   Lib   CHAR(10);
End-DS;

Dcl-DS list_Output_T QUALIFIED TEMPLATE;
   count   INT(5);
   entry  CHAR(10) DIM(2);
End-DS;

Dcl-DS list_externals_T QUALIFIED TEMPLATE;
   count   INT(5);
   entry  VARCHAR(128) DIM(5);
End-DS;

Dcl-DS list_CSS_T QUALIFIED TEMPLATE;
   count      INT(5);
   create     CHAR(10);
   createURL  VARCHAR(128);
   offset_to_externals INT(5);
   border     VARCHAR(32);
   background VARCHAR(32);
   externals  LIKEDS(list_externals_T);
End-DS;

Dcl-DS SVGfilename_structure_T QUALIFIED TEMPLATE;
   NumberOfElements   INT(5);
   Prefix            CHAR( 64);
   IncDate           CHAR( 10);
   IncTime           CHAR( 10);
   CntDigits       PACKED(1:0);
   IncSepChar        CHAR(  1);
End-DS;


Dcl-DS g_Colors QUALIFIED;
   DFT    VARCHAR(64);
   HI     VARCHAR(64);
   BL     VARCHAR(64);
   CS     VARCHAR(64);
   BLCS   VARCHAR(64);
   CSHI   VARCHAR(64);
   HIBLCS VARCHAR(64);
   l_UL   VARCHAR(64);
   l_CS   VARCHAR(64);
End-DS;


Dcl-ENum COLORS_LIGHT QUALIFIED;
   DFT       '#006400';
   HI        '#000000';
   BL        '#b00020';
   CS        '#008b8b';
   BLCS      '#a000a0';
   CSHI      '#9a8700';
   HIBLCS    '#003399';
   l_UL      'currentColor';
   l_CS      '#008b8b';
End-ENum;

Dcl-ENum COLORS_DARK  QUALIFIED;
   DFT       '#00ff00';
   HI        '#f0f0f0';
   BL        '#ff0000';
   CS        '#00ffff';
   BLCS      '#ff1aff';
   CSHI      '#ffff00';
   HIBLCS    '#7890f0';
   l_UL      'currentColor';
   l_CS      '#00ffff';
End-ENum;



Dcl-C #CRLF x'0D25';

Dcl-S g_charWidth   UNS(5) INZ(12);
Dcl-S g_charSize    UNS(5) INZ(20);

// Function prototypes
Dcl-PR f_escapeXML VARCHAR(512);
   myText VARCHAR(256) CONST;
End-PR;

/INCLUDE 'QSYSCPY/DQCMDEXC.RPGLEINC'

// Dcl-F QASCCPY DISK EXTFILE('QASCCPY') TEMPLATE;

// Dcl-DS RS1 QUALIFIED;
//    MAXROW UNS(5);
//    CURCEN CHAR(1);
//    CURDAT CHAR(6);
//    CURTIM CHAR(6);
// End-DS;

Dcl-S #IFS_SVG_FileName  VARCHAR(128);
Dcl-S #IFS_SVG_FullName  VARCHAR(512);
Dcl-S #IFS_CSS_FileName  VARCHAR(128) INZ('');
Dcl-S #IFS_CSS_FullName  VARCHAR(512);
Dcl-S #IFS_HTML_FullName VARCHAR(512);
Dcl-S #IFS_MD_FullName   VARCHAR(512);

Dcl-DS RS2 QUALIFIED DIM(*AUTO:27);
   SIROW  CHAR(  3);
   SIDATA CHAR(132);
   CURDAT CHAR(  8);
   CURTIM CHAR(  6);
End-DS;

Dcl-DS RS2_HLP LIKEDS(RS2);

// Bit   Value    Attribute (DSPATR-Name)
//  0      1    Reverse Image (RI)
//  1      2    High Intensity (HI)
//  2      4    Underline (UL)
//  3      8    Blink (BL)
//  4     16    Column separator (CS)
//  5     32    Always 1
//  6     64    Always 0
//  7    128    Protect (PR)

Dcl-DS screen QUALIFIED;
   rows    UNS(5) INZ(24);
   columns UNS(5) INZ(80);
End-DS;

Dcl-S #Cmd    VARCHAR(32000);

Dcl-S g_CSS_string VARCHAR(4096) INZ('');

// =================================================================================================

Dcl-Proc MAIN;
   Dcl-PI *N;
      PI_SCNCPY          LIKEDS(qualObj_T);
      PI_IFS_Path          CHAR(128);
      PI_SVG_Filename    LIKEDS(SVGfilename_structure_T);
      PI_Output          LIKEDS(list_Output_T);
      PI_CSS             LIKEDS(list_CSS_T);
   End-PI;

   Dcl-DS #FileCount QUALIFIED;
      num    ZONED(5:0) INZ(0);
      alpha   CHAR(5)   POS(1);
   End-DS;

   Dcl-DS #output QUALIFIED;
      HTML   IND INZ(*OFF);
      MD     IND INZ(*OFF);
   End-DS;

   Dcl-S #Last_IFS_SVG_FileName  LIKE(#IFS_SVG_FileName) INZ('');
   Dcl-S #count_sameFileName     UNS(5) INZ(0);

   Dcl-S #root VARCHAR(80) INZ('');

   Dcl-S h_CntDigits VARCHAR(5);
   Dcl-S h_CreateURL VARCHAR(128);
   // --------------------------------------------------------------------------
   // create Directory
   #Cmd = 'MKDIR ''' + %TRIMR(PI_IFS_Path) + '''';
   MONITOR;
      QCMDEXC(#Cmd:%LEN(#Cmd));
   ON-ERROR;
   ENDMON;


   #IFS_HTML_FullName = %TRIMR(PI_IFS_Path) +'/' + %TRIMR(PI_SVG_Filename.Prefix) +
                        '.html';
   #IFS_MD_FullName   = %TRIMR(PI_IFS_Path) +'/' + %TRIMR(PI_SVG_Filename.Prefix) +
                        '.md';


   SELECT;
      WHEN PI_CSS.create = '*NONE';
      WHEN PI_CSS.create = '*WEB';
         #root = ' :root { color-scheme: light dark; }' + #CRLF;
         g_Colors.DFT      = 'light-dark( ' + COLORS_LIGHT.DFT     + ', ' + COLORS_DARK.DFT     + ')';
         g_Colors.HI       = 'light-dark( ' + COLORS_LIGHT.HI      + ', ' + COLORS_DARK.HI      + ')';
         g_Colors.BL       = 'light-dark( ' + COLORS_LIGHT.BL      + ', ' + COLORS_DARK.BL      + ')';
         g_Colors.CS       = 'light-dark( ' + COLORS_LIGHT.CS      + ', ' + COLORS_DARK.CS      + ')';
         g_Colors.BLCS     = 'light-dark( ' + COLORS_LIGHT.BLCS    + ', ' + COLORS_DARK.BLCS    + ')';
         g_Colors.CSHI     = 'light-dark( ' + COLORS_LIGHT.CSHI    + ', ' + COLORS_DARK.CSHI    + ')';
         g_Colors.HIBLCS   = 'light-dark( ' + COLORS_LIGHT.HIBLCS  + ', ' + COLORS_DARK.HIBLCS  + ')';
         g_Colors.l_UL     = COLORS_LIGHT.l_UL;
         g_Colors.l_CS     = COLORS_LIGHT.l_CS;
      WHEN PI_CSS.create = '*DARK';
         g_Colors.DFT      = COLORS_DARK.DFT;
         g_Colors.HI       = COLORS_DARK.HI;
         g_Colors.BL       = COLORS_DARK.BL;
         g_Colors.CS       = COLORS_DARK.CS;
         g_Colors.BLCS     = COLORS_DARK.BLCS;
         g_Colors.CSHI     = COLORS_DARK.CSHI;
         g_Colors.HIBLCS   = COLORS_DARK.HIBLCS;
         g_Colors.l_UL     = COLORS_DARK.l_UL;
         g_Colors.l_CS     = COLORS_DARK.l_CS;
      OTHER;
         g_Colors.DFT      = COLORS_LIGHT.DFT;
         g_Colors.HI       = COLORS_LIGHT.HI;
         g_Colors.BL       = COLORS_LIGHT.BL;
         g_Colors.CS       = COLORS_LIGHT.CS;
         g_Colors.BLCS     = COLORS_LIGHT.BLCS;
         g_Colors.CSHI     = COLORS_LIGHT.CSHI;
         g_Colors.HIBLCS   = COLORS_LIGHT.HIBLCS;
         g_Colors.l_UL     = COLORS_LIGHT.l_UL;
         g_Colors.l_CS     = COLORS_LIGHT.l_CS;
   ENDSL;



   g_CSS_string = #root +
   ' .t {  font-family: IBM3270, Consolas, monospace;' + #CRLF +
   '       font-size: ' + %CHAR(g_charSize) + 'px;' + #CRLF +
   '       fill: ' + g_Colors.DFT + ';' + #CRLF +
   '       text-align: center; }' + #CRLF +
   ' .HI { font-weight: bold; fill: ' + g_Colors.HI + '; }' + #CRLF +
   ' .BL { fill: ' + g_Colors.BL + '; }' + #CRLF +
   ' .CS { fill: ' + g_Colors.CS + '; }' + #CRLF +
   ' .BL.CS { fill: ' + g_COLORS.BLCS + '; }' + #CRLF +
   ' .CS.HI { fill: ' + g_COLORS.CSHI + '; }' + #CRLF +
   ' .HI.BL.CS { fill: ' + g_COLORS.HIBLCS + '; }' + #CRLF +
   ' .l_UL { stroke: ' + g_COLORS.l_UL + '; stroke-width: 1px; }' + #CRLF +
   ' .l_CS { stroke: ' + g_COLORS.l_CS + '; stroke-width: 1px; stroke-opacity: 0.5; }' + #CRLF;


   // name of the css to be created in IFS
   #IFS_CSS_FileName = PI_CSS;
   IF PI_CSS.createURL <> '*INLINE' AND
      PI_CSS.createURL <> '*NONE';
      #IFS_CSS_FileName = %TRIMR(PI_CSS.createURL);
      IF %SUBST(#IFS_CSS_FileName:%LEN(#IFS_CSS_FileName) - 3:4) <> '.css';
         #IFS_CSS_FileName += '.css';
      ENDIF;
      #IFS_CSS_FullName = %TRIMR(PI_IFS_Path) +'/' + #IFS_CSS_FileName;

      EXEC SQL CALL QSYS2.IFS_WRITE_UTF8( PATH_NAME  => :#IFS_CSS_FullName,
                                          LINE       => :g_CSS_string,
                                          FILE_CCSID => 1208,
                                          OVERWRITE  => 'REPLACE');

   ENDIF;


   #output.HTML = %lookup('*HTML':PI_Output.entry) > 0;
   #output.MD   = %lookup('*MD'  :PI_Output.entry) > 0;

   IF #output.HTML;
      IF 0 = PI_SVG_Filename.CntDigits;
         h_CntDigits = '*NONE';
      ELSE;
         h_CntDigits = %CHAR(PI_SVG_Filename.CntDigits);
      ENDIF;

      IF '*' = %SUBST(PI_CSS.createURL:1:1);
         h_CreateURL = PI_CSS.createURL;
      ELSE;
         h_CreateURL ='''' + PI_CSS.createURL + '''';
      ENDIF;

      f_writeLineHTML(
         '<!DOCTYPE html>' + #CRLF +
         '<html lang="en">' + #CRLF +
         '<head>' + #CRLF +
         '    <meta charset="UTF-8">' + #CRLF +
         '    <meta name="viewport" content="width=device-width, initial-scale=1.0">' + #CRLF +
         '    <title>CPYSCN2SVG</title>' + #CRLF +
         '    <style type="text/css">' + #CRLF +
         '        :root { color-scheme: light dark; }' + #CRLF +
         '        html, body { font-family: Arial, Verdana, sans-serif; }' + #CRLF +
         '        img { display: block; width: 80%; margin-bottom: 10px; border:3px groove grey; }' + #CRLF +
         '        code { display: block;' + #CRLF +
         '               font-family: Consolas, monospace; ' + #CRLF +
         '               border:1px solid grey;' + #CRLF +
         '               background-color: #f0f0f0;' + #CRLF +
         '               color: #404040;' + #CRLF +
         '               padding: 12px; }' + #CRLF +
         '    </style>' + #CRLF +
         '</head>' + #CRLF +
         '<body>' + #CRLF +
         '<h1>CPYSCN2SVG output</h1>' + #CRLF +
         '<p>The following files have been created with:</p>' + #CRLF +
         '<code>CPYSCN2SVG FILE(' + %TRIMR(PI_SCNCPY.Lib) + '/' +
                                    %TRIMR(PI_SCNCPY.Name) + ')' +
                         ' PATH(''' + %TRIMR(PI_IFS_Path) + ''')' +
                         ' SVGNAME(''' + %TRIMR(PI_SVG_Filename.Prefix) + '''' +
                                   ' ' + %TRIMR(PI_SVG_Filename.IncDate) +
                                   ' ' + %TRIMR(PI_SVG_Filename.IncTime) +
                                   ' ' + h_CntDigits +
                                   ' ''' + PI_SVG_Filename.IncSepChar + ''')' +
                         ' OUTPUT(' + %CONCATARR(' ':PI_Output.entry) + ')' +
                         ' CSS(' + PI_CSS.create +
                           ' ' + h_createURL +
                           ' (''' + %CONCATARR(''' ''':%TRIMR(PI_CSS.externals.entry)) + ''')' +
                           ' ''' + PI_CSS.border + '''' +
                           ' ''' + PI_CSS.background + '''' +
                         ')' +
         '</code>' + #CRLF
         );
   ENDIF;

   IF #output.MD;
      f_writeLineMD('# CPYSCN2SVG converted screenshots' + #CRLF);
   ENDIF;





   // Override the system supplied outfile for STRCPYSCN
   #Cmd = 'OVRDBF QASCCPY TOFILE(' + %TRIMR(PI_SCNCPY.Lib) + '/' +
                                     %TRIMR(PI_SCNCPY.Name) + ')';

   QCMDEXC(#Cmd:%LEN(#Cmd));


   // now declare a second cursor to fetch the actual screen data for this screen
   EXEC SQL DECLARE CPYSCN2SVG_2 SCROLL CURSOR FOR
            SELECT SIROW, SIDATA,
                   CASE WHEN CURCEN = '1' THEN '20'
                                          ELSE '19' END CONCAT CURDAT,
                   CURTIM
            FROM QASCCPY SCNCPY
            WHERE SIROW <> ' '
            ORDER BY RRN(SCNCPY);

   EXEC SQL CLOSE CPYSCN2SVG_2;
   EXEC SQL OPEN  CPYSCN2SVG_2;

   DOU SQLCOD <> 0;

      EXEC SQL FETCH CPYSCN2SVG_2
                 FOR 27 ROWS
                INTO :RS2;
      IF SQLCOD <> 0;
         LEAVE;
      ENDIF;

      // check, whether we read too many rows
      IF %ELEM(RS2) = 27;
         IF RS2(27).SIROW = '03 ';
            %ELEM(RS2) = 24;
            EXEC SQL FETCH RELATIVE -3 FROM CPYSCN2SVG_2
                      INTO :RS2_HLP;
         ENDIF;
      ENDIF;


      RESET screen;
      screen.rows = %ELEM(RS2);
      IF screen.rows = 27;
         screen.columns = 132;
      ELSE;
         screen.columns =  80;
      ENDIF;

      // build the svg filename
      #IFS_SVG_FileName = %TRIMR(PI_SVG_Filename.Prefix);

      SELECT;
         WHEN PI_SVG_Filename.IncDate = '*ISO';
            #IFS_SVG_FileName += %TRIMR(PI_SVG_Filename.IncSepChar) +
                                 %SUBST(RS2(1).CURDAT:1:4) + '-' +
                                 %SUBST(RS2(1).CURDAT:5:2) + '-' +
                                 %SUBST(RS2(1).CURDAT:7:2);
         WHEN PI_SVG_Filename.IncDate = '*ISO0';
            #IFS_SVG_FileName += %TRIMR(PI_SVG_Filename.IncSepChar) +
                                 RS2(1).CURDAT;
      ENDSL;

      SELECT;
         WHEN PI_SVG_Filename.IncTime = '*HHMMSS';
            #IFS_SVG_FileName += %TRIMR(PI_SVG_Filename.IncSepChar) +
                                 RS2(1).CURTIM;
         WHEN PI_SVG_Filename.IncTime = '*HHMM';
            #IFS_SVG_FileName += %TRIMR(PI_SVG_Filename.IncSepChar) +
                                 %SUBST(RS2(1).CURTIM:1:4);
         WHEN PI_SVG_Filename.IncTime = '*HH-MM-SS';
            #IFS_SVG_FileName += %TRIMR(PI_SVG_Filename.IncSepChar) +
                                 %SUBST(RS2(1).CURTIM:1:2) + '-' +
                                 %SUBST(RS2(1).CURTIM:3:2) + '-' +
                                 %SUBST(RS2(1).CURTIM:5:2);
      ENDSL;

      #FileCount.num += 1;
      IF PI_SVG_Filename.CntDigits > 0;
         #IFS_SVG_FileName += %TRIMR(PI_SVG_Filename.IncSepChar) +
                              %SUBST(#FileCount.alpha:
                                     6 - PI_SVG_Filename.CntDigits:
                                     PI_SVG_Filename.CntDigits);
      ENDIF;

      // if the file name is equal to the last file name, include a counter to prevent overwriting
      IF #IFS_SVG_FileName = #Last_IFS_SVG_FileName;
         #count_sameFileName += 1;
         #IFS_SVG_FileName += ' (' + %TRIM(%CHAR(#count_sameFileName)) + ')';
      ELSE;
         #Last_IFS_SVG_FileName = #IFS_SVG_FileName;
         #count_sameFileName = 1;
      ENDIF;

      #IFS_SVG_FileName += '.svg';
      #IFS_SVG_FullName = %TRIMR(PI_IFS_Path) + '/' + #IFS_SVG_FileName;

      // generate the svg file
      f_svg(PI_CSS);

      IF #output.HTML;
         f_writeLineHTML(
            '<p><a href="' + #IFS_SVG_FileName + '">' +
                             #IFS_SVG_FileName + '</a><br>' +
            '<img src="' + #IFS_SVG_FileName + '"' +
                ' alt="' + #IFS_SVG_FileName + '"' +
            '></p>'
         );
      ENDIF;

      IF #output.MD;
         f_writeLineMD('![' + #IFS_SVG_FileName + ']' +
                        '(' + #IFS_SVG_FileName + ')');
      ENDIF;


   ENDDO;


   IF #output.HTML;
      f_writeLineHTML('</body></html>');
   ENDIF;


   // ==========================================================================
   ON-EXIT;

      #Cmd = 'DLTOVR QASCCPY';
      QCMDEXC(#Cmd:%LEN(#Cmd));

      EXEC SQL CLOSE CPYSCN2SVG_2;

End-Proc;


// -------------------------------------------------------------------------------------------------
Dcl-Proc f_svg;

   Dcl-PI *N;
      myCSS            LIKEDS(list_CSS_T) CONST;
   End-PI;

   Dcl-S charHeight  UNS(5);
   // 24 x  80
   // 27 x 132
   Dcl-S svgWidth   UNS(10);
   Dcl-S svgHeight  UNS(10);
   Dcl-S svgPosX    UNS(10) INZ(0);
   Dcl-S svgPosY    UNS(10) INZ(0);

   Dcl-S #row   UNS(5);
   Dcl-S #col   UNS(5);

   Dcl-S #char1          CHAR(1);
   Dcl-S #classString VARCHAR(18);
   Dcl-S #svgString   VARCHAR(1024);

   Dcl-S #i UNS(5);

   // Variables for grouping consecutive characters
   Dcl-S #textBuffer    VARCHAR(256);
   Dcl-S #lastClass     VARCHAR(18);
   Dcl-S #groupStartX   UNS(10);
   Dcl-S #groupStartCol UNS(5);

   // Variables for grouping underlines
   Dcl-S #ulStartX      UNS(10);
   Dcl-S #ulActive      IND INZ(*OFF);

   // --------------------------------------------------------------------------
   charHeight = g_charSize + 2;

   svgHeight = (screen.rows + 1) * charHeight;
   svgWidth  = screen.columns    * g_charWidth;

   svgPosY = charHeight;

   f_writeLineSVG('<svg xmlns="http://www.w3.org/2000/svg"' +
                 ' height="' + %CHAR(svgHeight) + '"' +
                 ' width="' + %CHAR(svgWidth) + '"' +
               //   ' viewBox="0 0 ' + %CHAR(svgHeight) + ' ' +
               //                      %CHAR(svgWidth) + '"' +
                 ' preserveAspectRatio="xMinYMin meet"' +
                 ' version="1.1"' +
                 ' xmlns:xlink="http://www.w3.org/1999/xlink"' +
                  '>');

   SELECT;
      WHEN myCSS.createURL = '*NONE';
      WHEN myCSS.createURL = '*INLINE';
         f_writeLineSVG('<style type="text/css">' + #CRLF +
         '  <![CDATA[' + #CRLF +
         g_CSS_string +
         '  ]]>' + #CRLF +
         '</style>');
      OTHER;
         f_writeLineSVG('<link xmlns="http://www.w3.org/1999/xhtml"' +
                        ' rel="stylesheet"' +
                        ' href="' + myCSS.createURL + '"' +
                        ' type="text/css" />');
   ENDSL;

   FOR #i = 1 TO myCSS.externals.count;
      IF %TRIMR(myCSS.externals.entry(#i)) = '' OR
                myCSS.externals.entry(#i)  = '*NONE';
         ITER;
      ENDIF;
      f_writeLineSVG('<link xmlns="http://www.w3.org/1999/xhtml"' +
                     ' rel="stylesheet"' +
                     ' href="' + %TRIMR(myCSS.externals.entry(#i)) + '"' +
                     ' type="text/css" />');
   ENDFOR;

   SELECT;
      WHEN myCSS.border     <> '*NONE'
       AND myCSS.background <> '*NONE';

         f_writeLineSVG('<rect x="0" y="0" width="' + %CHAR(svgWidth) + '"' +
                              ' height="' + %CHAR(svgHeight) + '"' +
                              ' fill="' + %TRIMR(myCSS.background) + '"' +
                              ' stroke="' + %TRIMR(myCSS.border) + '"' +
                              ' stroke-width="4" />');

      WHEN myCSS.background <> '*NONE';

         f_writeLineSVG('<rect x="0" y="0" width="' + %CHAR(svgWidth) + '"' +
                              ' height="' + %CHAR(svgHeight) + '"' +
                              ' fill="' + %TRIMR(myCSS.background) + '" />');

      WHEN myCSS.border <> '*NONE';

         f_writeLineSVG('<rect x="0" y="0" width="' + %CHAR(svgWidth) + '"' +
                              ' height="' + %CHAR(svgHeight) + '"' +
                              ' stroke="' + %TRIMR(myCSS.border) + '"' +
                              ' stroke-width="4" />');

   ENDSL;


   IF myCSS.border     <> '' AND
      myCSS.background <> '';
   ENDIF;




   // TODO: background rectangle for reverse image
   // f_writeLineSVG('<rect x="0" y="0" width="1" height="1" class="t" />');

   FOR #row = 1 TO screen.rows;
      RESET #textBuffer;
      RESET #lastClass;
      #groupStartX = 0;
      #groupStartCol = 0;
      #ulActive = *OFF;

      FOR #col = 1 TO screen.columns;
         #char1 = f_processChar(#row:
                                #col:
                                %SUBST(RS2(#row).SIDATA:#col:1):
                                #classString);

         // Check if we need to flush the text buffer
         // (class changed, or we hit a blank after non-blanks)
         IF (#classString <> #lastClass AND #textBuffer <> '') OR
            (#char1 = *BLANK AND #textBuffer <> '');

            // Write accumulated text
            f_writeLineSVG('<text x="' + %CHAR(#groupStartX) + '"' +
                           ' y="' + %CHAR(svgPosY) + '"' +
                           ' class="t' + #lastClass + '">' +
                           f_escapeXML(#textBuffer) + '</text>');
            RESET #textBuffer;
         ENDIF;

         // Handle underline grouping
         IF %SCAN(' UL':#classString) > 0;
            IF NOT #ulActive;
               // Start new underline
               #ulStartX = f_subToZero(svgPosX:1);
               #ulActive = *ON;
            ENDIF;
         ELSE;
            IF #ulActive;
               // End underline - draw the line
               f_writeLineSVG('<line x1="' + %CHAR(#ulStartX) + '"' +
                                   ' y1="' + %CHAR(svgPosY + 1) + '"' +
                                   ' x2="' + %CHAR(f_subToZero(svgPosX:1)) + '"' +
                                   ' y2="' + %CHAR(svgPosY + 1) + '"' +
                                   ' class="l_UL" />');
               #ulActive = *OFF;
            ENDIF;
         ENDIF;

         // Handle column separators (still individual lines)
         // Do this BEFORE adding to buffer so we don't affect class comparison
         IF %SCAN(' HI BL CS':#classString) > 0;
            // Don't draw CS lines for HIBLCS combination
         ELSE;
            IF %SCAN(' CS':#classString) > 0;
               f_writeLineSVG('<line x1="' + %CHAR(f_subToZero(svgPosX:1)) + '"' +
                                   ' y1="' + %CHAR(svgPosY) + '"' +
                                   ' x2="' + %CHAR(f_subToZero(svgPosX:1)) + '"' +
                                   ' y2="' + %CHAR(f_subToZero(svgPosY:2)) + '"' +
                                   ' class="l_CS" />');
               f_writeLineSVG('<line x1="' + %CHAR(svgPosX + g_charWidth - 1) + '"' +
                                   ' y1="' + %CHAR(svgPosY) + '"' +
                                   ' x2="' + %CHAR(svgPosX + g_charWidth - 1) + '"' +
                                   ' y2="' + %CHAR(f_subToZero(svgPosY:2)) + '"' +
                                   ' class="l_CS" />');
            ENDIF;
         ENDIF;

         // Add character to buffer if not blank
         IF #char1 <> *BLANK;
            IF #textBuffer = '';
               #groupStartX = svgPosX;
               #groupStartCol = #col;
               #lastClass = #classString;
            ENDIF;
            #textBuffer += #char1;
         ENDIF;

         svgPosX += g_charWidth;
      ENDFOR;

      // Flush any remaining text at end of row
      IF #textBuffer <> '';
         f_writeLineSVG('<text x="' + %CHAR(#groupStartX) + '"' +
                        ' y="' + %CHAR(svgPosY) + '"' +
                        ' class="t' + #lastClass + '">' +
                        f_escapeXML(#textBuffer) + '</text>');
      ENDIF;

      // Close any open underline at end of row
      IF #ulActive;
         f_writeLineSVG('<line x1="' + %CHAR(#ulStartX) + '"' +
                             ' y1="' + %CHAR(svgPosY + 1) + '"' +
                             ' x2="' + %CHAR(svgPosX - 1) + '"' +
                             ' y2="' + %CHAR(svgPosY + 1) + '"' +
                             ' class="l_UL" />');
      ENDIF;

      svgPosX  = 0;
      svgPosY += charHeight;
   ENDFOR;

   f_writeLineSVG('</svg>');


End-Proc;

// -------------------------------------------------------------------------------------------------
Dcl-Proc f_writeLineSVG;
   Dcl-PI *N;
      myLine VARCHAR(1024) CONST;
   End-PI;

   Dcl-S #OVERWRITE   VARCHAR(9) INZ('REPLACE') STATIC;

   // new svg = overwite existing file
   IF %LEN(myLine) >= 5;
      IF %SUBST(myLine:1:5) = '<svg ';
         RESET #OVERWRITE;
      ENDIF;
   ENDIF;

   EXEC SQL CALL QSYS2.IFS_WRITE_UTF8(PATH_NAME  => :#IFS_SVG_FullName,
                                      LINE       => :myLine,
                                      FILE_CCSID => 1208,
                                      OVERWRITE  => :#OVERWRITE);

   #OVERWRITE = 'APPEND';

End-Proc;
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
Dcl-Proc f_writeLineHTML;
   Dcl-PI *N;
      myLine VARCHAR(4096) CONST;
   End-PI;

   Dcl-S #OVERWRITE VARCHAR(9) INZ('REPLACE') STATIC;

   EXEC SQL CALL QSYS2.IFS_WRITE_UTF8(PATH_NAME  => :#IFS_HTML_FullName,
                                      LINE       => :myLine,
                                      FILE_CCSID => 1208,
                                      OVERWRITE  => :#OVERWRITE);

   #OVERWRITE = 'APPEND';

End-Proc;
// -------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------------------------------
Dcl-Proc f_writeLineMD;
   Dcl-PI *N;
      myLine VARCHAR(4096) CONST;
   End-PI;

   Dcl-S #OVERWRITE VARCHAR(9) INZ('REPLACE') STATIC;

   EXEC SQL CALL QSYS2.IFS_WRITE_UTF8(PATH_NAME  => :#IFS_MD_FullName,
                                      LINE       => :myLine,
                                      FILE_CCSID => 1208,
                                      OVERWRITE  => :#OVERWRITE);

   #OVERWRITE = 'APPEND';

End-Proc;
// -------------------------------------------------------------------------------------------------


// -------------------------------------------------------------------------------------------------
Dcl-Proc f_processChar;
   Dcl-PI *N LIKE(rtnChar);
      myRow#            UNS(5) CONST;
      myCol#            UNS(5) CONST;
      myChar           CHAR(1) CONST;
      myClassString VARCHAR(18);
   End-PI;

   Dcl-S rtnChar CHAR(1);

   Dcl-S #i                UNS(5);
   Dcl-S #classes         CHAR(2) DIM(*AUTO:6);
   Dcl-S #classString  VARCHAR(18) INZ('') STATIC;

   // Dcl-S #testChar CHAR(1);

   Dcl-ENum ATR5250 QUALIFIED;
      DF x'20'; // default (green on black)
      RI x'21'; // Reverse Image
      HI x'22'; // High Intensity
      UL x'24'; // Underline
      ND x'27'; // Non-Display
      BL x'28'; // Blink
      CS x'30'; // Column separators
      PR x'A0'; // Protect
   End-ENum;

   IF myRow# = 1 AND
      myCol# = 1;
      RESET #classString;
   ENDIF;

   rtnChar = myChar;

   // FOR #i = 1 TO 132;
   // #testChar = %SUBST(myLine:#i:1);
   // if the char is less than x'40', check for attribute and remove
   IF rtnChar < x'40';
      %ELEM(#classes) = 0;
      IF %BITAND(rtnChar:ATR5250.ND) = ATR5250.ND;
      ELSE;
         IF %BITAND(rtnChar:ATR5250.RI) = ATR5250.RI;
            #classes(*NEXT) = 'RI';
         ENDIF;
         IF %BITAND(rtnChar:ATR5250.HI) = ATR5250.HI;
            #classes(*NEXT) = 'HI';
         ENDIF;
         IF %BITAND(rtnChar:ATR5250.UL) = ATR5250.UL;
            #classes(*NEXT) = 'UL';
         ENDIF;
         IF %BITAND(rtnChar:ATR5250.BL) = ATR5250.BL;
            #classes(*NEXT) = 'BL';
         ENDIF;
         IF %BITAND(rtnChar:ATR5250.CS) = ATR5250.CS;
            #classes(*NEXT) = 'CS';
         ENDIF;
         // "Protect" is irrelevant
         // IF %BITAND(rtnChar:ATR5250.PR) = ATR5250.PR;
         //    #classes(*NEXT) = 'PR';
         // ENDIF;
      ENDIF;
      #classString = %CONCATARR(' ':#classes);
      IF rtnChar = ATR5250.DF;
         #classString = '';
      ENDIF;

      IF #classString <> '';
         #classString = ' ' + #classString;
      ENDIF;

      // remove this character
      rtnChar = ' ';
      myClassString = '';

   ELSE;
      myClassString = #classString;
   ENDIF;
   // ENDFOR;


   RETURN rtnChar;

End-Proc;


// -------------------------------------------------------------------------------------------------
// subtract mySub from myValue, but do not go below zero
Dcl-Proc f_subToZero;
   Dcl-PI *N LIKE(rtnValue);
      myValue           UNS(10) CONST;
      mySub             UNS(10) CONST;
   End-PI;

   Dcl-S rtnValue UNS(10);

   IF myValue < mySub;
      rtnValue = 0;
   ELSE;
      rtnValue = myValue - mySub;
   ENDIF;

   RETURN rtnValue;

End-Proc;

// -------------------------------------------------------------------------------------------------
// Escape special XML characters in text content
Dcl-Proc f_escapeXML;
   Dcl-PI *N VARCHAR(512);
      myText VARCHAR(256) CONST;
   End-PI;

   Dcl-S rtnText VARCHAR(512);

   rtnText = myText;

   // Replace special XML characters
   rtnText = %SCANRPL('&':'&amp;':rtnText);
   rtnText = %SCANRPL('<':'&lt;':rtnText);
   rtnText = %SCANRPL('>':'&gt;':rtnText);
   rtnText = %SCANRPL('"':'&quot;':rtnText);
   rtnText = %SCANRPL('''':'&apos;':rtnText);

   RETURN rtnText;

End-Proc;