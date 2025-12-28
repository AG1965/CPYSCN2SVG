/* ************************************************************************** */
             CMD        PROMPT('STRCPYSCN-OUTFILE to svg-files') TEXT(*CMDPMT)
/* ************************************************************************** */
             PARM       KWD(FILE) TYPE(QUALOBJ) MIN(1) +
                          PROMPT('STRCPYSCN-OUTFILE')

             PARM       KWD(PATH) TYPE(*PNAME) CASE(*MIXED) MIN(1) LEN(128) +
                          PROMPT('Path for svg-files')

             PARM       KWD(PREFIX) TYPE(*PNAME) CASE(*MIXED) LEN(64) +
                          DFT('cpyscn2svg') +
                          PROMPT('Prefix for svg-files')
             PARM       KWD(INCDATE) TYPE(*CHAR) LEN(10) +
                          DFT(*ISO) +
                          RSTD(*YES) VALUES(*NO *ISO *ISO0) +
                          PROMPT('Append Date')
             PARM       KWD(INCTIME) TYPE(*CHAR) LEN(10) +
                          DFT(*HHMMSS) +
                          RSTD(*YES) VALUES(*NO *HHMMSS *HHMM '*HH-MM-SS') +
                          PROMPT('Append time')
             PARM       KWD(INCCNT) TYPE(*DEC) LEN(1 0) +
                          DFT(*NONE) RANGE(1 5) +
                          SPCVAL((*NONE 0)) +
                          PROMPT('Append n digits counter')
             PARM       KWD(INCSEP) TYPE(*CHAR) LEN(1) +
                          DFT('_') +
                          SPCVAL((*NONE '')) +
                          PROMPT('Separator character')
             PARM       KWD(OUTPUT) TYPE(*CHAR) LEN(10) MAX(2) +
                          DFT(*HTML) +
                          RSTD(*YES) VALUES(*NONE *HTML *MD) +
                          PROMPT('HTML / Markdown output')

             PARM       KWD(CSS) TYPE(*PNAME) CASE(*MIXED) LEN(128) +
                          DFT(*INLINE) +
                          SPCVAL((*INLINE) (*NONE)) +
                          PROMPT('Create CSS inline / external')

             PARM       KWD(CSSEXT) TYPE(*PNAME) CASE(*MIXED) LEN(128) MAX(5) +
                          DFT(*NONE) SPCVAL((*NONE)) +
                          PROMPT('URLs for external CSS-files')


 QUALOBJ:    QUAL       TYPE(*NAME) LEN(10)
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL) (*CURLIB) (*USRLIBL) +
                          (*ALL) (*ALLUSR)) PROMPT('Library')

