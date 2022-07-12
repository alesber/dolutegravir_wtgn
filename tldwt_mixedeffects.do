cd "C:\Users\aesber\Box Sync\Shared Files- Reed and Esber\TLD\weight change"

/*update to dec 1 cutoffuse "tldwt_022621.dta", clear */
use "tldwt_102220.dta", clear 


/*filling in variables that do not change (may need to run bysort a few times)*/
bysort subjid: carryforward gender progid consendt hivstat hivflag dobdtn art_sdtn ht bmibase, replace 
gsort subjid -visit
bysort subjid: carryforward gender progid hivstat hivflag dobdtn art_sdtn ht, replace 
replace hivstat=hivflag if hivstat==. 
sort subjid visit
replace consendt=visitdt if visit==1 & consendt==.

*generating tldstart date
replace astartdt="NOV2018" if subjid=="B04-0026" & visit==13
replace astartdt="DEC2018" if subjid=="B04-0036" & visit==12
replace astartdt="FEB2019" if subjid=="C01-0386" & visit==9
replace astartdt="MAR2019" if subjid=="E03-0001" & (visit==9 | visit==10)
replace astartdt="NOV2018" if subjid=="E03-0010" & (visit==9 | visit==10 | visit==11)
replace astartdt="SEP2019" if subjid=="D01-0045" 
drop if visit>90
*flagging participants with a visit date after 2019 for sensitivity analysis on LTFU
gen cy19=1 if visitdt>= date( "01JAN2019", "DMY")
gsort subjid -visit
bysort subjid: carryforward cy19, replace 
sort subjid visit

/*dropping participants with TLD visit 1*/ drop if dolutegravir==1 & visit==1
/*dropping pregnant visits (n=317)*/ drop if currpreg==1
/*replacing cd4nadir with lowest cd4*/ replace cd4nadir=cd4nsub if cd4nadir==.


*fixing BMI and ht for C01-0185
replace ht=176 if ht==76 & subjid=="C01-0185"
replace bmi=27.1 if subjid=="C01-0185" & bmi>100
replace wt=74.5 if wt==745
*fixing hip data
replace hip=111.8 if subjid=="A01-0030" & hip==11.8
replace hip=93.6 if subjid=="A01-0471" & hip<20
replace hip=103 if subjid=="B01-0006" & hip<20
replace hip=108 if subjid=="B01-0052" & hip<20
replace hip=110 if subjid=="B06-0105" & hip<20
replace hip=101 if subjid=="D01-0045" & hip<20
replace hip=102 if subjid=="D01-0381" & hip<20
replace hip=100 if subjid=="D01-0424" & hip<20
replace hip=105 if subjid=="D01-0457" & hip<20
replace hip=114 if subjid=="E03-0125" & hip<20
replace hip=130 if subjid=="E03-0140" & hip<20

gen tstrt=date(astartdt, "MY") if dolutegravir==1
format tstrt %td
sort subjid visit
bysort subjid: carryforward tstrt, replace
gsort subjid -visit
bysort subjid: carryforward tstrt, replace
gen tld=1 if dolutegravir==1
sort subjid visit
bysort subjid: carryforward tld, replace
gsort subjid -visit
bysort subjid: carryforward tld, replace
replace tld=0 if tld==.
gen tvis=0 if dolutegravir==1
gen dur_tld=(visitdt-tstrt)/365.25 if tstrt!=.
label var dur_tld "Duration on TLD(years)"
gen start=tstrt-art_sdtn
gen tldnaive=0
replace tldnaive=1 if start<30 & start>-30
egen tldc=cut(dur_tld), at(-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4)
bysort tldnaive tldc: egen meanwt=mean(wt)

*generating analysis pop excluding participants starting TLD at enrollment
gen tldp=1 if tld==1 
replace tldp=. if dolutegravir==1 & visit==1


bysort tld visit: egen grpmean=mean(wt)
label var grpmean "Weight (kg)"

label var gender "Gender"
label def gender 1 "Male" 2 "Female"
label val gender gender

label var progid "Study site"
label define progid3 1  "Kayunga, Uganda" 2"South Rift Valley, Kenya" 3 "Kisumu West, Kenya" 4 "Mbeya, Tanzania" 5 "Abuja & Lagos Nigeria"
label val progid progid3

label def yn 0 "No" 1 "Yes"
bysort subjid: carryforward gender dobdtn  progid, replace

gen agev=(visitdt-dobdtn)/365.25
gen agec=0 if agev<30
replace agec=1 if agev>29 & agev<40
replace agec=2 if agev>39 & agev<50
replace agec=3 if agev>50 & agev!=.
label def agec 0 "15-29" 1 "30-39" 2 "40-49" 3 "50+"
label val agec agec
label var agec "Age at visit"
label var agev "Age at visit"
mkspline age0 30 age1 40 age2 50 age3 = agev 

*waist to hip ratio
gen wh=waist/hip
*Viral suppression
gen vs=1 if vl<1000 & vl!=.
replace vs=0 if vl>=1000 & vl!=.
label def vs 0 "not suppressed" 1 "suppressed"
label val vs vs

destring class_pi, replace
gen artreg=4 if  medication=="" & arv_code=="" & art_sdtn==.
replace artreg=1 if nevirapine==1
replace artreg=2 if dolutegravir==1
replace artreg=3 if class_pi==1
replace artreg=0 if efavirenz==1
replace artreg=5 if artreg==.
label def artreg 0 "EFV" 1 "NVP" 2 "DTG" 3 "PI" 4 "Naive" 5 "Other"
label val artreg artreg
label var artreg "ART type"

*CD4_cat
gen cd4_cat=0 if cd3_4_n<200
replace cd4_cat=1 if cd3_4_n>=200 & cd3_4_n<350
replace cd4_cat=2 if cd3_4_n>=350 & cd3_4_n<500
replace cd4_cat=3 if cd3_4_n>=500 & cd3_4_n !=.
label define cd4_cat 0"<200" 1 "200-349" 2 "350-499" 3 "500+" 
label val cd4_cat cd4_cat
label var cd4_cat "CD4"

*cd4 nadir categories 
gen cd4nc=0 if cd4nadir<200
replace cd4nc=1 if cd4nadir>=200 & cd4nadir<350
replace cd4nc=2 if cd4nadir>=350 & cd4nadir<500
replace cd4nc=3 if cd4nadir>=500 & cd4nadir !=.
label val cd4nc cd4_cat
label var cd4nc "CD4 nadir"
*filling in missing for dur_art
gen astartdtn=date(astartdt, "MY")
gen startdtn=date(startdt, "MY")
replace art_sdtn=startdtn if art_sdtn==. & astartdtn==. & startdtn!=. 
replace art_sdtn=astartdtn if art_sdtn==. & startdtn==. & astartdtn!=. 
replace art_sdtn=astartdtn if art_sdtn==.  & astartdtn<startdtn & astartdtn!=. & startdtn!=. 
replace art_sdtn=startdtn if art_sdtn==. & startdtn<astartdtn & astartdtn!=. & startdtn!=. 
bysort subjid: carryforward art_sdtn, replace
replace dur_art=(visitdt-art_sdtn)/365.25 if dur_art==. & art_sdtn!=.


*virologic failure
gen vf=1 if vl>=1000 & vl!=. 
replace vf=0 if vl<1000 & vl!=. 
label def vf 0 "Suppressed" 1 "Virologic Failure"
label val vf vf
label var vf "Virologic failure"

