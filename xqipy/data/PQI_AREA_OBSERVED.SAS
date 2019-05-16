* ===================== PROGRAM: PQI_AREA_OBSERVED.SAS ===================== ;
*
*  TITLE: AREA LEVEL OBSERVED RATES FOR AHRQ PREVENTION QUALITY INDICATORS 
*          
*  DESCRIPTION:
*         Uses proc summary to calculate observed rates for
*         prevention quality indicators across stratifiers.
*         output stratified by area, agecat, sexcat and racecat from 
*         population file and PQI_ALL_MEASURES.sas output.
*         variables created by this program are PAPQxx and OAPQxx.
*
*  VERSION: SAS QI v2018 (ICD-10 CM/PCS)
*  RELEASE DATE: JUNE 2018
*============================================================================ ;

*PATHNAME specifies the location of the PQI folder which includes 
          Programs, SASdata, and Macros subfolders;
%LET PATHNAME=Z:\HDD Working\SAS2018Public\PQI;                   *<===USER MUST modify;

filename CONTROL "&PATHNAME.\Programs\PQI_ALL_CONTROL.SAS"; 
%INCLUDE CONTROL;

/*MACRO TO ADJUST AREA AGGREGATION BASED ON MAREA VALUE IN PQI_ALL_CONTROL.*/

 %MACRO CTY2MA;
    %IF &MALEVL EQ 0 %THEN %DO;
        attrib MAREA length=$5
          label='FIPS STATE COUNTY CODE';
        MAREA = FIPSTCO;
    %END;
    %ELSE %IF &MALEVL EQ 1 %THEN %DO;
        attrib MAREA length=$5
          label='MODIFIED FIPS';
        MAREA = input(PUT(FIPSTCO,$M1AREA.),$5.);
    %END;
    %ELSE %IF &MALEVL EQ 2 %THEN %DO;
        attrib MAREA length=$5
          label='OMB 1999 METRO AREA';
        MAREA = input(PUT(FIPSTCO,$M2AREA.),$5.);
    %END;
    %ELSE %IF &MALEVL EQ 3 %THEN %DO;
        attrib MAREA length=$5
          label='OMB 2003 METRO AREA';
        MAREA = input(PUT(FIPSTCO,$M3AREA.),$5.);
    %END;
 %MEND;

 title2 'PROGRAM PQI_AREA_OBSERVED PART I';
 title3 'AHRQ PREVENTION QUALITY INDICATORS: CALCULATE ADJUSTED AREA RATES';

 * ---------------------------------------------------------------- ;
 * --- ADD POPULATION DENOMINATOR                               --- ;
 * --- THIS STEP DETERMINES WHICH AREAS ARE INCLUDED IN THE     --- ;
 * --- OUTPUT BASED ON AREAS IN PQI_ALL_MEASURES OUTPUT.        --- ;
 * ---------------------------------------------------------------- ;

 data   TEMP0 (keep=MAREA);
 set    OUTMSR.&OUTFILE_MEAS.;

 %CTY2MA

 run;
/* IDENTIFY UNIQUE MAREA VALUES IN PQI_ALL_MEASURES OUTPUT. */
 proc  Sort data=TEMP0 out=MAREA nodupkey;
 by    MAREA;
 run;
 
/* LOAD POPULATION FOR MAREA LEVEL AND YEAR IN PQI_ALL_CONTROL. */
 data QIPOP0;
    length FIPSTCO $5 SEXCAT POPCAT AGECAT RACECAT 3 
           POP_1995 POP_1996 POP_1997 POP_1998 POP_1999
           POP_2000 POP_2001 POP_2002 POP_2003 POP_2004
           POP_2005 POP_2006 POP_2007 POP_2008 POP_2009 
           POP_2010 POP_2011 POP_2012 POP_2013 POP_2014
           POP_2015 POP_2016 POP_2017 POP 8;

    infile POPFILE missover FIRSTOBS=2;

   input FIPSTCO SEXCAT POPCAT RACECAT 
          POP_1995 POP_1996 POP_1997 POP_1998 POP_1999
          POP_2000 POP_2001 POP_2002 POP_2003 POP_2004
          POP_2005 POP_2006 POP_2007 POP_2008 POP_2009
          POP_2010 POP_2011 POP_2012 POP_2013 POP_2014
          POP_2015 POP_2016 POP_2017;

    %CTY2MA

    if POPCAT in (1,2,3,4)            then AGECAT = 0;
    else if POPCAT in (5,6,7,8)       then AGECAT = 1;
    else if POPCAT in (9,10,11,12,13) then AGECAT = 2;
    else if POPCAT in (14,15)         then AGECAT = 3;
    else                                   AGECAT = 4;

    POP = POP_&POPYEAR.;

 run;

 proc   Summary data=QIPOP0 nway;
 class  MAREA POPCAT AGECAT SEXCAT RACECAT;
 var    POP;
 output out=QIPOP sum=;
 run;

 proc   Sort data=QIPOP;
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;
 run;
