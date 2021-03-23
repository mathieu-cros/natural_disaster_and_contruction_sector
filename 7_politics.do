
cd "D:\OneDrive - Université Paris-Dauphine\Tesis\data\"

*==========================================================================================
*						 			MAYORS 
*==========================================================================================

*=================================== 2008 ================================================= 
* 1st and 2nd ROUND - Municipalities with more than 3500 inhabitants 
forvalues tour=1(1)2 {
	import excel ".\departement\elections_mun_2008_3500plus.xls", sheet("Tour `tour'") firstrow clear
	local counter = 1 /* need to rename columns since as many cells as running mayors */
	foreach var of varlist Y-FC {
		rename `var' v`counter'
		local ++counter
	}
	rename (CodeNuance Sexe Nom Prénom Liste Sieges Voix VoixIns VoixExp) ///
	(CodeNuance0 Sexe0 Nom0 Prénom0 Liste0 Sieges0 Voix0 VoixIns0 VoixExp0)
	local counter = 1 /* standard names in order to reshape the dataset */
	forvalues j=1(9)135 {
		local i=`j'+1
		local k=`j'+2
		local l=`j'+3
		local m=`j'+4
		local n=`j'+5
		local o=`j'+6
		local p=`j'+7
		local q=`j'+8
		rename (v`j' v`i' v`k' v`l' v`m' v`n' v`o' v`p' v`q') ///
		(CodeNuance`counter' Sexe`counter' Nom`counter' Prénom`counter' ///
		Liste`counter' Sieges`counter' Voix`counter' VoixIns`counter' VoixExp`counter')	
		local ++counter
	}
	rename Codedudépartement DEP /* building ZIP code based on Departement and Commune code */
	rename Codedelacommune COM 
	replace DEP="0"+DEP if length(DEP)==1
	replace COM="0"+COM if length(COM)==2
	replace COM="00"+COM if length(COM)==1
	gen ZIP=DEP+COM
	tostring CodeNuance* Sexe* Nom* Prénom* Liste*, replace /* issue with formats - solved */
	destring Voix* VoixIns* VoixExp*, replace
	tostring AbsIns VotIns BlNulsIns BlNulsVot ExpIns ExpVot, replace
	replace AbsIns=subinstr(AbsIns, ",", ".", 1)
	replace VotIns=subinstr(VotIns, ",", ".", 1)
	replace BlNulsIns=subinstr(BlNulsIns, ",", ".", 1)
	replace BlNulsVot=subinstr(BlNulsVot, ",", ".", 1)
	replace ExpIns=subinstr(ExpIns, ",", ".", 1)
	replace ExpVot=subinstr(ExpVot, ",", ".", 1)
	destring AbsIns VotIns BlNulsIns BlNulsVot ExpIns ExpVot, replace
	drop Sieges*
	*destring Sieges7, force replace /* RESHAPED DATA */
	reshape long CodeNuance Sexe Nom Prénom Liste Voix VoixIns VoixExp, i(ZIP) j(Runnercode)
	drop if CodeNuance=="" & Nom=="" & Prénom==""
	drop if CodeNuance=="" & Nom=="." & Prénom=="."
	capture drop gagnant /* keep only the winner of the election (with the most votes) */
	by ZIP: egen gagnant=max(Voix) 
	*br if gagnant==.
	*keep if gagnant==Voix
	*keep if VoixExp>0.5
	*tab CodeNuance
	save .\departement\gagnant_2008_tour`tour', replace
}



use .\departement\gagnant_2008_tour1, clear /* Treating party belonging */
keep if VoixExp>50
append using .\departement\gagnant_2008_tour2 /* 1st and 2nd round - APPEND */
compress
tab CodeNuance 
rename CodeNuance party
label define politics_label 1 "Far-left" 2 "Left" 3 "Regional" 4 "Center" 5 "Right" 6 "Far-right" 
gen political_edge=1 if party=="LFI" | party=="LCOM" | party=="LEXG" | party=="LFG"
replace political_edge=2 if party=="LRDG" | party=="LDVG" | party=="LPG" | party=="LSOC" | party=="LUG" | party=="LVEC" | party=="LGC"
replace political_edge=3 if party=="LREG" | party=="NC" | party=="LAUT"
replace political_edge=4 if party=="LMDM" | party=="LUC" | party=="LUDI" | party=="LCMD" | party=="LMC" | party=="LMAJ"
replace political_edge=5 if party=="LDVD" | party=="LUD" | party=="LUMP" 
replace political_edge=6 if party=="LRN" | party=="LEXD" | party=="LFN"
tab party
label values political_edge politics_label
gen election = 2008
drop if Sexe==""
bysort ZIP: gen dup=_n 
br if dup>1
drop if dup>1
drop if substr(ZIP, 1, 1)=="Z"
rename (Libellédudépartement Libellédelacommune Inscrits Abstentions AbsIns ///
Votants VotIns Blancsetnuls BlNulsIns BlNulsVot Exprimés ExpIns ExpVot Sexe Nom Prénom ///
Liste Voix VoixIns VoixExp) (label_DEP label_ZIP registered abstentions p_abs votants ///
p_votants blank blank_registered p_blank valid valid_registered p_valid sex surname ///
firstname list votes votes_registered p_votes)
save .\departement\gagnant_2008_3500plus, replace

* 1st and 2nd ROUND - Municipalities with less than 3500 inhabitants 
import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\elections_mun_2008_3500moins.xls", sheet("OM 01-15") firstrow clear
save .\departement\gagnant_2008_3500moins, replace
foreach var in "16-26" "37-34" "35-48" {
	import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\elections_mun_2008_3500moins.xls", sheet(`var') firstrow clear
	tostring Codedépartement, replace
	append using .\departement\gagnant_2008_3500moins
	save .\departement\gagnant_2008_3500moins, replace
}
foreach var in "49-59" "60-69" "70-79" "80-88" "89-95" {
	import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\elections_mun_2008_3500moins2.xls", sheet(`var') firstrow clear
	tostring Codedépartement, replace
	append using .\departement\gagnant_2008_3500moins
	save .\departement\gagnant_2008_3500moins, replace
}
use .\departement\gagnant_2008_3500moins, clear
rename Codedépartement DEP 
rename Codecommune COM 
replace DEP="0"+DEP if length(DEP)==1
replace COM="0"+COM if length(COM)==2
replace COM="00"+COM if length(COM)==1
gen ZIP=DEP+COM
sort ZIP
by ZIP: egen max_TOURELECTIONcandidatélu=max(TOURELECTIONcandidatélu)
keep if max_TOURELECTIONcandidatélu==TOURELECTIONcandidatélu
codebook ZIP
capture drop gagnant
gsort ZIP -VOIX
by ZIP: gen gagnant=_n
drop if gagnant>1
codebook ZIP
replace ZIP=substr(ZIP, 1, 5)
drop if substr(ZIP, 1, 1)=="Z"
rename (Département Libellédelacommune TOURELECTIONcandidatélu Nombreinscrits ///
Nombreabstention ABS Nombrevotants VOT NombreBlancsetnuls BLCNUL Nombreexprimés EXP ///
Nombrevoix VOIX Sexe Nom Prénom) ///
(label_DEP label_ZIP round registered abstentions p_abs votants ///
p_votants blank p_blank valid p_valid votes p_votes sex surname ///
firstname)
save .\departement\gagnant_2008_3500moins, replace 