*generating regimen prior to tld switch
gsort subjid -dolutegravir visit
/*flagging first visit with tld*/ bysort subjid: gen vtld1=_n
sort subjid visit
bysort subjid: gen p_reg=artreg[_n-1] if vtld1==1
bysort subjid: carryforward p_reg, replace
label val p_reg artreg
label var p_reg "Regimen prior to switch"

gen pretld=artreg
replace pretld=p_reg if dolutegravir==1
label val pretld artreg
label var pretld "Prior regimen"

replace dolutegravir=0 if dolutegravir==.
label def dolutegravir 0 "Not on TLD" 1 "On TLD"
label val dolutegravir dolutegravir

*calculating weight change at various time points 
gen tldt=0 if dur_tld<-5 
replace tldt=1 if dur_tld>=-5 & dur_tld<-4
replace tldt=2 if dur_tld>=-4 & dur_tld<-3
replace tldt=3 if dur_tld>=-3 & dur_tld<-2
replace tldt=4 if dur_tld>=-2 & dur_tld<-1
replace tldt=5 if dur_tld>=-1 & dur_tld<0
replace tldt=6 if dur_tld>=-0 & dur_tld<.5
replace tldt=7 if dur_tld>=.5 & dur_tld<1
replace tldt=8 if dur_tld>=1 & dur_tld!=.
label def tldte 0 "-5+ yrs" 1 "-4-5 yrs" 2 "-3-4 yrs" 3 "-2-3 yrs" 4 "-1-2 yrs" 5 "-6 mos-1 yr" 6 "-<6 mos" 7 "<6 mos" 8 "6-12 mos" 9 "12+ mos"
label val tldt tldte
label var tldt "Time from TLD switch"

gen tldti=0 if dur_tld<-5 
replace tldti=1 if dur_tld>=-5 & dur_tld<-4
replace tldti=2 if dur_tld>=-4 & dur_tld<-3
replace tldti=3 if dur_tld>=-3 & dur_tld<-2
replace tldti=4 if dur_tld>=-2 & dur_tld<-1
replace tldti=5 if dur_tld>=-1 & dur_tld<-.5
replace tldti=6 if dur_tld>=-.5 & dur_tld<-.1
replace tldti=7 if  dur_tld>=-.1 & dur_tld<.1
replace tldti=8 if dur_tld<.5 & dur_tld>=.1
replace tldti=9 if dur_tld>=.5 & dur_tld<1
replace tldti=10 if dur_tld>=1 & dur_tld!=.
label def tldteb 0 "-5+ yrs" 1 "-4-5 yrs" 2 "-3-4 yrs" 3 "-2-3 yrs" 4 "-1-2 yrs" 5 "-6 mos-1 yr" 6 "Time of switch" 7 "-<6 mos" 7 "<6 mos" 8 "6-12 mos" 9 "12+ mos"
label val tldti tldteb
bysort subjid: gen wtch=wt-wt[_n-1] if tldp==1
bysort tldt: sum wtch if tldp==1, detail

*Calculating number of participants on tld
gsort subjid -visit
bysort subjid: gen n=_n if dolutegravir==1
tab n


*creating a spline term with TLD switch
mkspline tldtimea 0 tldtimeb 1 tldtimec = dur_tld
mkspline tldta 0 tldtb .5 tldtc = dur_tld, marginal


*creating a spline for duration on ART (at 6 months switch)
mkspline  durarta 0 durartb .5 durartc = dur_art 

*creating time from enrollment
gen etime=(visitdt-consendt)/365.25
label var etime "Time since enrollment (years)"


gen durtldi=round(dur_tld)
egen groupsex = group(gender durtldi)
egen groupage = group( agec durtldi)
egen groupsite = group( progid durtldi)
egen groupreg = group(p_reg durtldi )

*testing for missing at randomness for wt data
gen wtmiss=0
replace wtmiss=1 if wt==.
tab wtmiss tld, chi

gen tldhiv=tld 
replace tldhiv=2 if hivflag==2
label def tldhiv 0 "Did not Switch to TLD" 1 "Switched to TLD" 2 "Participants without HIV"
label val tldhiv tldhiv

bysort subjid: gen tab1=_n
*weight categorical 
astile wt_cat=wt, nq(4)
tabstat wt, stats(p25 p50 p75)
label def wt_cat 1 "<56" 2 "56-62" 3 "62-71" 4 ">71"
label val wt_cat wt_cat

gen bmic=0 if bmi<18.5
replace bmic=1 if bmi>=18.5 & bmi<25
replace bmic=2 if bmi>=25
label def bmi 0 "<18.5" 1 "18.5-24.99" 2 "25+"
label val bmic bmi
label var bmic "BMI"

gen prior_art=p_reg
replace prior_art=2 if p_reg==3 | p_reg==5
bysort subjid: carryforward prior_art, replace
label def priorart 0 "EFV" 1 "NVP" 2 "Other"
label val prior_art priorart

*Numbers for results section 
*calculating total number of person years on TLD 
gen totaltld=sum(dur_tld) if n==1
sum totaltld, detail
*median time on tld 
sum dur_tld if n==1, detail

*calculating total number of person years in study 
gen totaltime=sum(etime) if hivflag!=2
sum totaltime, detail

*calculating time on art prior to TLD based on reviewer 2 comments round 3 28 Mar 2022
gen dur_pretld=(dur_art-dur_tld)

*average age and wt at time of tld switch
sum wt if tldp==1 & tldti==6, detail
sum bmi if tldp==1 & tldti==6, detail
sum age if tldp==1 & tldti==6, detail
sum dur_art if tldp==1 & n==1, detail

*regimen prior to tld switch
tab pretld if vtld1==1 & tldp==1

table1 if visit==1, by(tldhiv) vars(progid cat\ agec cat \ age conts \ gender cat \ wt_cat cat \ bmic cat \ artreg cat \ cd4_cat cat \ vf cat) one  sav("table1.xlsx", replace)
table1 if visit==1, vars(progid cat\ agec cat \ age conts \ gender cat \ wt_cat cat \ bmic cat \ artreg cat \ cd4_cat cat \ vf cat) one  sav("table1all.xlsx", replace)
drop if hivflag==2 
drop if pretld==4 & vtld1==1 & tldp==1
/***** UPDATED 4 NOV 2021- REMOVE DEPRESSION, ADD PRIOR ART CD4 NADIR  
UPDATED 26 MAR 2021- Changing time since enrollment to time on ART 
UPDATE 25 Jan 2021 Continuous Duration on TLD variable with spline 
	/* Order of Code (survival analysis code in separate file)
		1. BMI
			1a. BMI change all participants
			1b. BMI change switchers only
			1c. BMI change suppressed switchers only 
			1d. Descriptive figure BMI change by gender, age, site previous regimen
			1e. Weight change all participants
			1f. Weight change switchers only
			1g. Weight change switchers suppressors only
			1h. Descriptive figure weight change by gender, age, site previous regimen
			1i. Descriptive figure WHR change by gender, age, site previous regimen
		
	 */ *////
	 
/* BMI
	ALL PLWH 
		Unadjusted*/
