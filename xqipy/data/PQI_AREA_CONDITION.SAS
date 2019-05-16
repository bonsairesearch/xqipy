*================== PROGRAM: PQI_AREA_CONDITION ====================;
*
*  DESCRIPTION: 
*         Uses proc summary to calculate condition-specific rates 
*         for Prevention Quality Indicators across stratifiers.
*         Output stratified by FIPST and AGECCAT from condition
*         population file and PQI_ALL_MEASURES.sas output.
*         variable created by this program is CAPQXX
*
*  VERSION: SAS QI v2018 (ICD-10 CM/PCS)
*  RELEASE DATE: JUNE 2018
*===================================================================;

*PATHNAME specifies the location of the PQI folder which includes 
          Programs, SASdata, and Macros subfolders;
%LET PATHNAME= c:\Pathname\PQI;                *<===USER MUST modify;

filename CONTROL "&PATHNAME.\Programs\PQI_ALL_CONTROL.SAS"; 
%INCLUDE CONTROL;

 title2 'PROGRAM PQI_AREA_CONDITION';
 title3 'AHRQ PREVENTION QUALITY INDICATORS: CALCULATE CONDITION-SPECIFIC RATES';
 run;

 * -------------------------------------------------------------- ;
 * --- CALCULATE THE NUMERATORS (T PREFIX) FOR THE CONDITION- --- ;
 * --- SPECIFIC RATES. ------------------------------------------ ;
 * -------------------------------------------------------------- ;

 proc   summary data=OUTMSR.&OUTFILE_MEAS. nway;
 class  FIPST AGECCAT;
 var    TAPQ01 TAPQ03 TAPQ14 TAPQ16;
 output out=NWAY
        SUM(TAPQ01 TAPQ03 TAPQ14 TAPQ16)=TAPQ01 TAPQ03 TAPQ14 TAPQ16;
 run;

 proc   Sort data=NWAY;
 by     FIPST AGECCAT ;
 run;

 * -------------------------------------------------------------- ;
 * --- ADD THE AREA POPULATION DENOMINATORS --------------------- ;
 * -------------------------------------------------------------- ;

 proc   Sort data=NWAY (keep=FIPST) out=FIPST NODUPKEY;
 by     FIPST;
 run;
 
 * -------------------------------------------------------------- ;
 * --- READ STATE LEVEL POPULATIONS ----------------------------- ;
 * -------------------------------------------------------------- ;

 data QIPOP;
    length FIPST $2 AGECCAT 3 POP 8;
    infile POPFILC dlm = '09'x missover;
    input  FIPST AGECCAT POP;
 run;
 
 proc   Summary data=QIPOP nway ;
 class  FIPST AGECCAT;
 var    POP;
 output out=QIPOPSUM sum(POP)=;
 run;

 proc   Sort data=QIPOPSUM;
 by     FIPST AGECCAT;
 run;

 data   QIPOP;
 merge  FIPST(in=X) QIPOPSUM;
 by     FIPST;
 if X;
 run;

 data  nway;
 merge nway QIPOP(keep=FIPST AGECCAT POP);
 by    FIPST AGECCAT;

 if POP = . then
    put 'MISSING POPULATION ' FIPST AGECCAT POP;

 array PPQ{4} PAPQ01 PAPQ03 PAPQ14 PAPQ16;

 do J = 1 to 4;
    PPQ{J} = POP;
 end;

 if AGECCAT in (0) then do;
   TAPQ01 = .; PAPQ01 = .;
   TAPQ03 = .; PAPQ03 = .;
   TAPQ14 = .; PAPQ14 = .;
   TAPQ16 = .; PAPQ16 = .;
 end;