use .\departement\gagnant_2008_3500plus, clear
append using .\departement\gagnant_2008_3500moins 
replace political_edge=3 if political_edge==. /* no party for municipalities with less than 1000 inhabitants */
replace ZIP="132"+substr(COM, -2, 2) if substr(ZIP, 1, 5)=="13055" & length(ZIP)>5
replace ZIP="6938"+substr(COM, -1, 1) if substr(ZIP, 1, 5)=="69123" & length(ZIP)>5
replace ZIP="751"+substr(COM, -2, 2) if substr(ZIP, 1, 5)=="75056" & length(ZIP)>5
drop dup 
sort ZIP /* to get the doubles (investigate the sections : 2 etc...)*/
by ZIP: gen dup=_n /* in mind to keep the more than 3500 */
br if dup>1
drop if dup>1
codebook political_edge
rename ZIP INSEE_COM
merge m:m INSEE_COM using .\departement\communes
br if _m==2 /* Paris, Marseille, Lyon treated before */
drop if _m==1
spmap political_edge using .\departement\Coord_communes.dta, id(id) clmethod(unique) ///
fcolor(Paired) ocolor(Paired) polygon(data(.\departement\Coord_DEP)) /// 
label(data(.\departement\villes) xcoord(X_CENTROID)  ycoord(Y_CENTROID) ///
label(NOM_COM) /*by(labtype)*/  size(*0.85 ..)) legtitle("Political Edge") /*leglabel(0 "Not hit" 1 "Hit")*/ legcount ///
title("Political edge of mayor in French municipalities (2008)", size(small)) /*options graphique */
graph export "D:\OneDrive - Université Paris-Dauphine\Tesis\maps\mayors_2008.png", as(png) replace
rename INSEE_COM ZIP
keep ZIP DEP label_DEP COM label_ZIP party sex surname firstname political_edge election
save .\departement\maires_2008, replace 


*=================================== 2014 ================================================= 