/* LIMIT POPULATION TOTALS TO MAREA CODES FOUND IN PQI_ALL_MEASURES OUTPUT. */
 data   QIPOP(keep=MAREA POPCAT AGECAT SEXCAT RACECAT POP);
 merge  MAREA(in=X) QIPOP(in=Y);
 by     MAREA;

 if X and Y;

 run;

 * -------------------------------------------------------------- ;
 * --- PREVENTION QUALITY INDICATORS ADJUSTED RATES ------------- ;
 * -------------------------------------------------------------- ;
 * AREA-LEVEL INDICATOR DENOMINATORS ARE ADJUSTED BASED ON THE    *
 * COMBINATION OF COUNTY, AGE, SEX, AND RACE IN THE NUMERATOR.    *
 * THE MOD3 MACRO ITERATES THROUGH EACH MEASURE IN THE            *
 * PQI_ALL_MEASURES OUTPUT AND REDUCES THE AREA POPULATION BY THE *
 * NUMERATOR TOTAL. THE AREA POPULATION TOTALS ARE THEN ADJUSTED  *
 * BASED ON THE MEASURE RELEVANT POPULATION. ONLY VALID AREA      *
 * CODES ARE RETURNED. THE MOD3 MACRO INPUTS ARE:                 *
 * --- N -  AREA MEASURE NUMBER                               --- *
 * --- PQ - THE PREVENTION QUALITY INDICATOR NAME WITHOUT THE --- *
 *          PREFIX (A)                                        --- ;
 * --- DL - INDICATE IF POPULATION IS NOT ADJUSTED (PQ02)     --- ;
 * -------------------------------------------------------------- ;

 %MACRO MOD3(N,PQ,DL);

 /* CREATE TEMPORARY TABLE WITH ALL DISCHARGES IN NUMERATOR FOR MEASURE N. */ 

 %IF &DL. = 0 %THEN %DO;

 data   TEMP_2;
 set    OUTMSR.&OUTFILE_MEAS.(keep=KEY FIPSTCO T&PQ. POPCAT AGECAT SEXCAT RACECAT);

 if T&PQ. in (1);

 %CTY2MA

 run;
