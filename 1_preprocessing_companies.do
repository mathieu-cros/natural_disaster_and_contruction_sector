
cd "D:\OneDrive - Université Paris-Dauphine\Tesis\"

*===============================================================================
*						COMPANY CHARACTERISTICS
*===============================================================================

* FILLIN IN ALL ZIP CODES + SOME ENTERPRISE CHARACTERISTICS - we do it in 4 steps for computational reasons (very long step because huge dataset)
import delimited ".\data\stock_etab\StockEtablissement_utf8_geo.csv", delimiter(",") varname(1) encoding(UTF-8) rowrange(1:10000000) clear
save .\data\stock_etab\stock_etab1, replace
import delimited ".\data\stock_etab\StockEtablissement_utf8_geo.csv", delimiter(",") varname(1) encoding(UTF-8) rowrange(10000001:20000000) clear
save .\data\stock_etab\stock_etab2, replace
import delimited ".\data\stock_etab\StockEtablissement_utf8_geo.csv", delimiter(",") varname(1) encoding(UTF-8) rowrange(20000001:30000000) clear
save .\data\stock_etab\stock_etab3, replace
import delimited ".\data\stock_etab\StockEtablissement_utf8_geo.csv", delimiter(",") varname(1) encoding(UTF-8) rowrange(30000001:40000000) clear
save .\data\stock_etab\stock_etab4, replace

* We keep variables we want + pre-processing - long step 
forvalues i = 1(1)4 {
	use .\data\stock_etab\stock_etab`i', clear
	rename (etablissementsiege codecommuneetablissement)(head ZIP)
	keep siren head ZIP
	keep if head=="true"
	tostring siren, replace
	replace siren = "0"+siren if length(siren)==8
	replace siren = "00"+siren if length(siren)==7
	replace siren = substr(siren,1,3)+" "+ substr(siren,4,3)+" "+substr(siren,7,3)
	save .\data\stock_etab\stock_etab2020_`i', replace
}

* We append the 4 datasets to get the exhaustive dataset 
save .\data\stock_etab\stock_etab_ZIP, replace empty
forvalues j = 1(1)4 {
	use .\data\stock_etab\stock_etab_ZIP, clear
	append using .\stock_etab2020_`j'
	save .\data\stock_etab\stock_etab_ZIP, replace
}

*==========================================================================================
*						 	NUMBER OF ESTABLISHMENTS 
*==========================================================================================

* On compute the firm maximum number of establishment in its whole life for each company 
* (because stock_etab contains all the establishments that have been recorded by the INSEE - including non-active ones)
clear
save .\data\stock_etab\nb_etab, replace empty
forvalues i = 1(1)4 {
	use .\data\stock_etab\stock_etab`i', clear
	tostring siren, replace
	replace siren = "0"+siren if length(siren)==8
	replace siren = "00"+siren if length(siren)==7
	replace siren = substr(siren,1,3)+" "+ substr(siren,4,3)+" "+substr(siren,7,3)
	collapse (count) siret, by(siren)
	append using .\data\stock_etab\nb_etab
	save .\data\stock_etab\nb_etab, replace
}

*==========================================================================================
*							FIRM DEMOGRAPHY
*==========================================================================================

* NUMBER OF ENTERPRISE BY YEAR 
clear
save .\data\firm_demographics\firm_demography, empty
forvalues i = 2008(1)2010 {
	import delimited .\data\firm_demographics\ent`i'.csv, clear
	gen annee=`i'
	append using .\data\firm_demographics\firm_demography
	save .\data\firm_demographics\firm_demography, replace
}

clear
save .\data\firm_demographics\firm_demography2, empty
forvalues i = 2011(1)2019 {
	import delimited .\data\firm_demographics\ent`i'.csv, clear
	gen annee=`i'
	append using .\data\firm_demographics\firm_demography2
	save .\data\firm_demographics\firm_demography2, replace
}