* 1st and 2nd ROUND - Municipalities with more than 1000 inhabitants 
*import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\elections_mun_2008_3500plus.xls", sheet("Tour 1") firstrow clear
forvalues tour=1(1)2 {
	import delimited "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\election_mun_2014_1000plus_t`tour'.csv", clear delimiter(";") varnames(1)
	if (`tour'==1) { 
		local nloop=1096
	} 
	else {
		local nloop=623
	}
	local counter = 1
	forvalues j=29(11)`nloop' {
			local i=`j'+1
			local k=`j'+2
			local l=`j'+3
			local m=`j'+4
			local n=`j'+5
			local o=`j'+6
			local p=`j'+7
			local q=`j'+8
			local r=`j'+9
			local s=`j'+10
			rename (v`j' v`i' v`k' v`l' v`m' v`n' v`o' v`p' v`q' v`r' v`s') ///
			(CodeNuance`counter' Sexe`counter' Nom`counter' Prénom`counter' ///
			Liste`counter' siãgeselu`counter' siãgessecteur`counter' siãgescc`counter' ///
			Voix`counter' VoixIns`counter' VoixExp`counter')	
			local ++counter
	}
	rename (codedudãpartement libellãdudãpartement codedelacommune libellãdelacommune ///
	inscrits abstentions absins votants votins blancsetnuls blnulsins blnulsvot ///
	exprimãs expins expvot codenuance sexe nom prãnom liste voix voixins ///
	voixexp) (Codedudépartement Libellédudépartement Codedelacommune Libellédelacommune ///
	Inscrits Abstentions AbsIns Votants VotIns Blancsetnuls BlNulsIns BlNulsVot ///
	Exprimés ExpIns ExpVot CodeNuance Sexe Nom Prénom Liste Voix VoixIns VoixExp)
	drop datedelexport typedescrutin siãgessecteur* siãgescc* siãgeselu*
	rename (CodeNuance Sexe Nom Prénom Liste Voix VoixIns VoixExp) ///
	(CodeNuance0 Sexe0 Nom0 Prénom0 Liste0 Voix0 VoixIns0 VoixExp0)
	local counter=`counter'-1
	forvalues i=0(1)`counter' {
		replace VoixIns`i'=subinstr(VoixIns`i', ",", ".", 1)
		replace VoixExp`i'=subinstr(VoixExp`i', ",", ".", 1)
	}
	rename Codedudépartement DEP 
	rename Codedelacommune COM 	
	replace DEP="0"+DEP if length(DEP)==1
	replace COM="0"+COM if length(COM)==2
	replace COM="00"+COM if length(COM)==1
	gen ZIP=DEP+COM
	tostring CodeNuance* Sexe* Nom* Prénom* Liste*, replace
	destring Voix* VoixIns* VoixExp*, replace
	reshape long CodeNuance Sexe Nom Prénom Liste Voix VoixIns VoixExp, i(ZIP) j(Runnercode)
	save .\departement\gagnant_2014_tour`tour', replace
}
use .\departement\gagnant_2014_tour1, clear
append using .\departement\gagnant_2014_tour2
drop if CodeNuance=="" & Nom=="" & Prénom==""
drop if CodeNuance=="" & Nom=="." & Prénom=="."
capture drop gagnant
by ZIP: egen gagnant=max(Voix) 
br if gagnant==.
keep if gagnant==Voix
tab CodeNuance
keep if VoixExp>50
tab CodeNuance 
rename CodeNuance party
label define politics_label 1 "Far-left" 2 "Left" 3 "Regional / Citizens" 4 "Center" 5 "Right" 6 "Far-right"  
gen political_edge=1 if party=="LFI" | party=="LCOM" | party=="LEXG" | party=="LFG"
replace political_edge=2 if party=="LRDG" | party=="LDVG" | party=="LPG" | party=="LSOC" | party=="LUG" | party=="LVEC"
replace political_edge=3 if party=="LREG" | party=="NC"
replace political_edge=4 if party=="LMDM" | party=="LUC" | party=="LUDI"
replace political_edge=5 if party=="LDVD" | party=="LUD" | party=="LUMP"
replace political_edge=6 if party=="LRN" | party=="LEXD" | party=="LFN"
label values political_edge politics_label
gen election=2014
bysort ZIP: gen dup=_n 
br if dup>1
drop if dup>1
drop if substr(ZIP, 1, 1)=="Z"
save .\departement\gagnant_2014, replace

import delimited "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\maires-17-06-2014.csv", delimiter(";") clear
rename codeinsee ZIP
merge m:m ZIP using .\departement\gagnant_2014
replace political_edge=3 if political_edge==. /* no party for municipalities with less than 1000 inhabitants */
save .\departement\gagnant_2014, replace 

use .\departement\gagnant_2014, clear
rename (Libellédudépartement Libellédelacommune Inscrits Abstentions AbsIns Votants VotIns ///
Blancsetnuls BlNulsIns BlNulsVot Exprimés ExpIns ExpVot Sexe Nom Prénom Liste Voix ///
VoixIns VoixExp) (label_DEP label_ZIP registered abstentions p_abs votants ///
p_votants blank blank_registered p_blank valid valid_registered p_valid sex surname ///
firstname list votes votes_registered p_votes)
drop _m
replace ZIP="132"+substr(COM, -2, 2) if substr(ZIP, 1, 5)=="13055" & length(ZIP)>5
replace ZIP="6938"+substr(COM, -1, 1) if substr(ZIP, 1, 5)=="69123" & length(ZIP)>5
replace ZIP="751"+substr(COM, -2, 2) if substr(ZIP, 1, 5)=="75056" & length(ZIP)>5
rename ZIP INSEE_COM
merge m:m INSEE_COM using .\departement\communes
br if _m==2
* Paris, Lyon et Marseille à traiter (récupérer les données du maire)
drop if _m==1 
spmap political_edge using .\departement\Coord_communes.dta, id(id) clmethod(unique) ///
fcolor(Paired) ocolor(Paired) polygon(data(.\departement\Coord_DEP)) /// 
label(data(.\departement\villes) xcoord(X_CENTROID)  ycoord(Y_CENTROID) ///
label(NOM_COM) /*by(labtype)*/  size(*0.85 ..)) legtitle("Political Edge") /*leglabel(0 "Not hit" 1 "Hit")*/ legcount ///
title("Political edge of mayor in French municipalities", size(small)) /*options graphique */
graph export "D:\OneDrive - Université Paris-Dauphine\Tesis\maps\mayors_2014.png", as(png) replace
rename INSEE_COM ZIP
keep ZIP DEP label_DEP COM label_ZIP party sex surname firstname political_edge election
save .\departement\maires_2014, replace

use .\departement\communes, clear
keep INSEE_COM
rename INSEE_COM ZIP
sort ZIP
forvalues j = 192(1)235 {
	gen qtime`j' = `j'
}
keep ZIP qtime*
reshape long qtime, i(ZIP)
drop _j
format qtime %tq
capture drop year quarter
tostring qtime, gen(year) format(%tq) force
gen quarter=substr(year, -1, 1)
replace year=substr(year, 1, 4)
destring year quarter, replace
save .\departement\ZIP_panel_quarter, replace 

* Variable to english + labeling 
use .\gaspar\gaspar12_init, clear
replace DEP=dptmt if DEP==""
rename (id_catnat INSEE Peril dat_deb dat_fin dur_catnat)(ND_id ZIP ND_type start end duration)
rename (annee m_catnat) (year m_ouv)
label variable ND_id "Natural disaster ID"
label variable ZIP "ZIP Code"
label variable ND_type "Natural disaster type"
label variable start "Starting date"
label variable end "Ending date"
label variable duration "Natural disaster duration"
label variable DEP "Département"
label variable POP "ZIP population"
label variable year "Year of occurrence of the natural disaster"
label variable m_ouv "Month of occurrence of the natural disaster"
label variable quarter "Quarter of occurrence of the natural disaster"
keep ND_id ZIP ND_type start end duration DEP year quarter m_ouv
codebook ND_type
rename start day 
encode ZIP, gen(ZIP2)
rename (ZIP ZIP2) (ZIP2 ZIP)
tab ND_type
keep if year>2007 & year<2019
keep if ND_type=="Inondations et coulées de boue" | ND_type=="Inondations par remontée de nappe phréatique" | ND_type=="Chocs mécaniques liés à l'action des vagues"
collapse (count) ZIP, by(ZIP2 year quarter) /*+ number of disaster by municipality quarter-year*/
rename ZIP n_hit
rename ZIP2 ZIP 
gen qdate=string(year)+"q"+string(quarter)
gen qtime=quarterly(qdate, "YQ")
format qtime %tq
merge m:m ZIP qtime using .\departement\ZIP_panel_quarter
* Paris, Marseille -> we will need to improve this because we lose it at the ZIP level (no issue at the DEP)
drop if _m==1
drop _m
save .\gaspar\gaspar_ZIP_panel, replace

