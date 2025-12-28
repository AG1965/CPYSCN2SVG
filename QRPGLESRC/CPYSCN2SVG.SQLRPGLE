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
   qualSCNCPY     LIKEDS(qualObj_T);
   IFS_Path          CHAR(128);
   IFS_Prefix        CHAR( 64);
   IFS_IncDate       CHAR( 10);
   IFS_IncTime       CHAR( 10);
   IFS_CntDigits   PACKED(1:0);
   IFS_IncSepChar    CHAR(  1);
   IFS_Output      LIKEDS(list_Output_T);
   CSS               CHAR(128);
   CSS_externals   LIKEDS(list_externals_T);
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
   entry  CHAR(128) DIM(5);
End-DS;


Dcl-DS colorsGrnOnWht QUALIFIED;
   grn  CHAR(7) INZ('#006400');
   wht  CHAR(7) INZ('#000000');
   blu  CHAR(7) INZ('#003399');
   trq  CHAR(7) INZ('#008b8b');
   red  CHAR(7) INZ('#b00020');
   pnk  CHAR(7) INZ('#a000a0');
   ylw  CHAR(7) INZ('#9a8700');
End-DS;

Dcl-C #CRLF x'0D25';

Dcl-S g_charWidth   UNS(5) INZ(12);
Dcl-S g_charSize    UNS(5) INZ(20);

/INCLUDE 'QSYSCPY/DQCMDEXC.RPGLEINC'

// Dcl-F QASCCPY DISK EXTFILE('QASCCPY') TEMPLATE;

Dcl-DS RS1 QUALIFIED;
   MAXROW UNS(5);
   CURCEN CHAR(1);
   CURDAT CHAR(6);
   CURTIM CHAR(6);
End-DS;

Dcl-S #IFS_SVG_FileName  VARCHAR(128);
Dcl-S #IFS_SVG_FullName  VARCHAR(512);
Dcl-S #IFS_CSS_FileName  VARCHAR(128) INZ('');
Dcl-S #IFS_CSS_FullName  VARCHAR(512);
Dcl-S #IFS_HTML_FullName VARCHAR(512);
Dcl-S #IFS_MD_FullName   VARCHAR(512);

Dcl-DS RS2 QUALIFIED DIM(27);
   SIDATA CHAR(132);
