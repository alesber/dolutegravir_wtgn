**********************************************************************************
** Program              : TLD and weight change
** Description          :
** Input                : MEDRX3 vitalpe viral load
** Output               : tldweight
** Population           :
** Author               : Aesber
** Creation Date        : 042820
**********************************************************************************
*update Nov 4, adding in pregnancy status and CD4 nadir based on reviewer comments
**********************************************************************************;
libname africos "S:\DCAC\AFRICOS\Data\QuarterlyReport\2022_0207_2021_1201";
OPTIONS nofmterr;
libname fmtlib "C:\Users\AEsber\Box Sync\DCAC data files\Formats";   
OPTIONS FMTSEARCH = ( Fmtlib.Formats);


data art; set AFRICOS.arvcode0;
if arv_code="J55" OR arv_code="J12" or medication="19" then dolutegravir=1;
if arv_code="J56" then efavirenz=1;
hivstat=1;
run; 
data dolutegravir; set art;
where dolutegravir=1;
run;
proc freq data=dolutegravir;
tables dolutegravir;
run;

proc sort data=dolutegravir out=dolsing nodupkey;
by subjid;
run; 

proc freq data=dolsing;
tables dolutegravir;
run;

data vl_;
set africos.v_load0;
rename drawper=drawper_vl;
where drawper=1;
keep subjid visitdt visit drawper vl_circ vlcopy vl hivflag;
run;

proc sort data=vl_ out=vl_nodups dupout=dups nodupkey;
by subjid visit vlcopy;
run;

proc sort data=vl_nodups out=nodups2 dupout=dups2 nodupkey;
by subjid visit;
run;

data vl;
set vl_nodups;
if subjid="B01-0033" and visit=7 and vlcopy=. then delete;
if subjid="B02-0230" and visit=7 and vlcopy=40 then delete;
if subjid="B03-0051" and visit=6 and vlcopy=. then delete;
run;

proc sort data=vl out=nodups3 dupout=dups3 nodupkey;
by subjid visit;
run;

proc sort data=AFRICOS.vital_pe0 out=vitl dupout=vitdups nodupkey;
by subjid visit;
run; 
data vitl; set vitl;
keep subjid visit visitdt hivflag progid bmi wt ht consendt mua WAIST hip; 
run;
data hivstat; set AFRICOS.HIVstat0;
keep subjid visit visitdt dur_art gender progid art_sdtn dobdtn dur_hiv age;
run; 

data lymph_;
set africos.lymph0;
rename drawper=drawper_cd4;
where drawper=1;
keep  subjid visitdt visit drawper CD3_4_N;
if subjid="E01-0007" and visit=11 and CD3_4_N=. then delete;
if subjid="E01-0011" and visit=11 and CD3_4_N=. then delete;
if subjid="E01-0019" and visit=12 and CD3_4_N=. then delete;
if subjid="E01-0023" and visit=8 and CD3_4_N=. then delete;
if subjid="E01-0024" and visit=8 and CD3_4_N=. then delete;
if subjid="E01-0025" and visit=12 and CD3_4_N=. then delete;
if subjid="E01-0027" and visit=8 and CD3_4_N=. then delete;
if subjid="E01-0032" and visit=8 and CD3_4_N=. then delete;
if subjid="E01-0032" and visit=12 and CD3_4_N=. then delete;
if subjid="E01-0033" and visit=8 and CD3_4_N=. then delete;
if subjid="E01-0034" and visit=8 and CD3_4_N=. then delete;
if subjid="E01-0048" and visit=8 and CD3_4_N=. then delete;
if subjid="E01-0062" and visit=7 and CD3_4_N=. then delete;
if subjid="E01-0063" and visit=7 and CD3_4_N=. then delete;
if subjid="E01-0066" and visit=7 and CD3_4_N=. then delete;
if subjid="E01-0075" and visit=7 and CD3_4_N=. then delete;
if subjid="E01-0077" and visit=7 and CD3_4_N=. then delete;
if subjid="E01-0096" and visit=7 and CD3_4_N=. then delete;
if subjid="E01-0098" and visit=6 and CD3_4_N=. then delete;
if subjid="E01-0103" and visit=6 and CD3_4_N=. then delete;
if subjid="E01-0120" and visit=5 and CD3_4_N=. then delete;
if subjid="E01-0124" and visit=5 and CD3_4_N=. then delete;
if subjid="E01-0128" and visit=5 and CD3_4_N=. then delete;
if subjid="E01-0136" and visit=5 and CD3_4_N=. then delete;
if subjid="E01-0142" and visit=5 and CD3_4_N=. then delete;
if subjid="E01-0146" and visit=1 and CD3_4_N=. then delete;
if subjid="E01-0147" and visit=1 and CD3_4_N=. then delete;
if subjid="E01-0148" and visit=1 and CD3_4_N=. then delete;
run;

proc sort data=lymph_ out=lymph dupout=dupout nodupkey;
by subjid visit;
run;
data women; set AFRICOS.women0;
keep subjid visit visitdt currpreg;
run;

*filling in nadir cd4 with lowest cd4 on record;
data extract; set AFRICOS.extract0; 
keep subjid visit WHOSTG function hivflag CD4NADIR;
run; 
proc sort data=AFRICOS.extra_vl0;
by subjid vlcd4;
run; 
proc sort data=AFRICOS.extra_vl0 out=cd4 nodupkey;
by subjid;
run;
data cd4; set cd4;
where vlcd4 ne .;
keep subjid vlcd4 visit;
run;


data cd4c; set AFRICOS.lymph0;
keep subjid visit cd3_4_n; 
where cd3_4_n ne .;
run;
proc sort data=cd4c out=cd42c nodupkey;
by subjid cd3_4_n;
run; 

data cd4nadir; merge extract cd42c;
by subjid;
if cd4nadir=. then cd4nadir=vlcd4;
if (cd4nadir=. AND vlcd4=.) then cd4nadir=cd3_4_n;
if cd4nadir=B then cd4nadir=cd3_4_n;
run; 
proc sort data=cd4nadir;
where hivflag=1;
by cd4nadir;
run;
data cd4nadir; set cd4nadir;
keep subjid cd4nadir cd4nsub;
cd4nsub=cd3_4_n;
run; 
proc sort data=cd4nadir;
by subjid;
run; 
data hivstat; merge hivstat cd4nadir;
by subjid;
run;
data bmibase; set vitl;
where visit=1;
bmibase=bmi;
keep subjid visit bmibase;
run; 
data tldwt; merge art vitl vl bmibase women hivstat lymph; 
by subjid visit;
run; 
 ***export TLDWT TO STATA FILE; 


***EXTRA CODE*****
*total enrollment numbers;
proc freq data=AFRICOS.hivstat0;
where visit=1;
tables hivflag;
run;
data tldwt; set tldwt;
where hivflag=1;
if dolutegravir=. then dolutegravir=0;
age=(visitdt-dobdtn)/365.25;
if age>40 then age40=1;
else age40=0;
if bmi ge 25 then overweight=1;
else overweight=0;
if bmi=. then overweight=.;
if age=. then age=. & age40=.;
run; 
