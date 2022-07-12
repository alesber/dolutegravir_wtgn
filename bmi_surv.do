cd "C:\Users\aesber\Box Sync\Shared Files- Reed and Esber\TLD\weight change"
use bmi_surv.dta, clear
sort subjid visit

drop if currpreg==1

/*changing seroconverters to DTG status */replace status=2 if subjid=="A01-0324" | subjid=="C01-0194" | subjid=="C01-0285"
bysort subjid: replace status=0 if status!=[_n-1] & status[_n-1]==0 & dolutegravir!=1
bysort subjid: gen flag=1 if status!=status[_n-1] 
gsort subjid -visit



label var gender "Gender"
label def gender 1 "Male" 2 "Female"
label val gender gender

label var progid "Study site"
label define progid3 1  "Kayunga, Uganda" 2"South Rift Valley, Kenya" 3 "Kisumu West, Kenya" 4 "Mbeya, Tanzania" 5 "Abuja & Lagos Nigeria"
label val progid progid3



*recoding education
gen edu_cat=0 if educat==0 | educat==1
replace edu_cat=1 if educat==3 | educat==2
replace edu_cat=2 if educat>3 & educat!=.
label define edu_cat 0 "None or some primary" 1 "Primary or some secondary" 2 "Secondary and above"
label val edu_cat edu_cat
label var edu_cat "Education"


*agecat at baseline

gen ageb=0 if age<30
replace ageb=1 if age>29 & age<40
replace ageb=2 if age>39 & age<50
replace ageb=3 if age>50 & age!=.
label def agec 0 "18-29" 1 "30-39" 2 "40-49" 3 "50+"
label val ageb agec
label var ageb "Age at baseline"

label def yn 0 "No" 1 "Yes"


mkspline age0 30 age1 40 age2 50 age3 = age 
*dropping visits after event occurred 
bysort subjid: carryforward pop, gen(newpop)
drop if newpop==.
drop newpop
keep if pop==1 | flag==1
sort subjid visit
bysort subjid: egen flagto=sum(flag) 
*check for participants with flagto>3
list subjid visit status if flagto==4


drop if flagto==1 & pop!=1
sort subjid visit
bysort subjid: gen n=_n

sort subjid visit
gen tldstart=date(astartdt, "MY") if dolutegravir==1
format tldstart %d
*replacing artstart date if art_sdtn is missing
gen astartn=date(astartdt, "MY")
format tldstart %d
gen startn=date(startdt, "MY")
format tldstart %d
replace art_sdtn=astartn if art_sdtn==. & astartn<startn
replace art_sdtn=startn if art_sdtn==.

*droppign people with 2 tld visits
bysort subjid: egen tldtot=sum(dolutegravir)
gsort subjid -visit
bysort subjid: gen tldn=_n


drop if tldn==2 & tldtot==2

bysort subjid: gen N=_N
sort subjid visit

gen enter=consendt if flagto==1 & pop==1


*generating enter and exit dates
/* flagto=1: HIV- or HIV on ART at all visits
	flagto=2: HIV on ART --> HIV TLD OR HIV naive --> HIV on ART
	flagto=3: HIV Naive --> HIV On ART --> HIV TLD*/

/*flagto2*/ 
replace enter=visitdt if flagto==2  & n==1
replace enter=visitdt[_n-1] if flagto==2  & n==3
replace enter=tldstart if flagto==2 & n==2 & status==2
/*flagto3*/ 
replace enter=visitdt if flagto==3 & (n==1 | n==2)
replace enter=tldstart if flagto==3 & n==3

gen exit=visitdt if flagto==1 & pop==1 
/*flagto2*/
replace exit=visitdt[_n+1] if flagto==2 & n==1
replace exit=visitdt if flagto==2 & n==3
replace exit=tldstart[_n+1] if flagto==2 & n==1 & status==0
replace exit=visitdt if flagto==2 & n==2 & status==2

/*flagto3*/
replace exit=visitdt[_n+1] if flagto==3 & n==1
replace exit=tldstart[_n+1] if flagto==3 & n==2
replace exit=visitdt if flagto==3 & n==3
format enter exit %d