* Number of firm by DEP year sector 
use .\data\firm_demographics\firm_demography, clear
append using .\data\firm_demographics\firm_demography2
sort dep annee a21
drop if a21=="A" | a21=="O" | a21=="D" | a21=="P" | a21=="E" /* public administration a,d education generally not subject to insolvency */
/* agriculture with bad data quality for both nb of firms and insolvency proceedings */
/* water, energy and gas companies not of interests + may be deeply affected because of capital destruction */
collapse (sum) freq, by(dep annee a21) 
save .\data\firm_demographics\firm_demography_a21, replace
* Solving double count issue
use .\data\firm_demographics\firm_demography_a21, clear
sort dep a21 annee
by dep a21: gen d_freq= (freq-freq[_n-1])/freq[_n-1]
tab a21 if d_freq<-0.4
tab a21 if d_freq>0.4 & d_freq~=.
by dep a21: replace freq=freq/2 if d_freq[_n+1]<-0.4
by dep a21: replace d_freq= (freq-freq[_n-1])/freq[_n-1]
by dep a21: replace freq=freq/2 if d_freq[_n+1]<-0.4
by dep a21: replace d_freq= (freq-freq[_n-1])/freq[_n-1]
by dep a21: replace freq=freq/2 if d_freq[_n+1]<-0.4
by dep a21: replace d_freq= (freq-freq[_n-1])/freq[_n-1]
save .\data\firm_demographics\firm_demography_a21, replace

* Number of firm by ZIP year sector 
use .\data\firm_demographics\firm_demography, clear
append using .\data\firm_demographics\firm_demography2
sort com annee a21
drop if a21=="A" | a21=="O" | a21=="D" | a21=="P" | a21=="E" /* public administration a,d education generally not subject to insolvency */
/* agriculture with bad data quality for both nb of firms and insolvency proceedings */
/* water, energy and gas companies not of interests + may be deeply affected because of capital destruction */
collapse (sum) freq, by(com annee a21) 
sort com a21 annee
replace freq=freq/2 if annee==2011 /* double count issue in 2011 */
save .\data\firm_demographics\firm_demography_com_a21, replace
saveold .\data\firm_demographics\firm_demography_com_a21, replace version(12)

* Number of firm by Departement year sector 
use .\data\firm_demographics\firm_demography_com_a21, clear 
gen DEP=substr(com, 1, 2)
collapse (sum) freq, by(DEP a21 annee)
drop if DEP==""
reshape wide freq, i(DEP annee) j(a21) string
rename annee year 
label variable freqB "Extractive industry"
label variable freqC "Manufacturing industry"
label variable freqF "Construction"
label variable freqG "Wholesale, retail, shops"
label variable freqH "Transport"
label variable freqI "Hotels and restaurants"
label variable freqJ "Information and communication"
label variable freqK "Financial activities"
label variable freqL "Real estate"
label variable freqM "Scientific activities"
label variable freqN "Administrative services"
label variable freqQ "Health industry"
label variable freqR "Arts and entertainment"
label variable freqS "Other services"
save .\data\departement\firm_demography_year_dep, replace 

* Interpolation - from year to quarter
use  .\data\departement\firm_demography_year_dep, clear
gen quarter=4
merge m:m DEP year quarter using .\bodacc\dep_sector_quarter_bodacc /* just to recup the panel */
drop if _m==1
drop if multi_siret==1
gen date=string(year)+string(quarter)
destring(date), replace
sort DEP date
foreach var in freqB freqC freqF freqG freqH freqI freqJ freqK freqL freqM freqN freqQ freqR freqS {
by DEP: ipolate `var' date, epolate gen(`var'2)
drop `var'
rename `var'2 `var'
replace `var'=round(`var')
}
keep year DEP quarter freqB freqC freqF freqG freqH freqI freqJ freqK freqL freqM freqN freqQ freqR freqS
save .\data\departement\firm_demography_quarter_dep, replace

