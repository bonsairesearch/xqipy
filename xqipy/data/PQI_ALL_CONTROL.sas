* ======================= PROGRAM: PQI_ALL_CONTROL.SAS ======================= ;
*  VERSION: SAS QI v2018 (ICD-10 CM/PCS)
*  RELEASE DATE: JUNE 2018
* =========================================================================== ;
 * The Prevention Quality Indicator (PQI) module of the AHRQ Quality
   Indicators software includes the following programs:
   
   1. PQI_ALL_CONTROL.SAS       Assigns user inputs required by other programs
                                and optional output options.  
                        
   2. PQI_ALL_FORMATS.SAS       Creates SAS format library used by other programs.

   3. PQI_ALL_MEASURES.SAS      Assigns Prevention Quality Indicators to 
                                inpatient records.

   4. PQI_AREA_OBSERVED.SAS     Calculates observed rates for area-level indicators.

   5. PQI_AREA_CONDITION.SAS    Calculates condition-specific rates for prevention
                                quality indicators across stratifiers.

 * The software also requires the following files:
 
    1. discharges.sas7bdat  User supplied discharge level file organized according 
                            to the layout in the software instructions.
                            The file name is up to the user but must be listed below.
                            
    2. PQI_Dx_Px_Macros.SAS Standard processes used by the other SAS programs.
                            The user does not need to open.
                            
    3. 1995-2017_Population_Files_V2018.txt  Population file with counts by area, age, and sex.
                            Required for area rate calculation. Available as a 
                            separate download from the AHRQ website.

    4. POP_CONDST_SAS2018.txt   Text file with diabetes populations, stratified by State 
                            and age categories for PQI Area Condition calculation. 

***************************************************************************** ;
******************************* PLEASE READ ********************************* ;
***************************************************************************** ;
 * The AHRQ Quality Indicator software is intended for use with discharges
   coded according to the standards in place at the date of the discharge. 
   Discharges should be classified under the ICD-10-CM/PCS specifications 
   effective 10/1/2015. Although results can be generated with inputs coded 
   under ICD9 and converted to ICD10 with General Equivalence Mappings, the 
   mapping process may produce unrepresentative results. ICD10 observed rate 
   calculations should not be used to produce ICD9 risk adjusted outputs.
   
 * The USER MUST modify portions of the following code in order to
   run this software.  With one exception (see NOTE immediately
   following this paragraph), the only changes necessary to run
   this software are changes in this program (PQI_ALL_CONTROL.SAS). 
   The modifications include such items as specifying the name and location
   of the input data set, the year of population data to be used, and the 
   name and location of output data sets.
 
 * NOTE:  PQI_ALL_CONTROL.SAS provides the option to read data in and write 
          data out to different locations.  For example, "libname INMSR" points
          to the location of the input data set for the PQI_ALL_MEASURES program
          and "libname OUTMSR" points to the location of the output data set
          created by the PQI_ALL_MEASURES program.  The location and file name of 
          each input and output can be assigned separately below. The default 
          values will place output in a SASData folder with standard names for
          each file based on the location of the PQI folder listed in the 
          PATHNAME variable.
          
 * NOTE:  In the other programs included with this package there is a 
          line of code that begins with "filename CONTROL".  
          The USER MUST include after "filename CONTROL" the location
          of the PQI_ALL_CONTROL.SAS file.

 Generally speaking, a first-time user of this software would proceed 
 as outlined below:

    1.  Modify and save PQI_ALL_CONTROL.SAS. (This program - MUST be done.)
    2.  Open PQI_ALL_FORMATS.SAS and specify location (path name) of
        PQI_ALL_CONTROL.SAS. (MUST be done.)
    3.  Run PQI_ALL_FORMATS.SAS. (MUST be done.) 
    4.  Open PQI_ALL_MEASURES.SAS and specify location of PQI_ALL_CONTROL.SAS
        program. (MUST be done.)
    5.  Run PQI_ALL_MEASURES.SAS. (MUST be done.)
    6.  To calculate observed rates for Area Prevention 
        Quality Indicators:
         a.  Open PQI_AREA_OBSERVED.SAS and specify location
             of PQI_ALL_CONTROL.SAS program. (MUST be done.) 
         b.  Run PQI_AREA_OBSERVED.SAS. (MUST have run PQI_ALL_MEASURES.SAS.)
         c.  Open PQI_AREA_CONDITION.SAS and specify location
             of PQI_ALL_CONTROL.SAS program.  (MUST be done.) 
         d.  Run PQI_AREA_CONDITION.SAS.  (MUST have run PQI_ALL_MEASURES.SAS.)

 * ---------------------------------------------------------------- ;
 * ---                       ALL PROGRAMS                       --- ;
 * ---------------------------------------------------------------- ;