use  .\gaspar\gaspar_ZIP_panel, clear
merge m:m ZIP using .\departement\maires_2014
drop if year<2014 | (year==2014 & quarter<3)
save .\gaspar\gaspar_maires, replace 
use  .\gaspar\gaspar_ZIP_panel, clear
merge m:m ZIP using .\departement\maires_2008
drop if year>2014 | (year==2014 & quarter>2)
append using .\gaspar\gaspar_maires
save .\gaspar\gaspar_maires, replace 

use .\gaspar\gaspar_maires, clear
replace n_hit=0 if n_hit==.
encode sex, gen(sex_dummy)
codebook political_edge 
gen majority=1 if (political_edge==5 & year<2012 | (year==2012 & quarter<3)) | (political_edge==2 & year>2012 | (year==2012 & quarter>2)) 
replace majority=0 if majority==. & political_edge~=.
encode DEP, gen(Departement)
encode ZIP, gen(ZIP2)
xtset ZIP2 qtime
gen decree=(n_hit>0)
gen in_sample=(year==2008 & quarter==2 & party~="")
sort ZIP
by ZIP: egen insample=max(in_sample)
drop in_sample
keep if insample==1
drop _m
merge m:m DEP qtime using .\econometrics\summary_statistics

* At the municipality scale 
logit n_hit majority r_rain sex_dummy i.qtime, fe
sum n_hit
local aver=`r(mean)'
outreg2 using ".\econometrics\mayors.tex", tex(frag pretty) replace ///
addstat("Ind. var. mean", `aver') ///
keep(n_hit r_rain majority sex_dummy) ctitle("Municipality") groupvar(majority r_rain sex_dummy) ///
title("Impact of mayors being in the same political edge", "than the government: 2008-2018") ///
addtext(Quarter-year FE, YES, Municipality FE, YES, Departement FE, NO)

collapse (count) ZIP2 (sum) n_hit majority (max) big_rain25 r_rain, by(DEP qtime quarter year)
merge m:m DEP qtime using .\econometrics\first_regressions_quarter
gen p_majority=majority/ZIP2
sort DEP qtime
by DEP: gen p_procF_1=p_procF[_n-1]
replace p_majority=0 if p_majority==.
xtset Departement qtime
sum p_hit
gen rain_ = r_rain
local aver=`r(mean)'
xtreg p_hit rain_ p_procF_1 p_procF_2 p_procF_3 p_majority i.qtime, fe vce(robust)
outreg2 using ".\econometrics\mayors_DEP.tex", tex(frag pretty) replace ///
addstat("Ind. var. mean", `aver') ///
keep(p_hit rain_ p_procF_1 p_procF_2 p_procF_3 p_majority) ctitle("Departement - Regression") ///
groupvar(rain_ p_procF_1 p_procF_2 p_procF_3 p_majority) ///
title("Impact of mayors being in the same political edge", "than the government: 2008-2018") ///
addtext(Quarter-year FE, YES, Municipality FE, NO, Departement FE, YES)
replace rain_ = big_rain25
sum big_decree50
local aver=`r(mean)'
xtreg big_decree50 rain_ p_procF_1 p_procF_2 p_procF_3 p_majority i.qtime, fe vce(robust)
outreg2 using ".\econometrics\mayors_DEP.tex", tex(frag pretty) append ///
addstat("Ind. var. mean", `aver') ///
keep(big_decree50 rain_ p_procF_1 p_procF_2 p_procF_3 p_majority) ctitle("Departement - Shock") ///
groupvar(rain_ p_procF_1 p_procF_2 p_procF_3 p_majority) ///
title("Impact of mayors being in the same political edge", "than the government: 2008-2018") ///
addtext(Quarter-year FE, YES, Municipality FE, NO, Departement FE, YES)


*==========================================================================================
*									DECREES REQUESTS
*==========================================================================================

import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\gaspar\BDarretes_complete.xlsx", sheet("BDarretes_complete") firstrow clear
rename (lib_commune cod_commune dept nom_dept region pop lat I num_risque_jo ///
lib_risque_jo dat_deb dat_fin dat_pub_arrete Franchise Décision) ///
(label_ZIP ZIP DEP label_DEP REG POP lat lon ND_code ND_type start end ///
decree_issuance franchise decision)
gen year=year(start)
gen quarter=quarter(start) 
gen month=month(start)
tab year decision if year>2007
replace ZIP="0"+ZIP if length(ZIP)==4
label variable ND_id "Natural disaster ID"
label variable ZIP "ZIP Code"
label variable ND_type "Natural disaster type"
label variable start "Starting date"
label variable end "Ending date"
label variable DEP "Département"
label variable POP "ZIP population"
label variable year "Year of occurrence of the natural disaster"
label variable month "Month of occurrence of the natural disaster"
label variable quarter "Quarter of occurrence of the natural disaster"
save .\gaspar\decree_decision, replace