* Summary statistics by sector/year - to be improved 
graph bar (sum) freq*, stack over(annee, label(angle(90))) /*by(a21)*/ ylabel(,angle(360)) ///
legend(label(1 "`:variable label freqB'") label(2 "`:variable label freqC'") label(3 "`:variable label freqF'") ///
label(4 "`:variable label freqG'") label(5 "`:variable label freqH'") label(6 "`:variable label freqI'") label(7 "`:variable label freqJ'") ///
label(8 "`:variable label freqK'") label(9 "`:variable label freqL'") label(10 "`:variable label freqM'") label(11 "`:variable label freqN'") ///
label(12 "`:variable label freqQ'") label(13 "`:variable label freqR'") label(14 "`:variable label freqS'") col(3) symysize(*0.7) size(*0.7)) ///
ytitle("Number of firms") 
graph export ".\graphs\nb_firms_sector_year.png", as(png) replace

* Number of firm by DEP year sector - firm sizes 
use .\data\firm_demographics\firm_demography, clear
append using .\data\firm_demographics\firm_demography2
sort dep annee a21
drop if a21=="A" | a21=="O" | a21=="D" | a21=="P" | a21=="E" /* public administration a,d education generally not subject to insolvency */
/* agriculture with bad data quality for both nb of firms and insolvency proceedings */
/* water, energy and gas companies not of interests + may be deeply affected because of capital destruction */
collapse (sum) freq, by(com annee a21 taille) 
drop if _n==1
reshape wide freq, i(com annee a21) j(taille)
rename (freq0 freq1 freq2 freq3 freq11 freq12 freq21 freq22 freq31 freq32 freq41 ///
freq42 freq51 freq52 freq53) (freq_sal_0 freq_sal_1a2 freq_sal_3a5 freq_sal_6a9 ///
freq_sal_10a19 freq_sal_20a49 freq_sal_50a99 freq_sal_100a199 freq_sal_200a249 ///
freq_sal_250a499 freq_sal_500a999 freq_sal_1000a1999 freq_sal_2000a4999 ///
freq_sal_5000a9999 freq_sal_10000p)
foreach x in freq_sal_0 freq_sal_1a2 freq_sal_3a5 freq_sal_6a9 freq_sal_10a19 freq_sal_20a49 freq_sal_50a99 freq_sal_100a199 freq_sal_200a249 freq_sal_250a499 freq_sal_500a999 freq_sal_1000a1999 freq_sal_2000a4999 freq_sal_5000a9999 freq_sal_10000p {
	replace `x' = 0 if (`x' >= .)
	replace `x' = `x'/2 if annee==2011
}
gen n_firm = freq_sal_0 + freq_sal_1a2 + freq_sal_3a5 +freq_sal_6a9 + ///
freq_sal_10a19 +freq_sal_20a49 +freq_sal_50a99 +freq_sal_100a199 +freq_sal_200a249 + ///
freq_sal_250a499+ freq_sal_500a999 +freq_sal_1000a1999 +freq_sal_2000a4999 + ///
freq_sal_5000a9999 +freq_sal_10000p
collapse (sum) freq_sal_* n_firm, by(com a21 annee)
gen DEP=substr(com, 1, 2)
collapse (sum) freq_sal* n_firm, by(DEP a21 annee)
drop if DEP==""
reshape wide freq_sal* n_firm, i(DEP annee) j(a21) string
rename annee year 
foreach var in 0 1a2 3a5 6a9 10a19 20a49 50a99 100a199 200a249 250a499 500a999 1000a1999 2000a4999 5000a9999 10000p {
label variable freq_sal_`var'B "Extractive industry"
label variable freq_sal_`var'C "Manufacturing industry"
label variable freq_sal_`var'F "Construction"
label variable freq_sal_`var'G "Wholesale, retail, shops"
label variable freq_sal_`var'H "Transport"
label variable freq_sal_`var'I "Hotels and restaurants"
label variable freq_sal_`var'J "Information and communication"
label variable freq_sal_`var'K "Financial activities"
label variable freq_sal_`var'L "Real estate"
label variable freq_sal_`var'M "Scientific activities"
label variable freq_sal_`var'N "Administrative services"
label variable freq_sal_`var'Q "Health industry"
label variable freq_sal_`var'R "Arts and entertainment"
label variable freq_sal_`var'S "Other services"
}
saveold .\data\firm_demographics\firm_demography_dep_a21_fsize, replace version(12)

