* ====================== PROGRAM: PQI_ALL_MEASURES.SAS ======================;
*
*  DESCRIPTION:
*         Assigns the Prevention Quality Indicator outcome of interest and 
*         stratifier categories to inpatient records. 
*         Variables created by this program are TAPQXX and stratifiers.
*
*  VERSION: SAS QI v2018 (ICD-10 CM/PCS)
*  RELEASE DATE: JUNE 2018
*
*  USER NOTE1: The PQI_FORMATS.SAS program must be run BEFORE
*               running this program.
*
*  USER NOTE2: The AHRQ QI software does not support the calculation of  
*              weighted estimates and standard errors using complex 
*              sampling designs. 
*
* ===========================================================================;

*PATHNAME specifies the location of the PQI  folder which includes 
          Programs, SASdata, and Macros subfolders;
%LET PATHNAME= C:\pathname\PQI;                *<===USER MUST modify;

filename CONTROL "&PATHNAME.\Programs\PQI_ALL_CONTROL.SAS"; 
%INCLUDE CONTROL;

 title2 'PROGRAM PQI_ALL_MEASURES';
 title3 'AHRQ PREVENTION QUALITY INDICATORS: ASSIGN QIS TO INPATIENT DATA';

 * ------------------------------------------------------------------ ;
 * --- CREATE A PERMANENT DATASET CONTAINING ALL RECORDS THAT     --- ; 
 * --- WILL NOT BE INCLUDED IN ANALYSIS BECAUSE KEY VARIABLE      --- ;
 * --- VALUES ARE MISSING. REVIEW AFTER RUNNING PQI_ALL_MEASURES. --- ;
 * ------------------------------------------------------------------ ;

 data   OUTMSR.&DELFILE.
     (keep=KEY HOSPID SEX AGE DX1 MDC YEAR DQTR);
 set     INMSR.&DISCHARGE.;
 if (AGE lt 0) or (AGE lt 18 and  MDC notin (14)) or (SEX le 0) or 
    (DX1 in (' ')) or (DQTR le .Z) or (YEAR le .Z);
 run;

 *--- Load standard diagnosis and procedure macros ---* ;
 %include MacLib (PQI_Dx_Px_Macros.sas);

 * ------------------------------------------------------------------ ;
 * --- PREVENTION QUALITY INDICATOR (PQI) NAMING CONVENTION:      --- ;
 * --- THE FIRST LETTER IDENTIFIES THE PREVENTION QUALITY         --- ;
 * --- INDICATOR AS ONE OF THE FOLLOWING:                         --- ;
 * ---             (T) NUMERATOR ("TOP")                          --- ;
 * --- THE SECOND LETTER REFERS TO THE INDICATOR SUBTYPE, (A)REA. --- ;
 * --- THE NEXT TWO CHARACTERS ARE ALWAYS 'PQ'. THE LAST TWO      --- ;
 * --- DIGITS ARE THE INDICATOR NUMBER (WITHIN THAT SUBTYPE).     --- ;
 * ------------------------------------------------------------------ ;

