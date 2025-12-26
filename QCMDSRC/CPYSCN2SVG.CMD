/* ************************************************************************** */
             CMD        PROMPT('STRCPYSCN in svg konvertieren') TEXT(*CMDPMT)
/* ************************************************************************** */
             PARM       KWD(FILE) TYPE(QUALOBJ) MIN(1) +
                          PROMPT('Von STRCPYSCN erstellte Datei')

             PARM       KWD(PATH) TYPE(*PNAME) MIN(1) LEN(128) +
                          PROMPT('Pfad für svg-Dateien')

             PARM       KWD(PREFIX) TYPE(*NAME) LEN(64) +
                          DFT('cpyscn2svg') +
                          PROMPT('Präfix für svg-files')
             PARM       KWD(INCDATE) TYPE(*CHAR) LEN(10) +
                          DFT(*ISO) +
                          RSTD(*YES) VALUES(*NO *ISO *ISO0) +
                          PROMPT('Datum anhängen')
             PARM       KWD(INCTIME) TYPE(*CHAR) LEN(10) +
                          DFT(*HHMMSS) +
                          RSTD(*YES) VALUES(*NO *HHMMSS *HHMM '*HH-MM-SS') +
                          PROMPT('Uhrzeit anhängen')
             PARM       KWD(INCCNT) TYPE(*DEC) LEN(5 0) +
                          DFT(*NONE) RANGE(1 5) +
                          SPCVAL((*NONE 0)) +
                          PROMPT('n Stellen Zähler anhängen')
             PARM       KWD(INCSEP) TYPE(*CHAR) LEN(1) +
                          DFT('_') +
                          SPCVAL((*NONE '')) +
                          PROMPT('Trennzeichen zw. Anhängseln')
             PARM       KWD(OUTPUT) TYPE(*CHAR) LEN(10) MAX(5) +
                          DFT(*HTML) +
                          RSTD(*YES) VALUES(*NONE *HTML *MD) +
                          PROMPT('HTML / Markdown ausgeben')

             PARM       KWD(CSS) TYPE(*CHAR) LEN(128) +
                          DFT(*INLINE) +
                          SPCVAL((*INLINE) (*NONE)) +
                          PROMPT('CSS erzeugen intern / extern')

             PARM       KWD(CSSEXT) TYPE(*PNAME) LEN(128) MAX(5) +
                          DFT(*NONE) SPCVAL((*NONE)) +
                          PROMPT('URL für externe CSS-Datei')


 QUALOBJ:    QUAL       TYPE(*NAME) LEN(10)
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL) (*CURLIB) (*USRLIBL) +
                          (*ALL) (*ALLUSR)) PROMPT('Bibliothek')

