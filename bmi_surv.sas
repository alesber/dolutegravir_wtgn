**********************************************************************************
** Program              : Time to elevated BMI
** Description          : See above
** Input                : HIVSTAT0 Vital Lymph0  extract arvcode womens
** Output               : bmi_surv
** Population           : all
** Author               : Aesber
** Creation Date        : 14mar22
**********************************************************************************

**********************************************************************************;
**********************************************************************************;
libname africos 'S:\DCAC\AFRICOS\Data\QuarterlyReport\2021_0103_20201201';
OPTIONS nofmterr;
libname fmtlib "C:\Users\AEsber\Box Sync\DCAC data files\Formats";   
OPTIONS FMTSEARCH = ( Fmtlib.Formats);

*TLD Overweight analysis;

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
data cd4; set lymph;
keep subjid visit  cd3_4_n;
run;
proc sort data=cd4 nodupkey;
by subjid visit;
run;
data hivstat; set AFRICOS.hivstat0;
keep subjid visit visitdt hivflag art_sdtn progid gender age dobdtn dur_art;
run;
data ncd; set AFRICOS.morb0_av;
keep subjid visit  glucose choles creat glu99 cho199 SYSBP DIABP bp cesd_score gfr gfr60 gfr90;
run;
proc sort data=ncd nodupkey;
by subjid visit;
run; 

data specimen; set AFRICOS.specimen0;
keep subjid visit  fast;
run; 

data vital; set AFRICOS.vital_pe0;
keep subjid visit visitdt gender hivflag progid dobdtn wt BMI;
run;

data art; set AFRICOS.arvcode0;
if arv_code="J55" then dolutegravir=1;
if arv_code="J56" then efavirenz=1;
run; 
data subdm; set AFRICOS.subjq_dm0;
keep subjid visit visitdt gender age progid   educat marital employed  HOWFRKM HOWLONGH HOWLONGM;
run;
data women; set AFRICOS.women0;
keep subjid visit visitdt currpreg;
run;
data bmi; merge lymph hivstat ncd specimen vital  art women subdm;
by subjid visit;
age=(visitdt-dobdtn)/365.25;
if age>40 then age40=1;
else age40=0;
if bmi ge 25 then overweight=1;
else overweight=0;
if bmi=. then overweight=.;
if age=. then age=. & age40=.;
if dur_art>5 then art5=1;
else art5=0;
if dur_art=. then art5=.;
rf= overweight + age40 + art5;
if rf>=2 then screen=1;
else screen=0;
if rf=. then screen=.;
run; 


****Creating survival dataset;
data art; set AFRICOS.arvcode0;
if arv_code="J55" then dolutegravir=1;
if arv_code="J56" then efavirenz=1;
if dolutegravir=. then dolutegravir=0;
if class_pi=. then class_pi=0;
if efavirenz=. then efavirenz=0;
run; 
data subdm; set AFRICOS.subjq_dm0;
keep subjid visit visitdt consendt gender age progid  dobdtn educat;
run;
data ncd; set AFRICOS.morb0_av;
keep subjid visit  glucose choles creat glu99 cho199 SYSBP DIABP bp cesd_score;
run;
data vital; set AFRICOS.vital_pe0;
keep subjid visit visitdt gender hivflag progid dobdtn wt BMI;
run;
data hivstat; set AFRICOS.hivstat0;
keep subjid visit visitdt hivflag art_sdtn progid gender age dobdtn dur_art;
run;
*flagging participants overweight at baseline;
data obesenrol; set bmi;
where visit=1 AND overweight=1;
obesflag=overweight;
keep subjid obesflag;
run;
data obese; merge obesenrol bmi;
by subjid;
run; 
proc freq data=obese;
tables visit*overweight;
run;
data bmibase; set vitl;
where visit=1;
bmibase=bmi;
keep subjid visit bmibase;
run; 
data overweight; merge vital hivstat obese art bmibase subdm women;
by subjid visit;
run; 

data overweight; set overweight;
where obesflag ne 1 AND overweight ne .;
run; 
proc freq data=overweight;
tables visit*overweight;
run;
*creating flag for survial analysis endpoint;
proc sort data=overweight;
by subjid descending overweight  visit;
run; 
DATA COUNT_IT;
 SET overweight (KEEP=subjid overweight);
 BY subjid;
 where overweight=1;
 IF FIRST.subjid THEN N_VISITS = 1;
 ELSE N_VISITS + 1;
 IF LAST.subjid THEN OUTPUT;
RUN; 
data ovrwtflag; merge count_it overweight;
	by subjid ;
run;  
*labeling for survival analysis;
data ovrwt_surv; set ovrwtflag;
	by subjid; 
	if first.subjid AND N_visits ne . then pop=1;
	if last.subjid AND N_visits=. then pop=1;
run; 

*generating exposure categories;
proc format; 
value status  		0 = "HIV/ART"
					1= "HIV/ART NAIVE"
					2= "HIV/TLD"
					3 = "HIV-";
run;
data bmi_surv; set ovrwt_surv;
by subjid;
if hivflag=1 AND class ne "" then status=0;
if hivflag=1 AND class="" then status=1;
if hivflag=1 & dolutegravir=1 then status=2;
if hivflag=2 then status=3;
format status status.;
if dolutegravir=1 then tldstart=Astartdt;
run;