data OUTMSR.&OUTFILE_MEAS.
                 (keep=KEY FIPST FIPSTCO DRG MDC YEAR DQTR 
                       AGECAT AGECCAT POPCAT SEXCAT RACECAT
                       TAPQ01--TAPQ16 TAPQ90-TAPQ93 );
 set INMSR.&DISCHARGE.
                 (keep=KEY DRG MDC SEX AGE PSTCO 
                       RACE YEAR DQTR PAY1
                       ASOURCE POINTOFORIGINUB04  
                       DX1-DX&NDX. PR1-PR&NPR.);

 * -------------------------------------------------------------------------- ;
 * --- DELETE RECORDS WITH MISSING VALUES FOR AGE, SEX, DX1, DQTR, & YEAR --- ;
 * --- DELETE NON ADULT RECORDS --------------------------------------------- ;
 * -------------------------------------------------------------------------- ;
 if SEX le 0 then delete;
 if AGE lt 0 then delete;
 if AGE lt 18 and  MDC notin (14) then delete;
 if DX1 in (' ') then delete;
 if DQTR le .Z then delete;
 if YEAR le .Z then delete;

 * ---------------------------------------------------------------- ;
 * --- DEFINE MDC ------------------------------------------------- ;
 * ---------------------------------------------------------------- ;
 attrib MDCNEW length=3
   label='RESPECIFIED MDC';

 if MDC notin (01,02,03,04,05,06,07,08,09,10,
               11,12,13,14,15,16,17,18,19,20,
               21,22,23,24,25)
 then do;
    MDCNEW = put(DRG,MDCF2T.);
    if MDCNEW in (01,02,03,04,05,06,07,08,09,10,
                  11,12,13,14,15,16,17,18,19,20,
                  21,22,23,24,25)
    then MDC=MDCNEW;
    else do;
        if DRG in (999) then MDC = 0;
       else put "INVALID MDC KEY: " KEY " MDC " MDC " DRG " DRG ;
    end;
 end;
 

 * ---------------------------------------------------------------- ;
 * --- DEFINE FIPS STATE AND COUNTY CODES ------------------------- ;
 * ---------------------------------------------------------------- ;
 attrib FIPSTCO length=$5
   label='FIPS STATE COUNTY CODE';
 FIPSTCO = put(PSTCO,Z5.);

 attrib FIPST length=$2
   label='STATE FIPS CODE';
 FIPST = substr(FIPSTCO,1,2);

 * --------------------------------------------------------------- ;
 * --- DEFINE ICD-10-CM VERSION ---------------------------------- ;
 * --------------------------------------------------------------- ;
 attrib ICDVER length=3
   label='ICD-10-CM VERSION';

 ICDVER = 0;
 if (YEAR in (2015) and DQTR in (4))          then ICDVER = 33;
 else if (YEAR in (2016) and DQTR in (1,2,3)) then ICDVER = 33;
 else if (YEAR in (2016) and DQTR in (4))     then ICDVER = 34;
 else if (YEAR in (2017) and DQTR in (1,2,3)) then ICDVER = 34;
 else if (YEAR in (2017) and DQTR in (4))     then ICDVER = 35;
 else if (YEAR in (2018) and DQTR in (1,2,3)) then ICDVER = 35;
 else ICDVER = 35; *Defaults to last version for discharges outside coding updates.;
 
 * --------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: PAYER CATEGORY ------------------------- ;
 * --------------------------------------------------------------- ;
 attrib PAYCAT length=3
   label='PATIENT PRIMARY PAYER';

 select (PAY1);
   when (1)  PAYCAT = 1;
   when (2)  PAYCAT = 2;
   when (3)  PAYCAT = 3;
   when (4)  PAYCAT = 4;
   when (5)  PAYCAT = 5;
   otherwise PAYCAT = 6;
 end; 


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: RACE CATEGORY ------------------------- ;
 * -------------------------------------------------------------- ;
 attrib RACECAT length=3
   label='PATIENT RACE/ETHNICITY';

 select (RACE);
   when (1)  RACECAT = 1;
   when (2)  RACECAT = 2;
   when (3)  RACECAT = 3;
   when (4)  RACECAT = 4;
   when (5)  RACECAT = 5;
   otherwise RACECAT = 6;
 end; 


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: AGE CATEGORY -------------------------- ;
 * -------------------------------------------------------------- ;
 attrib AGECAT length=3
   label='PATIENT AGE';

 SELECT;
   when (      AGE < 18)  AGECAT = 0;
   when (18 <= AGE < 40)  AGECAT = 1;
   when (40 <= AGE < 65)  AGECAT = 2;
   when (65 <= AGE < 75)  AGECAT = 3;
   when (75 <= AGE     )  AGECAT = 4;
   otherwise AGECAT = 0;
 end; 


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: CONDITION-SPECIFIC AGE CATEGORY ------- ;
 * -------------------------------------------------------------- ;
 attrib AGECCAT length=3
   label='PATIENT AGE';

 SELECT;
   when (      AGE < 18)  AGECCAT = 0;
   when (18 <= AGE < 45)  AGECCAT = 1;
   when (45 <= AGE < 65)  AGECCAT = 2;
   when (65 <= AGE < 75)  AGECCAT = 3;
   when (75 <= AGE     )  AGECCAT = 4;
   otherwise AGECCAT = 0;
 end; 


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: SEX CATEGORY -------------------------- ;
 * -------------------------------------------------------------- ;
 attrib SEXCAT length=3
   label='PATIENT SEX';

 select (SEX);
   when (1)  SEXCAT = 1;
   when (2)  SEXCAT = 2;
   otherwise SEXCAT = 0;
 end;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: POPULATION CATEGORY ------------------- ;
 * -------------------------------------------------------------- ;
 attrib POPCAT length=3
   label='PATIENT AGE';

 POPCAT=put(AGE,AGEFMT.);


 * -------------------------------------------------------------- ;
 * --- DEFINE AREA LEVEL ACSC INDICATORS ------------------------ ;
 * -------------------------------------------------------------- ;

 length TAPQ01 TAPQ02 TAPQ03 TAPQ05
        TAPQ07 TAPQ08 TAPQ10 TAPQ11 
        TAPQ12 TAPQ14 TAPQ15
        TAPQ16 TAPQ90 TAPQ91 TAPQ92 TAPQ93 8;

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

 * ------------------------------------------------------------------ ;
 * --- PQI 01 : DIABETES SHORT-TERM COMPLICATIONS ADMISSION RATE  --- ;
 * ------------------------------------------------------------------ ;

   if %MDX1($ACDIASD.) then

        TAPQ01 = 1;


 * -------------------------------------------------- ;
 * --- PQI 02 : PERFORATED APPENDIX ADMISSION RATE --- ;
 * -------------------------------------------------- ;

   if %MDX($ACSAP2D.) then do;

      TAPQ02 = 0;

      if %MDX($ACSAPPD.) then TAPQ02 = 1;

      *** Exclude: MDC 14;
      if MDC in (14) then TAPQ02 = .;

   end;


 * ----------------------------------------------------------------- ;
 * --- PQI 03 : DIABETES LONG-TERM COMPLICATIONS ADMISSION RATE  --- ;
 * ----------------------------------------------------------------- ;

   if %MDX1($ACDIALD.) then

        TAPQ03 = 1;


 * ------------------------------------------------------------------------------------------------------ ;
 * --- PQI 05 : CHRONIC OBSTRUCTIVE PULMONARY DISEASE (COPD) OR ASTHMA IN OLDER ADULTS ADMISSION RATE --- ;
 * ------------------------------------------------------------------------------------------------------ ;

   if AGE ge 40 then do;
     if %MDX1($ACCOPDD.) or %MDX1($ACSASTD.) 

        then do;  TAPQ05 = 1;
    
   *** Exclude Cystic Fibrosis and Anomalies 
          of the Respiratory System;

      if %MDX($RESPAN.) then TAPQ05 = .;
     end;

   end;

 * ------------------------------------------------ ;
 * --- PQI 07 : HYPERTENSION ADMISSION RATE     --- ;
 * ------------------------------------------------ ;

   if %MDX1($ACSHYPD.) then do;

        TAPQ07 = 1;

      ***Exclude Stage I-IV Kidney Disease
         with dialysis access procedures;
      if %MDX($ACSHY2D.) and %MPR($DIALY2P.)
      then TAPQ07 = .;

      *** Exclude Cardiac Procedures;
      if %MPR($ACSCARP.) then TAPQ07 = .;

   end;


 * -------------------------------------------------- ;
 * --- PQI 08 : HEART FAILURE ADMISSION RATE      --- ;
 * -------------------------------------------------- ;

   if %MDX1($MRTCHFD.) then do;

      TAPQ08 = 1;

      *** Exclude Cardiac Procedures;
      if %MPR($ACSCARP.) then TAPQ08 = .;

   end;


 * -------------------------------------------------- ;
 * --- PQI 10 : DEHYDRATION ADMISSION RATE        --- ;
 * -------------------------------------------------- ;

   if %MDX1($ACSDEHD.) or  
      (%MDX2($ACSDEHD.) and (%MDX1($HYPERID.) or %MDX1($ACPGASD.) or %MDX1($PHYSIDB.))) 
       then do;       TAPQ10 = 1;

         *** Exclude chronic renal failure ****;
         if %MDX($CRENLFD.) then TAPQ10 = .;

   end;


 * ------------------------------------------------------------ ;
 * --- PQI 11 : COMMUNITY-ACQUIRED PNEUMONIA ADMISSION RATE --- ;
 * ------------------------------------------------------------ ;

   if %MDX1($ACSBACD.) then do;

      TAPQ11 = 1;

      *** Exclude: Sickle Cell;
      if %MDX($ACSBA2D.)  then TAPQ11 = .;

      *** Exclude Immunocompromised state;
      if %MDX($IMMUNID.) or %MPR($IMMUNIP.) 
      then TAPQ11 = .;

   end;
      

 * ------------------------------------------------------- ;
 * --- PQI 12 : URINARY TRACK INFECTION ADMISSION RATE --- ;
 * ------------------------------------------------------- ;

   if  %MDX1($ACSUTID.) then do;

      TAPQ12 = 1;

      *** Exclude Immunocompromised state and 
          Kidney/Urinary Tract Disorder;
      if %MDX($IMMUNID.) or %MPR($IMMUNIP.) or 
         %MDX($KIDNEY.) 
      then TAPQ12 = .;

   end;


 * ----------------------------------------------------- ;
 * --- PQI 14 : UNCONTROLLED DIABETES ADMISSION RATE --- ;
 * ----------------------------------------------------- ;

   if %MDX1($ACDIAUD.) then

      TAPQ14 = 1;


 * ----------------------------------------------------------------- ;
 * --- PQI 15 : ASTHMA IN YOUNGER ADULTS DIABETES ADMISSION RATE --- ;
 * ----------------------------------------------------------------- ;

   if %MDX1($ACSASTD.) then do;

      TAPQ15 = 1;

      *** Exclude Cystic Fibrosis and Anomalies 
          of the Respiratory System;
      if %MDX($RESPAN.) then TAPQ15 = .;

      if AGE ge 40 then TAPQ15 = .;

   end;


 * ----------------------------------------------------------------------------- ;
 * --- PQI 16 : LOWER-EXTREMITY AMPUTATION AMONG PATIENTS WITH DIABETES RATE --- ;
 * ----------------------------------------------------------------------------- ;

   if %MPR($ACSLEAP.) and %MDX($ACSLEAD.) then do;

      TAPQ16 = 1;

      *** Exclude: MDC 14;
      if MDC in (14) then TAPQ16 = .;

      *** Exclude: Trauma;
      if %MDX($ACLEA2D.) then TAPQ16 = .;

   end;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT AREA LEVEL COMPOSITE INDICATORS ---------------- ;
 * -------------------------------------------------------------- ;

 * ----------------------------------------------------- ;
 * --- PQI 90 : PREVENTION QUALITY OVERALL COMPOSITE --- ;
 * ----------------------------------------------------- ;

   if TAPQ01 = 1 or TAPQ03 = 1 or TAPQ05 = 1 or TAPQ07 = 1 or 
      TAPQ08 = 1 or TAPQ10 = 1 or TAPQ11 = 1 or TAPQ12 = 1 or 
      TAPQ14 = 1 or TAPQ15 = 1 or TAPQ16 = 1
   then 
   TAPQ90 = MAX(OF TAPQ01 TAPQ03 TAPQ05 TAPQ07 
                   TAPQ08 TAPQ10 TAPQ11 TAPQ12
                   TAPQ14 TAPQ15 TAPQ16);

 * --------------------------------------------------- ;
 * --- PQI 91 : PREVENTION QUALITY ACUTE COMPOSITE --- ;
 * --------------------------------------------------- ;

   if TAPQ10 = 1 or TAPQ11 = 1 or TAPQ12 = 1 
   then 
   TAPQ91 = MAX(OF TAPQ10 TAPQ11 TAPQ12);

 * ----------------------------------------------------- ;
 * --- PQI 92 : PREVENTION QUALITY CHRONIC COMPOSITE --- ;
 * ----------------------------------------------------- ;

   if TAPQ01 = 1 or TAPQ03 = 1 or TAPQ05 = 1 or TAPQ07 = 1 or 
      TAPQ08 = 1 or TAPQ14 = 1 or TAPQ15 = 1 or 
      TAPQ16 = 1
   then 
   TAPQ92 = MAX(OF TAPQ01 TAPQ03 TAPQ05 TAPQ07 
                   TAPQ08 TAPQ14 TAPQ15
                   TAPQ16);

 * ------------------------------------------------------ ;
 * --- PQI 93 : PREVENTION QUALITY DIABETES COMPOSITE --- ;
 * ------------------------------------------------------ ;

   IF TAPQ01 = 1 OR TAPQ03 = 1 OR TAPQ14 = 1 OR TAPQ16 = 1
   THEN 
   TAPQ93 = MAX(OF TAPQ01 TAPQ03 TAPQ14 TAPQ16);


 * -------------------------------------------------------------- ;
 * --- EXCLUDE TRANSFERS ---------------------------------------- ;
 * -------------------------------------------------------------- ;

 * --- TRANSFER FROM ANOTHER ---------------- ;
 if ASOURCE in (2,3) or POINTOFORIGINUB04 in ('4','5','6')
 then do;
   TAPQ01 = .;
   TAPQ02 = .;
   TAPQ03 = .;
   TAPQ05 = .;
   TAPQ07 = .;
   TAPQ08 = .;
   TAPQ10 = .;
   TAPQ11 = .;
   TAPQ12 = .;
   TAPQ14 = .;
   TAPQ15 = .;
   TAPQ16 = .;
   TAPQ90 = .;
   TAPQ91 = .;
   TAPQ92 = .;
   TAPQ93 = .;
 end;

run;

proc contents DATA=OUTMSR.&OUTFILE_MEAS. position;
run;

***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM proc means STATEMENTS -------***;

proc means data = OUTMSR.&OUTFILE_MEAS. n nmiss min max NOLABELS ;
     var DRG MDC YEAR DQTR 
         AGECAT AGECCAT POPCAT SEXCAT RACECAT;
     title4 "PREVENTION QUALITY INDICATOR CATEGORICAL VARIABLES AND RANGES OF VALUES";
run; quit;

proc means data = OUTMSR.&OUTFILE_MEAS. n nmiss sum mean NOLABELS ;
     var TAPQ01-TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ10-TAPQ12 TAPQ14-TAPQ16 TAPQ90-TAPQ93;
     title5 "PREVENTION QUALITY INDICATOR NUMERATORS (COUNT=SUM)";
run; quit;
