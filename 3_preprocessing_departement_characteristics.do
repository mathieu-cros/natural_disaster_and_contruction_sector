
cd "D:\OneDrive - Université Paris-Dauphine\Tesis\"

*==========================================================================================
*								POPULATION
*==========================================================================================
clear
save .\data\departement\pop, replace empty
forvalues i=2008(1)2013 {
	import excel ".\data\departement\estim-pop-dep-sexe-gca-1975-2020.xls", sheet("`i'") cellrange(A5:T108) firstrow clear
	rename A DEP 
	drop if length(DEP)>2
	keep DEP Total 
	gen year=`i'
	append using .\data\departement\pop
	save .\data\departement\pop, replace
}
forvalues i=2014(1)2019 {
	import excel ".\data\departement\estim-pop-dep-sexe-gca-1975-2020.xls", sheet("`i'") cellrange(A5:T109) firstrow clear
	rename A DEP 
	drop if length(DEP)>2
	keep DEP Total 
	gen year=`i'
	append using .\data\departement\pop
	save .\data\departement\pop, replace
}
rename Total POP
save .\data\departement\pop, replace


*==========================================================================================
*								UNEMPLOYMENT
*==========================================================================================

* Control variable = number of people looking for a job (Pole Emploi) 
import excel ".\data\departement\dares_donnees_reg_brut_mens_07.2020.xlsx", sheet("Feuil1") clear firstrow
*import excel "C:\Users\cgsp\OneDrive - Université Paris-Dauphine\Tesis\data\departement\dares_donnees_reg_brut_mens_07.2020.xlsx", sheet("Feuil1") firstrow clear
drop if Département=="Total"
drop if Département==""
gen DEP=substr(Département, 1, 2)
drop Département

foreach v of varlist B-KJ {
	local x : variable label `v'
	rename `v' date_`x'
}
reshape long date_01jan date_01feb date_01mar date_01apr date_01may date_01jun date_01jul date_01aug date_01sep date_01oct date_01nov date_01dec,  i(DEP) j(year)
reshape long date_01, i(DEP year) j(m_ouv) string
rename date_01 unemployed
save .\data\departement\unemployment, replace

use .\data\departement\unemployment, clear
gen quarter=1 if m_ouv=="jan" | m_ouv=="feb" | m_ouv=="mar"
replace quarter=2 if m_ouv=="apr" | m_ouv=="may" | m_ouv=="jun"
replace quarter=3 if m_ouv=="jul" | m_ouv=="aug" | m_ouv=="sep"
replace quarter=4 if m_ouv=="oct" | m_ouv=="nov" | m_ouv=="dec"
collapse (mean) unemployed, by(DEP year quarter)
replace unemployed=int(unemployed)
sort DEP year quarter
gen d_unemployed=unemployed/unemployed[_n-1]-1
save .\data\departement\unemployed, replace 

/*==========================================================================================
*							ENERGY CONSUMPTION
*==========================================================================================

* Sector energy consumption - only from 2011 (dismissed from now)
import delimited .\data\departement\conso-elec-gaz-annuelle-par-naf-agregee-commune.csv, delimiter(";") clear 
rename (anne consommationmwh codegrandsecteur libellgrandsecteur codecommune codeepci libellepci codedpartement libelldpartement codergion libellrgion) ///
(annee conso_mwh code_secteur conso_secteur INSEE code_epci label_epci DEP label_DEP REG code_REG)
keep annee conso_mwh code_secteur conso_secteur INSEE code_epci label_epci DEP label_DEP REG code_REG
collapse (sum) conso_mwh, by(DEP annee conso_secteur)
reshape wide conso_mwh, i(annee DEP) j(conso_secteur) string
rename annee year
save .\data\departement\conso_energie_DEP, replace

* Graphs 
use .\data\departement\conso_energie_DEP, clear
collapse (sum) mwh_Agr mgw_Indus mgw_Foyers mgw_Tertiaire, by(annee)
twoway line (mwh_Agr mgw_Indus mgw_Foyers mgw_Tertiaire) (annee)
graph bar (sum) unemp_pop if year>2008, over(year, label(angle(90))) /*by(a21)*/ ylabel(,angle(360)) 

*==========================================================================================
*							 VALUE-ADDED BY SECTOR
*==========================================================================================

* Only until 2015 - dismissed for now 
clear 
save .\data\departement\value_added_regions, empty replace
forvalues i=2008(1)2015 {
	import excel ".\data\departement\VA_1990_2015_regions_diffusion.xls", sheet("`i'") cellrange(A4:U32) firstrow clear
	drop if AZ==.
	drop if C1=="n.d"
	rename codedelabrancheenA17 REG 
	gen year=`i'
	append using .\data\departement\value_added_regions
	save .\data\departement\value_added_regions, replace
}
drop if REG=="Dom" | REG=="Hors territoire" | REG=="France entière"
drop DEC1C2C3C4C5 GZHZIZ Total
foreach var in AZ DE C1 C2 C3 C4 C5 FZ GZ HZ IZ JZ KZ LZ MN OQ RU {
rename `var' VA_`var'
}
save .\data\departement\value_added_regions, replace*/

