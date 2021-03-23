
cd "D:\OneDrive - Université Paris-Dauphine\Tesis\"

*==========================================================================================
*									ECONOMETRICS
*==========================================================================================

use .\data\econometrics\summary_statistics, clear

* 0 - Preprocessing
capture drop Departement
encode DEP, gen(Departement)
xtset Departement qtime  
sort DEP qtime

* Neighbour 
gen big_neighbour50=(max_decree>50 & max_decree~=.)
gen big_neighbour75=(max_decree>50 & max_decree~=.)
gen big_neighbour90=(max_decree>50 & max_decree~=.)

* Lags
forvalues i=1(1)8 {
	*by DEP: gen big_decree30_`i'=big_decree30[_n-`i']
	by DEP: gen big_decree50_`i'=big_decree50[_n-`i']
	by DEP: gen big_decree75_`i'=big_decree75[_n-`i']
	by DEP: gen big_decree90_`i'=big_decree90[_n-`i']
	by DEP: gen big_rain50_`i'= big_rain50[_n-`i']
}
* Firms bankruptcies 
foreach var in "B" "C" "F" "G" "H" "I" "J" "K" "L" "M" "N" "Q" "R" "S" {
	gen p_proc`var' = (n_proc`var'/n_firm`var')*100
	gen p_L`var' = (n_L`var'/n_firm`var')*100
	gen p_R`var' = (n_R`var'/n_firm`var')*100
	gen p_S`var' = (n_S`var'/n_firm`var')*100
}

* Firm size 
foreach x in "B" "C" "F" "G" "H" "I" "J" "K" "L" "M" "N" "Q" "R" "S" {
	gen p_TPE_`x' = p_0sal`x' + p_1a2sal`x' + p_3a5sal`x' + p_6a9sal`x'
	gen p_PME_`x' = p_10a19sal`x' + p_20a49sal`x' + p_50a99sal`x' + p_100a199sal`x' + p_200a249sal`x'
	gen p_ETI_`x' = p_250a499sal`x' + p_500a999sal`x' + p_1000a1999sal`x' + p_2000a4999sal`x'
	gen p_GE_`x' = p_5000a9999sal`x' + p_10000psal`x' 
}
* Lagged value AR(4) to catch seasonnality 
sort DEP qtime
foreach x in "B" "C" "F" "G" "H" "I" "J" "K" "L" "M" "N" "Q" "R" "S" {
	by DEP: gen p_proc`x'_2= p_proc`x'[_n-2]
	by DEP: gen p_L`x'_2= p_L`x'[_n-2]
	by DEP: gen p_R`x'_2= p_R`x'[_n-2]
	by DEP: gen p_proc`x'_3= p_proc`x'[_n-3]
	by DEP: gen p_L`x'_3= p_L`x'[_n-3]
	by DEP: gen p_R`x'_3= p_R`x'[_n-3]
	by DEP: gen p_proc`x'_4= p_proc`x'[_n-4]
	by DEP: gen p_L`x'_4= p_L`x'[_n-4]
	by DEP: gen p_R`x'_4= p_R`x'[_n-4]
}
* Some places we could exclude from the analysis because of their characteristics
gen alsace=(DEP=="57" | DEP=="67" | DEP=="68") /* independant law system */
gen paris=(DEP=="75") /* macrocephalie */
gen election=(year==2009 | year==2014) /* municipal elections */

* Stationnarized regressors 
sort DEP qtime
by DEP: gen d_POP=POP[_n]/POP[_n-1]-1
by DEP: gen d_BN_TFPB=BN_TFPB/BN_TFPB[_n-1]-1
by DEP: gen d_BN_TFPB_POP=BN_TFPB_POP/BN_TFPB_POP[_n-1]-1
foreach x in "B" "C" "F" "G" "H" "I" "J" "K" "L" "M" "N" "Q" "R" "S" {
by DEP: gen d_n_firm`x'=(n_firm`x'/n_firm`x'[_n-1])-1
}
* Leads
sort DEP qtime
forvalues i=1(1)4 {
	by DEP: gen big_decree50_lead`i'=big_decree50[_n+`i']
	by DEP: gen big_decree90_lead`i'=big_decree90[_n+`i']
	by DEP: gen big_rain50_lead`i'= big_rain50[_n+`i']
}
save .\data\econometrics\regressions_quarter, replace

