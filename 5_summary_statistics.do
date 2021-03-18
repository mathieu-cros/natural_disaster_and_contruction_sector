
cd "D:\OneDrive - Université Paris-Dauphine\Tesis\"

*==========================================================================================
*							SUMMARY STATISTICS ON HIT AREAS
*==========================================================================================

* 1 - Summary statistics on Departement hit 
use .\data\econometrics\summary_statistics, clear
merge m:m DEP year quarter using .\data\firm_demographics\firm_demography_quarter_dep_fsize
drop _m
merge m:m DEP year quarter using .\data\bodacc\dep_sector_quarter_bodacc_all
drop _m 
merge m:m DEP year quarter using .\data\departement\dep_characteristics_quarter
drop _m 
capture drop dup
bysort DEP year quarter: gen dup=_n
drop if year<2001 | year==. | year==2020
*br if dup>1 /* multi_siret */
*drop dup
save .\data\econometrics\summary_statistics, replace 

use .\data\econometrics\summary_statistics, clear
sort DEP year quarter
* Year and DEP - rain & decrees
*===================== TABLE - APPENDIX ======================================== 
tabout DEP year if big_decree50==1 & year>2007 & year<2019 using ".\sum_stats\decree_shock50.tex", replace format(0.2) style(tex)
*=============================================================================== 
*===================== TABLE - APPENDIX ========================================
tabout DEP year if big_rain25==1 & year>2007 & year<2019 using ".\sum_stats\rain_shock50.tex", replace format(0.2) style(tex)
*=============================================================================== 
*===================== FIGURE II ===============================================
graph bar (sum) big_decree50 big_rain25 if year>2007, over(year) ///
legend(label(1 "Decree") label(2 "Rain") col(2) symysize(*0.7) size(*0.9)) ///
ytitle("Number of disasters", size(*0.9)) ///
ylabel(,angle(360) labsize(*0.9)) graphregion(color(white))
graph export ".\graphs\ND_rain_decree_years.png", as(png) replace
*===============================================================================

* Pre-processing for maps 
collapse (max) big_rain25 big_decree50 if big_rain25~=. & big_decree50~=. & year<2019 & year>2006, by(DEP) 
rename DEP CODE_DEPT 
merge 1:m CODE_DEPT using .\data\departement\FondsCartesDEP.dta
saveold .\data\union\map_natural_disaster_DEP, replace version(12)

* 2 - MAPS - rain / decree
use .\data\union\map_natural_disaster_DEP, clear
*rename big_rain50 rain
rename big_rain25 rain
rename big_decree50 decree
label define disaster 0 "No" 1 "Yes"
label values decree disaster 
label values rain disaster
gen disaster=0 if decree==0 & rain==0
replace disaster=1 if decree==1 & rain==0
replace disaster=2 if rain==1 & decree==0
replace disaster=3 if rain==1 & decree==1
label define disaster2 0 "No disaster" 1 "Decree" 2 "Rain" 3 "Decree and rain"
label values disaster disaster2 
*format p_proc* %12.2f 
*===================== FIGURE I - OMM STATIONS ================================= 
spmap using .\data\departement\Coord_DEP.dta, id(id) ///
label(data(.\data\departement\villes) xcoord(X_CENTROID)  ycoord(Y_CENTROID) position(0 3) ///
label(NOM_COM) /*by(labtype)*/  size(*0.85 ..)) ///
point(data(.\data\departement\omm_station_coord) xcoord(X_CENTROID) ycoord(Y_CENTROID) fcolor(red) legenda(on) leglabel("Meteorological stations")) 
graph export ".\maps\OMM_stations_DEP.png", as(png) replace
*=============================================================================== 
*===================== FIGURE III ============================================== 
spmap disaster using .\data\departement\Coord_DEP.dta, id(id) clmethod(unique) fcolor(Paired) ///
label(data(.\data\departement\villes) xcoord(X_CENTROID)  ycoord(Y_CENTROID) position(0 2) ///
label(NOM_COM) /*by(labtype)*/  size(*0.85 ..)) legcount ///
point(data(.\data\departement\omm_station_coord) xcoord(X_CENTROID) ycoord(Y_CENTROID) fcolor(red) legenda(on) leglabel("Meteorological stations")) /// option points 
title("Departements hit by natural disaster according to decrees and precipitations", size(small)) /*options graphique */
graph export ".\maps\disasters.png", as(png) replace
*=============================================================================== 