/* This uses time since enrollment, updating to time on ART
mixed bmi c.etime##i.dolutegravir  || subjid: visit , cov(un) noconst  mle
mixed bmi c.etime i.dolutegravir  || subjid: visit , cov(un) noconst  mle */
mixed bmi c.durarta c.durartb c.durartc i.dolutegravir  || subjid: visit , cov(un) noconst  mle
mixed bmi c.dur_art i.dolutegravir  || subjid: visit , cov(un) noconst  mle
mixed bmi i.gender || subjid: visit , cov(un) noconst  mle 
mixed bmi age0 age1 age2 age3 || subjid: visit , cov(un) noconst  mle 
mixed bmi i.progid || subjid: visit , cov(un) noconst  mle 
mixed bmi i.cd4nc || subjid: visit , cov(un) noconst  mle 
	*Adjusted model
mixed bmi c.durarta c.durartb c.durartc i.dolutegravir age0 age1 age2 age3  i.gender i.progid i.cd4nc|| subjid: visit , cov(un) noconst  mle
quietly margins, at(etime=(0(2)8)) over(dolutegravir)
marginsplot,  yti("BMI (kg/m{sup:2})")  xlabel(, labsize(small)) xscale(range(0 8)) yscale(range(20 26)) title("Average change in BMI (adjusted)") saving(bmicalladjplot, replace)


*Switchers only (1 yr post tld switch spline)

*descriptive to accompany figures 
kwallis bmi if tldp==1, by(groupsex)
kwallis bmi if tldp==1, by(groupage)
kwallis bmi if tldp==1, by(groupsite)
kwallis bmi if tldp==1, by(groupreg)


mixed bmi  c.tldtimea c.tldtimeb c.tldtimec if tldp==1|| subjid: visit , cov(un) noconst  mle
mixed bmi i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed bmi age0 age1 age2 age3 if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed bmi i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed bmi i.cd4nc if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed bmi i.prior_art if tldp==1|| subjid: visit , cov(un) noconst  mle 
*Adjusted
mixed bmi c.tldtimea c.tldtimeb c.tldtimec i.gender age0 age1 age2 age3  i.progid i.cd4nc i.prior_art  if tldp==1|| subjid: visit , cov(un)

*checking for interaction with age, sex
mixed bmi c.tldtimea##i.gender c.tldtimeb#i.gender c.tldtimec#i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle
 mixed bmi c.tldtimea##i.agec c.tldtimeb#i.agec c.tldtimec#i.agec if tldp==1|| subjid: visit , cov(un) noconst  mle
 mixed bmi c.tldtimea##i.progid c.tldtimeb#i.progid c.tldtimec#i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle
mixed bmi c.tldtimea##i.p_reg c.tldtimeb#i.p_reg c.tldtimec#i.p_reg if tldp==1|| subjid: visit , cov(un) noconst  mle


*Switchers AND suppressed (1 yr post tld switch spline)
mixed bmi c.tldtimea c.tldtimeb c.tldtimec if tldp==1 & vs==1 & cd4_cat==3|| subjid: visit , cov(un) noconst  mle
mixed bmi i.gender if tldp==1 & vs==1 & cd4_cat==3|| subjid: visit , cov(un) noconst  mle 
mixed bmi age0 age1 age2 age3 if tldp==1 & vs==1 & cd4_cat==3|| subjid: visit , cov(un) noconst  mle 
mixed bmi i.progid if tldp==1 & vs==1 & cd4_cat==3|| subjid: visit , cov(un) noconst  mle 
mixed bmi i.cd4nc if tldp==1 & vs==1 & cd4_cat==3|| subjid: visit , cov(un) noconst  mle 
*Adjusted
mixed bmi c.tldtimea c.tldtimeb c.tldtimec i.gender age0 age1 age2 age3  i.progid i.cd4nc i.prior_art if tldp==1 & vs==1 & cd4_cat==3|| subjid: visit , cov(un)

*only with visits after 2019
mixed bmi c.tldtimea c.tldtimeb c.tldtimec if tldp==1 & cy19==1|| subjid: visit , cov(un) noconst  mle 
*Adjusted
mixed bmi c.tldtimea c.tldtimeb c.tldtimec i.gender age0 age1 age2 age3  i.progid i.cd4nc i.prior_art  if tldp==1 &  cy19==1|| subjid: visit , cov(un) noconst  mle 

/*figures-- 
lgraph bmi durtldi  if tldp==1 & dur_tld<2 , statistic(mean) errortype(ci(95))  yti("BMI (kg/m{sup:2})")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1+") title("a. Overall") saving(bmi_all, replace)
lgraph bmi durtldi  gender if tldp==1 & dur_tld<2 , statistic(mean) errortype(ci(95))  yti("BMI (kg/m{sup:2})")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0"  1 "1+") title("a. Sex") saving(bmi_gen, replace)
lgraph bmi durtldi  agec if tldp==1 & dur_tld<2, statistic(mean) errortype(ci(95))  yti("BMI (kg/m{sup:2})")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1+") title("b. Age") saving(bmi_age, replace)
lgraph bmi durtldi  progid if tldp==1 & dur_tld<2, statistic(mean) errortype(ci(95))  yti("BMI (kg/m{sup:2})")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1+") title("c.Study Site") saving(bmi_site, replace)
lgraph bmi durtldi  pretld if tldp==1 & dur_tld<2, statistic(mean) errortype(ci(95))  yti("BMI (kg/m{sup:2})")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1+") title("d. Previous Regimen") saving(bmi_reg, replace)

graph combine bmi_gen.gph bmi_age.gph bmi_site.gph bmi_reg.gph, rows(2) cols(2)  iscale(.48)  saving(bmi.gph, replace)*/

*WT change ***********************************************************************
	/*ALL PLWH 
		Unadjusted*/
mixed wt c.durarta c.durartb c.durartc i.dolutegravir  || subjid: visit , cov(un) noconst  mle
mixed wt i.gender || subjid: visit , cov(un) noconst  mle 
mixed wt age0 age1 age2 age3 || subjid: visit , cov(un) noconst  mle 
mixed wt i.progid || subjid: visit , cov(un) noconst  mle 
mixed wt i.cd4nc  || subjid: visit , cov(un) noconst  mle 
	*Adjusted model
mixed wt c.durarta c.durartb c.durartc i.dolutegravir age0 age1 age2 age3 i.gender i.progid i.cd4nc|| subjid: visit , cov(un) noconst  mle
 margins, at(etime=(0(2)8)) over(dolutegravir)
quietly margins, at(etime=(0(2)8)) over(dolutegravir)
marginsplot,  yti("Weight (kg)")  xlabel(, labsize(small)) xscale(range(0 8)) yscale(range(60 68)) title("Average change in Weight (adjusted)") saving(wtcalladjplot, replace)


*Switchers only (1 yr post tld switch spline)
mixed wt  c.tldtimea c.tldtimeb c.tldtimec if tldp==1|| subjid: visit , cov(un) noconst  mle
mixed wt i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed wt age0 age1 age2 age3 if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed wt i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed wt i.cd4nc if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed wt i.prior_art if tldp==1|| subjid: visit , cov(un) noconst  mle 
*Adjusted
mixed wt c.tldtimea c.tldtimeb c.tldtimec i.gender age0 age1 age2 age3 i.progid i.cd4nc i.prior_art  if tldp==1|| subjid: visit , cov(un)

*checking for interaction with age, sex, previous regimen for results section
*checking for interaction with age, sex
mixed wt c.tldtimea##i.gender c.tldtimeb#i.gender c.tldtimec#i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle
margins, over(gender)
 mixed wt c.tldtimea##i.agec c.tldtimeb#i.agec c.tldtimec#i.agec if tldp==1|| subjid: visit , cov(un) noconst  mle
 mixed wt c.tldtimea##i.progid c.tldtimeb#i.progid c.tldtimec#i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle
