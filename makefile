OBJ_LIB = ANGO1                                                                                                        
                                                                                                                          
QOBJ_LIB = /QSYS.LIB/$(OBJ_LIB).LIB                                                                                         
QSRC_PATH = /home/ANGO/CPYSCN2SVG                                                                                          
                                                                                                                          
$(QOBJ_LIB)/CPYSCN2SVG.CMD: QCMDSRC/CPYSCN2SVG.CMD                                                                                
 system "CRTCMD CMD($(OBJ_LIB)/CPYSCN2SVG) PGM($(OBJ_LIB)/CPYSCN2SVG) SRCSTMF('QCMDSRC/CPYSCN2SVG.CMD')"                 
                                                                                                                          
$(QOBJ_LIB)/CPYSCN2SVG.PGM: QRPGLESRC/CPYSCN2SVG.SQLRPGLE                                                                           
 system "CRTSQLRPGI OBJ($(OBJ_LIB)/CPYSCN2SVG) SRCSTMF('QRPGSRCLE/CPYSCN2SVG.SQLRPGLE') RPGPPOPT(*LVL2) DBGVIEW(*LIST)"
