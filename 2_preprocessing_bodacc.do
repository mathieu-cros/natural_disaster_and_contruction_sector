
cd "D:\OneDrive - Université Paris-Dauphine\Tesis\"

*==========================================================================================
*						 	BODACC TREATMENT
*==========================================================================================

* Getting all ZIP codes
use ".\data\bodacc\Bodacc_v2_30072020_final.dta", replace
save .\data\bodacc\bodacc, replace
merge 1:m siren using .\data\stock_etab\stock_etab_ZIP
keep if _m==1 | _m==3
drop _m
save .\data\bodacc\bodacc, replace

* FILLING IN ALL SECTOR CODES
use ".\data\firm_demographics\siren2020_NAF", clear /* 2 GB */
replace siren = substr(siren, 1, 3) + " " + substr(siren, 4, 3) + " " + substr(siren, 7, 3)
merge m:m siren using .\data\bodacc\bodacc
keep if _m==3 | _m==2
drop _m
codebook  NAF
save .\data\bodacc\bodacc, replace

* FORMATTING BODACC 
use .\data\bodacc\bodacc, clear
replace d_LJ=d_lia if d_LJ==. & d_lia~=.
replace d_LJ=d_lep if d_LJ==. & d_lep~=.
drop head d_lep d_lia d_homol obs1 jug1 modif_1 suivi1 echec1 conversion obs2 jug2 modif2 suivi2 echec2 dur_plan_S dur_plan_R
drop a_ouv m_ouv w_ouv a_plan1 a_plan2 a_CE a_plan /*max_dup*/ 
rename d_ouv day
label variable siren "ID"
label variable creation "Company creation date"
label variable treffec "Nb employees"
label variable a_treffec "Year of employee record"
label variable type_ent "Firm category = MICRO PME ETI GE"
label variable NAF "Sector"
label variable type_NAF "Nomenclature type of the sector"
label variable employeur "Has employees"
label variable tri "Court"
label variable type_tri "Court type"
label variable proc "Insolvency type = Liquidation, RJ, Safeguard"
label variable day "Insolvency filing date"
label variable d_CE "Transfer date"
label variable d_LJ "Liquidation date"
*label variable a_ouv "Year of filing"
label variable ZIP "ZIP code"
label variable d_plan1 "Date when debt reorganization is accepted" 
save .\data\bodacc\bodacc, replace

* FIND SECTOR 
use .\data\bodacc\bodacc, clear
import excel .\data\bodacc\naf2008_5_niveaux.xls, firstrow clear
rename NIV5 NAF
rename NIV1 sector
replace NAF=substr(NAF,1,2)+substr(NAF, 4,3)
merge m:m NAF using .\data\bodacc\bodacc
drop if _m==1
drop _m 
drop NIV4-NIV2
label variable sector "Sector by NAF A10 categories"
save .\data\bodacc\bodacc, replace

* Maximum number of establishments - mono-establishments vs multi-establishments
use .\data\bodacc\bodacc, clear
merge m:m siren using .\data\stock_etab\nb_etab
keep if _m==1 | _m==3
drop _m 
gen multi_siret=(siret>1)
save .\data\bodacc\bodacc, replace

*================ BODACC - work at the quarter level ===========================
* Year + Municipality + A17 treatment 
use .\data\bodacc\bodacc, clear
gen n_ouv=1
gen year=year(day) 
gen quarter=quarter(day) 
gen DEP=substr(ZIP,1,2)
sort DEP multi_siret sector year quarter proc 
collapse (count) n_ouv if year>2007 & year<2021, by(ZIP multi_siret sector year quarter proc) /*first: dates*/
reshape wide n_ouv, i(ZIP multi_siret sector year quarter) j(proc) s
* Filling holes in the data to put "0"
drop if ZIP=="" | sector==""
gen id=ZIP+sector+string(multi_siret)
egen id2 = group(id)
gen time=string(year)+string(quarter)
egen time2 = group(time)
xtset id2 time2
tsfill, full
gsort id2 -id 
by id2: replace id=id[_n-1] if id==""
gsort time2 -time
by time2: replace time=time[_n-1] if time==""
tostring multi, replace
replace multi_siret = substr(id, -1, 1)
replace sector = substr(id, -2, 1)
replace ZIP = substr(id, 1, 5)
gen year2 = substr(time, 1, 4)
gen quarter2 = substr(time, 5, 1)
destring year2 quarter2, replace
replace year = year2 if year==.
replace quarter = quarter2 if quarter==.
replace n_ouvL = 0 if n_ouvL==.
replace n_ouvS = 0 if n_ouvS==.
replace n_ouvR = 0 if n_ouvR==.
drop id2 id time time2 year2 quarter2
rename (n_ouvL n_ouvR n_ouvS) (n_L n_R n_S)
gen DEP=substr(ZIP, 1, 2)
label variable year "Year of bankruptcy filing"
label variable quarter "Quarter of bankruptcy filing"
label variable n_L "Number of liquidations"
label variable n_R "Number of reorganizations"
label variable n_S "Number of safeguard"
label variable DEP "Département"
label variable sector "Sector (construction is F)"
sort ZIP sector year
save .\data\bodacc\ZIP_sector_quarter_bodacc, replace

* To year statistics
use .\data\bodacc\ZIP_sector_quarter_bodacc, replace
rename sector a21
drop if a21=="A" | a21=="O" | a21=="D" | a21=="P" | a21=="E" /* public administration a,d education generally not subject to insolvency */
gen n_proc = n_L + n_R + n_S 
sort a21 DEP year
collapse (sum) n_proc n_L n_R n_S, by(DEP multi_siret year quarter a21)
drop if DEP=="" | a21=="" | year==.
drop if DEP=="97"
reshape wide n_proc n_L n_R n_S, i(DEP multi_siret year quarter) j(a21) string
foreach var in n_proc n_L n_R n_S {
label variable `var'B "Extractive industry"
label variable `var'C "Manufacturing industry"
label variable `var'F "Construction"
label variable `var'G "Wholesale, retail, shops"
label variable `var'H "Transport"
label variable `var'I "Hotels and restaurants"
label variable `var'J "Information and communication"
label variable `var'K "Financial activities"
label variable `var'L "Real estate"
label variable `var'M "Scientific activities"
label variable `var'N "Administrative services"
label variable `var'Q "Health industry"
label variable `var'R "Arts and entertainment"
label variable `var'S "Other services"
}

label define multisiret 0 "Unique establishment" 1 "Multi-establishments"
destring multi_siret, replace
label values multi_siret multisiret
save .\data\bodacc\dep_sector_quarter_bodacc, replace

use .\data\bodacc\dep_sector_quarter_bodacc, clear
collapse (sum) n_proc* n_L* n_R* n_S*, by(DEP year quarter)
save .\data\bodacc\dep_sector_quarter_bodacc_all, replace

use .\data\bodacc\dep_sector_quarter_bodacc, clear
drop if multi_siret==1
save .\data\bodacc\dep_sector_quarter_bodacc_mono, replace
