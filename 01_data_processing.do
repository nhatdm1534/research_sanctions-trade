* 0/ Set working directory
global path "yourpath"
cd "$path"

* 1/ Clean and preprocess GSDB data
use "data_raw_gsdp.dta", clear 

drop case_id sanctioning_state sanctioned_state
rename (sanctioning_state_iso3 sanctioned_state_iso3) (iso3_o iso3_d)
drop if missing(iso3_d)

duplicates report iso3_o iso3_d year
duplicates list iso3_o iso3_d year

tempfile sanctions
save `sanctions'

local ymin = 1981
local ymax = 2020

preserve
	keep iso3_o iso3_d
	duplicates drop
	tempfile bil
	save `bil'
restore

clear

set obs `= `ymax' - `ymin' + 1'
gen year = `ymin' + _n - 1
tempfile years
save `years'

use `bil', clear
cross using `years'

merge 1:1 iso3_o iso3_d year using `sanctions'
save "data_inter_sanctions.dta", replace

use "data_inter_sanctions.dta", clear

drop _merge
keep if year>1980 & year<2021
drop if iso3_o == iso3_d

foreach var of varlist arms military trade financial travel other target_mult sender_mult {
	replace `var' = 0 if missing(`var')
}

gen nontrade_sanctions_any = (arms==1 | military==1 | financial==1 | travel==1 | other==1)
gen sanctions_any = (arms==1 | military==1 | trade ==1 | financial==1 | travel==1 | other==1)
drop if iso3_o == iso3_d
order iso3_o iso3_d year sanctions_any arms military trade financial travel other nontrade_sanctions_any target_mult sender_mult success descr_trade objective
save "data_inter_sanctions.dta", replace 

* 2/ Clean and preprocess CEPII gravity data
use "data_raw_cepii.dta", clear

drop country_id_o country_id_d iso3num_o iso3num_d
order iso3_o iso3_d year distcap gdp_o gdp_d gdpcap_o gdpcap_d tradeflow_comtrade_o tradeflow_comtrade_d tradeflow_imf_o tradeflow_imf_d gatt_o gatt_d wto_o wto_d eu_o eu_d rta 
keep if year>1980 & year<2021
drop if iso3_o == iso3_d

duplicates report iso3_o iso3_d year
duplicates list iso3_o iso3_d year

bys iso3_o iso3_d year: gen n_dup = _N
egen n_miss = rowmiss(_all)
bys iso3_o iso3_d year: egen min_miss = min(n_miss)
keep if n_miss == min_miss
bys iso3_o iso3_d year: gen keep1 = _n
keep if keep1 == 1

duplicates report iso3_o iso3_d year

save "data_inter_gravity.dta", replace

use "data_inter_gravity.dta", clear

drop tradeflow_comtrade_o tradeflow_comtrade_d tradeflow_imf_o
rename tradeflow_imf_d exports

preserve
	keep iso3_o iso3_d year exports
	rename (iso3_o iso3_d exports) (iso3_d iso3_o imports)
	order iso3_o iso3_d year
	sort iso3_o iso3_d year
	tempfile mirror
	save `mirror', replace
restore

merge 1:1 iso3_o iso3_d year using `mirror'
order iso3_o iso3_d year exports imports 
sort iso3_o iso3_d year

gen exports_1 = exports*1000
gen imports_1 = imports*1000
drop exports imports
rename (exports_1 imports_1) (exports imports)
label var exports "O exports to D (current USD)"
label var imports "O imports from D (current USD)"
drop n_dup n_miss min_miss keep1 _merge

save "data_inter_gravity.dta", replace

* 3/ Merge datasets
use "data_inter_gravity.dta", clear

merge 1:1 iso3_o iso3_d year using "data_inter_sanctions.dta"

keep if _merge == 3
order iso3_o iso3_d year exports imports distcap sanctions_any arms military trade financial travel other nontrade_sanctions_any target_mult sender_mult gdp_o gdp_d gatt_o gatt_d wto_o wto_d eu_o eu_d rta arms military trade financial travel other target_mult sender_mult success descr_trade objective

drop _merge 

gen has_trade = !missing(exports) & !missing(imports)
bys iso3_o iso3_d: egen ever_trade = max(has_trade)
drop if ever_trade == 0
drop has_trade ever_trade

