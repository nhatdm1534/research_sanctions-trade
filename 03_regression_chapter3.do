* Ensure that the latest versions of jwdid.ado and jwdid_estat.ado 
* are installed by overwriting any existing versions. 
* Files are available at:
* https://github.com/friosavila/stpackages/tree/main/jwdid

* ======================== *
* 0/ Set working directory *
* ======================== *
global path "yourpath"
global fig  "$path\your_folder_to_save_figures"

do "$path\02_data_graph.do"

* ============================= *
* 1/ Sacntions_any - Tradeflows *
* ============================= *
use "$path\data_sdid.dta", clear

egen od = group(iso3_o iso3_d)
egen ot = group(iso3_o year)
egen dt = group(iso3_d year)

xtset od year
	* ------------------------ *
	* Extended TWFE with JWDID *
		* Treatment Effect *
		jwdid tradeflows, i(od) t(year) g(gvar_sanctions_any)  never method(ppmlhdfe) accel(cg)
		estat simple, predict(xb)

		* Event-study *	
		jwdid tradeflows, i(od) t(year) g(gvar_sanctions_any)  never method(ppmlhdfe) hettype(twfe) fevar(ot) accel(cg)
		jwdid_store_tests
		
		jwdid tradeflows, i(od) t(year) g(gvar_sanctions_any)  never method(ppmlhdfe) hettype(event) accel(cg)
		jwdid_event_plot, side(pre) min(-10) max(-2) saving("$fig\Pre-treatment test_Sanctions.png")
		jwdid_event_plot, side(post) min(0) max(10) saving("$fig\ETWFE_Post-treatment_Sanctions.png")
	* ------------------------ *
	
	* ------------------ *
	* TWFE with PPMLHDFE *
		* Treatment Effect *
		ppmlhdfe tradeflows sanctions_any, abs(od year)
		
		* Event-study *
		capture drop rel_time
		gen rel_time = year - gvar_sanctions_any if gvar_sanctions_any < .

		forvalues k = 0/10 {
			capture drop post_`k'
			gen post_`k' = (rel_time == `k')
			replace post_`k' = 0 if missing(post_`k')
		}
		
		ppmlhdfe tradeflows post_0 post_1 post_2 post_3 post_4 post_5 post_6 post_7 post_8 post_9 post_10, abs(od year) 
		ppmlhdfe_post_plot, min(0) max(10) saving("$fig\TWFE_Post-treatment_Sanctions.png")
	* ------------------ *
		
* =============================== *
* 2/ Trade_sanctions - Tradeflows *
* =============================== *
use "$path\data_sdid.dta", clear

egen od = group(iso3_o iso3_d)
egen ot = group(iso3_o year)
egen dt = group(iso3_d year)

xtset od year
	* ------------------------ *
	* Extended TWFE with JWDID *
		* Treatment Effect *
		jwdid tradeflows, i(od) t(year) g(gvar_trade_sanctions) never method(ppmlhdfe) accel(cg)
		estat simple, predict(xb)

		* Event-study *	
		jwdid tradeflows, i(od) t(year) g(gvar_trade_sanctions)  never method(ppmlhdfe) hettype(event) accel(cg)
		jwdid_event_plot, side(post) min(0) max(10) saving("$fig\ETWFE_Post-treatment_TradeSanctions.png")
	* ------------------------ *
	
	* ------------------ *
	* TWFE with PPMLHDFE *
		* Treatment Effect *
		ppmlhdfe tradeflows trade_sanctions, abs(od year)
		
		* Event-study *
		capture drop rel_time
		gen rel_time = year - gvar_trade_sanctions if gvar_trade_sanctions < .

		forvalues k = 0/10 {
			capture drop post_`k'
			gen post_`k' = (rel_time == `k')
			replace post_`k' = 0 if missing(post_`k')
		}
		
		ppmlhdfe tradeflows post_0 post_1 post_2 post_3 post_4 post_5 post_6 post_7 post_8 post_9 post_10, abs(od year) 
		ppmlhdfe_post_plot, min(0) max(10) saving("$fig\TWFE_Post-treatment_TradeSanctions.png")
	* ------------------ *
	
* ====================================== *
* 3/ Nontrade_sanctions_any - Tradeflows *
* ====================================== *
use "$path\data_sdid.dta", clear

egen od = group(iso3_o iso3_d)
egen ot = group(iso3_o year)
egen dt = group(iso3_d year)