label
 POP    = 'AREA POPULATION                         '
 TAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Numerator)'
 TAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Numerator)'
 TAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Numerator)'
 TAPQ16 = 'PQI 16 Lower-Extremity Amputation Among Patients with Diabetes Rate (Numerator)'
 PAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Denominator)'
 PAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Denominator)'
 PAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Denominator)'
 PAPQ16 = 'PQI 16 Lower-Extremity Amputation Among Patients with Diabetes Rate (Denominator)'
        ;

 drop J _FREQ_ _TYPE_;

 run;

 * -------------------------------------------------------------- ;
 * --- AGGREGATE POPULATION COUNTS BY STRATIFIERS --------------- ;
 * -------------------------------------------------------------- ;

 proc   Summary data=nway ;
 class  FIPST AGECCAT ;
 var    TAPQ01 TAPQ03 TAPQ14 TAPQ16 PAPQ01 PAPQ03 PAPQ14 PAPQ16;
 output out=&OUTFILE_CND. sum=;
 run;

 * -------------------------------------------------------------- ;
 * --- CALCULATE CONDITION-SPECIFIC RATES ----------------------- ;
 * -------------------------------------------------------------- ;
 * --- DISCHARGES WITH MISSING FIPST DATA HAVE BEEN ------------- ;
 * --- EXCLUDED FROM THIS ANALYSIS. ----------------------------- ;
 * -------------------------------------------------------------- ;
 
 data   OUTCND.&OUTFILE_CND. ;
 set    &OUTFILE_CND.(where=(_TYPE_ in (2,3)));

 array  PPQ{4}  PAPQ01 PAPQ03 PAPQ14 PAPQ16 ;
 array  TPQ{4}  TAPQ01 TAPQ03 TAPQ14 TAPQ16 ;
 array  CPQ{4}  CAPQ01 CAPQ03 CAPQ14 CAPQ16 ;

 do J = 1 to 4;
         if TPQ{J} GT 0 AND PPQ{J} GT 0 then CPQ{J} = TPQ{J} / PPQ{J};
    else if                 PPQ{J} GT 0 then CPQ{J} = 0 ;
 end;

 drop J _FREQ_ ;

 label
 CAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Condition)'
 CAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Condition)'
 CAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Condition)'
 CAPQ16 = 'PQI 16 Lower-Extremity Amputation Among Patients with Diabetes Rate (Condition)'
  _TYPE_ = 'Stratification level';

 run;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF AREA CONDITION-SPECIFIC FILE ------- ;
 * -------------------------------------------------------------- ;

 proc Contents data=OUTCND.&OUTFILE_CND. position;
 run;


 proc Means data=OUTCND.&OUTFILE_CND.(where=(_TYPE_ in (2))) n nmiss min max mean sum nolabels;
 title4 "SUMMARY OF AREA-LEVEL RATES";
 run;


 * -------------------------------------------------------------- ;
 * --- PRINT AREA CONDITION-SPECIFIC MEANS FILE ----------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PQ,TEXT);

 proc   print data=OUTCND.&OUTFILE_CND. label SPLIT='*';
 var    FIPST AGECCAT  TAPQ&PQ. PAPQ&PQ. CAPQ&PQ. ;
 label FIPST      = "FIPST"
       AGECCAT    = "AGECCAT"
       TAPQ&PQ.   = "TAPQ&PQ.*(Numerator)"
       PAPQ&PQ.   = "PAPQ&PQ.*(Denominator)"
       CAPQ&PQ.   = "CAPQ&PQ.*(Condition)"
       ;
 format AGECCAT AGECCAT.   
	  TAPQ&PQ. PAPQ&PQ. COMMA13.0
	  CAPQ&PQ. 8.6
        ;
 title4 "Indicator  &PQ.: &TEXT";
 run;

 %MEND PRT;

 %PRT(01,Diabetes Short-Term Complications Admission Rate);
 %PRT(03,Diabetes Short-Term Complications Admission Rate);
 %PRT(14,Uncontrolled Diabetes Admission Rate);
 %PRT(16,Lower-Extremity Amputation Among Patients with Diabetes Rate);
 %END;

 %MEND PRT2;

 %PRT2; 


 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS ----------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXT;

 %IF &TEXTC. = 1  %THEN %DO; 

 data _NULL_;
   set OUTCND.&OUTFILE_CND.;
 file PQTEXTC LRECL=600;
 if _N_=1 then do;

put "FIPST" "," "Age" "," "Type" ","
 "TAPQ01" "," "TAPQ03" "," "TAPQ14" "," "TAPQ16" ","
 "PAPQ01" "," "PAPQ03" "," "PAPQ14" "," "PAPQ16" ","
 "CAPQ01" "," "CAPQ03" "," "CAPQ14" "," "CAPQ16";
 end;
 
 put FIPST $2. "," AGECCAT 3. "," _TYPE_ 2. ","
 (TAPQ01 TAPQ03 TAPQ14 TAPQ16) (7.0 ",")
  ","
 (PAPQ01 PAPQ03 PAPQ14 PAPQ16) (13.2 ",") 
 ","
 (CAPQ01 CAPQ03 CAPQ14 CAPQ16) (12.10 ",")
 ;
 
 run;

 %END;

 %MEND TEXT;

 %TEXT;