gen zero_trade = (exports == 0 | imports == 0)
bys iso3_o iso3_d: egen n_years = count(year)
bys iso3_o iso3_d: egen n_zero = total(zero_trade)
gen zero_share = n_zero/n_years
drop if zero_share > 0.25
drop zero_trade n_years n_zero zero_share

save "data_clean.dta", replace

* 4/ Construct business cycle comovement measure
use "data_clean.dta", clear

tempfile master
save `master', replace

clear
gen iso3_o = ""
gen iso3_d = ""
gen year = .
tempfile outcomes
save `outcomes', replace

forvalues start = 1981(5)2016 {
	local end = `start' + 4
	
	use `master', clear
	keep if year >= `start' & year<=`end'
	
	egen pair = group(iso3_o iso3_d)
	xtset pair year
	
	gen gdp_g_o = ln(gdp_o/L.gdp_o)
	gen gdp_g_d = ln(gdp_d/L.gdp_d)

	gen ln_gdp_o = ln(gdp_o)
	gen ln_gdp_d = ln(gdp_d)
	
	gen L2_ln_gdp_o = L2.ln_gdp_o
	gen L2_ln_gdp_d = L2.ln_gdp_d

	rangestat (reg) ln_gdp_o L2_ln_gdp_o, by(pair) interval(year . .)
	gen gdp_ham_o = ln_gdp_o - L2_ln_gdp_o*b_L2_ln_gdp_o - b_cons
	drop reg_nobs-se_cons

	rangestat (reg) ln_gdp_d L2_ln_gdp_d, by(pair) interval(year . .)
	gen gdp_ham_d = ln_gdp_d - L2_ln_gdp_d*b_L2_ln_gdp_d - b_cons
	drop reg_nobs-se_cons
	
	rangestat (corr) gdp_ham_o gdp_ham_d, by(pair) interval(year . .)
	
	rename corr_x com_`start'_`end'
	drop corr_nobs
	
	keep iso3_o iso3_d year com_`start'_`end'
	
	append using `outcomes'
	save `outcomes', replace
}

use `master', clear
merge 1:1 iso3_o iso3_d year using `outcomes'

gen comov = .

foreach start in 1981 1986 1991 1996 2001 2006 2011 2016 {
	local end = `start' + 4
	
	replace comov = com_`start'_`end' if year >= `start' & year <= `end'
}

label var comov "Business cycle comovement correlation"
drop _merge
order iso3_o iso3_d year exports imports gdp_o gdp_d comov distcap sanctions_any arms military trade financial travel other nontrade_sanctions_any target_mult sender_mult 
save "data_clean.dta", replace

* 5/ Construct trade intensity measure
use "data_clean.dta", clear

gen TI_1 = max(imports/gdp_o,exports/gdp_d)
gen lnTI_1 = ln(TI_1)
gen TI_2 = ((exports+imports)/(gdp_o+gdp_d))
gen lnTI_2 = ln(TI_2)

order iso3_o iso3_d year exports imports gdp_o gdp_d comov TI_1 lnTI_1 TI_2 lnTI_2 distcap sanctions_any arms military trade financial travel other nontrade_sanctions_any target_mult sender_mult 

save "data_clean.dta", replace
save "data_tradecomov.dta", replace

use "data_tradecomov.dta", clear
egen od = group(iso3_o iso3_d)
bysort od: egen miss_flag = max(missing(comov) | missing(lnTI_1) | missing(lnTI_2))
drop if miss_flag == 1
drop miss_flag
save "data_tradecomov.dta", replace

* 6/ Construct dataset for staggered DiD analysis
use "data_clean.dta", clear

rename (exports trade) (tradeflows trade_sanctions)
gen ln_tradeflows = ln(tradeflows)
drop imports

egen od = group(iso3_o iso3_d)
xtset od year
sort od year

foreach var in sanctions_any trade_sanctions nontrade_sanctions_any {
	by od: gen lag_`var' = L.`var'
	gen re_`var' = (lag_`var'==1 & `var'==0)
	bys od: egen has_re_`var' = max(re_`var')
		
	drop if has_re_`var' == 1
	drop lag_`var' re_`var' has_re_`var'
			
	egen gvar_`var' = csgvar(`var'), tvar(year) ivar(od)
}

drop od

save "data_sdid.dta", replace