replace exit=art_sdtn if n==1 & flagto==2 & N==2 & enter[_n+1]==.
replace enter=art_sdtn if n==2 & flagto==2 & N==2 & enter==.
replace exit=visitdt  if n==2 & flagto==2 & N==2 & enter==.


replace enter=tldstart if tldn==1 & tldtot==2
replace enter=tldstart if tldn==1 & tldtot==2
replace exit=visitdt if tldn==1 & tldtot==2
bysort subjid: replace exit=art_sdtn[_n+1] if status==1 & exit==.
replace exit=visitdt if status==0 & exit==.
bysort subjid: drop if status==status[_n+1] & enter==.

gen t1=(enter-consendt)/365.25
replace t1= (enter-visitdt)/365.25 if visit==1
gen t2=exit-consendt


gen time=(exit-enter)/365.25
replace time=(exit-enter)/365.25

replace time=t1+time if n==1 & t1!=0

bysort subjid: egen ttime=sum(time)
replace ttime=time if n==1
bysort subjid: replace ttime=time+time[_n-1] if n==2

/*SOME ARE MISSING CONSENDT NEED TO FILL IN MANUALLY (N=10ISH)*/

stset ttime if hivflag==1, fail(overweight) id(subjid) time0(t1) 
/*fixes the rounding issue*/ replace t1=t1+.00001 if _st==0 & visit!=1 & hivflag==1
*rerunning with all participants
stset ttime, fail(overweight) id(subjid) time0(t1) 
stcox i.status if progid==5, nolog
stcox i.status if progid==4, nolog
stcox i.status if progid==3, nolog
stcox i.status if progid==2, nolog
stcox i.status if progid==1, nolog
stcox i.status, nolog
estat phtest
stcox i.gender, nolog
estat phtest
stcox age0 age1 age2 age3, nolog
estat phtest
stcox i.progid, nolog
estat phtest 

stcox i.status i.gender age0 age1 age2 age3  i.progid,  nolog

*table 1 for slides
gsort subjid -dolutegravir
gen tld=1 if dolutegravir==1
bysort subjid: carryforward tld, replace
replace tld=0 if tld==.
sort subjid visit
table1 if (num==1 & hivflag==1 & _st==1), by(tld) vars(gender cat \ progid cat  \ agec cat \ depress cat \ edu_cat cat \ cd4_cat cat \ vs cat) one missing sav("tabl1ow.xlsx", replace)  
table1 if (num==1 & hivflag==1 & _st==1), vars(gender cat \ progid cat \ agec cat \ depress cat \ edu_cat cat \ cd4_cat cat \ vs cat) one missing sav("tabltot1ow.xlsx", replace)  

sts graph, by(status) legend(order(1 "HIV/ART" 2 "HIV/No ART" 3 "HIV/TLD" 4 "No HIV")) xti("Time (days)") scheme(s2mono) 
sts test status  , wilcox
*Calculating incidence rates
stset ttime , fail(overweight) id(subjid) time0(t1)
 stptime,by(status) per(1000)
  stptime if progid==1,by(status) per(1000)
   stptime if progid==2,by(status) per(1000)
    stptime if progid==3,by(status) per(1000)
	 stptime if progid==4,by(status) per(1000)
	  stptime if progid==5,by(status) per(1000)
	  stptime, per(1000)

	  
	  
	  *****************************OLD CODE********************************************************************
	  stset ttime if hivflag==1, fail(overweight) id(subjid) time0(t1) 
stcox i.status if progid==5, nolog
stcox i.status if progid==4, nolog
stcox i.status if progid==3, nolog
stcox i.status if progid==2, nolog
stcox i.status if progid==1, nolog
stcox i.status, nolog
estat phtest
stcox i.gender, nolog
estat phtest
stcox i.ageb, nolog
estat phtest
stcox i.progid, nolog
estat phtest 
stcox i.depress, nolog
estat phtest 
stcox i.status i.gender i.ageb  i.progid,  nolog

*additional data for slides
gen tld_dur=visitdt-tldstart if dolutegravir==1
sum tld_dur if hivflag==1 & dolutegravir==1, detail

*additional data for dr. ake presentation