* 2008 
use .\departement\gagnant_2008_tour1, clear /* Treating party belonging */
gen tour=1
append using .\departement\gagnant_2008_tour2
replace tour=2 if tour==.
drop if CodeNuance=="" & Nom=="" & Prénom==""
drop if CodeNuance=="" & Nom=="." & Prénom=="."
rename CodeNuance party
drop if party==""
br if length(ZIP)>5
replace ZIP = substr(ZIP, 1, 5) if length(ZIP)>5
collapse (sum) VoixExp Voix VoixIns (max) Inscrits Abstentions AbsIns Votants VotIns Blancsetnuls BlNulsIns BlNulsVot Exprimés ExpIns ExpVot, by(ZIP DEP party tour)
sort ZIP tour
by ZIP: egen max_tour=max(tour)
keep if tour==max_tour
*keep if VoixExp>50
*append using .\departement\gagnant_2008_tour2 /* 1st and 2nd round - APPEND */
*compress
*tab CodeNuance 
*rename CodeNuance party
label define politics_label 1 "Far-left" 2 "Left" 3 "Regional" 4 "Center" 5 "Right" 6 "Far-right" 
gen political_edge=1 if party=="LFI" | party=="LCOM" | party=="LEXG" | party=="LFG"
replace political_edge=2 if party=="LRDG" | party=="LDVG" | party=="LPG" | party=="LSOC" | party=="LUG" | party=="LVEC" | party=="LGC"
replace political_edge=3 if party=="LREG" | party=="NC" | party=="LAUT"
replace political_edge=4 if party=="LMDM" | party=="LUC" | party=="LUDI" | party=="LCMD" | party=="LMC" | party=="LMAJ"
replace political_edge=5 if party=="LDVD" | party=="LUD" | party=="LUMP" 
replace political_edge=6 if party=="LRN" | party=="LEXD" | party=="LFN"
tab party
label values political_edge politics_label
gen majority=(political_edge==5)
collapse (sum) VoixExp Voix VoixIns (max) Inscrits Abstentions AbsIns Votants VotIns Blancsetnuls BlNulsIns BlNulsVot Exprimés ExpIns ExpVot, by(ZIP DEP majority)
gsort ZIP -majority
by ZIP: gen diff=VoixExp-VoixExp[_n+1] if VoixExp[_n+1]~=.
by ZIP: egen max_majority=max(majority)
replace diff=-100 if max_majority==0
drop if majority==0 & max_majority==1
replace diff=100 if diff==.
drop if diff==100 | diff==-100
hist diff  
save .\municipale_2008_diff, replace 
use .\gaspar\decree_decision, clear
tab decision
gen asked=(decision~="")
gen issued=(decision=="Reconnue")
gen refused=(decision=="Non reconnue")
collapse (sum) issued asked if year>=2008 & year<2012, by(ZIP)
gen p_decree= issued/asked
hist p_decree
merge m:m ZIP using .\municipale_2008_diff
save .\municipale_2008_diff, replace
use .\municipale_2008_diff, clear
rdplot p_decree diff, ci(95) shade  graph_options(graphregion(color(white)) title("RD design"))
rdrobust p_decree diff