xtset od year
	* ------------------------ *
	* Extended TWFE with JWDID *
		* Treatment Effect *
		jwdid tradeflows, i(od) t(year) g(gvar_nontrade_sanctions_any) never method(ppmlhdfe) accel(cg)
		estat simple, predict(xb)

		* Event-study *	
		jwdid tradeflows, i(od) t(year) g(gvar_nontrade_sanctions_any)  never method(ppmlhdfe) hettype(event) accel(cg)
		jwdid_event_plot, side(post) min(0) max(10) saving("$fig\ETWFE_Post-treatment_NonTradeSanctions.png")
	* ------------------------ *
	
	* ------------------ *
	* TWFE with PPMLHDFE *
		* Treatment Effect *
		ppmlhdfe tradeflows nontrade_sanctions_any, abs(od year)
		
		* Event-study *
		capture drop rel_time
		gen rel_time = year - gvar_nontrade_sanctions_any if gvar_nontrade_sanctions_any < .

		forvalues k = 0/10 {
			capture drop post_`k'
			gen post_`k' = (rel_time == `k')
			replace post_`k' = 0 if missing(post_`k')
		}
		
		ppmlhdfe tradeflows post_0 post_1 post_2 post_3 post_4 post_5 post_6 post_7 post_8 post_9 post_10, abs(od year) 
		ppmlhdfe_post_plot, min(0) max(10) saving("$fig\TWFE_Post-treatment_NonTradeSanctions.png")
	* ------------------ *
	
* ============================== *
* 4/ Different Groups of Cohorts *
* ============================== *
	* --------------------- *
	* Sanctions_any - Trade *
	* --------------------- *
		* ----------------------- *
		* The 1981 - 1999 cohorts *
		* ----------------------- *
use "$path\data_sdid.dta", clear

egen od = group(iso3_o iso3_d)
egen ot = group(iso3_o year)
egen dt = group(iso3_d year)

xtset od year
		
		gen cohort_year = gvar_sanctions_any if gvar_sanctions_any > 0
		keep if gvar_sanctions_any == 0 | inrange(cohort_year, 1981, 1999)
		* Extended TWFE *
		jwdid tradeflows, i(od) t(year) g(gvar_sanctions_any)  never method(ppmlhdfe) accel(cg)
		estat simple, predict(xb)		
		jwdid tradeflows, i(od) t(year) g(gvar_sanctions_any)  never method(ppmlhdfe) hettype(event) accel(cg)
		jwdid_event_cohort, saving("$fig\ETWFE_Post-treatment_Sanctions_Ch1981-1999.png")
			
		* ----------------------- *
		* The 2000 - 2020 cohorts *
		* ----------------------- *
use "$path\data_sdid.dta", clear

egen od = group(iso3_o iso3_d)
egen ot = group(iso3_o year)
egen dt = group(iso3_d year)

xtset od year
		
		gen cohort_year = gvar_sanctions_any if gvar_sanctions_any > 0
		keep if gvar_sanctions_any == 0 | inrange(cohort_year, 2000, 2020)
		* Extended TWFE *
		jwdid tradeflows, i(od) t(year) g(gvar_sanctions_any)  never method(ppmlhdfe)accel(cg)
		estat simple, predict(xb)		
		jwdid tradeflows, i(od) t(year) g(gvar_sanctions_any)  never method(ppmlhdfe) hettype(event) accel(cg)
		jwdid_event_cohort, saving("$fig\ETWFE_Post-treatment_Sanctions_Ch2000-2020.png")
		
	* --------------------- *
	* Trade_sanctions - Trade *
	* --------------------- *
		* ----------------------- *
		* The 1981 - 1999 cohorts *
		* ----------------------- *
use "$path\data_sdid.dta", clear

egen od = group(iso3_o iso3_d)
egen ot = group(iso3_o year)
egen dt = group(iso3_d year)

xtset od year
		
		gen cohort_year = gvar_trade_sanctions if gvar_trade_sanctions > 0
		keep if gvar_trade_sanctions == 0 | inrange(cohort_year, 1981, 1999)
		* Extended TWFE *
		jwdid tradeflows, i(od) t(year) g(gvar_trade_sanctions)  never method(ppmlhdfe) accel(cg)
		estat simple, predict(xb)		
		jwdid tradeflows, i(od) t(year) g(gvar_trade_sanctions)  never method(ppmlhdfe) hettype(event) accel(cg)
		jwdid_event_cohort, saving("$fig\ETWFE_Post-treatment_TradeSanctions_Ch1981-1999.png")
			
		* ----------------------- *
		* The 2000 - 2020 cohorts *
		* ----------------------- *
use "$path\data_sdid.dta", clear

egen od = group(iso3_o iso3_d)
egen ot = group(iso3_o year)
egen dt = group(iso3_d year)

