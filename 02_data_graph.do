* =============================== *
* Store pre/post results of JWDID *
* =============================== *
capture program drop jwdid_store_tests
program define jwdid_store_tests, rclass
    version 17

    matrix b = e(b)
    matrix V = e(V)
    local cn : colfullnames b
    local zcrit = invnormal(0.975)

    local found = 0

    foreach c of local cn {
        if "`c'" == "_cons" continue

        if strpos("`c'","__post__#c.__tr__") {
            local ++found
            local j = colnumb(b, "`c'")

            scalar bb  = el(b,1,`j')
            scalar se  = sqrt(el(V,`j',`j'))
            scalar zz  = bb/se
            scalar pp  = 2*normal(-abs(zz))
            scalar ll  = bb - `zcrit'*se
            scalar ul  = bb + `zcrit'*se

            if `found' == 1 {
                scalar JWDID_PRE_B  = bb
                scalar JWDID_PRE_SE = se
                scalar JWDID_PRE_Z  = zz
                scalar JWDID_PRE_P  = pp
                scalar JWDID_PRE_LL = ll
                scalar JWDID_PRE_UL = ul
                local pre_name "`c'"
            }
            else if `found' == 2 {
                scalar JWDID_POST_B  = bb
                scalar JWDID_POST_SE = se
                scalar JWDID_POST_Z  = zz
                scalar JWDID_POST_P  = pp
                scalar JWDID_POST_LL = ll
                scalar JWDID_POST_UL = ul
                local post_name "`c'"
            }
        }
    }

    if `found' < 2 {
        di as error "Could not find both pre-treatment and post-treatment coefficients"
        di as error "Detected coefficient names:"
        foreach c of local cn {
            di as txt "`c'"
        }
        exit 111
    }

    di as text "------------------------------------------------------"
    di as text "Stored pre-treatment and post-treatment test results"
    di as text "Pre coefficient : `pre_name'"
    di as text "Post coefficient: `post_name'"
    di as result "Pre-Trt : b = " %8.4f scalar(JWDID_PRE_B) ///
        ", z = " %6.3f scalar(JWDID_PRE_Z) ///
        ", p = " %6.4f scalar(JWDID_PRE_P)
    di as result "Post-Trt: b = " %8.4f scalar(JWDID_POST_B) ///
        ", z = " %6.3f scalar(JWDID_POST_Z) ///
        ", p = " %6.4f scalar(JWDID_POST_P)
    di as text "------------------------------------------------------"

    return scalar pre_b   = scalar(JWDID_PRE_B)
    return scalar pre_se  = scalar(JWDID_PRE_SE)
    return scalar pre_z   = scalar(JWDID_PRE_Z)
    return scalar pre_p   = scalar(JWDID_PRE_P)
    return scalar post_b  = scalar(JWDID_POST_B)
    return scalar post_se = scalar(JWDID_POST_SE)
    return scalar post_z  = scalar(JWDID_POST_Z)
    return scalar post_p  = scalar(JWDID_POST_P)
end