use .\departement\gagnant_2014_tour1, clear
gen tour=1
append using .\departement\gagnant_2014_tour2
replace tour=2 if tour==.
drop if CodeNuance=="" & Nom=="" & Prénom==""
drop if CodeNuance=="" & Nom=="." & Prénom=="."
rename CodeNuance party
drop if party==""
sort ZIP tour
by ZIP: egen max_tour=max(tour)
keep if tour==max_tour
label define politics_label 1 "Far-left" 2 "Left" 3 "Regional / Citizens" 4 "Center" 5 "Right" 6 "Far-right"  
gen political_edge=1 if party=="LFI" | party=="LCOM" | party=="LEXG" | party=="LFG"
replace political_edge=2 if party=="LRDG" | party=="LDVG" | party=="LPG" | party=="LSOC" | party=="LUG" | party=="LVEC"
replace political_edge=3 if party=="LREG" | party=="NC"
replace political_edge=4 if party=="LMDM" | party=="LUC" | party=="LUDI"
replace political_edge=5 if party=="LDVD" | party=="LUD" | party=="LUMP"
replace political_edge=6 if party=="LRN" | party=="LEXD" | party=="LFN"
label values political_edge politics_label
foreach var in AbsIns VotIns BlNulsIns BlNulsVot ExpIns ExpVot {
	replace `var'=subinstr(`var', ",", ".", 1)
	destring `var', replace
}
gen majority=(political_edge==2) /* left */
collapse (sum) VoixExp Voix VoixIns (max) Inscrits Abstentions AbsIns Votants VotIns Blancsetnuls BlNulsIns BlNulsVot Exprimés ExpIns ExpVot, by(ZIP DEP majority)
gsort ZIP -majority
by ZIP: gen diff=VoixExp-VoixExp[_n+1] if VoixExp[_n+1]~=.
by ZIP: egen max_majority=max(majority)
replace diff=-100 if max_majority==0
drop if majority==0 & max_majority==1
replace diff=100 if diff==.
drop if diff==100 | diff==-100
hist diff  
save .\municipale_2014_diff, replace 
use .\gaspar\decree_decision, clear
tab decision
gen asked=(decision~="")
gen issued=(decision=="Reconnue")
gen refused=(decision=="Non reconnue")
collapse (sum) issued asked if year>=2014 & year<2017, by(ZIP)
gen p_decree= issued/asked
hist p_decree
merge m:m ZIP using .\municipale_2014_diff
save .\municipale_2014_diff, replace

use .\municipale_2014_diff, clear
merge m:m ZIP using .\municipale_2008_diff
rdplot p_decree diff, ci(95) shade  graph_options(graphregion(color(white)) title("RD design"))
rdrobust p_decree diff


*==========================================================================================
*						 			DEPUTEES / MPS  
*==========================================================================================

* Passage des circonscriptions 
import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\legislative\passage_communes_circonscriptions_2012.xls", sheet("Communes de France") firstrow clear
rename (Codedéptcanton Codedépartement Nomdépartement Codecanton Nomcanton Codecommune ///
Nomcommune Circlégislative1986 Circlégislative2012) (DEP_CANT DEP label_DEP CANT label_CANT ///
ZIP label_ZIP CIRC_1986 CIRC_2012)
save .\departement\passage_communes_circonscriptions_2012, replace 
import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\legislative\passage_communes_circonscriptions_2017.xlsx", sheet("PR17_Découpage") firstrow
rename (CODEDPT NOMDPT CODECOMMUNE NOMCOMMUNE CODECIRCLEGISLATIVE CODECANTON NOMCANTON) ///
(DEP label_DEP ZIP label_ZIP CIRC_2017 CANT label_CANT)
save .\departement\passage_communes_circonscriptions_2017, replace 
use .\departement\passage_communes_circonscriptions_2012, clear
replace DEP="0"+DEP if length(DEP)==1
gen DEP_CIRC1986=DEP+"C"+CIRC_1986
gen DEP_CIRC2012=DEP+"C"+string(CIRC_2012)
drop J K L
save .\departement\passage_communes_circonscriptions_2007, replace
use .\departement\passage_communes_circonscriptions_2007, clear
replace DEP="0"+DEP if length(DEP)==1
replace ZIP="0"+ZIP if length(ZIP)==2
replace ZIP="00"+ZIP if length(ZIP)==1
replace ZIP=DEP+ZIP
replace ZIP=subinstr(ZIP, "69123AR0", "6938", .)
replace ZIP=subinstr(ZIP, "13055AR", "132", .)
replace ZIP=subinstr(ZIP, "75056AR", "751", .)
save .\departement\passage_communes_circonscriptions_2007, replace

* MPs / Legislative elections
import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\legislative\legislatives_2007.xls", sheet("Circo Leg T1") firstrow clear
gen round=1
save .\departement\legislatives_2007, replace 
import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\legislative\legislatives_2007.xls", sheet("Circo leg T2") firstrow clear
gen round=2
append using .\departement\legislatives_2007
save .\departement\legislatives_2007, replace 
import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\legislative\legislatives_2012.xls", sheet("Circo leg T1") firstrow clear
gen round=1
save .\departement\legislatives_2012, replace 
import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\legislative\legislatives_2012.xls", sheet("Circo leg T2") firstrow clear
gen round=2
append using .\departement\legislatives_2012 
save .\departement\legislatives_2012, replace 
import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\legislative\legislatives_2017.xlsx", sheet("Circo. leg. T1") cellrange(A3:JA580) firstrow clear
gen round=1
save .\departement\legislatives_2017, replace 
import excel "D:\OneDrive - Université Paris-Dauphine\Tesis\data\departement\legislative\legislatives_2017.xlsx", sheet("Circo. leg. T2") cellrange(A3:AS576) firstrow clear
gen round=2
append using .\departement\legislatives_2017 
save .\departement\legislatives_2017, replace 

forvalues i = 2007(5)2017 {
use .\departement\legislatives_`i', clear
gen Blancsetnuls = Blancs + Nuls if `i'==2017
gen BlNulsIns = Blancsetnuls / Inscrits if `i'==2017
gen BlNulsVot = Blancsetnuls / Votants if `i'==2017
rename (Codedudépartement Libellédudépartement Codedelacirconscription Libellédelacirconscription ///
Inscrits Abstentions AbsIns Votants VotIns Blancsetnuls BlNulsIns BlNulsVot Exprimés ///
ExpIns ExpVot Sexe Nom Prénom Nuance Voix VoixIns VoixExp) (DEP label_DEP CIRC_`i' label_CIRC ///
registered abstentions p_abs votants p_votants blank blank_registered p_blank valid ///
valid_registered p_valid sex surname firstname party votes votes_registered p_votes)
replace DEP="0"+DEP if length(DEP)==1
gen DEP_CIRC=DEP+"C"+string(CIRC_`i')
sort DEP_CIRC round
by DEP_CIRC: egen max_round=max(round)
keep if round==max_round
save .\departement\legislatives_`i', replace
}

use .\departement\legislatives_2007, clear
order round
local counter = 1 /* need to rename columns since as many cells as running mayors */
	foreach var of varlist W-EZ {
		rename `var' v`counter'
		local ++counter
	}
save .\departement\legislatives_2007, replace	
use .\departement\legislatives_2012, clear
order round
local counter = 1 /* need to rename columns since as many cells as running mayors */
	foreach var of varlist W-FT {
		rename `var' v`counter'
		local ++counter
	}
save .\departement\legislatives_2012, replace	
use .\departement\legislatives_2017, clear
order round
local counter = 1 /* need to rename columns since as many cells as running mayors */
	foreach var of varlist AB-JA {
		rename `var' v`counter'
		local ++counter
	}
save .\departement\legislatives_2017, replace	

forvalues var = 2007(5)2017 {
	use .\departement\legislatives_`var', clear
	if (`var'==2007) { 
		local nloop=127
		local pas=7
	} 
	else if (`var'==2012) {
		local nloop=147
		local pas=7
	}
	else {
		local nloop=226
		local pas=9
	}
	local counter = 1
	forvalues j=1(`pas')`nloop' {
			local i=`j'+1
			local k=`j'+2
			local l=`j'+3
			local m=`j'+4
			local n=`j'+5
			local o=`j'+6
			local p=`j'+7
			if (`var'==2007 | `var'==2012) { 
				rename (v`j' v`i' v`k' v`l' v`m' v`n' v`o') ///
				(sex`counter' surname`counter' firstname`counter' party`counter' ///
				votes`counter' votes_registered`counter' p_votes`counter')
			}
			else {
				rename (v`i' v`k' v`l' v`m' v`n' v`o' v`p') ///
				(sex`counter' surname`counter' firstname`counter' party`counter' ///
				votes`counter' votes_registered`counter' p_votes`counter')	
			}
			local ++counter
	}
	tostring sex* surname* firstname* party*, replace /* issue with formats - solved */
	rename (sex surname firstname party votes votes_registered p_votes) (sex0 surname0 ///
	firstname0 party0 votes0 votes_registered0 p_votes0)