xtset od year
		
		gen cohort_year = gvar_trade_sanctions if gvar_trade_sanctions > 0
		keep if gvar_trade_sanctions == 0 | inrange(cohort_year, 2000, 2020)
		* Extended TWFE *
		jwdid tradeflows, i(od) t(year) g(gvar_trade_sanctions)  never method(ppmlhdfe) accel(cg)
		estat simple, predict(xb)		
		jwdid tradeflows, i(od) t(year) g(gvar_trade_sanctions)  never method(ppmlhdfe) hettype(event) accel(cg)
		jwdid_event_cohort, saving("$fig\ETWFE_Post-treatment_TradeSanctions_Ch2000-2020.png")
	
	* --------------------- *
	* NonTrade_sanctions - Trade *
	* --------------------- *
		* ----------------------- *
		* The 1981 - 1999 cohorts *
		* ----------------------- *
use "$path\data_sdid.dta", clear

egen od = group(iso3_o iso3_d)
egen ot = group(iso3_o year)
egen dt = group(iso3_d year)

xtset od year
		
		gen cohort_year = gvar_nontrade_sanctions_any if gvar_nontrade_sanctions_any > 0
		keep if gvar_nontrade_sanctions_any == 0 | inrange(cohort_year, 1981, 1999)
		* Extended TWFE *
		jwdid tradeflows, i(od) t(year) g(gvar_nontrade_sanctions_any)  never method(ppmlhdfe) accel(cg)
		estat simple, predict(xb)		
		jwdid tradeflows, i(od) t(year) g(gvar_nontrade_sanctions_any)  never method(ppmlhdfe) hettype(event) accel(cg)
		jwdid_event_cohort, saving("$fig\ETWFE_Post-treatment_NonTradeSanctions_Ch1981-1999.png")
			
		* ----------------------- *
		* The 2000 - 2020 cohorts *
		* ----------------------- *
use "$path\data_sdid.dta", clear

egen od = group(iso3_o iso3_d)
egen ot = group(iso3_o year)
egen dt = group(iso3_d year)

xtset od year
		
		gen cohort_year = gvar_nontrade_sanctions_any if gvar_nontrade_sanctions_any > 0
		keep if gvar_nontrade_sanctions_any == 0 | inrange(cohort_year, 2000, 2020)
		* Extended TWFE *
		jwdid tradeflows, i(od) t(year) g(gvar_nontrade_sanctions_any)  never method(ppmlhdfe) accel(cg)
		estat simple, predict(xb)		
		jwdid tradeflows, i(od) t(year) g(gvar_nontrade_sanctions_any)  never method(ppmlhdfe) hettype(event) accel(cg)
		jwdid_event_cohort, saving("$fig\ETWFE_Post-treatment_NonTradeSanctions_Ch2000-2020.png")

* =================== *
* 5/ Robustness Check *
* =================== *
	* --------------------- *
	* Using CSDID Estimator * 
	* --------------------- *
	use "$path\data_sdid.dta", clear
		* --------------------- *
		* Sanctions_any - Trade *
		* --------------------- *		
		csdid ln_tradeflows, ivar(od) time(year) gvar(gvar_sanctions_any) method(dripw) never long2
		estat simple
		
		* ----------------------- *
		* Trade_sanctions - Trade *
		* ----------------------- *
		csdid ln_tradeflows, ivar(od) time(year) gvar(gvar_trade_sanctions) method(dripw) never long2
		estat simple
		
		* --------------------- *
		* NonTrade_sanctions - Trade *
		* --------------------- *
		csdid ln_tradeflows, ivar(od) time(year) gvar(gvar_nontrade_sanctions_any) method(dripw) never long2
		estat simple

	* ---------------- *
	* Removing outlier * 
	* ---------------- *
		use "$path\data_sdid.dta", clear
		
		sum tradeflows, detail
		local p5 = r(p5)
		local p95 = r(p95)
		gen outlier = tradeflows < `p5' | tradeflows > `p95'
		sort iso3_o iso3_d year
		by iso3_o iso3_d: egen dyad_outlier = max(outlier)
		drop if dyad_outlier == 1
		egen od = group(iso3_o iso3_d)
		egen ot = group(iso3_o year)
		egen dt = group(iso3_d year)
		xtset od year 
		
		* --------------------- *
		* Sanctions_any - Trade *
		* --------------------- *
		jwdid tradeflows, i(od) t(year) g(gvar_sanctions_any)  never method(ppmlhdfe) accel(cg)
		estat simple, predict(xb)
		
		* ----------------------- *
		* Trade_sanctions - Trade *
		* ----------------------- *
		jwdid tradeflows, i(od) t(year) g(gvar_trade_sanctions)  never method(ppmlhdfe) accel(cg)
		estat simple, predict(xb)
		
		* ------------------------------ *
		* Nontrade_sanctions_any - Trade *
		* ------------------------------ *
		jwdid tradeflows, i(od) t(year) g(gvar_nontrade_sanctions_any)  never method(ppmlhdfe) accel(cg)
		estat simple, predict(xb)





