End-DS;

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
      PI_IFS_Prefix        CHAR( 64);
      PI_IFS_IncDate       CHAR( 10);
      PI_IFS_IncTime       CHAR( 10);
      PI_IFS_CntDigits   PACKED(1:0);
      PI_IFS_IncSepChar    CHAR(  1);
      PI_IFS_Output      LIKEDS(list_Output_T);
      PI_CSS               CHAR(128);
      PI_CSS_externals   LIKEDS(list_externals_T);
   End-PI;

   Dcl-DS #FileCount QUALIFIED;
      num    ZONED(5:0) INZ(0);
      alpha   CHAR(5)   POS(1);
   End-DS;

   Dcl-DS #output QUALIFIED;
      HTML   IND INZ(*OFF);
      MD     IND INZ(*OFF);
   End-DS;

   // --------------------------------------------------------------------------
   // create Directory
   #Cmd = 'MKDIR ''' + %TRIMR(PI_IFS_Path) + '''';
   MONITOR;
      QCMDEXC(#Cmd:%LEN(#Cmd));
   ON-ERROR;
   ENDMON;


   #IFS_HTML_FullName = %TRIMR(PI_IFS_Path) +'/' + %TRIMR(PI_IFS_Prefix) +
                        '.html';
   #IFS_MD_FullName   = %TRIMR(PI_IFS_Path) +'/' + %TRIMR(PI_IFS_Prefix) +
                        '.md';


   g_CSS_string =
   ' :root { color-scheme: light dark; }' + #CRLF +
   ' .t {  font-family: IBM3270, Consolas, monospace;' + #CRLF +
   '       font-size: ' + %CHAR(g_charSize) + 'px;' + #CRLF +
   '       fill: light-dark( #006400, #00ff00);' + #CRLF +
   '       text-align: center; }' + #CRLF +
   ' .HI { font-weight: bold; fill: light-dark( #000000, #f0f0f0); }' + #CRLF +
   ' .BL { fill: light-dark( #b00020, #ff0000); }' + #CRLF +
   ' .CS { fill: light-dark( #008b8b, #00ffff); }' + #CRLF +
   ' .BL.CS { fill: light-dark( #a000a0, #ff1aff); }' + #CRLF +
   ' .HI.BL.CS { fill: light-dark( #003399, #7890f0); }' + #CRLF +
   ' .l_UL { stroke: currentColor; stroke-width: 1px; }' + #CRLF +
   ' .l_CS { stroke: light-dark( #008b8b, #00ffff); stroke-width: 1px; stroke-opacity: 0.5; }' + #CRLF;

   // name of the css to be created in IFS
   #IFS_CSS_FileName = PI_CSS;
   IF PI_CSS <> '*INLINE' AND
      PI_CSS <> '*NONE';
      #IFS_CSS_FileName = %TRIMR(PI_CSS);
      IF %SUBST(#IFS_CSS_FileName:%LEN(#IFS_CSS_FileName) - 3:4) <> '.css';
         #IFS_CSS_FileName += '.css';
      ENDIF;
      #IFS_CSS_FullName = %TRIMR(PI_IFS_Path) +'/' + #IFS_CSS_FileName;

      EXEC SQL CALL QSYS2.IFS_WRITE_UTF8( PATH_NAME  => :#IFS_CSS_FullName,
                                          LINE       => :g_CSS_string,
                                          FILE_CCSID => 1208,
                                          OVERWRITE  => 'REPLACE');

   ENDIF;


   #output.HTML = %lookup('*HTML':PI_IFS_Output.entry) > 0;
   #output.MD   = %lookup('*MD'  :PI_IFS_Output.entry) > 0;

   IF #output.HTML;
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
                         ' PREFIX(''' + %TRIMR(PI_IFS_Prefix) + ''')' +
                         ' INCDATE(' + %TRIMR(PI_IFS_IncDate) + ')' +
                         ' INCTIME(' + %TRIMR(PI_IFS_IncTime) + ')' +
                         ' INCCNT(' + %CHAR(PI_IFS_CntDigits) + ')' +
                         ' INCSEP(''' + PI_IFS_IncSepChar + ''')' +
                         ' OUTPUT(' + %CONCATARR(' ':PI_IFS_Output.entry) + ')' +     
                         ' CSS(''' + PI_CSS + ''')' +
                         ' CSSEXT(' + %CONCATARR(' ':PI_CSS_externals.entry) + ')' +     
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

   // Declare a cursor to a result set that contains one line per screen and provides the number of lines (24 or 27)
   EXEC SQL DECLARE CPYSCN2SVG_1 CURSOR FOR
            SELECT MAX(SIROW),
                  CURCEN, CURDAT, CURTIM
            FROM QASCCPY
            WHERE SIROW <> ' '
            GROUP BY CURCEN, CURDAT, CURTIM
            ORDER BY CURCEN, CURDAT, CURTIM;

   EXEC SQL CLOSE CPYSCN2SVG_1;
   EXEC SQL OPEN  CPYSCN2SVG_1;

   DOU SQLCOD <> 0;
      EXEC SQL FETCH CPYSCN2SVG_1 INTO :RS1;
      IF SQLCOD <> 0;
         LEAVE;
      ENDIF;

      RESET screen;
      screen.rows = RS1.MAXROW;
      IF screen.rows = 27;
         screen.columns = 132;
      ELSE;
         screen.columns =  80;
      ENDIF;

      // now declare a second cursor to fetch the actual screen data for this screen
      EXEC SQL DECLARE CPYSCN2SVG_2 CURSOR FOR
               SELECT SIDATA
               FROM QASCCPY
               WHERE SIROW <> ' '
               AND CURCEN = :RS1.CURCEN
               AND CURDAT = :RS1.CURDAT
               AND CURTIM = :RS1.CURTIM
               ORDER BY SIROW;

      EXEC SQL CLOSE CPYSCN2SVG_2;
      EXEC SQL OPEN  CPYSCN2SVG_2;

      EXEC SQL FETCH CPYSCN2SVG_2
                 FOR :RS1.MAXROW ROWS
                INTO :RS2;

      EXEC SQL CLOSE CPYSCN2SVG_2;

      // build the svg filename
      #IFS_SVG_FileName = %TRIMR(PI_IFS_Prefix);

      SELECT;
         WHEN PI_IFS_IncDate = '*ISO';
            #IFS_SVG_FileName += %TRIMR(PI_IFS_IncSepChar) +
                                 '20' + %SUBST(RS1.CURDAT:1:2) + '-' +
                                       %SUBST(RS1.CURDAT:3:2) + '-' +
                                       %SUBST(RS1.CURDAT:5:2);
         WHEN PI_IFS_IncDate = '*ISO0';
            #IFS_SVG_FileName += %TRIMR(PI_IFS_IncSepChar) +
                                 '20' + RS1.CURDAT;
      ENDSL;

      SELECT;
         WHEN PI_IFS_IncTime = '*HHMMSS';
            #IFS_SVG_FileName += %TRIMR(PI_IFS_IncSepChar) +
                                 RS1.CURTIM;
         WHEN PI_IFS_IncTime = '*HHMM';
            #IFS_SVG_FileName += %TRIMR(PI_IFS_IncSepChar) +
                                 %SUBST(RS1.CURTIM:1:4);
         WHEN PI_IFS_IncTime = '*HH-MM-SS';
            #IFS_SVG_FileName += %TRIMR(PI_IFS_IncSepChar) +
                                 %SUBST(RS1.CURTIM:1:2) + '-' +
                                 %SUBST(RS1.CURTIM:3:2) + '-' +
                                 %SUBST(RS1.CURTIM:5:2);
      ENDSL;

      #FileCount.num += 1;
      IF PI_IFS_CntDigits > 0;
         #IFS_SVG_FileName += %TRIMR(PI_IFS_IncSepChar) +
                              %SUBST(#FileCount.alpha:
                                     6 - PI_IFS_CntDigits:
                                     PI_IFS_CntDigits);
      ENDIF;

      #IFS_SVG_FileName += '.svg';
      #IFS_SVG_FullName = %TRIMR(PI_IFS_Path) + '/' + #IFS_SVG_FileName;

      // generate the svg file
      f_svg(#IFS_CSS_FileName:
            PI_CSS_externals);

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

   EXEC SQL CLOSE CPYSCN2SVG_1;

   IF #output.HTML;
      f_writeLineHTML('</body></html>');
   ENDIF;



   ON-EXIT;

      #Cmd = 'DLTOVR QASCCPY';
      QCMDEXC(#Cmd:%LEN(#Cmd));


End-Proc;


// -------------------------------------------------------------------------------------------------
Dcl-Proc f_svg;

   Dcl-PI *N;
      myCSS            VARCHAR(128) CONST;
      myCSS_externals  LIKEDS(list_externals_T) CONST;
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
      WHEN myCSS = '*NONE';
      WHEN myCSS = '*INLINE';
         f_writeLineSVG('<style type="text/css">' + #CRLF +
         '  <![CDATA[' + #CRLF +
         g_CSS_string +
         '  ]]>' + #CRLF +
         '</style>');
      OTHER;
         f_writeLineSVG('<link xmlns="http://www.w3.org/1999/xhtml"' +
                        ' rel="stylesheet"' +
                        ' href="' + myCSS + '"' +
                        ' type="text/css" />');
   ENDSL;

   FOR #i = 1 TO myCSS_externals.count;
      IF %TRIMR(myCSS_externals.entry(#i)) = '' OR
                myCSS_externals.entry(#i)  = '*NONE';
         ITER;
      ENDIF;
      f_writeLineSVG('<link xmlns="http://www.w3.org/1999/xhtml"' +
                     ' rel="stylesheet"' +
                     ' href="' + %TRIMR(myCSS_externals.entry(#i)) + '"' +
                     ' type="text/css" />');
   ENDFOR;

   // TODO: background rectangle for reverse image
   // f_writeLineSVG('<rect x="0" y="0" width="1" height="1" class="t" />');

   FOR #row = 1 TO screen.rows;
      FOR #col = 1 TO screen.columns;
         #char1 = f_processChar(#row:
                                #col:
                                %SUBST(RS2(#row).SIDATA:#col:1):
                                #classString);

         // #charWidth = %LEN(%SUBST(RS2(#row).SIDATA:#col:1)); // TODO: das kann ja nur 1 sein?!
         IF #char1 <> *BLANK;
            f_writeLineSVG('<text x="' + %CHAR(svgPosX) + '"' +
                           ' y="' + %CHAR(svgPosY) + '"' +
                           ' class="t' + #classString + '">' +
                           #char1 + '</text>');
         ENDIF;

         IF %SCAN(' UL':#classString) > 0;
            f_writeLineSVG('<line x1="' + %CHAR(f_subToZero(svgPosX:1)) + '"' +
                                ' y1="' + %CHAR(svgPosY + 1) + '"' +
                                ' x2="' + %CHAR(svgPosX + g_charWidth - 1) + '"' +
                                ' y2="' + %CHAR(svgPosY + 1) + '"' +
                                ' class="l_UL" />');
         ENDIF;
         IF %SCAN(' HI BL CS':#classString) > 0;
            #classString = %SCANRPL(' HI BL CS':' HIBLCS':#classString);
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

         svgPosX += g_charWidth;
      ENDFOR;
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