mixed wt c.tldtimea##i.p_reg c.tldtimeb#i.p_reg c.tldtimec#i.p_reg if tldp==1|| subjid: visit , cov(un) noconst  mle

*Switchers AND suppressed (1 yr post tld switch spline)
mixed wt c.tldtimea c.tldtimeb c.tldtimec if tldp==1 & vs==1 & cd4_cat==3|| subjid: visit , cov(un) noconst  mle
mixed wt i.gender if tldp==1 & vs==1 & cd4_cat==3|| subjid: visit , cov(un) noconst  mle 
mixed wt i.agec if tldp==1 & vs==1 & cd4_cat==3|| subjid: visit , cov(un) noconst  mle 
mixed wt i.progid if tldp==1 & vs==1 & cd4_cat==3|| subjid: visit , cov(un) noconst  mle 
mixed wt i.depress if tldp==1 & vs==1 & cd4_cat==3|| subjid: visit , cov(un) noconst  mle 
*Adjusted
mixed wt c.tldtimea c.tldtimeb c.tldtimec i.gender age0 age1 age2 age3  i.progid i.cd4nc i.prior_art  if tldp==1 & vs==1& cd4_cat==3|| subjid: visit , cov(un)
*post 2019
*Switchers AND suppressed (1 yr post tld switch spline)
mixed wt c.tldtimea c.tldtimeb c.tldtimec if tldp==1 & cy19==1|| subjid: visit , cov(un) noconst  mle

*Adjusted
mixed wt c.tldtimea c.tldtimeb c.tldtimec i.gender agev  i.progid cd4nadir i.prior_art  if tldp==1 & cy19==1|| subjid: visit , cov(un)

/*figures-- 
lgraph wt durtldi  if tldp==1 & dur_tld<2 , statistic(mean) errortype(ci(95))  yti("Weight (kg))")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1+") title("a. Overall") saving(wt_all, replace)
lgraph wt durtldi  gender if tldp==1 & dur_tld<2 , statistic(mean) errortype(ci(95))  yti("Weight (kg)")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0"  1 "1+") title("a. Sex") saving(wt_gen, replace)
lgraph wt durtldi  agec if tldp==1 & dur_tld<2, statistic(mean) errortype(ci(95))  yti("Weight (kg)")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1+") title("b. Age") saving(wt_age, replace)
lgraph wt durtldi  progid if tldp==1 & dur_tld<2, statistic(mean) errortype(ci(95))  yti("Weight (kg)")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1+") title("c. Study Site") saving(wt_site, replace)
lgraph wt durtldi  pretld if tldp==1 & dur_tld<2, statistic(mean) errortype(ci(95))  yti("Weight (kg)")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1+") title("d. Previous Regimen") saving(wt_reg, replace) */

graph combine   wt_gen.gph wt_age.gph wt_site.gph wt_reg.gph, rows(2) cols(2)  iscale(.48)  saving(wt.gph, replace)


*figures-- WHR 
*All PLWH
mixed wh c.durarta c.durartb c.durartc i.dolutegravir  || subjid: visit , cov(un) noconst  mle
mixed wh c.durarta c.durartb c.durartc i.dolutegravir i.gender i.agec i.progid i.depress  || subjid: visit , cov(un) noconst  mle

*Interactions
mixed wh c.tldtimea##i.gender c.tldtimeb#i.gender c.tldtimec#i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle
margins, at(tldtimea==1) over(gender)
margins, at(tldtimeb==1) over(gender)
margins, at(tldtimec==1) over(gender)
 mixed wh c.tldtimea##i.agec c.tldtimeb#i.agec c.tldtimec#i.agec if tldp==1|| subjid: visit , cov(un) noconst  mle
 mixed wh c.tldtimea##i.progid c.tldtimeb#i.progid c.tldtimec#i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle
mixed wh c.tldtimea##i.p_reg c.tldtimeb#i.p_reg c.tldtimec#i.p_reg if tldp==1|| subjid: visit , cov(un) noconst  mle

*Switchers only (1 yr post tld switch spline)
mixed wh  c.tldtimea c.tldtimeb c.tldtimec if tldp==1|| subjid: visit , cov(un) noconst  mle
mixed wh  c.tldtimea c.tldtimeb c.tldtimec i.gender i.agec i.depress i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle


*exported data for R figures--******************************************************
save "tldwtfig.dta", replace
keep if tldp==1
keep subjid visit visitdt dur_tld durtldi gender progid agec artp pretld 








*******************OLD CODE**********************************************************

/*calculating switch 1 year post 
lgraph wh durtldi  if tldp==1 & dur_tld<2 , statistic(mean) errortype(ci(95))  yti("Waist to Hip Ratio")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1+") title("a. Overall") saving(wh_all, replace)
lgraph wh durtldi  gender if tldp==1 & dur_tld<2 , statistic(mean) errortype(ci(95))  yti("Waist to Hip Ratio")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0"  1 "1+") title("a. Sex") saving(wh_gen, replace)
lgraph wh durtldi  agec if tldp==1 & dur_tld<2, statistic(mean) errortype(ci(95))  yti("Waist to Hip Ratio")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1+") title("b. Age") saving(wh_age, replace)
lgraph wh durtldi  progid if tldp==1 & dur_tld<2, statistic(mean) errortype(ci(95))  yti("Waist to Hip Ratio")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1+") title("c. Study Site") saving(wh_site, replace)
lgraph wh durtldi  pretld if tldp==1 & dur_tld<2, statistic(mean) errortype(ci(95))  yti("Waist to Hip Ratio")  xti("Duration on TLD (years)") xlabel(-6 "-6" -5 "-5" -4 "-4" -3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1+") title("d.Previous Regimen") saving(wh_reg, replace)

graph combine   wh_gen.gph wh_age.gph wh_site.gph wh_reg.gph, rows(2) cols(2)  iscale(.48)  saving(wh.gph, replace) */
*****UPDATE 28 OCTOBER 2020 Continuous Duration on TLD variable 
	/* Order of Code (survival analysis code in IAS Folder)
		1. Continuous models
			1a. Weight change all participants
			1b. Weight change switchers only
			1c. Weight change suppressed switchers only 
			1d. BMI change all participants
			1e. BMI change switchers only
			1f. BMI change suppressed switchers only
			1g. WHR change all participants
			1h. WHR change switchers only
			1i. WHR change suppressed switchers only
		2. Categorical Models
			2a. Weight change switchers only
			2b. BMI change switchers only
			2c. WHR change suppressed switchers only
		CODE FOR FIGURES FOLLOWS RESPECTIVE CODE FOR MODELS */ 
		
/*Weight change models*/
*all participants
mixed wt c.etime##i.dolutegravir  || subjid: visit , cov(un) noconst  mle
quietly margins, at(etime=(0(2)8)) over(dolutegravir)
marginsplot,  yti("Weight (kg)")  xlabel(, labsize(small)) xscale(range(0 8)) title("Average change in weight")saving(wtcallplot, replace)

mixed wt c.etime##i.dolutegravir i.agec i.gender i.progid i.depress || subjid: visit , cov(un) noconst  mle
quietly margins, at(etime=(0(2)8)) over(dolutegravir)
marginsplot,  yti("Weight (kg)")  xlabel(, labsize(small)) xscale(range(0 8)) yscale(range(60 70)) title("Average change in weight (adjusted)")saving(wtcalladjplot, replace)