/* SUM THE NUMERATOR 'T' FLAGS BY MAREA POPCAT AGECAT SEXCAT RACECAT. */
 proc   Summary data=TEMP_2 NWAY;
 class  MAREA POPCAT AGECAT SEXCAT RACECAT;
 var    T&PQ.;
 output out=TEMP_3 N=TCOUNT;
 run;

 proc   Sort data=TEMP_3;
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;
 run;

 /* REDUCE THE DENOMINATOR POPULATION BY THE SUM OF THE NUMERATOR COUNT. */

 data   TEMP_4(DROP=TCOUNT);
 merge  QIPOP(in=X keep=MAREA POPCAT AGECAT SEXCAT RACECAT POP) 
        TEMP_3(keep=MAREA POPCAT AGECAT SEXCAT RACECAT TCOUNT);
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;

 if X;

 if TCOUNT > 0 then PCOUNT = POP - TCOUNT;
 else PCOUNT = POP;

 if PCOUNT < 0 then PCOUNT = 0;

 if AGECAT in (0) then PCOUNT = 0;

 N = &N.;

 if N in (5) and AGECAT in (1) then PCOUNT = 0;
 if N in (15) and AGECAT in (2,3,4) then PCOUNT = 0;


 if PCOUNT = 0 then delete;

 run;

 /* FOR NUMERATOR, RETAIN ONLY RECORDS WITH A VALID MAREA CODE. */

 data   TEMP_3(DROP=POP);
 merge  TEMP_3(in=X keep=MAREA POPCAT AGECAT SEXCAT RACECAT TCOUNT)
        QIPOP(keep=MAREA POPCAT AGECAT SEXCAT RACECAT POP);
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;

 if X;

 if POP < 0 then PCOUNT = 0;
 else if TCOUNT > 0 then PCOUNT = TCOUNT;
 else PCOUNT = 0;

 if PCOUNT = 0 then delete;

 run;

 /* COMBINE THE NUMERATOR AND DENOMINATOR */

 data   TEMP1;
 set    TEMP_3(in=X) TEMP_4;

 if X then T&PQ. = 1;
 else T&PQ. = 0;

 run;

 %END;
 %ELSE %DO;

 data   TEMP_2;
 set    OUTMSR.&OUTFILE_MEAS.(keep=KEY FIPSTCO T&PQ. POPCAT AGECAT SEXCAT RACECAT);

 if T&PQ. in (0,1);

 %CTY2MA

 run;

 proc   Summary data=TEMP_2 NWAY;
 class  T&PQ. MAREA POPCAT AGECAT SEXCAT RACECAT;
 var    T&PQ.;
 output out=TEMP_3 N=TCOUNT;
 run;

 proc   Sort data=TEMP_3;
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;
 run;

 /* RETAIN ONLY RECORDS WITH A VALID MAREA CODE */;

 data   TEMP1;
 merge  TEMP_3(in=X keep=MAREA POPCAT AGECAT SEXCAT RACECAT TCOUNT T&PQ.)
        QIPOP(keep=MAREA POPCAT AGECAT SEXCAT RACECAT POP);
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;

 if X;

 if POP < 0 then PCOUNT = 0;
 else if TCOUNT > 0 then PCOUNT = TCOUNT;
 else PCOUNT = 0;

 N = &N.;

 if N in (2) and AGECAT in (0) then PCOUNT = 0;
 if N in (9) and AGECAT in (1,2,3,4) then PCOUNT = 0;

 if PCOUNT = 0 then delete;

 run;

 %END;


 data TEMP1Y;
   set TEMP1;
   ONE = 1;
 run;

 
 * ------------------------------------------------------------------ ;
 * --- AGGREGATE POPULATION COUNTS BY STRATIFIERS                 --- ;
 * --- ADJUSTED POPULATION OUTPUT AFTER ELIMINATING AREAS         --- ;  
 * --- WITHOUT A MEASURE DISCHARGE AND LIMITING TO MEASURE        --- ;
 * --- RELEVANT SUB-GROUPS.                                       --- ;
 * ------------------------------------------------------------------ ;

 proc   Summary data=TEMP1Y;
 class  MAREA AGECAT SEXCAT RACECAT;
 var    T&PQ. ONE;
 output out=ADJ_&PQ. sum(T&PQ. ONE)=T&PQ. P&PQ.;
 WEIGHT PCOUNT;
 run;

 data ADJ_&PQ.;
    set ADJ_&PQ.;
    if _TYPE_ &TYPELVLA;
    keep MAREA AGECAT SEXCAT RACECAT T&PQ. P&PQ. _TYPE_;
 run;

 proc Sort data=ADJ_&PQ.;
   by MAREA AGECAT SEXCAT RACECAT;
 run; quit;

 proc   Datasets nolist;
 delete TEMP1 TEMP1Y TEMP_2 TEMP_3 TEMP_4;
 run;

 %MEND;

 %MOD3(1,APQ01,0);
 %MOD3(2,APQ02,1);
 %MOD3(3,APQ03,0);
 %MOD3(5,APQ05,0);
 %MOD3(7,APQ07,0);
 %MOD3(8,APQ08,0);
 %MOD3(10,APQ10,0);
 %MOD3(11,APQ11,0);
 %MOD3(12,APQ12,0);
 %MOD3(14,APQ14,0);
 %MOD3(15,APQ15,0);
 %MOD3(16,APQ16,0);
 %MOD3(90,APQ90,0);
 %MOD3(91,APQ91,0);
 %MOD3(92,APQ92,0);
 %MOD3(93,APQ93,0);

* --- MERGE THE ADJUSTED DENOMINATOR AND NUMERATOR FOR AREA PREVENTION QUALITY INDICATORS. --- ;

* --------------------------------------------------------------- ;
* --- PREVENTION QUALITY INDICATOR (PQI) NAMING CONVENTION:   --- ;
* --- THE FIRST LETTER IDENTIFIES THE PREVENTION QUALITY      --- ;
* --- INDICATOR AS ONE OF THE FOLLOWING:
                (T) NUMERATOR ("TOP") - FROM PDI_ALL_MEASURES
                (P) POPULATION ("POP")
                (A) ADJUSTED POPULATION
                (O) OBSERVED RATES