save .\departement\legislatives_`var', replace
}

use .\departement\legislatives_2007, clear
drop sex17-p_votes19
reshape long sex surname firstname party votes votes_registered p_votes, i(DEP_CIRC label_CIRC registered abstentions votants blank valid) j(Runnercode)
drop if surname==""
foreach var in p_abs p_votants blank_registered p_blank valid_registered p_valid votes_registered p_votes {
replace `var'=subinstr(`var', ",", ".", 1)
}
destring p_abs p_votants blank_registered p_blank valid_registered p_valid votes_registered p_votes, replace
save .\departement\legislatives_2007, replace 
use .\departement\legislatives_2012, clear
drop sex16-v154
reshape long sex surname firstname party votes votes_registered p_votes, i(DEP_CIRC label_CIRC registered abstentions votants blank valid) j(Runnercode)
drop if surname==""
save .\departement\legislatives_2012, replace 
use .\departement\legislatives_2017, clear
drop sex22-p_votes26
reshape long sex surname firstname party votes votes_registered p_votes, i(DEP_CIRC label_CIRC registered abstentions votants blank valid) j(Runnercode)
drop if surname==""
destring p_abs p_votants blank_registered p_blank valid_registered p_valid votes_registered p_votes, replace
drop v1-v181 
drop v189 v190 v234
save .\departement\legislatives_2017, replace 

* MAPS with circonscriptions - 1986 == 2007
use .\departement\communes.dta, clear
rename INSEE_COM ZIP
merge m:m ZIP using .\departement\passage_communes_circonscriptions_2007
sort ZIP /* to get the doubles (investigate the sections : 2 etc...)*/
by ZIP: gen dup=_n /* in mind to keep the more than 3500 */
br if dup>1
drop if dup>1
drop if _m==1
mergepoly id using .\departement\Coord_communes.dta, by(DEP_CIRC1986) coor(.\departement\Coord_CIRC1986.dta) replace
drop _m
saveold .\departement\FondsCartesCIRC1986.dta, replace version(12) /* contient id */
use .\departement\FondsCartesCIRC1986.dta, clear
rename DEP_CIRC1986 DEP_CIRC
merge m:m DEP_CIRC using .\departement\legislatives_2007
drop dup
gsort DEP_CIRC -p_votes
by DEP_CIRC: gen dup=_n
drop if dup>1
drop dup
label define politics_label 1 "Far-left" 2 "Left" 3 "Regional / Citizens" 4 "Center" 5 "Right" 6 "Far-right"  
gen political_edge=1 if party=="COM" 
replace political_edge=2 if party=="RDG" | party=="DVG" | party=="UDFD" | party=="SOC" | party=="VEC"
replace political_edge=3 if party=="REG" 
replace political_edge=4 if party=="DIV" | party=="UDFD"
replace political_edge=5 if party=="DVD" | party=="MPF" | party=="UMP" | party=="MAJ"
label values political_edge politics_label
spmap political_edge using .\departement\Coord_CIRC1986.dta, id(id) clmethod(unique) ///
fcolor(Paired) /*polygon(data(.\departement\Coord_CIRC1986))*/ /// 
label(data(.\departement\villes) xcoord(X_CENTROID)  ycoord(Y_CENTROID) ///
label(NOM_COM) /*by(labtype)*/  size(*0.85 ..)) legtitle("Political Edge") /*leglabel(0 "Not hit" 1 "Hit")*/ legcount ///
title("Political edge of MPs in French Departement", size(small)) /*options graphique */

* MAPS with circonscriptions - 2012
use .\departement\communes.dta, clear
rename INSEE_COM ZIP
merge m:m ZIP using .\departement\passage_communes_circonscriptions_2007
sort ZIP /* to get the doubles (investigate the sections : 2 etc...)*/
by ZIP: gen dup=_n /* in mind to keep the more than 3500 */
br if dup>1
drop if dup>1
drop if _m==1
mergepoly id using .\departement\Coord_communes.dta, by(DEP_CIRC2012) coor(.\departement\Coord_CIRC2012.dta) replace
saveold .\departement\FondsCartesCIRC2012.dta, replace version(12) /* contient id */
use .\departement\FondsCartesCIRC2012.dta, clear
rename DEP_CIRC2012 DEP_CIRC
drop _m
merge m:m DEP_CIRC using .\departement\legislatives_2012
drop dup
gsort DEP_CIRC -p_votes
by DEP_CIRC: gen dup=_n
drop if dup>1
drop dup
label define politics_label 1 "Far-left" 2 "Left" 3 "Regional / Citizens" 4 "Center" 5 "Right" 6 "Far-right"  
codebook party 
gen political_edge=1 if party=="COM" | party=="FG"
replace political_edge=2 if party=="RDG" | party=="DVG" | party=="UDFD" | party=="SOC" | party=="VEC"
replace political_edge=3 if party=="REG" 
replace political_edge=4 if party=="DIV" | party=="UDFD" | party=="NCE"  | party=="CEN" | party=="PRV" | party=="ALLI"
replace political_edge=5 if party=="DVD" | party=="MPF" | party=="UMP" | party=="MAJ"
replace political_edge=6 if party=="EXD" 
label values political_edge politics_label
spmap political_edge using .\departement\Coord_CIRC1986.dta, id(id) clmethod(unique) ///
fcolor(Paired) /*polygon(data(.\departement\Coord_CIRC1986))*/ /// 
label(data(.\departement\villes) xcoord(X_CENTROID)  ycoord(Y_CENTROID) ///
label(NOM_COM) /*by(labtype)*/  size(*0.85 ..)) legtitle("Political Edge") /*leglabel(0 "Not hit" 1 "Hit")*/ legcount ///
title("Political edge of MPs in French Departement", size(small)) /*options graphique */