graph combine  wtcallplot.gph wtcalladjplot.gph ,  saving(wtc_comb_all, replace)

*Extra models for the table for all participants
mixed wt i.gender || subjid: visit , cov(un) noconst  mle 
mixed wt i.agec || subjid: visit , cov(un) noconst  mle 
mixed wt i.progid || subjid: visit , cov(un) noconst  mle 
mixed wt i.depress || subjid: visit , cov(un) noconst  mle 



	*Switchers ONLY
	*use this model for the figure (the results are the same when add up interaction terms)
mixed wt c.dur_tld##i.dolutegravir  if tldp==1|| subjid: visit , cov(un) noconst  mle
quietly margins, at(dur_tld=(-5(1)2))
marginsplot,  yti("Weight (kg)") xline(6.5) xlabel(, labsize(small)) xscale(range(-0.25 2.25)) title("Average change in weight")saving(wtcplot, replace)
/*use this model for the table*/mixed wt  c.tldtimea c.tldtimeb if tldp==1|| subjid: visit , cov(un) noconst  mle

mixed wt i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed wt i.agec if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed wt i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed wt i.depress if tldp==1|| subjid: visit , cov(un) noconst  mle 
*1 year spline post tld switch
mixed wt c.tldtimea c.tldtimeb c.tldtimec i.gender i.agec  i.progid i.depress  if tldp==1|| subjid: visit , cov(un) noconst  mle 

*6 month spline post tld switcher
mixed wt c.tldta c.tldtb c.tldtc i.gender i.agec  i.progid i.depress  if tldp==1|| subjid: visit , cov(un) noconst  mle 

*full model suppressed only
mixed wt c.tldtimea c.tldtimeb   if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle
mixed wt c.tldtimea c.tldtimeb  i.gender i.agec  i.progid i.depress   if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle 


*Figure 1 data (continuous)
mixed wt c.dur_tld##i.agec if tldp==1|| subjid: visit , cov(un) noconst  mle 
quietly margins, at(dur_tld=(-5(1)2)) over(agec)
marginsplot,  yti("Weight (kg)") xline(6.5) xlabel(, labsize(small)) xscale(range(-0.25 2.25)) title("Age at visit")saving(wtcageplot, replace)

mixed wt c.dur_tld##i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle 
quietly margins, at(dur_tld=(-5(1)2)) over(gender)
marginsplot,  yti("Weight (kg)")  xline(6.5) xlabel(, labsize(small))  xscale(range(-0.25 2.25)) title("Sex") saving(wtcgenplot, replace)

mixed wt c.dur_tld##i.pretld if tldp==1|| subjid: visit , cov(un) noconst  mle 
quietly margins, at(dur_tld=(-5(1)2)) over(pretld)
marginsplot,  yti("Weight (kg)") xline(6.5) xlabel(, labsize(small)) xscale(range(-0.25 2.25)) title("Previous regimen") saving(wtcpregplot, replace)

mixed wt c.dur_tld##i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle 
quietly margins, at(dur_tld=(-5(1)2)) over(progid) 
marginsplot,  yti("Weight (kg)")  xlabel(, labsize(small)) xscale(range(-0.25 2.25)) title("Study site") saving(wtcprogidplot, replace)

graph combine  wtcgenplot.gph wtcageplot.gph wtcprogidplot.gph wtcpregplot.gph, rows(2) cols(2)  iscale(.48) saving(wtc_comb, replace)


/* BMI models*/
*ALL PLWH
mixed bmi c.etime##i.dolutegravir  || subjid: visit , cov(un) noconst  mle
quietly margins, at(etime=(0(2)8)) over(dolutegravir)
marginsplot,  yti("BMI (kg/m{sup:2})")  xlabel(, labsize(small)) xscale(range(0 8)) title("Average change in BMI")saving(bmicallplot, replace)

mixed bmi c.etime##i.dolutegravir i.agec i.gender i.progid i.depress || subjid: visit , cov(un) noconst  mle
quietly margins, at(etime=(0(2)8)) over(dolutegravir)
marginsplot,  yti("BMI (kg/m{sup:2})")  xlabel(, labsize(small)) xscale(range(0 8)) yscale(range(20 26)) title("Average change in BMI (adjusted)")saving(bmicalladjplot, replace)

graph combine  bmicallplot.gph bmicalladjplot.gph ,  saving(bmic_comb_all, replace)

*Extra models for the table for all participants
mixed bmi i.gender || subjid: visit , cov(un) noconst  mle 
mixed bmi i.agec || subjid: visit , cov(un) noconst  mle 
mixed bmi i.progid || subjid: visit , cov(un) noconst  mle 
mixed bmi i.depress || subjid: visit , cov(un) noconst  mle 


*Switchers only 
	*Switchers ONLY
	*use this model for the figure (the results are the same when add up interaction terms)
mixed bmi c.dur_tld##i.dolutegravir  if tldp==1|| subjid: visit , cov(un) noconst  mle
quietly margins, at(dur_tld=(-5(1)2))
marginsplot,  yti("Weight (kg)") xline(6.5) xlabel(, labsize(small)) xscale(range(-0.25 2.25)) title("Average change in BMI")saving(wtcplot, replace)

/*use this model for the table*/mixed bmi c.tldtimea c.tldtimeb if tldp==1|| subjid: visit , cov(un) noconst  mle
mixed bmi i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed bmi i.agec if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed bmi i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed bmi i.depress if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed bmi c.tldtimea c.tldtimeb i.gender i.agec  i.progid i.depress  if tldp==1|| subjid: visit , cov(un) noconst  mle 


*full model suppressed only
mixed bmi c.tldtimea c.tldtimeb   if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle
mixed bmi i.gender if tldp==1 & vs==1|| subjid: visit , cov(un) noconst  mle 
mixed bmi i.agec if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle 
mixed bmi i.progid if tldp==1 & vs==1|| subjid: visit , cov(un) noconst  mle 
mixed bmi i.depress if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle 
mixed bmi c.tldtimea c.tldtimeb  i.gender i.agec  i.progid i.depress   if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle 


*Figure 1 data (continuous)
mixed bmi c.dur_tld##i.agec if tldp==1|| subjid: visit , cov(un) noconst  mle 
quietly margins, at(dur_tld=(-5(1)2)) over(agec)
marginsplot,  yti("BMI (kg/m{sup:2})") xline(6.5) xlabel(, labsize(small)) xscale(range(-0.25 2.25)) title("Age at visit")saving(bmicageplot, replace)

mixed bmi c.dur_tld##i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle 
quietly margins, at(dur_tld=(-5(1)2)) over(gender)
marginsplot,  yti("BMI (kg/m{sup:2})")  xline(6.5) xlabel(, labsize(small))  xscale(range(-0.25 2.25)) title("Sex") saving(bmicgenplot, replace)

mixed bmi c.dur_tld##i.pretld if tldp==1|| subjid: visit , cov(un) noconst  mle 
quietly margins, at(dur_tld=(-5(1)2)) over(pretld)
marginsplot,  yti("BMI (kg/m{sup:2})") xline(6.5) xlabel(, labsize(small)) xscale(range(-0.25 2.25)) title("Previous regimen") saving(bmicpregplot, replace)