* 1 - Base specification with all event types
use .\data\econometrics\regressions_quarter, clear

* Decrees
*===================== TABLE I =============================================== 
* Reminder: F is construction, G is wholesale, retail and shops, I is hotels restaurants... 
foreach x in "F" "G" "H" "I" "N" { 
rename (p_TPE_`x' p_PME_`x' p_ETI_`x' share_`x' d_n_firm`x') (p_TPE p_PME p_ETI share d_nfirm)
sum p_proc`x', d
local aver = `r(mean)'
xtreg p_proc`x' big_decree50 p_TPE p_PME p_ETI share d_nfirm d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
outreg2 using .\data\econometrics\regression_decree_sector_comparisons.tex, tex(frag pretty) append addstat(F-stat, `e(F)', "Ind. var. mean", `aver') /// /**/
keep(p_proc`x' big_decree50 /*p_TPE p_PME p_ETI share nfirm d_POP d_BN_TFPB*/) ctitle("`x'") ///
groupvar(big_decree50 /*p_TPE p_PME p_ETI share nfirm d_POP d_BN_TFPB*/) ///
title("Impact of natural events (demand shocks) on insolvency proceedings", ///
"in different sectors: 2008-2018") addtext(Quarter-year FE, YES, Departement FE, YES, Firm type, All)
rename (p_TPE p_PME p_ETI d_nfirm share) (p_TPE_`x' p_PME_`x' p_ETI_`x' d_n_firm`x' share_`x')
}
*=============================================================================== 

* 2 - Insolvency types
*===================== TABLE II (PART I) =======================================
foreach x in "L" "R" "S" { 
	rename (p_TPE_F p_PME_F p_ETI_F share_F d_n_firmF) (p_TPE p_PME_F p_ETI_F share_F d_nfirm)
	sum p_`x'F, d
	local aver = `r(mean)'
	xtreg p_`x'F big_decree50 p_TPE p_PME_F p_ETI_F share_F d_nfirm d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
	outreg2 using .\data\econometrics\decree_insolvency_comparisons.tex, tex(frag pretty) append addstat(F-stat, `e(F)', "Ind. var. mean", `aver') /// /**/
	keep(p_`x'F big_decree50) ctitle("`x'") groupvar(big_decree50) ///
	title("Impact of natural events (demand shocks) on insolvency and", ///
	"economic conditions: 2008-2018") addtext(Quarter-year FE, YES, Departement FE, YES)
	rename (p_TPE p_PME_F p_ETI_F share_F d_nfirm) (p_TPE_F p_PME_F p_ETI_F share_F d_n_firmF)
}
*=============================================================================== 

* 3 - Neighbourhood effect 
*===================== TABLE III =============================================== 
foreach i in 50 75 90 {
	rename (p_TPE_F p_PME_F p_ETI_F d_n_firmF share_F) (p_TPE p_PME p_ETI d_nfirm share) 
	sum p_LF, d
	local aver = `r(mean)'
	gen decree=big_decree`i'
	gen decree_1=big_decree`i'_1
	gen neighbour=big_neighbour`i'
	xtreg p_LF decree decree_1 neighbour p_TPE p_PME p_ETI share d_nfirm d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
	outreg2 using .\data\econometrics\neighbourhood_effects.tex, tex(frag pretty) append addstat(F-stat, `e(F)', "Ind. var. mean", `aver') /// /**/
	keep(p_LF decree decree_1 neighbour) ctitle("p_hit>`i'") groupvar(decree decree_1 neighbour) ///
	title("Impact of natural events with neighbourhood effects on liquidation", ///
	"by disaster magnitude: 2008-2018") addtext(Quarter-year FE, YES, Departement FE, YES)
	drop decree decree_1 neighbour 
	rename (p_TPE p_PME p_ETI d_nfirm share) (p_TPE_F p_PME_F p_ETI_F d_n_firmF share_F)
}
*=============================================================================== 

* 4 - Other outcomes
gen depvar=.
*===================== TABLE II (PART II) ======================================
foreach var in dpaeF n_jobsF wage_capitaF new_contractsF {
replace depvar=`var'
sum depvar
local aver=`r(mean)'
xtreg depvar big_decree50 p_TPE_F p_PME_F p_ETI_F share_F d_n_firmF d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
outreg2 using .\data\econometrics\decree_insolvency_comparisons.tex, tex(frag pretty) append addstat(F-stat, `e(F)', "Ind. var. mean", `aver') /// /**/
keep(depvar big_decree50) ctitle("`var'") groupvar(big_decree50) ///
title("Impact of natural events (demand shocks) on different outcomes", ///
"in the construction sector: 2008-2018") addtext(Quarter-year FE, YES, Departement FE, YES)
}
*=============================================================================== 

* 5 - Autocorrelation (at the Département level)
xtserial p_procF big_decree50 p_TPE_F p_PME_F p_ETI_F d_n_firmF share_F d_BN_TFPB POP if year>2007 & year<2019
* By Département
xtreg p_procF big_decree50 p_TPE_F p_PME_F p_ETI_F share_F d_n_firmF d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
capture drop res
predict res, resid 
label variable res "Residuals"
* Depending on the Département, the residuals may be positive or negative 
*===================== APPENDIX ================================================
levelsof DEP, local(dep)
foreach var of local dep {
	twoway line res qtime if DEP=="`var'" & year>2007 & year<2019, title("Residuals - `var'") graphregion(color(white))  
	graph export ".\graphs\autocorrelation_residuals\auto_corr_`var'.png", as(png) replace
	pac res if DEP=="`var'" & year>2007 & year<2019, srv title("Partial Auto-Correlagram - `var'") graphregion(color(white))  
	graph export ".\graphs\autocorrelation_residuals\pac_`var'.png", as(png) replace
}
*=============================================================================== 
* Normality 
hist res, bin(100) normal lcolor(white) color(ltblue)

* 6 - Placebos 
* 6.1 - Decree placebos with leads
sort DEP qtime 
*===================== TABLE V ============================================
forvalues i=1(1)4 {
	sum p_LF, d
	local aver=`r(mean)'
	gen lead = big_decree50_lead`i'
	xtreg p_LF lead p_TPE_F p_PME_F p_ETI_F share_F d_n_firmF d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
	outreg2 using .\data\econometrics\placebo_regression.tex, tex(frag pretty) append addstat(F-stat, `e(F)', "Ind. var. mean", `aver') /// /**/
	keep(p_LF lead) ctitle("`i' period before") groupvar(lead) ///
	title("Placebos effect on insolvency proceedings", ///
	"in the construction sector: 2008-2018") addtext(Quarter-year FE, YES, Departement FE, YES)
	drop lead
}
forvalues i=1(1)4 {
	sum p_LF, d
	local aver=`r(mean)'
	gen lead = big_decree50_`i'
	xtreg p_LF lead p_TPE_F p_PME_F p_ETI_F share_F d_n_firmF d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
	outreg2 using .\data\econometrics\placebo_regression.tex, tex(frag pretty) append addstat(F-stat, `e(F)', "Ind. var. mean", `aver') /// /**/
	keep(p_LF lead) ctitle("`i' period after") groupvar(lead) ///
	title("Placebos effect on insolvency proceedings", ///
	"in the construction sector: 2008-2018") addtext(Quarter-year FE, YES, Departement FE, YES)
	drop lead
}
* All in one regression
xtreg p_LF big_decree50_lead1 big_decree50_lead2 big_decree50_lead3 ///
big_decree50_lead4 big_decree50_1 big_decree50_2 big_decree50_3 big_decree50_4 ///
p_TPE_F p_PME_F p_ETI_F share_F d_n_firmF d_POP d_BN_TFPB_POP  ///
i.qtime if year>2007 & year<2019, fe vce(robust)
* I input the results into the precedent table in another row (by hand)
*===============================================================================

*===================== APPENDIX ? ============================================
xtreg p_LF big_decree50_lead4 big_decree50_lead8 ///
big_decree50_lag4 big_decree50_lag8 /// 
p_TPE_F p_PME_F p_ETI_F share_F d_n_firmF d_POP d_BN_TFPB_POP  ///
i.qtime if year>2007 & year<2019, fe vce(robust)
*===============================================================================

* 6.2 - Bootstrap 
* Handmade bootstrapping - decree 50% of municipalities
use .\data\econometrics\regressions_quarter, clear
set matsize 11000
set seed 123456789
local counter=0
matrix coefficients_decree = J(10000, 1, 0)
matrix pvalues_decree = J(10000, 1, 0)
matrix sterrors_decree = J(10000, 1, 0)
capture drop treat* y_treated
sort DEP year
by DEP year: egen y_treated=max(big_decree50)
forval i=1(1)10000 {
	quietly: sum big_decree50
	quietly: gen treat`i'=runiform()<=`r(mean)' if y_treated==0
	quietly: replace treat`i'=0 if treat`i'==. & y_treated==1
	quietly: xtreg p_LF treat`i' p_TPE_F p_PME_F p_ETI_F share_F d_n_firmF d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
	matrix coefficients_decree[`i', 1] = _b[treat`i'] /* coefficient stocks */
	matrix sterrors_decree[`i', 1] = _se[treat`i'] /* coefficient stocks */
	matrix pvalues_decree[`i', 1] = 2 * ttail(e(df_r), abs(_b[treat`i']/_se[treat`i'])) /* pvalues stocks confidence interval */
	if 2 * ttail(e(df_r), abs(_b[treat`i']/_se[treat`i']))<=0.05 {
		local counter=`counter'+1 
	}
	quietly : drop treat`i'
	disp(`i')
}
disp(`counter'/10000)
svmat coefficients_decree
svmat sterrors_decree
svmat pvalues_decree
save .\data\econometrics\regressions_quarter_bootstrap50, replace
use .\data\econometrics\regressions_quarter_bootstrap50, clear
count if coefficients_decree<-0.108
count if pvalues_decree<0.05
count if pvalues_decree<0.05 & coefficients_decree<0
*===================== FIGURE  ===============================================
hist coefficients_decree if pvalues>0, xline(-0.108, lcolor(green)) color(ebblue) lcolor(white) graphregion(color(white))  ///
/*title("Coefficient distribution after bootstrap randomization of treatment group", size(medium))*/ ///
xtitle("Bootstrap regression coefficients") ///
note("Note : vertical lines for coefficients when 50% of the municipalities are hit")
graph export ".\graphs\bootstrap_coefficient_distribution_decree50.png", as(png) replace
*===============================================================================
*===================== APPENDIX ===============================================
hist pvalues_decree if pvalues>0, xline(0.006, lcolor(green)) color(ebblue) lcolor(white) graphregion(color(white)) ///
/*title("P-values distribution after bootstrap randomization of treatment group", size(medium))*/ ///
xtitle("Bootstrap regression pvalues") ///
note("Note : vertical lines for coefficients when 50% of the municipalities are hit")
graph export ".\graphs\bootstrap_pvalues_distribution_decree50.png", as(png) replace
*===============================================================================

* Handmade bootstrapping - decree 90% of municipalities
use .\data\econometrics\regressions_quarter, clear
set matsize 11000
set seed 123456789
local counter=0
matrix coefficients_decree = J(10000, 1, 0)
matrix pvalues_decree = J(10000, 1, 0)
matrix sterrors_decree = J(10000, 1, 0)
capture drop treat* y_treated
sort DEP year
by DEP year: egen y_treated=max(big_decree90)
forval i=1(1)10000 {
	quietly: sum big_decree90
	quietly: gen treat`i'=runiform()<=`r(mean)' if y_treated==0
	quietly: replace treat`i'=0 if treat`i'==. & y_treated==1
	quietly: xtreg p_LF treat`i' p_TPE_F p_PME_F p_ETI_F share_F d_n_firmF d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
	matrix coefficients_decree[`i', 1] = _b[treat`i'] /* coefficient stocks */
	matrix sterrors_decree[`i', 1] = _se[treat`i'] /* coefficient stocks */
	matrix pvalues_decree[`i', 1] = 2 * ttail(e(df_r), abs(_b[treat`i']/_se[treat`i'])) /* pvalues stocks confidence interval */
	if 2 * ttail(e(df_r), abs(_b[treat`i']/_se[treat`i']))<=0.05 {
		local counter=`counter'+1 
	}
	quietly : drop treat`i'
	disp(`i')
}
disp(`counter'/10000)
svmat coefficients_decree
svmat sterrors_decree
svmat pvalues_decree
save .\data\econometrics\regressions_quarter_bootstrap90, replace
use .\data\econometrics\regressions_quarter_bootstrap90, clear
count if coefficients_decree<-0.126621
count if pvalues_decree<0.05
count if pvalues_decree<0.05 & coefficients_decree<0
*===================== FIGURE  =================================================
hist coefficients_decree if pvalues>0, xline(-0.126621, lcolor(red)) color(ebblue) lcolor(white) graphregion(color(white))  ///
/*title("Coefficient distribution after bootstrap randomization of treatment group", size(medium))*/ ///
xtitle("Bootstrap regression coefficients") ///
note("Note : vertical red line for coefficients when 90% of the municipalities are hit")
graph export ".\graphs\bootstrap_coefficient_distribution_decree90.png", as(png) replace
*===============================================================================
*===================== APPENDIX ================================================
hist pvalues_decree if pvalues>0, xline(0.007, lcolor(red)) color(ebblue) lcolor(white) graphregion(color(white)) ///
/*title("P-values distribution after bootstrap randomization of treatment group", size(medium))*/ ///
xtitle("Bootstrap regression pvalues") ///
note("Note : vertical red line for pvalue when 90% of the municipalities are hit")
graph export ".\graphs\bootstrap_pvalues_distribution_decree90.png", as(png) replace
*===============================================================================

* 6.3 - Event study presentation of parallel trends 
* Which treated Departements 
tab qtime DEP if year>2007 & year<2019 & big_decree50==1
gen treated_2009q1=(DEP=="11" | DEP=="31" | DEP=="32" | DEP=="33" | DEP=="40" | DEP=="64" | DEP=="65" | DEP=="66")
gen treated_2010q1=(DEP=="17" | DEP=="79" | DEP=="85" | DEP=="86")
gen treated_2011q4=(DEP=="83")
gen treated_2016q2=(DEP=="41" | DEP=="45" | DEP=="91" | DEP=="92")
gen treated_2017q3=(DEP=="75")
gen treated_2018q1=(DEP=="75")
gen treated_2018q3=(DEP=="75")

sort Departement year 
local counter = 29
forvalues j = 2008(1)2018 {
	forvalues i = 1(1)4 {
		by Departement : gen base`j'q`i'=p_procF[`counter']
		gen p_procF_base`j'q`i'=p_procF/base`j'q`i'
		by Departement : gen baseL`j'q`i'=p_LF[`counter']
		gen p_LF_base`j'q`i'=p_LF/baseL`j'q`i'
		local counter=`counter'+1
	}
}
save .\data\econometrics\parallel_trends, replace

use .\data\econometrics\parallel_trends, clear /* 2009q1 - no parrallel trend */
*===================== FIGURE X / APPENDIX III =================================
collapse (mean) p_LF_*, by(treated_2009q1 qtime year)
twoway  (line p_LF_base2008q3 qtime if treated_2009q1==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2008q3 qtime if treated_2009q1==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(194) xline(196, lpattern(dash)) ///
		ytitle("Insolvency (base 2008q3)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2009q1_scale_2008q3.png", as(png) replace
twoway  (line p_LF_base2008q4 qtime if treated_2009q1==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2008q4 qtime if treated_2009q1==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(195) xline(196, lpattern(dash)) ///
		ytitle("Insolvency (base 2008q4)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2009q1_scale_2008q4.png", as(png) replace
use .\data\econometrics\parallel_trends, clear /* 2010q1 - parrallel trend */
collapse (mean) p_LF_*, by(treated_2010q1 qtime year)
twoway  (line p_LF_base2009q3 qtime if treated_2010q1==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2009q3 qtime if treated_2010q1==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(198) xline(200, lpattern(dash)) ///
		ytitle("Insolvency (base 2009q3)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2010q1_scale_2009q3.png", as(png) replace
twoway  (line p_LF_base2009q4 qtime if treated_2010q1==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2009q4 qtime if treated_2010q1==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(199) xline(200, lpattern(dash)) ///
		ytitle("Insolvency (base 2009q4)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2010q1_scale_2009q4.png", as(png) replace
use .\data\econometrics\parallel_trends, clear /*2011q2 - no parallel trend*/
collapse (mean) p_LF_*, by(treated_2011q4 qtime year)
twoway  (line p_LF_base2011q2 qtime if treated_2011q4==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2011q2 qtime if treated_2011q4==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(205) xline(207, lpattern(dash)) ///
		ytitle("Insolvency (base 2011q2)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2011q4_scale_2011q2.png", as(png) replace
twoway  (line p_LF_base2011q3 qtime if treated_2011q4==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2011q3 qtime if treated_2011q4==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(206) xline(207, lpattern(dash)) ///
		ytitle("Insolvency (base 2011q3)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2011q4_scale_2011q3.png", as(png) replace
use .\data\econometrics\parallel_trends, clear /* 2016q2 - parrallel trend */
collapse (mean) p_LF_*, by(treated_2016q2 qtime year)
twoway  (line p_LF_base2015q4 qtime if treated_2016q2==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2015q4 qtime if treated_2016q2==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(223) xline(225, lpattern(dash)) ///
		ytitle("Insolvency (base 2015q4)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2016q2_scale_2015q4.png", as(png) replace
twoway  (line p_LF_base2016q1 qtime if treated_2016q2==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2016q1 qtime if treated_2016q2==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(224) xline(225, lpattern(dash)) ///
		ytitle("Insolvency (base 2016q1)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2016q2_scale_2016q1.png", as(png) replace
use .\data\econometrics\parallel_trends, clear /* 2017q3 - parrallel trend */
collapse (mean) p_LF_*, by(treated_2017q3 qtime year)
twoway  (line p_LF_base2017q1 qtime if treated_2017q3==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2017q1 qtime if treated_2017q3==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(228) xline(230, lpattern(dash)) ///
		ytitle("Insolvency (base 2017q1)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2017q3_scale_2017q1.png", as(png) replace
twoway  (line p_LF_base2017q2 qtime if treated_2017q3==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2017q2 qtime if treated_2017q3==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(229) xline(230, lpattern(dash)) ///
		ytitle("Insolvency (base 2017q2)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2017q3_scale_2017q2.png", as(png) replace
use .\data\econometrics\parallel_trends, clear /* 2018q3 - no parrallel trend */
collapse (mean) p_LF_*, by(treated_2018q1 qtime year)
twoway  (line p_LF_base2017q3 qtime if treated_2018q1==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2017q3 qtime if treated_2018q1==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(230) xline(232, lpattern(dash)) ///
		ytitle("Insolvency (base 2017q3)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2018q1_scale_2017q3.png", as(png) replace
twoway  (line p_LF_base2017q4 qtime if treated_2018q1==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2017q4 qtime if treated_2018q1==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(231) xline(232, lpattern(dash)) ///
		ytitle("Insolvency (base 2017q4)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2018q1_scale_2017q4.png", as(png) replace
use .\data\econometrics\parallel_trends, clear /* 2018q3 - no parrallel trend */
collapse (mean) p_LF_*, by(treated_2018q3 qtime year)
twoway  (line p_LF_base2018q1 qtime if treated_2018q3==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2018q1 qtime if treated_2018q3==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(232) xline(234, lpattern(dash)) ///
		ytitle("Insolvency (base 2018q1)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2018q3_scale_2018q1.png", as(png) replace
twoway  (line p_LF_base2018q2 qtime if treated_2018q3==0 & year>2007 & year<2019, lcolor(black)) || ///
		(line p_LF_base2018q2 qtime if treated_2018q3==1 & year>2007 & year<2019, lcolor(black) lpattern(dash)), ///
		legend(order(1 "Control group" 2 "Treatment group")) xline(233) xline(234, lpattern(dash)) ///
		ytitle("Insolvency (base 2018q2)") graphregion(color(white))
graph export ".\graphs\parrallel_trends_treatment_2018q3_scale_2018q2.png", as(png) replace
*===============================================================================

* 7 - Rain => Decree /&/ Rain => Insolvency 
use .\data\econometrics\regressions_quarter, clear
gen rain_=0
*====================== TABLE VII ============================================== 
/* 1 steplike IV */ 
foreach var in big_rain10 big_rain15 big_rain20 big_rain25 big_rain30 big_rain50 { 
	sum big_decree50, d
	local aver = `r(mean)'
	replace rain_ = `var' 
	xtreg big_decree50 rain_ i.qtime, fe vce(robust)
	outreg2 using .\data\econometrics\decree_vs_rain_shocks_quarter.tex, tex(frag pretty) append addstat("Ind. var. mean", `aver') /// /
	keep(big_decree50 rain_) ctitle("`var'") groupvar(rain_) ///
	title("Impact of rain on decree issuance", ///
	"by proceeding type: 2008-2018") addtext(Quarter-year FE, YES, Departement FE, YES)
}
*=============================================================================== 
*===================== TABLE VIII ==============================================
 /* Effect of rain on insolvency */
foreach var in big_rain10 big_rain15 big_rain20 big_rain25 big_rain30 big_rain40 big_rain50 {
	sum p_procF, d
	local aver = `r(mean)'
	replace rain_ = `var' 
	xtreg p_procF rain_ p_TPE_F p_PME_F p_ETI_F n_firmF share_F d_POP d_BN_TFPB i.qtime if year>2007 & year<2019, fe vce(robust)
	*outreg2 using .\data\econometrics\regression_insolvency_vs_rain.tex, tex(frag pretty) append addstat(F-stat, `e(F)', "Ind. var. mean", `aver') /// 
	*keep(p_procF rain_) ctitle("`var'") groupvar(rain_) ///
	*title("Impact of rain on bankruptcy", ///
	*"by proceeding type: 2008-2018") addtext(Quarter-year FE, YES, Departement FE, YES)
}
*=============================================================================== 

foreach var in big_rain10 big_rain15 big_rain20 big_rain25 big_rain30 big_rain40 big_rain50 {
	sum p_LF, d
	local aver = `r(mean)'
	replace rain_ = `var' 
	xtreg p_LF rain_ p_TPE_F p_PME_F p_ETI_F n_firmF share_F d_POP d_BN_TFPB i.qtime if year>2007 & year<2019, fe vce(robust)
	outreg2 using .\data\econometrics\regression_liquidation_vs_rain.tex, tex(frag pretty) append addstat(F-stat, `e(F)', "Ind. var. mean", `aver') /// 
	keep(p_procF rain_) ctitle("`var'") groupvar(rain_) ///
	title("Impact of rain on bankruptcy", ///
	"by proceeding type: 2008-2018") addtext(Quarter-year FE, YES, Departement FE, YES)
}

/* Controls endogeneity */
 
sum p_procF, d
local aver = `r(mean)'
xtreg p_procF big_decree50 i.qtime if year>2007 & year<2019, fe vce(robust)
outreg2 using .\data\econometrics\decree_controls.tex, tex(frag pretty) append addstat(F-stat, `e(F)', "Ind. var. mean", `aver') /// /**/
keep(p_procF big_decree50) ctitle("No controls") groupvar(big_decree50) addtext(Firms control, NO, Other control, NO, Quarter-year FE, YES, Departement FE, YES)
xtreg p_procF big_decree50 d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
outreg2 using .\data\econometrics\decree_controls.tex, tex(frag pretty) append addstat(F-stat, `e(F)', "Ind. var. mean", `aver') /// /**/
keep(p_procF big_decree50) ctitle("Some controls") groupvar(big_decree50) addtext(Firms control, NO, Other control, YES, Quarter-year FE, YES, Departement FE, YES)
xtreg p_procF big_decree50 p_TPE_F p_PME_F p_ETI_F share_F d_n_firmF d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
outreg2 using .\data\econometrics\decree_controls.tex, tex(frag pretty) append addstat(F-stat, `e(F)', "Ind. var. mean", `aver') /// /**/
keep(p_procF big_decree50) ctitle("All controls") groupvar(big_decree50) addtext(Firms control, NO, Other control, YES, Quarter-year FE, YES, Departement FE, YES)

reg p_procF big_decree50 p_TPE_F p_PME_F p_ETI_F share_F d_n_firmF POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, vce(robust)
xtreg p_procF big_decree50 d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
xtreg p_procF big_decree50 share_F i.qtime if year>2007 & year<2019, fe vce(robust)

xtreg p_LF p_hit p_TPE_F p_PME_F p_ETI_F n_firmF share_F d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe vce(robust)
sort Departement year
by Departement: gen p_LF_1=p_LF[_n-1]
xtreg p_LF p_LF_1 p_hit p_TPE_F p_PME_F p_ETI_F d_n_firmF share_F d_POP d_BN_TFPB i.qtime if year>2007 & year<2019, fe vce(robust)
xtreg p_LF p_LF_1 r_rain p_TPE_F p_PME_F p_ETI_F d_n_firmF share_F d_POP d_BN_TFPB i.qtime if year>2007 & year<2019, fe vce(robust)

ssc install twowayfeweights

sort Departement year
by Departement: gen diff=p_LF-p_LF[_n-1] 
by Departement: gen p_LF_1=p_LF[_n-1]
forvalues i=1(1)4 {
	by Departement: gen diff_`i'=diff[_n-`i']
	by Departement: gen p_TPE_F_`i'=p_TPE_F[_n-`i']
	by Departement: gen p_PME_F_`i'=p_PME_F[_n-`i']
	by Departement: gen p_ETI_F_`i'=p_ETI_F[_n-`i']
	by Departement: gen d_n_firmF_`i'=d_n_firmF[_n-`i']
	by Departement: gen share_F_`i'=share_F[_n-`i']
}
*xtreg diff diff_1 big_decree50 d_BN_TFPB i.qtime if year>2007 & year<2019, fe vce(robust)
xi: xtabond2 p_LF p_LF_1 p_LF_2 big_decree50 p_TPE_F p_PME_F p_ETI_F d_n_firmF share_F ///
d_POP d_BN_TFPB if year>2007 & year<2019, robust twostep nodiff ///
gmmstyle(p_LF) iv(p_TPE_F_1 p_PME_F_1 p_ETI_F_1 d_n_firmF_1 share_F_1, collapse equation(both))
 
xtreg big_decree50 big_rain25 i.qtime if year>2007 & year<2019, fe vce(robust) 
robust cluster(Departement) 
xi: xtivreg2 p_LF (big_decree50=big_rain25) share_F d_POP d_BN_TFPB_POP i.qtime if year>2007 & year<2019, fe robust first cluster(Departement)