* Percentage of each firm size in the Departement sector 
foreach x in "B" "C" "F" "G" "H" "I" "J" "K" "L" "M" "N" "Q" "R" "S" {
	foreach var in 0 1a2 3a5 6a9 10a19 20a49 50a99 100a199 200a249 250a499 500a999 1000a1999 2000a4999 5000a9999 10000p {
	gen p_`var'sal`x' = freq_sal_`var'`x' / n_firm`x'
	label variable p_`var'sal`x' "Share of `var'-employees firms in the Departement sector `x'"
	}
}
* Percentage of each sector in the Departement economy 
egen n_firm = rowtotal(n_firm*) 
foreach x in "B" "C" "F" "G" "H" "I" "J" "K" "L" "M" "N" "Q" "R" "S" {
	gen share_`x' = n_firm`x' / n_firm
	label variable share_`x' "Share of sector `x' in the Departement economy (percentage of firms)"
}
* Share of Departement sector in the overall sector in France
sort year DEP
foreach x in "B" "C" "F" "G" "H" "I" "J" "K" "L" "M" "N" "Q" "R" "S" {
	by year: egen n_firm_fr`x' = sum(n_firm`x')
	gen p_firm_fr`x' = n_firm`x'/n_firm_fr`x' 
	label variable p_firm_fr`x' "Share of the Departement in the overall sector `x' (percentage of firms)"
}
saveold .\data\firm_demographics\firm_demography_dep_a21_fsize, replace version(12)

* Firm demography - firm size - interpolation 
use .\data\firm_demographics\firm_demography_dep_a21_fsize, clear
gen quarter=4
merge m:m DEP year quarter using .\data\bodacc\dep_sector_quarter_bodacc /* just to recup the panel */
drop if _m==1
drop if multi_siret==1
gen date=string(year)+string(quarter)
destring(date), replace
sort DEP date

foreach x in "B" "C" "F" "G" "H" "I" "J" "K" "L" "M" "N" "Q" "R" "S" {
	foreach var in 0 1a2 3a5 6a9 10a19 20a49 50a99 100a199 200a249 250a499 500a999 1000a1999 2000a4999 5000a9999 10000p {

	by DEP: ipolate freq_sal_`var'`x' date, epolate gen(freq_sal_`var'`x'2)
	drop freq_sal_`var'`x'
	rename freq_sal_`var'`x'2 freq_sal_`var'`x'
	replace freq_sal_`var'`x'=round(freq_sal_`var'`x')
	label variable freq_sal_`var'`x' "Number of `var'-employees firms in the Departement sector `x'"
	
	by DEP: ipolate p_`var'sal`x' date, epolate gen(p_`var'sal`x'2)
	drop p_`var'sal`x'
	rename p_`var'sal`x'2 p_`var'sal`x'
	label variable p_`var'sal`x' "Share of `var'-employees firms in the Departement sector `x'"
	
	}
	
	by DEP: ipolate n_firm`x' date, epolate gen(n_firm`x'2)
	drop n_firm`x'
	rename n_firm`x'2 n_firm`x'
	replace n_firm`x'=round(n_firm`x')
	label variable n_firm`x' "Number of firms in the Departement sector `x'"
		
	by DEP: ipolate p_firm_fr`x' date, epolate gen(p_firm_fr`x'2)
	drop p_firm_fr`x'
	rename p_firm_fr`x'2 p_firm_fr`x'
	label variable p_firm_fr`x' "Share of the Departement in the overall sector `x' (percentage of firms)"
	
	by DEP: ipolate share_`x' date, epolate gen(share_`x'2)
	drop share_`x'
	rename share_`x'2 share_`x'
	label variable share_`x' "Share of sector `x' in the Departement economy (percentage of firms)"

}

keep year DEP quarter freq* n_firm* p_firm* share* p_*
drop n_firm_fr*
save .\data\firm_demographics\firm_demography_quarter_dep_fsize, replace