*PATHNAME specifies the location of the PQI folder which includes the
          Programs, Macros, and SASdata subfolders;
%LET PATHNAME=C:\pathname\PQI;                           *<===USER MUST modify;
*DISFOLDER specifies the folder that contains the discharge data;
%LET DISFOLDER=c:\pathname;                              *<===USER MUST modify;
*DISCHARGE specifies the name of the discharge data file;
%LET DISCHARGE= discharges;                              *<===USER MUST modify;
*SUFX specifies an identifier suffix to be placed on output datasets;
%LET SUFX = SAS18_ICD10;                                    *<===USER MUST modify;

*LIBRARY is where formats generated by PQI_ALL_FORMATS will be saved.;
libname LIBRARY  "&PATHNAME.\SASData";                    *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF COUNTY-LEVEL AREAS SHOULD BE CONVERTED TO      -- ;
 * --- METROPOLITAIN AREAS                                          -- ;
 * ---     0 - County level with U.S. Census FIPS                -- ;
 * ---     1 - County level with Modified FIPS                   -- ;
 * ---     2 - Metro Area level with OMB 1999 definition         -- ;
 * ---     3 - Metro Area level with OMB 2003 definition         -- ;
 * ---------------------------------------------------------------- ;
%LET MALEVL = 0;                                *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * NOTE:  SELECT THE POPULATION DATA FOR THE YEAR THAT BEST MATCHES ;
 *        THE DISCHARGE DATA. POPYEAR WILL IDENTIFY POPULATION USED ;
 *          BY THE PQI_AREA_OBSERVED PROGRAM.                         ;
 * ---------------------------------------------------------------- ;
%LET POPYEAR = 2017;                            *<===USER may modify;
 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF POPULATION FILE                          --- ;
 * ---------------------------------------------------------------- ;
filename POPFILE  "&PATHNAME.\1995-2017_Population_Files_V2018.txt"; *<===USER may modify;
 * ---------------------------------------------------------------- ;
 * --- INDICATE IF RECORDS SHOULD BE PRINTED AS SAS OUTPUT AT   --- ;
 * --- END OF EACH PROGRAM.  0 = NO, 1 = YES                    --- ;
 * ---------------------------------------------------------------- ;
%LET PRINT = 0;                                 *<===USER may modify;
  * --------------------------------------------------------------- ;
 * --- ADD OPTIONS TO COMPRESS OUTPUT AND SUPPRESS SOURCE CODE  --- ;
 * --- IN LOG. RECOMMENDED WITH LARGE FILES. TO RESTORE, RUN:   --- ;
 * --- options source compress = no                             --- ;
 * ---------------------------------------------------------------- ;
options compress = YES ;                        *<===USER may modify;
 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF SAS MACRO LIBRARY                        --- ;
 * ---------------------------------------------------------------- ;
filename MacLib "&PATHNAME.\Macros\" ;          *<===USER may modify;
 * ---------------------------------------------------------------- ;
 * ---              PROGRAM : PQI_ALL_MEASURES.SAS              --- ;
 * ---------------------------------------------------------------- ;
 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF PQI_ALL_MEASURES INPUT DATA              --- ;
 * ---------------------------------------------------------------- ;
libname INMSR  "&DISFOLDER.";                    *<==USER may modify;
 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF PQI_ALL_MEASURES OUTPUT DATA             --- ;
 * ---------------------------------------------------------------- ;
libname OUTMSR "&PATHNAME.\SASdata";             *<==USER may modify;
 * --- SET NAME OF OUTPUT FILE FROM PQI_ALL_MEASURES            --- ;
%LET OUTFILE_MEAS = PQMSR_&SUFX.; *<===USER may modify;
 * ---------------------------------------------------------------- ;
 * --- MODIFY INPUT AND OUTPUT FILE                             --- ;
 * ---------------------------------------------------------------- ;
 * --- PROGRAM DEFAULT ASSUMES THERE ARE                        --- ;
 * ---     35 DIAGNOSES (DX1-DX35)                              --- ;
 * ---     30 PROCEDURES (PR1-PR30)                             --- ;
 * ---------------------------------------------------------------- ;
 * --- MODIFY NUMBER OF DIAGNOSIS AND PROCEDURE VARIABLES TO    --- ;
 * --- MATCH USER DISCHARGE INPUT DATA                          --- ;
 * ---------------------------------------------------------------- ;
%LET NDX = 35;                                  *<===USER MUST modify;
%LET NPR = 30;                                  *<===USER MUST modify;
 * ---------------------------------------------------------------- ;
 * --- INDICATE IF DATA AVAILABLE REGARDING NUMBER OF DAYS      --- ;
 * --- FROM ADMISSION TO SECONDARY PROCEDURES                   --- ;
 * --- 0 = PRDAY IS NOT INCLUDED, 1 = PRDAY IS INCLUDED         --- ;
 * ---------------------------------------------------------------- ;