* --- THE SECOND LETTER IDENTIFIES THE PQI AS A PROVIDER (P)  --- ;
* --- OR AN AREA (A) LEVEL INDICATOR. THE NEXT TWO            --- ;
* --- CHARACTERS ARE ALWAYS 'PQ'. THE LAST TWO DIGITS ARE THE --- ;
* --- INDICATOR NUMBER (WITHIN THAT SUBTYPE).                 --- ;
* --------------------------------------------------------------- ;
data TEMP2Y;
  merge ADJ_APQ01 ADJ_APQ02 ADJ_APQ03 ADJ_APQ05 ADJ_APQ07 ADJ_APQ08 ADJ_APQ10 
        ADJ_APQ11 ADJ_APQ12 ADJ_APQ14 ADJ_APQ15 ADJ_APQ16 ADJ_APQ90 
        ADJ_APQ91 ADJ_APQ92 ADJ_APQ93;
  by MAREA AGECAT SEXCAT RACECAT;

run;
/* CALCULATE OBSERVED RATE AS SUM OF NUMERATOR / SUM OF ADJUSTED DENOMINATOR.*/
data &OUTFILE_AREAOBS.;
 set TEMP2Y;

 ARRAY PPQ2{16} PAPQ01-PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ10-PAPQ12 PAPQ14-PAPQ16 
                PAPQ90-PAPQ93;
 ARRAY TPQ{16} TAPQ01-TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ10-TAPQ12 TAPQ14-TAPQ16
               TAPQ90-TAPQ93;
 ARRAY OPQ{16} OAPQ01-OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ10-OAPQ12 OAPQ14-OAPQ16 
               OAPQ90-OAPQ93;

 do J = 1 to 16;
    if TPQ{J} GT 0 and PPQ2{J} GT 0 then OPQ{J} = TPQ{J} / PPQ2{J};
    else if PPQ2{J} GT 0 then OPQ{J} = 0 ;
 end;

 label
 TAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Numerator)'
 TAPQ02 = 'PQI 02 Perforated Appendix Admission Rate (Numerator)'
 TAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Numerator)'
 TAPQ05 = 'PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate (Numerator)'
 TAPQ07 = 'PQI 07 Hypertension Admission Rate (Numerator)'
 TAPQ08 = 'PQI 08 Heart Failure Admission Rate (Numerator)'
 TAPQ10 = 'PQI 10 Dehydration Admission Rate (Numerator)'
 TAPQ11 = 'PQI 11 Community-Acquired Pneumonia Admission Rate (Numerator)'
 TAPQ12 = 'PQI 12 Urinary Tract Infection Admission Rate (Numerator)'
 TAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Numerator)'
 TAPQ15 = 'PQI 15 Asthma in Younger Adults Admission Rate (Numerator)'
 TAPQ16 = 'PQI 16 Lower-Extremity Amputation Among Patients with Diabetes Rate (Numerator)'
 TAPQ90 = 'PQI 90 Prevention Quality Overall Composite (Numerator)'
 TAPQ91 = 'PQI 91 Prevention Quality Acute Composite (Numerator)'
 TAPQ92 = 'PQI 92 Prevention Quality Chronic Composite (Numerator)'
 TAPQ93 = 'PQI 93 Prevention Quality Diabetes Composite (Numerator)'
 ;
 label
 PAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Denominator)'
 PAPQ02 = 'PQI 02 Perforated Appendix Admission Rate (Denominator)'
 PAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Denominator)'
 PAPQ05 = 'PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate (Denominator)'
 PAPQ07 = 'PQI 07 Hypertension Admission Rate (Denominator)'
 PAPQ08 = 'PQI 08 Heart Failure Admission Rate (Denominator)'
 PAPQ10 = 'PQI 10 Dehydration Admission Rate (Denominator)'
 PAPQ11 = 'PQI 11 Community-Acquired Pneumonia Admission Rate (Denominator)'
 PAPQ12 = 'PQI 12 Urinary Tract Infection Admission Rate (Denominator)'
 PAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Denominator)'
 PAPQ15 = 'PQI 15 Asthma in Younger Adults Admission Rate (Denominator)'
 PAPQ16 = 'PQI 16 Lower-Extremity Amputation Among Patients with Diabetes Rate (Denominator)'
 PAPQ90 = 'PQI 90 Prevention Quality Overall Composite (Denominator)'
 PAPQ91 = 'PQI 91 Prevention Quality Acute Composite (Denominator)'
 PAPQ92 = 'PQI 92 Prevention Quality Chronic Composite (Denominator)'
 PAPQ93 = 'PQI 93 Prevention Quality Diabetes Composite (Denominator)'
 ;
 label
 OAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Observed)'
 OAPQ02 = 'PQI 02 Perforated Appendix Admission Rate (Observed)'
 OAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Observed)'
 OAPQ05 = 'PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate (Observed)'
 OAPQ07 = 'PQI 07 Hypertension Admission Rate (Observed)'
 OAPQ08 = 'PQI 08 Heart Failure Admission Rate (Observed)'
 OAPQ10 = 'PQI 10 Dehydration Admission Rate (Observed)'
 OAPQ11 = 'PQI 11 Community-Acquired Pneumonia Admission Rate (Observed)'
 OAPQ12 = 'PQI 12 Urinary Tract Infection Admission Rate (Observed)'
 OAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Observed)'
 OAPQ15 = 'PQI 15 Asthma in Younger Adults Admission Rate (Observed)'
 OAPQ16 = 'PQI 16 Lower-Extremity Amputation Among Patients with Diabetes Rate (Observed)'
 OAPQ90 = 'PQI 90 Prevention Quality Overall Composite (Observed)'
 OAPQ91 = 'PQI 91 Prevention Quality Acute Composite (Observed)'
 OAPQ92 = 'PQI 92 Prevention Quality Chronic Composite (Observed)'
 OAPQ93 = 'PQI 93 Prevention Quality Diabetes Composite (Observed)'
 _TYPE_ = 'Stratification level                    '
 ;

 DROP J;

 run;

 proc Sort data=&OUTFILE_AREAOBS. out=OUTAOBS.&OUTFILE_AREAOBS.;
 by MAREA AGECAT SEXCAT RACECAT;
 run;