*==========================================================================================
*							LOCAL TAXES
*==========================================================================================

* Local taxes 
import excel ".\data\departement\taxes_locales\2008_dep_fichedescriptive.xls", sheet("Synthèse départementale") cellrange(A4:N104) firstrow
save .\data\departement\local_tax_2008, replace
import excel ".\data\departement\taxes_locales\2009_dep_fichedescriptive.xls", sheet("Synthèse départements") cellrange(A4:N104) firstrow clear
save .\data\departement\local_tax_2009, replace
import excel ".\data\departement\taxes_locales\2010_dep_fichedescriptive.xls", sheet("Synthèse départements") cellrange(B3:L108) firstrow clear
save .\data\departement\local_tax_2010, replace
import excel ".\data\departement\taxes_locales\2011_dep_fichedescriptive.xls", sheet("Synthèse départements") cellrange(B3:F108) firstrow clear
save .\data\departement\local_tax_2011, replace
import excel ".\data\departement\taxes_locales\2012_dep_fichedescriptive.xls", sheet("Synthèse départements") cellrange(B3:F108) firstrow clear
save .\data\departement\local_tax_2012, replace
import excel ".\data\departement\taxes_locales\2013_dep_fichedescriptive.xls", sheet("Synthèse département") cellrange(B3:F105) firstrow clear
save .\data\departement\local_tax_2013, replace
import excel ".\data\departement\taxes_locales\2014_dep_fichedescriptive.xls", sheet("Synthèse département") cellrange(B4:F108) firstrow clear
save .\data\departement\local_tax_2014, replace
import excel ".\data\departement\taxes_locales\btp_2015_tfpb.xls", sheet("Synthèse département") cellrange(B4:F106) firstrow clear
save .\data\departement\local_tax_2015, replace
import excel ".\data\departement\taxes_locales\btp_2016_tfpb.xls", sheet("Synthèse département") cellrange(B4:F108) firstrow clear
save .\data\departement\local_tax_2016, replace
import excel ".\data\departement\taxes_locales\btp_2017_tfpb.xls", sheet("Synthèse département") cellrange(B4:F108) firstrow clear
save .\data\departement\local_tax_2017, replace
import excel ".\data\departement\taxes_locales\btp_2018_tfpb.xls", sheet("Synthèse département") cellrange(B4:F110) firstrow clear
save .\data\departement\local_tax_2018, replace

use .\data\departement\local_tax_2008, clear
keep Code F
rename (Code F) (DEP BN_TFPB)
gen annee=2008
save .\data\departement\local_tax, replace
use .\data\departement\local_tax_2009, clear
keep Code F
rename (Code F) (DEP BN_TFPB)
gen annee=2009
append using .\data\departement\local_tax
save .\data\departement\local_tax, replace
forvalues i=2010(1)2018 {
	use .\data\departement\local_tax_`i', clear
	keep Code TaxeFoncièresurlesPropriétés
	rename (Code TaxeFoncièresurlesPropriétés) (DEP BN_TFPB)
	drop if BN_TFPB=="" | DEP==""
	destring BN_TFPB, replace
	gen annee=`i'
	append using .\data\departement\local_tax
	save .\data\departement\local_tax, replace
}
set more off
tab DEP 
replace DEP=substr(DEP, 1, 2) if length(DEP)>2
replace DEP="0"+DEP if length(DEP)<2
drop if DEP=="TO"
rename annee year
label variable BN_TFPB "Local tax on built properties"
save .\data\departement\local_tax, replace

*==========================================================================================
*							PRE-EMPLOYMENT PROCEEDINGS
*==========================================================================================

import delimited .\data\departement\dpae-par-departement-x-grand-secteur.csv, delimiter(";") clear 
keep codedãpartement grandsecteurdactivitã annãe trimestre dpaebrut dpaecvs
rename (codedãpartement grandsecteurdactivitã annãe trimestre dpaebrut dpaecvs) ///
(DEP sector year quarter dpae dpaecvs) 
collapse (sum) dpae dpaecvs, by(DEP sector year quarter)
tab sector
replace sector="F" if sector=="GS2 Construction"
replace sector="C" if sector=="GS1 Industrie"
replace sector="I" if sector=="GS4 HÃ´tellerie-restauration"
replace sector="G" if sector=="GS3 Commerce"
drop if length(sector)>1
sort DEP year quarter
reshape wide dpae dpaecvs, i(DEP year quarter) j(sector) string 
drop if length(DEP)>2 | DEP=="99"
save .\data\departement\dpae_employment_DEP, replace 