%LET PRDAY  = 1;                                *<===USER may modify; 

* ----------------------------------------------------------------- ;
* --- CREATE PERMANENT SAS DATASET TO STORE RECORDS THAT WILL   --- ;
* --- NOT BE INCLUDED IN CALCULATIONS BECAUSE KEY VARIABLE      --- ;
* --- VALUES ARE MISSING.  THIS DATASET SHOULD BE REVIEWED      --- ;
* --- AFTER RUNNING PQI_ALL_MEASURES.                           --- ;
* ----------------------------------------------------------------- ;
%LET DELFILE  = PQI_DELETED_&SUFX.;             *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * ---        PROGRAM: PQI_AREA_OBSERVED.SAS                    --- ;
 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF AREA OBSERVERED OUTPUT LIBRARY           --- ;
 * ---------------------------------------------------------------- ;
libname OUTAOBS "&PATHNAME.\SASdata";           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- TYPELVLA indicates the levels (or _TYPE_) of             --- ;
 * --- summarization to be kept in the output.                  --- ;
 * ---                                                          --- ;
 * ---  TYPELVLA      stratification                            --- ;
 * ---  --------  -------------------------                     --- ;
 * ---     0      OVERALL                                       --- ;
 * ---     1                           RACE                     --- ;
 * ---     2                     SEX                            --- ;
 * ---     3                     SEX * RACE                     --- ;
 * ---     4               AGE                                  --- ;
 * ---     5               AGE *       RACE                     --- ;
 * ---     6               AGE * SEX                            --- ;
 * ---     7               AGE * SEX * RACE                     --- ;
 * ---     8       AREA                                         --- ;
 * ---     9       AREA  *             RACE                     --- ;
 * ---    10       AREA  *       SEX                            --- ;
 * ---    11       AREA  *       SEX * RACE                     --- ;
 * ---    12       AREA  * AGE                                  --- ;
 * ---    13       AREA  * AGE *       RACE                     --- ;
 * ---    14       AREA  * AGE * SEX                            --- ;
 * ---    15       AREA  * AGE * SEX * RACE                     --- ;
 * ---                                                          --- ;
 * --- The default TYPELVLA (0,8) will provide an overall       --- :
 * --- total and an area-level total.                           --- ;
 * ---------------------------------------------------------------- ;
%LET TYPELVLA = IN (0,8);             *<===USER may modify;

 * ----------------------------------------------------------------- ;
 * --- NAME OF SAS DATASET OUTPUT FROM PROGRAM PQI_AREA_OBSERVED --- ;
 * ----------------------------------------------------------------- ;
%LET  OUTFILE_AREAOBS = PQAO_&SUFX.;     *<===USER may modify;

 * ----------------------------------------------------------------- ;
 * --- INDICATE IF A COMMA-DELIMITED FILE SHOULD BE GENERATED    --- ;
 * --- FOR EXPORT INTO A SPREADSHEET. 0 = NO, 1 = YES.           --- ;
 * ----------------------------------------------------------------- ;
%LET TXTAOBS=0;                                 *<===USER may modify;

 * ----------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE          -- ;
 * --- LOCATION OF THE FILE.                                      -- ;
 * ----------------------------------------------------------------- ;
filename PQTXTAOB "&PATHNAME.\SASdata\PQAO_&SUFX..TXT"; *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * ---        PROGRAM: PQI_AREA_CONDITION.SAS                   --- ;
 * ---------------------------------------------------------------- ;
libname OUTCND "&PATHNAME.\SASdata";           *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- NAME OF SAS DATASET OUTPUT FROM PROGRAM PQI_AREA_CONDITION - ;
 * ---------------------------------------------------------------- ;
%LET OUTFILE_CND = PQAC_&SUFX.; *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF CONDITION POPULATION FILE ---------------------- ;
 * ---------------------------------------------------------------- ;
filename POPFILC "&PATHNAME.\ParmFiles\POP_CONDST_SAS2018.txt"; *<===USER must modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF YOU WANT TO CREATE A COMMA-DELIMITED FILE    --- ;
 * --- FOR EXPORT INTO A SPREADSHEET.                           --- ;
 * ---------------------------------------------------------------- ;
%LET TEXTC=0;                                   *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE          --- ;
 * --- LOCATION OF THE FILE.                                    --- ;
 * ---------------------------------------------------------------- ;
filename PQTEXTC "&PATHNAME.\SASdata\PQAC_&SUFX..TXT"; *<===USER may modify;

************************* END USER INPUT ************************** ;