mixed bmi c.dur_tld##i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle 
quietly margins, at(dur_tld=(-5(1)2)) over(progid) 
marginsplot,  yti("BMI (kg/m{sup:2})")  xlabel(, labsize(small)) xscale(range(-0.25 2.25)) title("Study site") saving(bmicprogidplot, replace)

graph combine  bmicgenplot.gph bmicageplot.gph bmicprogidplot.gph bmicpregplot.gph, rows(2) cols(2)  iscale(.48) saving(bmic_comb, replace)





/* WHR models*/
*ALL PLWH
mixed wh c.etime##i.dolutegravir  || subjid: visit , cov(un) noconst  mle
quietly margins, at(etime=(0(2)8)) over(dolutegravir)
marginsplot,  yti("WHR")  xlabel(, labsize(small)) xscale(range(0 8)) title("Average change in Waist to Hip Ratio")saving(whrcallplot, replace)

mixed wh c.etime##i.dolutegravir i.agec i.gender i.progid i.depress || subjid: visit , cov(un) noconst  mle
quietly margins, at(etime=(0(2)8)) over(dolutegravir)
marginsplot,  yti("WHR")  xlabel(, labsize(small)) xscale(range(0 8)) title("Average change in Waist to Hip Ratio (adjusted)")saving(whrcalladjplot, replace)

graph combine  whrcallplot.gph whrcalladjplot.gph ,  saving(whrc_comb_all, replace)

*Extra models for the table for all participants
mixed wh i.gender || subjid: visit , cov(un) noconst  mle 
mixed wh i.agec || subjid: visit , cov(un) noconst  mle 
mixed wh i.progid || subjid: visit , cov(un) noconst  mle 
mixed wh i.depress || subjid: visit , cov(un) noconst  mle 

*Switchers only
/*update add in cd4nadir and previous regimen take out depression 11/4/21*/
*use this model for the table*/mixed bmi c.tldtimea c.tldtimeb if tldp==1|| subjid: visit , cov(un) noconst  mle
mixed wh i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed wh agev if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed wh i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed wh i.p_reg if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed wh cd4nadir if tldp==1|| subjid: visit , cov(un) noconst  mle 
mixed wh c.tldtimea c.tldtimeb   if tldp==1 || subjid: visit , cov(un) noconst  mle
mixed wh c.tldtimea c.tldtimeb i.gender i.agec  i.progid i.depress  if tldp==1|| subjid: visit , cov(un) noconst  mle 


*full model suppressed only
mixed wh c.tldtimea c.tldtimeb   if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle
mixed wh i.gender if tldp==1 & vs==1|| subjid: visit , cov(un) noconst  mle 
mixed wh i.agec if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle 
mixed wh i.progid if tldp==1 & vs==1|| subjid: visit , cov(un) noconst  mle 
mixed wh i.depress if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle 
mixed wh c.tldtimea c.tldtimeb  i.gender i.agec  i.progid i.depress   if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle 


*Figure 1 data (continuous)
mixed wh c.dur_tld##i.agec if tldp==1|| subjid: visit , cov(un) noconst  mle 
quietly margins, at(dur_tld=(-5(1)2)) over(agec)
marginsplot,  yti("WHR") xline(6.5) xlabel(, labsize(small)) xscale(range(-0.25 2.25)) title("Age at visit")saving(whrcageplot, replace)

mixed wh c.dur_tld##i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle 
 margins, at(dur_tld=(-5(1)2)) over(gender)
marginsplot,  yti("WHR")  xline(6.5) xlabel(, labsize(small))  xscale(range(-0.25 2.25)) title("Sex") saving(whrcgenplot, replace)

mixed wh c.dur_tld##i.pretld if tldp==1|| subjid: visit , cov(un) noconst  mle 
quietly margins, at(dur_tld=(-5(1)2)) over(pretld)
marginsplot,  yti("WHR") xline(6.5) xlabel(, labsize(small)) xscale(range(-0.25 2.25)) title("Previous regimen") saving(whrcpregplot, replace)

mixed wh c.dur_tld##i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle 
quietly margins, at(dur_tld=(-5(1)2)) over(progid) 
marginsplot,  yti("WHR")  xlabel(, labsize(small)) xscale(range(-0.25 2.25)) title("Study site") saving(whrcprogidplot, replace)

graph combine  whrcgenplot.gph whrcageplot.gph whrcprogidplot.gph whrcpregplot.gph, rows(2) cols(2)  iscale(.48) saving(whrc_comb, replace)

*full model suppressed only
mixed wh i.dolutegravir##c.dur_tld i.gender i.agec  i.progid i.depress   if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle 


*graph with descriptive data
lgraph wt tldt  gender if tldp==1, statistic(mean) xline(6) xlabel(0 "-5+ yrs" 1 "-4-5 yrs" 2 "-3-4 yrs" 3 "-2-3 yrs" 4 "-1-2 yrs" 5 "-6 mos-1 yr" 6 "Time of switch" 7 "<6 mos" 7 "<6 mos" 8 "6-12 mos" 9 "12+ mos", valuelabel) errortype(iqr)  saving(wtaavggen, replace)
*******Time as categorical variable************************************************ 
*use this variable for the actual modeling 

label var tldt "Time from TLD switch"*another tld time points variable (before, 0, after) use this variable for the plots
gen tldt=0 if dur_tld<-5 
replace tldt=1 if dur_tld>=-5 & dur_tld<-4
replace tldt=2 if dur_tld>=-4 & dur_tld<-3
replace tldt=3 if dur_tld>=-3 & dur_tld<-2
replace tldt=4 if dur_tld>=-2 & dur_tld<-1
replace tldt=5 if dur_tld>=-1 & dur_tld<0
replace tldt=6 if dur_tld>=-0 & dur_tld<.5
replace tldt=7 if dur_tld>=.5 & dur_tld<1
replace tldt=8 if dur_tld>=1 & dur_tld!=.
label def tldte 0 "-5+ yrs" 1 "-4-5 yrs" 2 "-3-4 yrs" 3 "-2-3 yrs" 4 "-1-2 yrs" 5 "-6 mos-1 yr" 6 "-<6 mos" 7 "<6 mos" 8 "6-12 mos" 9 "12+ mos"
label val tldt tldte
label var tldt "Time from TLD switch"


/*Weight change models*/
mixed wt ib7.tldtb if tld==1|| subjid: visit , cov(un) noconst  mle 
margins i.tldt
marginsplot, x(tldt) yti("Weight (kg)") xline(6.5) xlabel(, labsize(small)) xscale(range(-0.25 3.25)) title("Average change in weight")saving(wtplot, replace)
mixed wt i.gender if tld==1|| subjid: visit , cov(un) noconst  mle 
mixed wt i.agec if tld==1|| subjid: visit , cov(un) noconst  mle 
mixed wt i.progid if tld==1|| subjid: visit , cov(un) noconst  mle 
mixed wt i.depress if tld==1|| subjid: visit , cov(un) noconst  mle 

*Figure 1 data
mixed wt i.tldt##i.agec if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt agec)
marginsplot, x(tldt) yti("Weight (kg)") xline(6.5) xlabel(, labsize(small)) xscale(range(-0.25 3.25)) title("Age at visit")saving(wtageplot, replace)

mixed wt i.tldt##i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt gender)
marginsplot, x(tldt) yti("Weight (kg)")  xline(6.5) xlabel(, labsize(small))  xscale(range(-0.25 3.25)) title("Sex") saving(wtgenplot, replace)