use  .\gaspar\gaspar_ZIP_panel, clear
merge m:m ZIP using .\departement\passage_communes_circonscriptions_2007
keep if party=="UMP"
merge m:m ZIP using .\departement\maires_2014
drop if year<2014 | (year==2014 & quarter<3)
save .\gaspar\gaspar_maires, replace 
use  .\gaspar\gaspar_ZIP_panel, clear
merge m:m ZIP using .\departement\maires_2008
drop if year>2014 | (year==2014 & quarter>2)
append using .\gaspar\gaspar_maires
save .\gaspar\gaspar_maires, replace 

* Computing percentage votes of the majority party
* 2007 = RIGHT 
use .\departement\legislatives_2007, clear
sort DEP_CIRC round
by DEP_CIRC: egen max_round=max(round)
keep if round==max_round
label define politics_label 1 "Far-left" 2 "Left" 3 "Regional / Citizens" 4 "Center" 5 "Right" 6 "Far-right"  
gen political_edge=1 if party=="COM" 
replace political_edge=2 if party=="RDG" | party=="DVG" | party=="UDFD" | party=="SOC" | party=="VEC"
replace political_edge=3 if party=="REG" 
replace political_edge=4 if party=="DIV" | party=="UDFD"
replace political_edge=5 if party=="DVD" | party=="MPF" | party=="UMP" | party=="MAJ"
label values political_edge politics_label
gen right=(political_edge==5)
collapse (sum) votes votes_registered p_votes (max) p_abs p_votants blank_registered p_blank valid_registered p_valid, by(DEP_CIRC right)
gsort DEP_CIRC -right
by DEP_CIRC: gen diff=p_votes-p_votes[_n+1] if p_votes[_n+1]~=.
by DEP_CIRC: egen max_right=max(right)
replace diff=-100 if max_right==0
drop if right==0 & max_right==1
replace diff=100 if diff==.
drop if diff==100 | diff==-100
hist diff  
save .\departement\legislatives_2007_diff, replace 

* 2012 = LEFT 
use .\departement\legislatives_2012, clear
sort DEP_CIRC round
capture drop max_round
by DEP_CIRC: egen max_round=max(round)
keep if round==max_round
label define politics_label 1 "Far-left" 2 "Left" 3 "Regional / Citizens" 4 "Center" 5 "left" 6 "Far-left"  
gen political_edge=1 if party=="COM" 
replace political_edge=2 if party=="RDG" | party=="DVG" | party=="UDFD" | party=="SOC" | party=="VEC"
replace political_edge=3 if party=="REG" 
replace political_edge=4 if party=="DIV" | party=="UDFD"
replace political_edge=5 if party=="DVD" | party=="MPF" | party=="UMP" | party=="MAJ"
label values political_edge politics_label
gen left=(political_edge==2)
collapse (sum) votes votes_registered p_votes (max) p_abs p_votants blank_registered p_blank valid_registered p_valid, by(DEP_CIRC left)
gsort DEP_CIRC -left
by DEP_CIRC: gen diff=p_votes-p_votes[_n+1] if p_votes[_n+1]~=.
by DEP_CIRC: egen max_left=max(left)
replace diff=-100 if max_left==0
drop if left==0 & max_left==1
replace diff=100 if diff==.
drop if diff==100 | diff==-100
hist diff  
save .\departement\legislatives_2012_diff, replace 

use .\gaspar\decree_decision, clear
merge m:m ZIP using .\departement\passage_communes_circonscriptions_2007
keep if _m==3
tab decision
gen asked=(decision~="")
gen issued=(decision=="Reconnue")
gen refused=(decision=="Non reconnue")
collapse (sum) issued asked if year>=2007 & year<2012, by(DEP DEP_CIRC1986)
gen p_decree= issued/asked
hist p_decree if p_decree~=0 & p_decree~=1
rename DEP_CIRC1986 DEP_CIRC
merge m:m DEP_CIRC using .\departement\legislatives_2007_diff
keep if _m==3 /* need to solve the 26 issues of CIRC */
save .\gaspar\decree_decision_2007_2011, replace
use .\gaspar\decree_decision, clear
merge m:m ZIP using .\departement\passage_communes_circonscriptions_2007
keep if _m==3
tab decision
gen asked=(decision~="")
gen issued=(decision=="Reconnue")
gen refused=(decision=="Non reconnue")
collapse (sum) issued asked if year>=2012 & year<2017, by(DEP DEP_CIRC2012)
gen p_decree= issued/asked
hist p_decree if p_decree~=0 & p_decree~=1
rename DEP_CIRC2012 DEP_CIRC
merge m:m DEP_CIRC using .\departement\legislatives_2012_diff
keep if _m==3 /* need to solve the 35 issues of CIRC */
save .\gaspar\decree_decision_2012_2016, replace

use .\gaspar\decree_decision_2007_2011, clear
append using .\gaspar\decree_decision_2012_2016
rdplot p_decree diff, ci(95) shade graphregion(color(white))
rdrobust p_decree diff

use .\gaspar\gaspar_maires, clear
replace n_hit=0 if n_hit==.
encode sex, gen(sex_dummy)
codebook political_edge 
gen majority=1 if (political_edge==5 & year<2012 | (year==2012 & quarter<3)) | (political_edge==2 & year>2012 | (year==2012 & quarter>2)) 
replace majority=0 if majority==. & political_edge~=.
encode DEP, gen(Departement)
encode ZIP, gen(ZIP2)
xtset ZIP2 qtime
gen decree=(n_hit>0)
gen in_sample=(year==2008 & quarter==2 & party~="")
sort ZIP
by ZIP: egen insample=max(in_sample)
drop in_sample
keep if insample==1