*==========================================================================================
*								EMPLOYMENT AND WAGES
*==========================================================================================

import delimited .\data\departement\effectifs-salaries-et-masse-salariale-du-secteur-prive-par-departement-x-grand-s, delimiter(";") clear 
keep codedãpartement dãpartement grandsecteurdactivitã annãe trimestre effectifssalariãsbrut effectifssalariãscvs massesalarialebrut massesalarialecvs
rename (codedãpartement dãpartement grandsecteurdactivitã annãe trimestre effectifssalariãsbrut effectifssalariãscvs massesalarialebrut massesalarialecvs) ///
(DEP DEP_name sector year quarter n_jobs n_jobs_cvs wage wage_cvs) 
tab sector 
replace sector="F" if sector=="GS2 Construction"
replace sector="C" if sector=="GS1 Industrie"
replace sector="I" if sector=="GS4 HÃ´tellerie-restauration"
replace sector="G" if sector=="GS3 Commerce"
drop if length(sector)>1
sort DEP year quarter
reshape wide n_jobs n_jobs_cvs wage wage_cvs, i(DEP year quarter) j(sector) string
drop if length(DEP)>2
save .\data\departement\jobs_wages_DEP, replace


*==========================================================================================
*							CONTROL/CHARATERISTICS DATASET
*==========================================================================================

use .\data\departement\pop, clear
drop if year<2008 | year==2020
merge m:m DEP year using .\data\departement\local_tax
drop if _m==1 /* 2019 */
drop if _m==2 /* DEP 97 */
drop _m
save .\data\departement\dep_characteristics, replace 

use .\data\departement\dep_characteristics, clear
gen quarter=4
merge m:m DEP year quarter using .\data\departement\panel_departement
gen date=string(year)+string(quarter)
destring(date), replace
sort DEP date
foreach var in POP {
by DEP: ipolate `var' date, epolate gen(`var'2)
drop `var'
rename `var'2 `var'
replace `var'=round(`var')
}
gsort DEP year -quarter  /* we do not interpolate tax base on built property, we assign the value to the whole year (it could be divided by 4) */
by DEP year: replace BN_TFPB=BN_TFPB[_n-1] if BN_TFPB[_n-1]~=.
keep DEP year POP BN_TFPB quarter
save .\data\departement\dep_characteristics_quarter, replace

use .\data\departement\dep_characteristics_quarter, clear
merge m:m DEP year quarter using .\data\departement\unemployed 
gen unemployed_POP = unemployed/POP
gen BN_TFPB_POP = BN_TFPB/POP
save .\data\departement\dep_characteristics_quarter, replace

use .\data\departement\dep_characteristics_quarter, clear
drop _m
merge m:m DEP year quarter using .\data\departement\dpae_employment_DEP
drop _m 
merge m:m DEP year quarter using .\data\departement\jobs_wages_DEP
drop _m
save .\data\departement\dep_characteristics_quarter, replace

use .\data\departement\dep_characteristics_quarter, clear
label variable POP "Population"
label variable unemployed "Number of unemployed workers"
label variable d_unemployed "Growth rate of unemployed workers"
label variable unemployed_POP "Number of unemployed workers / Population"
label variable BN_TFPB_POP "Local tax on built property per capita"
foreach sector in C F G I {
	label variable dpae`sector' "Pre-employment declaration (sector `sector')"
	label variable dpaecvs`sector' "Pre-employment declaration (sector `sector') - Seasonally corrected"
	label variable n_jobs`sector' "Number of posts (sector `sector')"
	label variable n_jobs_cvs`sector' "Number of posts (sector `sector') - Seasonally corrected"
	label variable wage`sector' "Overall wage (sector `sector')"
	label variable wage_cvs`sector' "Overall wage (sector `sector') - Seasonally corrected"
	gen wage_capita`sector' = wage`sector' / n_jobs`sector'
	gen wage_capita_cvs`sector' = wage_cvs`sector' / n_jobs_cvs`sector'
	gen new_contracts`sector' = dpae`sector'/n_jobs`sector'
	gen new_contracts_cvs`sector' = dpaecvs`sector'/n_jobs_cvs`sector'
	label variable wage_capita`sector' "Wage per job (sector `sector')"
	label variable wage_capita_cvs`sector' "Wage per job (sector `sector') - Seasonally corrected"
	label variable new_contracts`sector' "New contracts / number of jobs (sector `sector')"
	label variable new_contracts_cvs`sector' "New contracts / number of jobs (sector `sector') - Seasonally corrected"
}
save .\data\departement\dep_characteristics_quarter, replace
