
cd "D:\OneDrive - Université Paris-Dauphine\Tesis"

*==========================================================================================
*									GASPAR TREATMENT
*==========================================================================================

* Importing data issued from 1st treatment
use .\data\gaspar\gaspar12.dta, clear
rename (cod_nat_catnat cod_commune lib_commune num_risque_jo lib_risque_jo) (code_catnat INSEE Commune Risque Peril)
rename (dat_pub_arrete dat_pub_jo) (date_arrete date_journal)
label variable INSEE "code insee"
label variable dat_deb "date de debut de catastrophe naturelle"
label variable dat_fin  "date de fin de catastrophe naturelle"
label variable date_arrete  "date de publication de l'arrete de catastrophe naturelle"
label variable date_journal  "date de publication de l'arrete dans le journal de la republique"
save .\data\gaspar\gaspar12_init.dta, replace 

replace INSEE="0"+INSEE if length(INSEE)==4
gen dpt=substr(INSEE,1,2)
drop if dpt=="97"
* ID = generating an id variable (when Peril, dat_deb and dat_fin are identical, the id variable for natural disaster is the same
bysort dat_deb dat_fin Peril: gen id_catnat=substr(Peril,1,4)+substr(Peril,-7,5)+string(dat_deb)+string(dat_fin)
replace id_catnat = subinstr(id_catnat, " ", "_", .)
*replace id_catnat = subinstr(id_catnat, "�", "_", .)

* Formatting dates 
format dat_deb %tddd/nn/CCYY
format dat_fin %tddd/nn/CCYY
format date_arrete %tddd/nn/CCYY

* Creating dates variables
gen a_catnat=year(dat_deb)
gen m_catnat=month(dat_deb)
gen quarter=quarter(dat_deb)
gen a_arrete=year(date_arrete)
gen m_arrete=month(date_arrete)
gen dur_catnat=dat_fin-dat_deb+1
gen dur_arrete=date_arrete-dat_deb+1
replace dur_catnat=365 if dur_catnat>365
* nombre communes touchees par id_catnat
* drop if a_catnat==2019
egen communes_hit = count(1), by(id_catnat)

* Labelling
label variable communes_hit "Nombre de communes touchées par la catastrophe naturelle"
label variable a_catnat "Année de début de la catastrophe naturelle"
label variable m_catnat "Mois de début de la catastrophe naturelle"
label variable a_arrete "Année de l'arrêté de catastrophe naturelle"
label variable m_arrete "Mois de l'arrêté de catastrophe naturelle"
label variable dur_catnat "Durée entre le début de la catastrophe naturelle (en jours)"
label variable dur_arrete "Durée entre le début de la catastrophe naturelle et son arrété (en jours)"
label variable id_catnat "variable identité fondée sur le péril, la date de début et de fin du péril"
label variable dpt "Département d'occurence de la catastrophe naturelle" 
save .\data\gaspar\gaspar12_init.dta, replace

* Renaming ND types
use .\data\gaspar\gaspar12_init.dta, clear
codebook Peril 
replace Peril="Landslides due to droughts" if Peril== "Mouvements de terrain différentiels consécutifs à la sécheresse et à la réhydratation des sols" ///
| Peril== "Mouvements de terrain consécutifs à la sécheresse"
replace Peril="Wave shocks and floods" if Peril=="inondations et coulées de boue et inondations et chocs mécaniques liés à l'action des vagues" ///
| Peril=="Chocs mécaniques liés à l'action des vagues" | Peril=="Inondations et chocs mécaniques liés à l'action des vagues" ///
| Peril=="Inondations, coulées de boue et chocs mécaniques liés à l'action des vagues" ///
| Peril=="Inondations, coulées de boue, mouvements de terrain et chocs mécaniques liés à l'action des vagues" ///
| Peril=="Inondations, coulées de boue, glissements et chocs mécaniques liés à l'action des vagues" | Peril=="Raz-de-marée" 
replace Peril="Floods because of underground water rise" if Peril=="Inondations par remontées de nappe phréatique" ///
| Peril=="Inondations par remontées de nappe naturelle" | Peril=="inondations et coulées de boue, inondations par remontées de nappe phréatique" ///
| Peril=="Inondations par remontée de la nappe phréatique et mouvements de terrain"
replace Peril="Landslides" if Peril=="Séisme" | Peril=="Mouvements de terrain" | Peril=="Tassement de terrain" ///
| Peril=="Effondrements / éboulements" | Peril=="Affaissement de terrain" | Peril=="Chutes de rochers / de blocs rocheux" | Peril=="Eboulement de falaise" ///
| Peril=="Eboulement ou effondrement de carrière" | Peril=="Eboulement, glissement et affaissement de terrain" | Peril=="Eboulements rocheux" ///
| Peril=="Effondrement de terrain" | Peril=="Glissement de terrain" | Peril=="Glissement de terrain et effondrement de terrain" ///
| Peril=="Glissements de terrain et éboulements rocheux" 
replace Peril="Others" if Peril=="Lave torrentielle" | Peril=="Tempête" | Peril=="Avalanche" | Peril=="Tornade et grêle" | Peril=="Poids de la neige - chutes de neige" ///
| Peril=="Coulées de boue et lave torrentielle"
replace Peril="Floods and mudslides" if Peril=="Inondations et coulées de boue" | Peril=="Inondations et coulées de boue" ///
| Peril=="Inondations, coulées de boue et mouvements de terrain" | Peril=="Crues torrentielles et glissements de terrain" ///
| Peril=="Inondations, coulées de boue et effets exceptionnels dus aux précipitations" | Peril=="Inondations, coulées de boue et glissements de terrain"
save .\data\gaspar\gaspar12_init.dta, replace

* Simplifying 
use .\data\gaspar\gaspar12_init.dta, clear
keep INSEE Commune Peril quarter dat_deb dat_fin date_arrete id_catnat dpt a_catnat m_catnat a_arrete m_arrete dur_catnat dur_arrete communes_hit 
rename (a_catnat dpt) (annee DEP)
sort INSEE annee
merge m:m INSEE annee using ".\data\departement\24092019_ZE_CP_INSEE_POP.dta"
* _m == 1 -> catnat sans communes = 0
* _m == 2 -> communes sans catnat = 18 735 - OK 
drop _m
compress
label variable Peril "Natural disaster type"
label variable dur_catnat "Natural disaster duration (days)"
save .\data\gaspar\gaspar12_init.dta, replace

* Variable to english + labeling 
use .\data\gaspar\gaspar12_init, clear
replace DEP=dpt if DEP==""
rename (id_catnat INSEE Peril dat_deb dat_fin dur_catnat)(ND_id ZIP ND_type start end duration)
label variable ND_id "Natural disaster ID"
label variable ZIP "ZIP Code"
label variable ND_type "Natural disaster type"
label variable start "Starting date"
label variable end "Ending date"
label variable duration "Natural disaster duration"
label variable DEP "Département"
label variable quarter "Quarter of occurrence of the natural disaster"
keep ND_id ZIP ND_type start end duration DEP quarter
codebook ND_type
rename start day 
encode ZIP, gen(ZIP2)
rename (ZIP ZIP2) (ZIP2 ZIP)
tab ND_type
keep if ND_type=="Floods and mudslides" | ND_type=="Floods because of underground water rise" | ND_type=="Wave shocks and floods"
collapse (count) ZIP, by(DEP day) /*+ number of town hit*/
rename ZIP n_hit
save .\data\gaspar\gaspar, replace /* match with RAIN - go down */


*==========================================================================================
*						SYNOP TREATMENT (METEOROLOGICAL OBS)
*==========================================================================================

* Meteorological observations 
use .\data\meteo\synop_almost_treated, clear
* Average and maximum of daily observations 
bysort numer_sta date2: egen wspeed = mean(ff)
replace rafper = raf10 if rafper==. & raf10~=.
replace per = -10 if rafper==. & raf10~=.
bysort numer_sta date2: egen max_wind = max(rafper)
bysort numer_sta date2: egen pluie = max(rr24) /* (170323 missing values generated)*/
bysort numer_sta date2: egen pluie2 = sum(rr12) if pluie==.
replace pluie = pluie2 if pluie==.
capture drop pluie2
keep numer_sta date2 nom INSEE dptmt region wspeed max_wind pluie
bysort date2 numer_sta: gen dup=_n
drop if dup > 1
drop dup 
count if numer_sta==7005 /* 7347 different dates */
save .\data\meteo\choc_meteo, replace /* here need to complete the dataset - see at the end */

* Completing dataset in section at the end : CONTIGUITY MATRIX + NEIGHBOUR AVERAGE (Mata)
* Contiguity matrix import 
use .\data\departement\Coord_DEP.dta, clear
bysort _ID: egen _X_=mean(_X) /* computing barycenter of each _ID (DEP) */
bysort _ID: egen _Y_=mean(_Y)
bysort _ID: gen dup=_n /* drop duplicates because of spmat command */
drop if dup>1
keep _ID _X_ _Y_
rename _X_ longitude
rename _Y_ latitude
shp2dta using .\data\departement\departements-20140306-50m.shp, database(..\data\departement\departement2.dta) coordinates(.\departement\Coord_DEP2.dta) replace genid(id)
use .\data\departement\departement2.dta, clear /* spmat contiguity command creates the c_DEP object */
spmat contiguity c_DEP using .\data\departement\Coord_DEP2.dta, id(id) rook replace /*saving(".\departement\contiguity.txt")*/
*spmat idistance c_DEP using .\communes_shapefile\Coord_DEP.dta, id(id) replace idist saving(".\departement\contiguity_idist.txt")
spmat export c_DEP using .\data\departement\contiguity.txt, replace

* Generating all the dates for each Departement
import delimited ".\data\departement\contiguity.txt", delimiter(" ") clear
drop if _n==1
rename v1 id 
merge m:m id using .\data\departement\FondsCartesDEP.dta
drop if _m==1
order CODE_DEPT
keep CODE_DEPT v2-v97
rename CODE_DEPT DEP
* All the dates for each DEP : 14 610 - 21 996
sort DEP
forvalues j = 14610(1)21996 {
	gen date`j' = `j'
}
keep DEP date*
reshape long date, i(DEP)
*drop if _j==2
drop _j
rename date date2
format date %tddd/nn/ccyy
save .\data\meteo\DEP_dates_meteo, replace

* Renaming dpt for the merge 
use .\data\meteo\choc_meteo, clear
rename dptmt DEP
save .\data\meteo\choc_meteo, replace 

* Merge each date with the observation if there is one (when OMM station in the DEP) 
use .\data\meteo\DEP_dates_meteo, clear
merge m:m DEP date2 using .\meteo\choc_meteo
gen OMM=(numer_sta~=.)
drop _m
sort date2 DEP
save .\data\meteo\choc_meteo_contiguity1, replace

* Vicinity work to set the missing observations to average of its neighbours 
set matsize 11000
import delimited ".\data\departement\contiguity.txt", delimiter(" ") clear
drop v98-v102
drop if _n==1 | _n>97
* - mkmat - dataset to stata matrix
mkmat v2-v97, mat(contiguity)
egen n_voisin = rowtotal(v2-v97)
keep v1 n_voisin
rename v1 id 
merge 1:1 id using .\data\departement\FondsCartesDEP.dta
drop _m
rename CODE_DEPT DEP
merge m:m DEP using .\data\meteo\choc_meteo_contiguity1
drop _m

* Initialization
gen OMM_nm=OMM
replace OMM_nm=0 if OMM_nm==.
gen wspeed_nm=wspeed 
replace wspeed_nm=0 if wspeed_nm==.
gen max_wind_nm=max_wind 
replace max_wind_nm=0 if max_wind_nm==.
gen pluie_nm=pluie 
replace pluie_nm=0 if pluie_nm==.

* FIRST ROUND 
sort date2 DEP /* crucial because of continguity matrix order !! */
matrix voisin = J(96, 7387, 0)
matrix voisin_wspeed = J(96, 7387, 0)
matrix voisin_max_wind = J(96, 7387, 0)
matrix voisin_pluie = J(96, 7387, 0) /* zeros matrix (96,96)*/
* Matrices 96 x 7387
local counter 1
forvalues j = 1/7387 {  /*LOOP OVER COLUMNS*/
    forvalues i = 1/96 { /*LOOP OVER ROWS OF TARGET*/
		matrix voisin[`i',`j'] = OMM_nm[`counter'] 
        matrix voisin_wspeed[`i',`j'] = wspeed_nm[`counter'] 
		matrix voisin_max_wind[`i',`j'] = max_wind_nm[`counter'] 
		matrix voisin_pluie[`i',`j'] = pluie_nm[`counter'] 
        local ++counter
     }
}

set more off 
mata 
// Import dans Mata des variables Stata
voisin = st_matrix("voisin")
voisin_wspeed = st_matrix("voisin_wspeed")
voisin_max_wind = st_matrix("voisin_max_wind")
voisin_pluie = st_matrix("voisin_pluie") 
contiguity = st_matrix("contiguity")
// Initialisation
voisin_hold=voisin[.,1]
voisin_wspeed_hold=voisin_wspeed[.,1]
voisin_max_wind_hold=voisin_max_wind[.,1]
voisin_pluie_hold=voisin_pluie[.,1]
// Calcul de la somme des chocs voisins
voisin_hold = contiguity * voisin_hold  
voisin_wspeed_hold = contiguity * voisin_wspeed_hold
voisin_max_wind_hold = contiguity * voisin_max_wind_hold
voisin_pluie_hold = contiguity * voisin_pluie_hold
// Moyenne en divisant par le nombre de voisins ayant des observations / division par 0 non prise en charge
voisin_wspeed_hold = voisin_wspeed_hold :/ voisin_hold
voisin_max_wind_hold = voisin_max_wind_hold :/ voisin_hold
voisin_pluie_hold = voisin_pluie_hold :/ voisin_hold
// Stock dans la variables finale 
voisin_end = voisin_hold
voisin_wspeed_end = voisin_wspeed_hold
voisin_max_wind_end = voisin_max_wind_hold
voisin_pluie_end= voisin_pluie_hold
voisin_end
voisin_wspeed_end
voisin_max_wind_end
voisin_pluie_end
end

mata 
for (i=2; i<7388;i++)  {

voisin_hold=voisin[.,i]
voisin_wspeed_hold=voisin_wspeed[.,i]
voisin_max_wind_hold=voisin_max_wind[.,i]
voisin_pluie_hold=voisin_pluie[.,i]

voisin_hold = contiguity * voisin_hold
voisin_wspeed_hold = contiguity * voisin_wspeed_hold
voisin_max_wind_hold = contiguity * voisin_max_wind_hold
voisin_pluie_hold = contiguity * voisin_pluie_hold

voisin_wspeed_hold = voisin_wspeed_hold :/ voisin_hold
voisin_max_wind_hold = voisin_max_wind_hold :/ voisin_hold
voisin_pluie_hold = voisin_pluie_hold :/ voisin_hold

voisin_end = voisin_end \ voisin_hold
voisin_wspeed_end = voisin_wspeed_end \ voisin_wspeed_hold
voisin_max_wind_end = voisin_max_wind_end \ voisin_max_wind_hold
voisin_pluie_end= voisin_pluie_end \ voisin_pluie_hold

}
end
// Import of Mata vectors obtained into Stata 
mata 
// add the new variable to the current Stata data set
resindex1 = st_addvar("float","voisin_wspeed_end")
resindex2 = st_addvar("float","voisin_max_wind_end")
resindex3 = st_addvar("float","voisin_pluie_end")
// store the calculated values in the new Stata variable
st_store((1,rows(voisin_wspeed_end)),resindex1,voisin_wspeed_end)
st_store((1,rows(voisin_max_wind_end)),resindex2,voisin_max_wind_end)
st_store((1,rows(voisin_pluie_end)),resindex3,voisin_pluie_end)
end 
replace wspeed_nm=voisin_wspeed_end if OMM==0 & wspeed_nm==0
replace max_wind_nm=voisin_max_wind_end if OMM==0 & max_wind_nm==0
replace pluie_nm=voisin_pluie_end if OMM==0 & pluie_nm==0
replace OMM_nm = ~(wspeed_nm==. & max_wind_nm==. & pluie_nm==.)
codebook OMM_nm
replace wspeed_nm=0 if wspeed_nm==. & max_wind_nm==. & pluie_nm==.
replace max_wind_nm=0 if wspeed_nm==0 & max_wind_nm==. & pluie_nm==.
replace pluie_nm=0 if wspeed_nm==0 & max_wind_nm==0 & pluie_nm==.

* SECOND ROUND
sort date2 DEP /* très important car la matrice de contiguité est construite de ZE ࡚E et on doit avoir ZE1 ZE2 ZE3 ࡬a suite */
matrix voisin = J(96, 7387, 0)
matrix voisin_wspeed = J(96, 7387, 0)
matrix voisin_max_wind = J(96, 7387, 0)
matrix voisin_pluie = J(96, 7387, 0) /*initialisation matrice remplie de 0 format (96,96)*/
* Matrices 96 x 7387
local counter 1
forvalues j = 1/7387 {  /*LOOP OVER COLUMNS*/
    forvalues i = 1/96 { /*LOOP OVER ROWS OF TARGET*/
		matrix voisin[`i',`j'] = OMM_nm[`counter'] 
        matrix voisin_wspeed[`i',`j'] = wspeed_nm[`counter'] 
		matrix voisin_max_wind[`i',`j'] = max_wind_nm[`counter'] 
		matrix voisin_pluie[`i',`j'] = pluie_nm[`counter'] 
        local ++counter
     }
}

mata 
// Import of Mata vectors obtained into Stata 
voisin = st_matrix("voisin")
voisin_wspeed = st_matrix("voisin_wspeed")
voisin_max_wind = st_matrix("voisin_max_wind")
voisin_pluie = st_matrix("voisin_pluie") 
contiguity = st_matrix("contiguity")
// Initialization
voisin_hold=voisin[.,1]
voisin_wspeed_hold=voisin_wspeed[.,1]
voisin_max_wind_hold=voisin_max_wind[.,1]
voisin_pluie_hold=voisin_pluie[.,1]
// Sum of neighbour values
voisin_hold = contiguity * voisin_hold
voisin_wspeed_hold = contiguity * voisin_wspeed_hold
voisin_max_wind_hold = contiguity * voisin_max_wind_hold
voisin_pluie_hold = contiguity * voisin_pluie_hold
// Moyenne en divisant par le nombre de voisins ayant des observations / division par 0 non prise en charge
voisin_wspeed_hold = voisin_wspeed_hold :/ voisin_hold
voisin_max_wind_hold = voisin_max_wind_hold :/ voisin_hold
voisin_pluie_hold = voisin_pluie_hold :/ voisin_hold
// Stock dans la variables finale 
voisin_end = voisin_hold
voisin_wspeed_end = voisin_wspeed_hold
voisin_max_wind_end = voisin_max_wind_hold
voisin_pluie_end= voisin_pluie_hold
// Display to see if all values are covered (if not another round will be necessary) 
voisin_end
voisin_wspeed_end
voisin_max_wind_end
voisin_pluie_end
end

mata 
for (i=2; i<7388;i++)  {

voisin_hold=voisin[.,i]
voisin_wspeed_hold=voisin_wspeed[.,i]
voisin_max_wind_hold=voisin_max_wind[.,i]
voisin_pluie_hold=voisin_pluie[.,i]

voisin_hold = contiguity * voisin_hold
voisin_wspeed_hold = contiguity * voisin_wspeed_hold
voisin_max_wind_hold = contiguity * voisin_max_wind_hold
voisin_pluie_hold = contiguity * voisin_pluie_hold

voisin_wspeed_hold = voisin_wspeed_hold :/ voisin_hold
voisin_max_wind_hold = voisin_max_wind_hold :/ voisin_hold
voisin_pluie_hold = voisin_pluie_hold :/ voisin_hold

voisin_end = voisin_end \ voisin_hold
voisin_wspeed_end = voisin_wspeed_end \ voisin_wspeed_hold
voisin_max_wind_end = voisin_max_wind_end \ voisin_max_wind_hold
voisin_pluie_end= voisin_pluie_end \ voisin_pluie_hold

}
end

// Import in Stata Mata vectors obtained 
mata 
// add the new variable to the current Stata data set
resindex1 = st_addvar("float","voisin_wspeed_end2")
resindex2 = st_addvar("float","voisin_max_wind_end2")
resindex3 = st_addvar("float","voisin_pluie_end2")
// store the calculated values in the new Stata variable
st_store((1,rows(voisin_wspeed_end)),resindex1,voisin_wspeed_end)
st_store((1,rows(voisin_max_wind_end)),resindex2,voisin_max_wind_end)
st_store((1,rows(voisin_pluie_end)),resindex3,voisin_pluie_end)
end 

replace wspeed_nm=voisin_wspeed_end2 if OMM_nm==0
replace max_wind_nm=voisin_max_wind_end2 if OMM_nm==0
replace pluie_nm=voisin_pluie_end2 if OMM_nm==0
replace OMM_nm = ~(wspeed_nm==. & max_wind_nm==. & pluie_nm==.)
codebook OMM_nm

* SI ON VEUT FAIRE UNE CARTE EVOLUTIVE IL FAUT LE FAIRE AVANT 
drop voisin_wspeed_end* voisin_max_wind_end* voisin_pluie_end*
drop INSEE n_voisin nom region
compress
rename date2 dat_deb
save .\data\meteo\choc_meteo_final, replace /* end - go back to meteorological data */
* We end up with the .\meteo\choc_meteo_final dataset (completed average based on neighbours)

*========================= RAIN + DECREE MERGE =============================
* Summary statistics: rain + gaspar
use .\data\meteo\choc_meteo_final, clear 
replace wspeed = wspeed_nm if wspeed==.
replace max_wind = max_wind_nm if max_wind==.
replace pluie = pluie_nm if pluie==.
drop wspeed_nm max_wind_nm pluie_nm OMM_nm
keep DEP dat_deb numer_sta wspeed max_wind pluie OMM
rename dat_deb day
gen year=year(day)
gen m_ouv=month(day)
*drop if year<2008
merge m:m DEP day using .\data\gaspar\gaspar
tab _m if (pluie>75 & pluie~=.) /* after 75 mm, the number of disaster do no increase anymore */ 
br if _m==3 & (pluie>75 & pluie~=.)
drop _m

* Renaming and labeling the dataset  
rename (numer_sta /*date2 nom INSEE dptmt region*/ wspeed max_wind pluie) ///
(station_ID /*day station_name ZIP DEP REG*/ wspeed wmax rain)
label variable station_ID "ID of the WMO station"
label variable day "Record date"
*label variable station_name "Station name"
*label variable ZIP "ZIP of the station"
label variable DEP "Département of the station"
*label variable REG "Region of the station"
label variable wspeed "Average windspeed (m/s) the last 24 hours before d_record"
label variable wmax "Maximum windspeed (m/s) the last 24 hours before d_record"
label variable rain "Precipitation (mm) the last 24 hours before d_record"
sort DEP day
by DEP : gen rain_3=rain[_n-2]+rain[_n-1]+rain[_n] if rain[_n-2]~=. & rain[_n-1]~=. & rain[_n]~=.
replace n_hit=0 if n_hit==.
*rename ZIP n_hit
save .\data\meteo\choc_meteo_final2, replace /* contains information on decrees + meteorological observations */


*==========================================================================================
*						RAIN VS DECREE (FIRST ANALYSIS)
*==========================================================================================

* Number of towns of the Departement  
import excel ".\data\departement\ensemble.xls", sheet("Départements") cellrange(A8:J109) firstrow clear
drop Coderégion Nomdelarégion Nomdudépartement Nombredarrondissements Nombredecantons Populationmunicipale J
rename (Codedépartement Nombredecommunes Populationtotale) (DEP n_town pop)
merge m:m DEP using .\data\meteo\choc_meteo_final2 /* merged with the shock */
drop if _m==1
drop _m
gen p_hit=n_hit/n_town
gen quarter=quarter(day)

* Computing the ratio by Departement 
encode DEP, gen(Departement)
gen r_rain=.
gen r_wmax2=.
gen r_rain_32=.
levelsof Departement, local(dep)
foreach var of local dep {
	quietly : sum rain if Departement==`var' & year<2008
	quietly : replace r_rain=rain/r(mean) if Departement==`var'
	quietly : sum rain_3 if Departement==`var' & year<2008
	quietly : replace r_rain_3=rain_3/r(mean) if Departement==`var'
	quietly : sum wmax if Departement==`var' & year<2008
	quietly : replace r_wmax=wmax/r(mean) if Departement==`var'
}

drop if day==.
sort DEP
replace p_hit=p_hit*100 /* to be put in percentage */
replace p_hit = 100 if p_hit>100 /* correction for more than 100% */ 
sum p_hit, d
save .\data\meteo\choc_meteo_final2, replace

* Neighbouring analysis of rain vs decree - GETTING NEIGHBOUR VALUES/AVERAGES 
set matsize 11000
import delimited ".\data\departement\contiguity.txt", delimiter(" ") clear
drop v98-v102
drop if _n==1 | _n>97
mkmat v2-v97, mat(contiguity) /* * - mkmat - transform variables into stata matrix */
egen n_voisin = rowtotal(v2-v97)
keep v1 n_voisin
rename v1 id 
merge 1:1 id using .\data\departement\FondsCartesDEP.dta
drop _m
rename CODE_DEPT DEP
merge m:m DEP using .\data\meteo\choc_meteo_final2
drop _m
drop if year==.
sort DEP
drop Departement
encode DEP, gen(Departement)
xtset Departement day
tsfill, full
sort day DEP /* very important to have DEP1 DEP2 DEP3 in a row */
matrix rain = J(96, 7387, 0)
matrix n_neighbour = J(96, 7387, 0)
matrix decree = J(96, 7387, 0)
gen rain_nm=r_rain
gen n_neighbour_nm=1
gen decree_nm = p_hit
local counter 1
forvalues j = 1/7387 {  /*LOOP OVER COLUMNS*/
    forvalues i = 1/96 { /*LOOP OVER ROWS OF TARGET*/
        matrix rain[`i',`j'] = rain_nm[`counter']
        matrix n_neighbour[`i',`j'] = n_neighbour_nm[`counter'] 
        matrix decree[`i',`j'] = decree_nm[`counter'] 
        local ++counter
     }
}
set more off 
mata // Import dans Mata des variables Stata
neighbour = st_matrix("n_neighbour")
neighbour_rain = st_matrix("rain")
neighbour_decree = st_matrix("rain")
contiguity = st_matrix("contiguity")
neighbour_hold=neighbour[.,1] // init
neighbour_rain_hold=neighbour_rain[.,1] // init
neighbour_decree_hold=neighbour_decree[.,1] // init
neighbour_hold = contiguity * neighbour_hold // somme voisin
neighbour_rain_hold = contiguity * neighbour_rain_hold // sum neighbour rain
neighbour_decree_hold = contiguity * neighbour_decree_hold // sum neighbour decree
average_neighbour_rain_hold = neighbour_rain_hold :/ neighbour_hold // average neighbour rain
average_neighbour_decree_hold = neighbour_decree_hold :/ neighbour_hold // average neighbour decree
neighbour_rain_end = neighbour_rain_hold // stock variable finale 
average_neighbour_rain_end = average_neighbour_rain_hold
neighbour_decree_end = neighbour_decree_hold // stock variable finale 
average_neighbour_decree_end = average_neighbour_decree_hold
neighbour_rain_end  // Display to see if all values are covered (if not another round will be necessary) 
average_neighbour_rain_end
neighbour_decree_end  // Display to see if all values are covered (if not another round will be necessary) 
average_neighbour_decree_end
end
mata 
for (i=2; i<7388;i++)  {
neighbour_hold=neighbour[.,i]
neighbour_hold = contiguity * neighbour_hold 
neighbour_rain_hold=neighbour_rain[.,i] // rain
neighbour_rain_hold = contiguity * neighbour_rain_hold
average_neighbour_rain_hold = neighbour_rain_hold :/ neighbour_hold 
neighbour_rain_end = neighbour_rain_end \ neighbour_rain_hold
average_neighbour_rain_end = average_neighbour_rain_end \ average_neighbour_rain_hold
neighbour_decree_hold=neighbour_decree[.,i] // decree
neighbour_decree_hold = contiguity * neighbour_decree_hold
average_neighbour_decree_hold = neighbour_decree_hold :/ neighbour_hold 
neighbour_decree_end = neighbour_decree_end \ neighbour_decree_hold
average_neighbour_decree_end = average_neighbour_decree_end \ average_neighbour_decree_hold
}
end 
mata // To get the maximum value of neighbours 
contiguity_hold=contiguity // init
for (i=1; i<97;i++) {
	for (j=1; j<97;j++) {
		if (contiguity[i,j]==1) contiguity_hold[i,j]=neighbour_rain[j,1] /* for each column the value assigned to the row DEP */
		if (contiguity[i,j]==1) contiguity_hold[i,j]=neighbour_decree[j,1] /* for each column the value assigned to the row DEP */
	}
}
max_rain=rowmax(contiguity_hold)
max_rain_end=max_rain
max_rain_end
max_decree=rowmax(contiguity_hold)
max_decree_end=max_decree
max_decree_end
end
mata
for (k=2; k<7388;k++) { // for each time value k 
	contiguity_hold=contiguity
	for (i=1; i<97;i++) {
		for (j=1; j<97;j++)  {
			if (contiguity[i,j]==1) contiguity_hold[i,j]=neighbour_rain[j,k]
			if (contiguity[i,j]==1) contiguity_hold[i,j]=neighbour_decree[j,k]
		}
	}
	max_rain=rowmax(contiguity_hold)
	max_rain_end = max_rain_end \ max_rain
	max_decree=rowmax(contiguity_hold)
	max_decree_end = max_decree_end \ max_decree
}
end
capture drop neighbour_rain average_neighbour_rain max_rain
mata // Import dans Stata des vecteurs Mata obtenus 
resindex1 = st_addvar("float","neighbour_rain_end") // add the new variable to the current Stata data set
resindex2 = st_addvar("float","average_neighbour_rain_end") // add the new variable to the current Stata data set
resindex3 = st_addvar("float","max_rain_end") // add the new variable to the current Stata data set
st_store((1,rows(neighbour_rain_end)),resindex1,neighbour_rain_end) // store the calculated values in the new Stata variable
st_store((1,rows(average_neighbour_rain_end)),resindex2,average_neighbour_rain_end) // store the calculated values in the new Stata variable
st_store((1,rows(max_rain_end)),resindex3,max_rain_end) // store the calculated values in the new Stata variable
resindex4 = st_addvar("float","neighbour_decree_end") // add the new variable to the current Stata data set
resindex5 = st_addvar("float","average_neighbour_decree_end") // add the new variable to the current Stata data set
resindex6 = st_addvar("float","max_decree_end") // add the new variable to the current Stata data set
st_store((1,rows(neighbour_decree_end)),resindex4,neighbour_decree_end) // store the calculated values in the new Stata variable
st_store((1,rows(average_neighbour_decree_end)),resindex5,average_neighbour_decree_end) // store the calculated values in the new Stata variable
st_store((1,rows(max_decree_end)),resindex6,max_decree_end) // store the calculated values in the new Stata variable
end 

* Formatting variables 
rename (neighbour_rain_end average_neighbour_rain_end max_rain_end neighbour_decree_end average_neighbour_decree_end max_decree_end) ///
(neighbour_rain average_neighbour_rain neighbour_max_rain neighbour_decree average_neighbour_decree max_decree)
label variable r_rain "Rain ratio = rain / rain average"
label variable average_neighbour_rain "Neighbour rain ratio average"
label variable neighbour_max_rain "Neighbour maximum rain ratio"
label variable p_hit "Percentage of the municipalities in the Département with decree"

gen qdate=string(year)+"q"+string(quarter)
gen qtime=quarterly(qdate, "YQ")
format qtime %tq

* Different specifications for decree vs rain (not dummies - day basis)
xtset Departement day  
sort DEP day 
by DEP: gen r_rain_1=r_rain[_n-1]
pwcorr p_hit rain r_rain neighbour_rain average_neighbour_rain neighbour_max_rain if year<2019 & year>2007
* Correlation between rain and decrees
estpost corr p_hit rain r_rain neighbour_rain average_neighbour_rain neighbour_max_rain
esttab using ".\sum_stats\correlation_rain_decree.tex", replace

* Decree dummy 
capture drop big_decree*
gen big_decree30=(p_hit>30 & p_hit~=.)
gen big_decree50=(p_hit>50 & p_hit~=.)
gen big_decree75=(p_hit>75 & p_hit~=.)
gen big_decree90=(p_hit>90 & p_hit~=.)
gen big_decree5=(p_hit>5 & p_hit~=.) 
gen big_neighbour50=(max_decree>50 & max_decree~=. & big_decree50==0) 
gen big_neighbour75=(max_decree>75 & max_decree~=. & big_decree75==0) 
gen big_neighbour90=(max_decree>90 & max_decree~=. & big_decree90==0) 

* Rain measurement distributions
hist r_rain if r_rain<100 & r_rain>0, color(ebblue) lcolor(white) bin(40) title("Rain ratio distribution", size(medium)) graphregion(color(white)) 
graph export ".\graphs\rain_ratio_distribution.png", as(png) replace
hist r_rain if big_decree50==1, color(ebblue) lcolor(white) bin(20) title("Rain ratios when more than" "50% of the municipalities are hit by a natural disaster", size(medium)) graphregion(color(white)) 
graph export ".\graphs\rain_ratio_if_decree.png", as(png) replace
hist average_neighbour_rain if big_decree50==1, color(ebblue) lcolor(white) bin(20) title("Neighbour rain ratios average when more than" "50% of the municipalities are hit by a natural disaster", size(medium)) graphregion(color(white)) 
graph export ".\graphs\neighbour_rain_ratio_if_decree.png", as(png) replace
hist neighbour_max_rain if big_decree50==1, color(ebblue) lcolor(white) bin(20) title("Neighbour maximum rain ratios when more than" "50% of the municipalities are hit by a natural disaster", size(medium)) graphregion(color(white)) 
graph export ".\graphs\neighbour_max_rain_ratio_if_decree.png", as(png) replace

* Rain distribution when there is no decree vs when there is a decree
twoway (histogram r_rain if big_decree50==1 & r_rain<50, bin(40) /*start(30) width(5)*/ color(green)) ///
       (histogram r_rain if big_decree50==0 & r_rain<50, /*start(30) width(5)*/ ///
	   fcolor(none) lcolor(black)), legend(order(1 "Disaster" 2 "Normal" )) ///
	   title("Rain ratios distribution when more than" "50% of the municipalities are hit by a natural disaster", size(medium)) graphregion(color(white))
graph export ".\graphs\rain_ratio_if_decree.png", as(png) replace
twoway (histogram average_neighbour_rain if big_decree50==1 & average_neighbour_rain<50, bin(40) /*start(30) width(5)*/ color(green)) ///
       (histogram average_neighbour_rain if big_decree50==0 & average_neighbour_rain<50, /*start(30) width(5)*/ ///
	   fcolor(none) lcolor(black)), legend(order(1 "Disaster" 2 "Normal" )) ///
	   title("Neighbour rain ratios average when more than" "50% of the municipalities are hit by a natural disaster", size(medium)) graphregion(color(white)) 
graph export ".\graphs\neighbour_rain_ratio_if_decree.png", as(png) replace
twoway (histogram neighbour_max_rain if big_decree50==1 & neighbour_max_rain<100, bin(40) /*start(30) width(5)*/ color(green)) ///
       (histogram neighbour_max_rain if big_decree50==0 & neighbour_max_rain<100, /*start(30) width(5)*/ ///
	   fcolor(none) lcolor(black)), legend(order(1 "Disaster" 2 "Normal" )) ///
	   title("Neighbour maximum rain ratios when more than" "50% of the municipalities are hit by a natural disaster", size(medium)) graphregion(color(white)) 
graph export ".\graphs\neighbour_max_rain_ratio_if_decree.png", as(png) replace

* Rain dummies based on different thresholds 
gen log_rain = ln(1+rain)
gen rain_sq = rain^2
gen big_rain10=(r_rain>10 & r_rain~=.) 
gen big_rain15=(r_rain>15 & r_rain~=.) 
gen big_rain20=(r_rain>20 & r_rain~=.) 
gen big_rain25=(r_rain>25 & r_rain~=.) 
gen big_rain30=(r_rain>30 & r_rain~=.) 
gen big_rain40=(r_rain>40 & r_rain~=.) 
gen big_rain50=(r_rain>50 & r_rain~=.) 
save .\data\econometrics\rain_vs_decree, replace

* From day to quarter 
use .\data\econometrics\rain_vs_decree, clear
collapse (max) big_decree* wspeed wmax rain r_rain n_hit big_rain* rain_3 p_hit ///
neighbour_rain average_neighbour_rain neighbour_max_rain neighbour_decree ///
average_neighbour_decree max_decree, by(DEP year quarter qtime)
label variable r_rain "Rain ratio = rain / rain average"
label variable average_neighbour_rain "Neighbour rain ratio average"
label variable neighbour_max_rain "Neighbour maximum rain ratio"
label variable p_hit "Maximum percentage of the municipalities with decree the same day"
label variable qtime "Quarter-year"
label variable big_decree5 "Percentage of municipalities with decree > 5%"
label variable big_decree30 "Percentage of municipalities with decree > 30%"
label variable big_decree50 "Percentage of municipalities with decree > 50%"
label variable big_decree75 "Percentage of municipalities with decree > 75%"
label variable big_decree90 "Percentage of municipalities with decree > 90%"
label variable wspeed "Average wind speed record"
label variable wmax "Maximum wind speed record"
label variable rain "Precipitations (in mm)"
label variable r_rain "Rain ratio = Rain / E(rain)"
label variable n_hit "Number of municipalities with decree"
label variable big_rain10 "Rain ratio > 10"
label variable big_rain15 "Rain ratio > 15"
label variable big_rain20 "Rain ratio > 20"
label variable big_rain25 "Rain ratio > 25"
label variable big_rain30 "Rain ratio > 30"
label variable big_rain40 "Rain ratio > 40"
label variable big_rain50 "Rain ratio > 50"
label variable rain_3 "Rain on 3 days"
label variable neighbour_rain "Average rain of neighbours" 
label variable average_neighbour_decree "Average percentage of decree in neighbourhood" 
label variable max_decree "Maximum percentage of neighbours with decree"
saveold .\data\econometrics\summary_statistics, version(12) replace