proc Datasets nolist;
  delete MAREA QIPOP QIPOP0 TEMP0 TEMP2Y
         ADJ_APQ01 ADJ_APQ02 ADJ_APQ03 ADJ_APQ05 ADJ_APQ07 ADJ_APQ08 ADJ_APQ10 
         ADJ_APQ11 ADJ_APQ12 ADJ_APQ14 ADJ_APQ15 ADJ_APQ16 ADJ_APQ90
         ADJ_APQ91 ADJ_APQ92 ADJ_APQ93;
run; quit;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF AREA OBSERVED MEANS FILE ----------- ;
 * -------------------------------------------------------------- ;

 proc CONTENTS data=OUTAOBS.&OUTFILE_AREAOBS. POSITION;
 run;

 *proc Means data=OUTAOBS.&OUTFILE_AREAOBS.(where=(_TYPE_ IN (8))) N NMISS MIN MAX MEAN sum NOLABELS;
 *title4 "SUMMARY OF AREA-LEVEL RATES (_TYPE_=8)";
 *run;

 ***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

proc Means data = OUTAOBS.&OUTFILE_AREAOBS.(where=(_TYPE_ in (8))) n nmiss min max sum nolabels;
     var TAPQ01-TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ10-TAPQ12 TAPQ14-TAPQ16 TAPQ90-TAPQ93;
     title  "PREVENTION QUALITY AREA-LEVEL INDICATOR OVERALL NUMERATOR WHEN _TYPE_ =8 ";
run; quit;

proc Means data = OUTAOBS.&OUTFILE_AREAOBS. (where=(_TYPE_ in (8))) n nmiss min max sum nolabels;
     var PAPQ01-PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ10-PAPQ12 PAPQ14-PAPQ16 PAPQ90-PAPQ93;
     title  "PREVENTION QUALITY AREA-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_ =8";
run; quit;

proc Means data = OUTAOBS.&OUTFILE_AREAOBS. (where=(_TYPE_ in (8))) n nmiss min max mean nolabels;
     var OAPQ01-OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ10-OAPQ12 OAPQ14-OAPQ16 OAPQ90-OAPQ93;
     title  "PREVENTION QUALITY AREA-LEVEL INDICATOR AVERAGE OBSERVED RATE (MEAN) WHEN _TYPE_ =8";
