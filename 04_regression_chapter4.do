* =========== *
* 0/ Khai báo *
* =========== *
global path "yourpath"
cd "$path"

use "data_tradecomov.dta", clear

egen od = group(iso3_o iso3_d)
egen ot = group(iso3_o year)
egen dt = group(iso3_d year)
xtset od year

rename (trade financial) (trade_sanctions financial_sanctions)

gen TI1xSanc      = lnTI_1 * sanctions_any
gen TI1xTrade     = lnTI_1 * trade_sanctions
gen TI1xFinancial = lnTI_1 * financial_sanctions
gen TI2xSanc      = lnTI_2 * sanctions_any

label variable lnTI_1					"Trade intensity (sum-based)"
label variable lnTI_2					"Trade intensity (max-based)"
label variable TI1xSanc					"Trade intensity (sum-based) x Sanctions (any)"
label variable TI1xTrade				"Trade intensity (sum-based) x Trade sanctions"
label variable TI1xFinancial			"Trade intensity (sum-based) x Financial sanctions"
label variable TI2xSanc					"Trade intensity (max-based) x Sanctions (any)"
label variable comov					"Business cycle comovement"
label variable sanctions_any			"Sanctions (any)"
label variable financial_sanctions		"Financial sanctions"
label variable trade_sanctions			"Trade sanctions"

* =========== *
* 1/ Pre-test *
* =========== *
* Descriptive statistics *
sum comov lnTI_1 lnTI_2 sanctions_any TI1xSanc

* Correlation matrix *
pwcorr comov lnTI_1 sanctions_any
pwcorr comov lnTI_2 sanctions_any

* VIF *
reg comov lnTI_1 sanctions_any TI1xSanc
vif
reg comov lnTI_2 sanctions_any TI1xSanc
vif

qnorm comov, msymbol(O) msize(small) mcolor(blue*0.75) lcolor(black) lwidth(vthin) legend(off) graphregion(color(white) margin(l+1 r+1 t+1 b+1)) plotregion(color(white)) xlabel(, nogrid) ylabel(, grid glcolor(gs14)) note("`ptxt'", size(vsmall) position(7) ring(0) just(left))
graph export "qnorm_comov.png", width(2400) replace

qnorm lnTI_1, msymbol(O) msize(small) mcolor(blue*0.75) lcolor(black) lwidth(vthin) legend(off) graphregion(color(white) margin(l+1 r+1 t+1 b+1)) plotregion(color(white)) xlabel(, nogrid) ylabel(, grid glcolor(gs14)) note("`ptxt'", size(vsmall) position(7) ring(0) just(left))
graph export "qnorm_TI1.png", width(2400) replace

qnorm lnTI_2, msymbol(O) msize(small) mcolor(blue*0.75) lcolor(black) lwidth(vthin) legend(off) graphregion(color(white) margin(l+1 r+1 t+1 b+1)) plotregion(color(white)) xlabel(, nogrid) ylabel(, grid glcolor(gs14)) note("`ptxt'", size(vsmall) position(7) ring(0) just(left))
graph export "qnorm_TI2.png", width(2400) replace

qnorm sanctions_any, msymbol(O) msize(small) mcolor(blue*0.75) lcolor(black) lwidth(vthin) legend(off) graphregion(color(white) margin(l+1 r+1 t+1 b+1)) plotregion(color(white)) xlabel(, nogrid) ylabel(, grid glcolor(gs14)) note("`ptxt'", size(vsmall) position(7) ring(0) just(left))
graph export "qnorm_sanctions.png", width(2400) replace

* ============= *
* 2/ Regression *
* ============= *
* Baseline *
local rowoder "lnTI_1 sanctions_any TI1xSanc"
mmqreg comov lnTI_1 sanctions_any TI1xSanc, abs(od year) q(0.25 0.50 0.75 0.90)
qregplot

* Heterogeneity *
local rowoder "lnTI_1 trade_sanctions TI1xTrade"
mmqreg comov lnTI_1 trade_sanctions TI1xTrade, abs(od year) q(0.25 0.50 0.75 0.90)
qregplot

local rowoder "lnTI_1 financial_sanctions TI1xFinancial"
mmqreg comov lnTI_1 financial_sanctions TI1xFinancial, abs(od year) q(0.25 0.50 0.75 0.90)
qregplot

* Robust 1: lnTI_2 *
local rowoder "lnTI_2 sanctions_any TI1xSanc"
mmqreg comov lnTI_2 sanctions_any TI2xSanc, abs(od year) q(0.25 0.50 0.75 0.90)
qregplot

* Robust 2: CSA-2SLS *
gen lndist = ln(dist)

csa2sls comov (lnTI_1 = wto_o wto_d eu_o eu_d rta lndist contig comlang_off) sanctions_any TI1xSanc, large

csa2sls comov (lnTI_1 = wto_o wto_d eu_o eu_d rta lndist contig comlang_off) trade_sanctions TI1xTrade, large

csa2sls comov (lnTI_1 = wto_o wto_d eu_o eu_d rta lndist contig comlang_off) financial_sanctions TI1xFinancial, large