mixed wt i.tldt##i.pretld if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt pretld)
marginsplot, x(tldt) yti("Weight (kg)") xline(6.5) xlabel(, labsize(small)) xscale(range(-0.25 3.25)) title("Previous regimen") saving(wtpregplot, replace)

mixed wt i.tldt##i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt progid) 
marginsplot, x(tldt) yti("Weight (kg)") xline(6.5) xlabel(, labsize(small)) xscale(range(-0.25 3.25)) title("Study site") saving(wtprogidplot, replace)

graph combine  wtgenplot.gph wtageplot.gph wtprogidplot.gph wtpregplot.gph, rows(2) cols(2)  iscale(.48) saving(wt_comb, replace)


mixed wt ib7.tldtb i.gender i.agec  i.progid i.depress  if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins i.tldt
marginsplot, x(tldt) yti("Weight (kg)")  xscale(range(-0.25 3.25)) title("Average change in weight") saving(wtadj, replace)

*full model suppressed only
mixed wt i.tldt i.gender i.agec i.progid i.pretld   if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle 
margins i.tldt
marginsplot, x(tldt) yti("Weight (kg)")  xscale(range(-0.25 2.25)) title("Average Weight after TLD Switch")saving(wtadjvs, replace)



/* BMI change models*/ 
mixed bmi ib7.tldtb if tldp==1|| subjid: visit , cov(un) noconst  mle 

mixed bmi ib7.tldtb i.gender i.agec  i.progid i.depress  if tldp==1|| subjid: visit , cov(un) noconst  mle 

mixed bmi i.tldt##i.agec if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt agec) 
marginsplot, x(tldt) yti("BMI (kg/m{sup:2})")  xscale(range(-0.25 2.25)) title("Age") saving(bmiageplot, replace)

mixed bmi i.tldt##i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt i.gender)
marginsplot, x(tldt) yti("BMI (kg/m{sup:2})")  xscale(range(-0.25 2.25)) title("Gender") saving(bmigenplot, replace)

mixed bmi i.tldt##i.pretld if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt pretld) 
marginsplot, x(tldt) yti("BMI (kg/m{sup:2})")  xscale(range(-0.25 2.25)) title("Previous regimen") saving(bmipretld, replace)

mixed bmi i.tldt##i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt progid)
marginsplot, x(tldt) yti("BMI (kg/m{sup:2})")  xscale(range(-0.25 2.25)) title("Study site") saving(bmiprogidplot, replace)

graph combine bmigenplot.gph bmiageplot.gph  bmiprogidplot.gph  bmipretld.gph, rows(2) cols(2)  iscale(.48) saving(bmi_comb, replace)

*WHR models
mixed wh ib7.tldtb if tldp==1|| subjid: visit , cov(un) noconst  mle 

mixed wh ib7.tldtb i.gender i.agec  i.progid i.depress  if tldp==1|| subjid: visit , cov(un) noconst  mle 

mixed wh i.tldt##i.agec if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt agec) 
marginsplot, x(tldt) yti("WHR")  xscale(range(-0.25 2.25)) title("Age") saving(whrageplot, replace)

mixed wh i.tldt##i.gender if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt i.gender)
marginsplot, x(tldt) yti("WHR")  xscale(range(-0.25 2.25)) title("Gender") saving(whrgenplot, replace)

mixed wh i.tldt##i.pretld if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt pretld) 
marginsplot, x(tldt) yti("WHR")  xscale(range(-0.25 2.25)) title("Previous regimen") saving(whpretld, replace)

mixed wh i.tldt##i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt progid)
marginsplot, x(tldt) yti("WHR")  xscale(range(-0.25 2.25)) title("Study site") saving(whrprogidplot, replace)

graph combine whrgenplot.gph whrageplot.gph  whrprogidplot.gph  whpretld.gph, rows(2) cols(2)  iscale(.48) saving(whr_comb, replace)


*full model among VS
mixed bmi i.tldt i.gender i.agec  i.progid i.pretld   if tldp==1 & vs==1 || subjid: visit , cov(un) noconst  mle 
margins i.tldt
marginsplot, x(tldt) yti("BMI (kg/m {sup:2})")  xscale(range(-0.25 2.25)) title("Average BMI change ") saving(bmiadjvs, replace)
egen pin = group(subjid), label

*additional figure for dr. ake DP slides

bysort tldt: sum wt if tldp==1, detail
bysort tldt agec: sum wtch if tldp==1, detail
bysort tldt gender: sum wtch if tldp==1, detail
bysort tldt progid: sum wt if tldp==1, detail
bysort tldt pretld: sum wtch if tldp==1, detail
lgraph wt tldt if tldp==1, statistic(median) errortype(iqr)  xscale(range(-0.25 3.25)) xlabel(0 "Pre-switch" 1 "<6 months" 2 "6-12 months" 3 "12+ months", valuelabel) saving(wtmed, replace)
lgraph wt dur_tld agec if tldp==1, statistic(median) errortype(iqr) xscale(range(-0.25 3.25)) xlabel(0 "Pre-switch" 1 "<6 months" 2 "6-12 months" 3 "12+ months", valuelabel) saving(wtmedage, replace)
lgraph wt tldt  gender if tldp==1, statistic(median) errortype(iqr) xscale(range(-0.25 3.25))  xlabel(0 "Pre-switch" 1 "<6 months" 2 "6-12 months" 3 "12+ months", valuelabel) saving(wtmedgen, replace)
lgraph wt tldt progid if tldp==1, statistic(median) errortype(iqr) xscale(range(-0.25 3.25)) xlabel(0 "Pre-switch" 1 "<6 months" 2 "6-12 months" 3 "12+ months", valuelabel) saving(wtmedprogid, replace)
lgraph wt tldt pretld if tldp==1, statistic(median) errortype(iqr)  xscale(range(-0.25 3.25)) xlabel(0 "Pre-switch" 1 "<6 months" 2 "6-12 months" 3 "12+ months", valuelabel)saving(wtmedpretld, replace)