run; quit;

 * -------------------------------------------------------------- ;
 * --- PRINT AREA OBSERVED MEANS FILE --------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PQ,TEXT);

 proc  PRINT data=OUTAOBS.&OUTFILE_AREAOBS. label SPLIT='*';
 var   MAREA AGECAT SEXCAT RACECAT TAPQ&PQ. PAPQ&PQ. OAPQ&PQ. ;
 label MAREA   = "MAREA"
       AGECAT  = "AGECAT"
       SEXCAT  = "SEXCAT"
       RACECAT = "RACECAT"
       TAPQ&PQ.   = "TAPQ&PQ.*(Numerator)"
       PAPQ&PQ.   = "PAPQ&PQ.*(Denominator)"
       OAPQ&PQ.   = "OAPQ&PQ.*(Observed)"
       ;
 FORMAT AGECAT AGECAT.   
        SEXCAT SEXCAT.
        RACECAT RACECAT.
      TAPQ&PQ. PAPQ&PQ. COMMA13.0
      OAPQ&PQ. 8.6
        ;
 title4 "Indicator &PQ.: &TEXT";
 run;

 %MEND PRT;

 %PRT(01,Diabetes Short-Term Complications Admission Rate);
 %PRT(02,Perforated Appendix Admission Rate);
 %PRT(03,Diabetes Long-Term Complications Admission Rate);
 %PRT(05,Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate);
 %PRT(07,Hypertension Admission Rate);
 %PRT(08,Heart Failure Admission Rate);
 %PRT(10,Dehydration Admission Rate);
 %PRT(11,Community-Acquired Pneumonia Admission Rate);
 %PRT(12,Urinary Tract Infection Admission Rate);
 %PRT(14,Uncontrolled Diabetes Admission Rate);
 %PRT(15,Asthma in Younger Adults Admission Rate);
 %PRT(16,Lower-Extremity Amputation Among Patients with Diabetes Rate);
 %PRT(90,Prevention Quality Overall Composite);
 %PRT(91,Prevention Quality Acute Composite);
 %PRT(92,Prevention Quality Chronic Composite);
 %PRT(93,Prevention Quality Diabetes Composite);

 %END;

 %MEND PRT2;

 %PRT2; 

 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS ----------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXT;

 %IF &TXTAOBS. = 1  %THEN %DO;

 data _NULL_;
 set OUTAOBS.&OUTFILE_AREAOBS.;
 file PQTXTAOB lrecl=1000;
 if _N_=1 then do;

  put "MAREA" "," "Age" "," "Sex" "," "Race" "," "Type" ","
 "TAPQ01" "," "TAPQ02" "," "TAPQ03" "," 
 "TAPQ05" "," "TAPQ07" "," "TAPQ08" ","
 "TAPQ10" "," "TAPQ11" "," "TAPQ12" "," 
 "TAPQ14" "," "TAPQ15" "," "TAPQ16" ","
 "TAPQ90" "," "TAPQ91" "," "TAPQ92" "," "TAPQ93" ","
 "PAPQ01" "," "PAPQ02" "," "PAPQ03" "," 
 "PAPQ05" "," "PAPQ07" "," "PAPQ08" ","
 "PAPQ10" "," "PAPQ11" "," "PAPQ12" "," 
 "PAPQ14" "," "PAPQ15" "," "PAPQ16" ","
 "PAPQ90" "," "PAPQ91" "," "PAPQ92" "," "PAPQ93" ","
 "OAPQ01" "," "OAPQ02" "," "OAPQ03" "," 
 "OAPQ05" "," "OAPQ07" "," "OAPQ08" ","
 "OAPQ10" "," "OAPQ11" "," "OAPQ12" "," 
 "OAPQ14" "," "OAPQ15" "," "OAPQ16" ","
 "OAPQ90" "," "OAPQ91" "," "OAPQ92" "," "OAPQ93";
 
 end;

 PUT MAREA $5. "," AGECAT 3. "," SEXCAT 3. "," RACECAT 3. "," _TYPE_ 2. ","
 (TAPQ01-TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ10-TAPQ12 TAPQ14-TAPQ16 TAPQ90-TAPQ93) (7.0 ",")
 ","
 (PAPQ01-PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ10-PAPQ12 PAPQ14-PAPQ16 PAPQ90-PAPQ93) (13.2 ",") 
 ","
 (OAPQ01-OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ10-OAPQ12 OAPQ14-OAPQ16 OAPQ90-OAPQ93) (12.10 ",")
 ;
 run;

 %END;

 %MEND TEXT;

 %TEXT;