* 3 - Summary statistics on insolvency proceedings 
use .\data\econometrics\summary_statistics, clear
collapse (sum) n_firm* n_proc* n_L* n_R* n_S*, by(qtime year quarter)
foreach var in "B" "C" "F" "G" "H" "I" "J" "K" "L" "M" "N" "Q" "R" "S" {
	gen p_proc`var' = n_proc`var'/n_firm`var'
	gen p_L`var' = n_L`var'/n_firm`var'
	gen p_R`var' = n_R`var'/n_firm`var'
	gen p_S`var' = n_S`var'/n_firm`var'
}
foreach x in p n {
	foreach proc in proc L R S {
		label variable `x'_`proc'B "Extractive industry"
		label variable `x'_`proc'C "Manufacturing industry"
		label variable `x'_`proc'F "Construction"
		label variable `x'_`proc'G "Wholesale, retail, shops"
		label variable `x'_`proc'H "Transport"
		label variable `x'_`proc'I "Hotels and restaurants"
		label variable `x'_`proc'J "Information and communication"
		label variable `x'_`proc'K "Financial activities"
		label variable `x'_`proc'L "Real estate"
		label variable `x'_`proc'M "Scientific activities"
		label variable `x'_`proc'N "Administrative services"
		label variable `x'_`proc'Q "Health industry"
		label variable `x'_`proc'R "Arts and entertainment"
		label variable `x'_`proc'S "Other services"
	}
}
label variable n_firmF "Construction"
label variable n_firmG "Wholesale, retail, shops"
label variable n_firmH "Transport"
label variable n_firmI "Hotels and restaurants"
label variable n_firmM "Scientific activities"
label variable n_firmN "Administrative services"
label variable n_firmQ "Health industry"
*===================== FIGURE IV - INSOLVENCY PROPENSITY ======================= 
twoway line p_procF p_procG p_procH p_procI p_procM p_procN qtime if qtime>191 & qtime<236, legend(label(1 "`:variable label p_procF'") lwidth(3) ///
label(2 "`:variable label p_procG'") label(3 "`:variable label p_procH'") label(4 "`:variable label p_procI'") label(5 "`:variable label p_procM'") ///
col(3) symysize(*0.7) size(*0.7)) /*xscale(range(2008q1 2018q4)) xlabel(2008 2010 2012 2014 2016 2018)*/ xtitle(Quarter, size(small)) ///
ytitle("Percentage of insolvent firms", size(small)) ylabel(,angle(360) labsize(small)) xlabel(,labsize(small)) bcolor(white) ///
graphregion(color(white))
graph export ".\graphs\percent_insolvency_by_sector_quarter.png", as(png) replace
*=============================================================================== 
*===================== APPENDIX - NUMBER OF INSOLVENT FIRMS ==================== 
twoway line n_procF n_procG n_procH n_procI n_procN n_procM qtime if qtime>191 & qtime<236, legend(label(1 "`:variable label n_procF'") lwidth(3) ///
label(2 "`:variable label n_procG'") label(3 "`:variable label n_procH'") label(4 "`:variable label n_procI'") label(5 "`:variable label n_procN'") ///
col(3) symysize(*0.7) size(*0.7)) /*xscale(range(2008 2018)) xlabel(2008 2010 2012 2014 2016 2018)*/ xtitle(Year, size(small)) ///
ytitle("Number of insolvent firms", size(small)) ylabel(,angle(360) labsize(small)) xlabel(, labsize(small)) bcolor(white) ///
graphregion(color(white))
graph export ".\graphs\nb_insolvency_by_sector_quarter.png", as(png) replace
*=============================================================================== 
*===================== FIGURE V - FIRM DEMOGRAPHICS ============================ 
* Other plot (firm demographics)
twoway line n_firmF n_firmG n_firmH n_firmI n_firmN n_firmM qtime if qtime>191 & qtime<236, legend(label(1 "`:variable label n_firmF'") lwidth(3) ///
label(2 "`:variable label n_firmG'") label(3 "`:variable label n_firmH'") label(4 "`:variable label n_firmI'") label(5 "`:variable label n_firmN'") ///
col(3) symysize(*0.7) size(*0.7)) /*xscale(range(2008 2018)) xlabel(2008 2010 2012 2014 2016 2018)*/ xtitle(Year, size(small)) ///
ytitle("Number of firms in the sector", size(small)) ylabel(,angle(360) labsize(small)) xlabel(, labsize(small)) bcolor(white) ///
graphregion(color(white))
graph export ".\graphs\nb_firms_by_sector_quarter.png", as(png) replace
*=============================================================================== 

* Plotting residuals 
set seed 123456789 
capture drop res*
tsset qtime
/* Insolvency regressed on fixed effects to understand if autocorrelation is controlled at the aggregate level */
foreach var in F G H I M N { 
reg p_proc`var' i.qtime if year>2007 & year<2019
predict res`var', resid 
}
label variable resF "Construction"
label variable resG "Wholesale, retail, shops"
label variable resH "Transport"
label variable resI "Hotels and restaurants"
label variable resM "Scientific activities"
label variable resN "Administrative services"
*===================== FIGURE VIII ============================================= 
twoway line (resF) qtime if year>2007 & year<2019, /*title("Residuals - Aggregated insolvency regressed on" "time fixed-effect (construction)", size(medium))*/ ///
xlabel(, labsize(*0.9)) ylabel(, labsize(*0.9)) xtitle(, size(*0.9)) ytitle(, size(*0.9)) graphregion(color(white))  
graph export ".\graphs\autocorrelation_construction.png", as(png) replace
*===============================================================================
*===================== APPENDIX ================================================ 
twoway line (res*) qtime if year>2007 & year<2019, title("Residuals of regression insolvency (at the aggregate level)" "vs time fixed-effect", size(medium)) ///
xlabel(, labsize(*0.9)) ylabel(, labsize(*0.9)) xtitle(, size(*0.9)) ytitle(, size(*0.9)) graphregion(color(white))  
graph export ".\graphs\autocorrelation_all_sectors.png", as(png) replace
*===============================================================================

* Proceedings correlations - at the aggregate level 
*===================== APPENDIX ================================================
estpost corr p_procF p_procG p_procH p_procI p_procN p_procM
esttab using ".\sum_stats\insolvency_correlation_sector_quarter.tex", replace
*===============================================================================