* ========================== *
* Plot event-study for JWDID *
* ========================== *
capture program drop jwdid_event_plot
program define jwdid_event_plot
    syntax , SIDE(string) SAVING(string) [MIN(integer -1000) MAX(integer 1000)]

    local side = lower("`side'")
    if !inlist("`side'","pre","post") {
        di as error "side() must be pre or post"
        exit 198
    }

    capture confirm scalar JWDID_PRE_P
    if _rc {
        di as error "Stored test results not found. Run jwdid ... , hettype(twfe) first, then jwdid_store_tests"
        exit 111
    }

    if "`side'" == "pre" {
        local ptxt : display "Pre-treatment test: p_value = " %6.3f scalar(JWDID_PRE_P)
    }

    matrix b = e(b)
    matrix V = e(V)
    local cn : colfullnames b
    local z = invnormal(0.975)

    tempfile es
    tempname h
    postfile `h' int event_time double bhat ll ul str120 term using `es', replace

    foreach c of local cn {
        if "`c'" == "_cons" continue
        local j = colnumb(b, "`c'")

        if `j' < . & `j' > 0 {
            if regexm("`c'", "^([0-9]+)b?\.__evnt__#c\.__tr__$") {
                local lvl = real(regexs(1))
                local et  = `lvl' - 40

                if `et' >= `min' & `et' <= `max' {
                    scalar bb  = el(b,1,`j')
                    scalar se  = sqrt(el(V,`j',`j'))
                    scalar lci = bb - `z'*se
                    scalar uci = bb + `z'*se
                    post `h' (`et') (bb) (lci) (uci) ("`c'")
                }
            }
        }
    }

    postclose `h'

    preserve
        use `es', clear
        drop if missing(event_time) | missing(bhat)
        sort event_time

        if _N == 0 {
            di as error "No observations available in window [`min', `max']"
            restore
            exit 2000
        }

        quietly summarize event_time, meanonly
        local xmin = r(min)
        local xmax = r(max)

        if "`side'" == "pre" {
            twoway ///
                (rcap ul ll event_time, lwidth(vthin)) ///
                (scatter bhat event_time, msymbol(O) msize(small)), ///
                yline(0, lpattern(dash) lwidth(vthin)) ///
                xtitle("Periods from treatment onset") ///
                ytitle("Treatment effect") ///
                xlabel(`xmin'(1)`xmax', nogrid) ///
                legend(off) ///
                graphregion(color(white) margin(l+1 r+1 t+1 b+1)) ///
                plotregion(color(white)) ///
                note("`ptxt'", size(vsmall) position(7) ring(0) just(left))
        }
        else {
            twoway ///
                (rcap ul ll event_time, lwidth(vthin)) ///
                (scatter bhat event_time, msymbol(O) msize(small)), ///
                yline(0, lpattern(dash) lwidth(vthin)) ///
				yscale(range(-1.0 0.2)) ///
				ylabel(-1.0(0.2)0.2) ///
                xtitle("Periods from treatment onset") ///
                ytitle("Treatment effect") ///
                xlabel(`xmin'(1)`xmax', nogrid) ///
                legend(off) ///
                graphregion(color(white) margin(l+1 r+1 t+1 b+1)) ///
                plotregion(color(white)) ///
                note("`ptxt'", size(vsmall) position(7) ring(0) just(left))
        }

        graph export "`saving'", as(png) width(2400) replace
    restore
end

* ============================= *
* Plot event-study for PPMLHDFE *
* ============================= *
capture program drop ppmlhdfe_post_plot
program define ppmlhdfe_post_plot
    syntax , SAVING(string) [MIN(integer 0) MAX(integer 10) PTEXT(string)]

    matrix b = e(b)
    matrix V = e(V)
    local cn : colfullnames b
    local z = invnormal(0.975)

    tempfile es
    tempname h
    postfile `h' int event_time double bhat ll ul str40 term using `es', replace

    foreach c of local cn {
        if regexm("`c'","^post_([0-9]+)$") {
            local et = real(regexs(1))
            local j  = colnumb(b,"`c'")

            if `et' >= `min' & `et' <= `max' {
                scalar bb  = el(b,1,`j')
                scalar se  = sqrt(el(V,`j',`j'))
                scalar lci = bb - `z'*se
                scalar uci = bb + `z'*se
                post `h' (`et') (bb) (lci) (uci) ("`c'")
            }
        }
    }

    postclose `h'

    preserve
        use `es', clear
        drop if missing(event_time) | missing(bhat)
        sort event_time

        if _N == 0 {
            di as error "No post-treatment coefficients found in window [`min', `max']"
            restore
            exit 2000
        }

        quietly summarize event_time, meanonly
        local xmin = r(min)
        local xmax = r(max)

        if `"`ptext'"' == "" {
            local ptext " "
        }

        twoway ///
            (rcap ul ll event_time, lwidth(vthin)) ///
            (scatter bhat event_time, msymbol(O) msize(small)), ///
            yline(0, lpattern(dash) lwidth(vthin)) ///
			yscale(range(-1.0 0.2)) ///
			ylabel(-1.0(0.2)0.2) ///
            xtitle("Periods from treatment onset") ///
            ytitle("Treatment effect") ///
            xlabel(`xmin'(1)`xmax', nogrid) ///
            legend(off) ///
            graphregion(color(white) margin(l+1 r+1 t+1 b+1)) ///
            plotregion(color(white)) ///
            note(`"`ptext'"', size(vsmall) position(7) ring(0) just(left))

        graph export "`saving'", as(png) width(2400) replace
    restore
end

* ================================= *
* Event-study for Groups of Cohorts *
* ================================= *
capture program drop jwdid_event_cohort
program define jwdid_event_cohort
    syntax , SAVING(string)

    local min = 0
    local max = 10
    local z = invnormal(0.975)

    capture confirm variable __evnt__
    if _rc {
        di as error "__evnt__ not found in memory."
        exit 111
    }

    local vlab : value label __evnt__
    if "`vlab'" == "" {
        di as error "__evnt__ has no value label; cannot map factor levels to t+k."
        exit 111
    }

    matrix b = e(b)
    matrix V = e(V)
    local cn : colfullnames b

    tempfile es
    tempname h
    postfile `h' int event_time double bhat ll ul str120 term str20 evlbl using `es', replace

    foreach c of local cn {
        if "`c'" == "_cons" continue

        local j = colnumb(b, "`c'")
        if missing(`j') | `j' <= 0 continue

        if regexm("`c'", "^([0-9]+)\.__evnt__#c\.__tr__$") {
            local lvl = real(regexs(1))

            local lab : label `vlab' `lvl'

            if regexm(`"`lab'"', "^t\+([0-9]+)$") {
                local et = real(regexs(1))

                if `et' >= `min' & `et' <= `max' {
                    scalar bb  = el(b,1,`j')
                    scalar se  = sqrt(el(V,`j',`j'))
                    scalar lci = bb - `z'*se
                    scalar uci = bb + `z'*se

                    post `h' (`et') (bb) (lci) (uci) ("`c'") (`"`lab'"')
                }
            }
        }
    }

    postclose `h'

    preserve
        use `es', clear
        drop if missing(event_time) | missing(bhat)
        sort event_time

        if _N == 0 {
            di as error "No coefficients found for t+0 to t+10."
            restore
            exit 2000
        }

        list event_time evlbl bhat ll ul, noobs sep(0)

        twoway ///
            (rcap ul ll event_time, lwidth(vthin)) ///
            (scatter bhat event_time, msymbol(O) msize(medsmall)), ///
            yline(0, lpattern(dash)) ///
			yscale(range(-1.2 0.2)) ///
			ylabel(-1.2(0.2)0.2) ///
            xtitle("Post-treatment periods") ///
            ytitle("Treatment effect") ///
            xlabel(0(1)10, nogrid) ///
            legend(off) ///
            graphregion(color(white)) ///
            plotregion(color(white))

        graph export "`saving'", as(png) width(2400) replace
    restore
end