/*gen group mean
mkspline xtld1 0 xtld2 = dur_tld, marginal
twoway (connected wt visit if tld==0) (connected wt visit if tld==1)
twoway scatter wt dur_tld if tld==1 & tstrt!=. & dur_tld<3, mcolor(*.6) || lfit wt dur_tld if tld==1 & tstrt!=. & dur_tld<3 || lowess wt dur_tld if tld==1 & tstrt!=. & dur_tld<3
twoway  lfitci wt dur_tld if tld==1 & tstrt!=. & dur_tld<3 || lowess wt dur_tld if tld==1 & tstrt!=. & dur_tld<3  
mixed wt i.dolutegravir##i.visit|| subjid: visit , cov(un) noconst  mle 
contrast dolutegravir#visit, effect
margins dolutegravir#visit
marginsplot, x(visit) saving(margplot)
predict y_fitted, fitted
sort subjid dolutegravir
twoway (connected y_fitted dolutegravir, connect msymbol(i) lpattern(dash) (ascending))  || (qfit y dolutegravir, lwidth(medthick)) , saving(modelreg)
mixed wt i.dolutegravir##i.visit i.agec i.gender i.artreg|| subjid: visit , cov(un) noconst  mle 

mixed wt i.visit##i.dolutegravir if tld==1|| subjid: visit , cov(un) noconst  mle 
margins i.visit##i.dolutegravir
marginsplot, x(visit) saving(margplot)
predict y_fitted, fitted
sort subjid dolutegravir
twoway (connected y_fitted dolutegravir, connect msymbol(i) lpattern(dash) (ascending))  || (qfit y dolutegravir, lwidth(medthick)) , saving(modelreg)
*creating a figure

sort tld visit
twoway (scatter grpmean visit if tld==1, connect(ascending) msymbol(T) lpattern(dash)) ///
	(scatter grpmean visit if tld==0, connect(ascending) ), saving("program",replace) legend(order(1 "TLD" 2 "No TLD")) title("Weight over time by TLD group")

	twoway lowess wt visit if tld==1 || lowess wt visit if tld==0, saving("lowess",replace) legend(order(1 "TLD" 2 "No TLD")) title("Weight over time by TLD group")
twoway lfitci wt dur_tld if tld==1 & tstrt!=. & dur_tld<3 || lowess wt dur_tld if tld==1 & tstrt!=. & dur_tld<3, color(145) lw(thick)  , saving("lowesstld",replace) ytitle("Weight (kg)") title("Weight before/after TLD switch")
twoway lfitci wt dur_tld if tld==1  & tstrt!=. & dur_tld<3 , saving("lfit",replace)  title("Lowess curve weight before/after TLD switch")
sort tldnaive tldc


twoway (scatter meanwt tldc if tldnaive==0 & tld==1 & tstrt!=. & dur_tld<3 , connect(ascending) msymbol(T) lpattern(dash)),  saving("mean",replace)  title("Change in weight before/after TLD") xtitle("Time since TLD initiation (yrs)") ytitle("Weight (kg)")

mixed wt i.tldv if tld==1|| subjid: visit , cov(un) noconst  mle 
*/
*BOX PLOTS

bysort subjid: gen wtch12=wt-wt[_n-3]
gen gage=0 if agec==0 & gender==1
replace gage=1 if agec==0 & gender==2
replace gage=2 if agec==1 & gender==1
replace gage=3 if agec==1 & gender==2
replace gage=4 if agec==2 & gender==1
replace gage=5 if agec==2 & gender==2
replace gage=6 if agec==3 & gender==1
replace gage=7 if agec==3 & gender==2
label def gageb 0 "18-29" 2 "30-39" 4 "40-49" 6 "50+"
label val gage gageb
graph box wtch12 if tldp==1 & tldt==3, o(gage)
graph box wtch12 gender if tldp==1 & tldt==3, o(gage)
graph box wtf wtm if tldp==1 & tldt==3, o(gage) ytitle("Weight change (kg)") saving(mfboxplot.gph,replace)

graph box wtch12 if tldp==1 & tldt==3, o(agec) ytitle("Weight change (kg)") saving(ageboxplot.gph,replace)
graph box wtch12 if tldp==1 & tldt==3, o(gender) ytitle("Weight change (kg)") saving(genderplot.gph,replace)

*adding waist to hip ratio plots
lgraph wh tldt if tldp==1 & tldt>5, statistic(median) errortype(iqr)  xscale(range(6, 9.25)) xlabel(6 "Pre-switch" 7 "<6 months" 8 "6-12 months" 9 "12+ months", valuelabel) saving(whmed, replace)
lgraph wh tldt agec if tldp==1, statistic(median) errortype(iqr) xscale(range(-0.25 3.25)) xlabel(0 "Pre-switch" 1 "<6 months" 2 "6-12 months" 3 "12+ months", valuelabel) saving(whmedage, replace)
lgraph wt durtldi  gender if tldp==1 & dur_tld<2, statistic(mean) xlabel(0 "-5+ yrs" 1 "-4-5 yrs" 2 "-3-4 yrs" 3 "-2-3 yrs" 4 "-1-2 yrs" 5 "-6 mos-1 yr" 6 "Time of switch" 7 "<6 mos"  8 "6-12 mos" 9 "12+ mos", valuelabel) errortype(iqr)  saving(wtaavggen, replace)
lgraph wh tldt progid if tldp==1, statistic(median) errortype(iqr) xscale(range(-0.25 3.25)) xlabel(0 "Pre-switch" 1 "<6 months" 2 "6-12 months" 3 "12+ months", valuelabel) saving(whmedprogid, replace)
lgraph wh tldt pretld if tldp==1, statistic(median) errortype(iqr)  xscale(range(-0.25 3.25)) xlabel(0 "Pre-switch" 1 "<6 months" 2 "6-12 months" 3 "12+ months", valuelabel)saving(whmedpretld, replace)

lgraph wh tldt if tldp==1 & tldt>5, statistic(median) errortype(iqr)  xscale(range(6, 9.25)) xlabel(6 "Pre-switch" 7 "<6 months" 8 "6-12 months" 9 "12+ months", valuelabel) || lgraph wh tldt if tldp==1 & tldt>5 & gender==1, statistic(median) errortype(iqr)  xscale(range(6, 9.25)) xlabel(6 "Pre-switch" 7 "<6 months" 8 "6-12 months" 9 "12+ months", valuelabel)
/*
gen time=0 if (visitdt-consendt)/365.25>=5 & tldt==0
replace time=1 if (visitdt-consendt)/365.25>=4 & (visitdt-consendt)/365.25<5  & tldt==0
replace time=2 if (visitdt-consendt)/365.25>=3 & (visitdt-consendt)/365.25<4  & tldt==0
replace time=3 if (visitdt-consendt)/365.25>=2 & (visitdt-consendt)/365.25<3  & tldt==0
replace time=4 if (visitdt-consendt)/365.25>=1 & (visitdt-consendt)/365.25<2  & tldt==0
replace time=5 if (visitdt-consendt)/365.25>=.5 & (visitdt-consendt)/365.25<1  & tldt==0
replace time=6 if (visitdt-consendt)/365.25>=0 & (visitdt-consendt)/365.25<.5  & tldt==0
replace time=7 if tldt==1
replace time=8 if tldt==2
replace time=9 if tldt==3
*/

*waist hip ratio models*//*Weight change models*/
mixed wh i.tldt if tld==1|| subjid: visit , cov(un) noconst  mle 
margins i.tldt
marginsplot, x(tldt) yti("Waist hip ratio")  xscale(range(-0.25 3.25)) title("")saving(whplot, replace)

mixed wh i.tldt##i.agec if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt agec)
marginsplot, x(tldt) yti("Waist hip ratio")  xscale(range(-0.25 3.25)) title("")saving(whageplot, replace)

mixed wh i.tldt##i.gender if tldp==1 & tldt>5|| subjid: visit , cov(un) noconst  mle 
lincom 9.tldt + 9.tldt#2.gender
margins, over(tldt gender)
marginsplot, x(tldt) yti("Waist hip ratio")  xscale(range(5.75 9.25)) title("") saving(whgenplot, replace)


mixed wh i.tldt##i.pretld if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt pretld)
marginsplot, x(tldt) yti("Waist hip ratio")  xscale(range(-0.25 3.25)) title("") saving(whpregplot, replace)

mixed wh i.tldt##i.progid if tldp==1|| subjid: visit , cov(un) noconst  mle 
margins, over(tldt progid) 
marginsplot, x(tldt) yti("Waist hip ratio")  xscale(range(-0.25 3.25)) title("") saving(whprogidplot, replace)

mixed wh i.tldt i.gender i.agec  i.progid i.pretld   if tldp==1|| subjid: visit , cov(un) noconst  mle 


