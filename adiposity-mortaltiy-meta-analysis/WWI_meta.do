///Continous///
import excel "C:\Users\WWI\WWI_meta.xlsx", sheet("continuous") firstrow clear

keep if id == 
destring RR LCI UCI, replace

gen double logrr = ln(RR)
gen double loglci = log(LCI)
gen double loguci = log(UCI)
gen double selogrr = (ln(UCI) - ln(LCI)) / (2*invnormal(.975))

list logrr selogrr loglci loguci


///GLST///
import excel "C:\Users\WWI\WWI_meta.xlsx", sheet("categorical") firstrow clear

keep if id == 

gen double logrr = ln(RR)
gen double selogrr = (ln(UCI) - ln(LCI))/(2 * invnormal(.975))

gen byte ref = abs(RR - 1) < 1e-10 & abs(LCI - 1) < 1e-10 & abs(UCI - 1) < 1e-10

count if ref
assert r(N) == 1

gsort -ref dose

gen double dosec = dose - dose[1]

assert ref[1] == 1
assert abs(dosec[1]) < 1e-10
assert abs(logrr[1]) < 1e-10
assert abs(selogrr[1]) < 1e-10

glst logrr dosec, se(selogrr) cov(person_years case) ir


///linear///
/*HKSJ method*/
/*BMI unadjusted*/
import excel "C:\Users\WWI\WWI_meta.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if full_model == 1
keep if minimum == 1
meta set coef se, studylabel(Studyname)

meta summarize, random(reml) se(khartung)

scalar pooled_rr  = exp(r(theta))
scalar pooled_lci = exp(r(ci_lb))
scalar pooled_uci = exp(r(ci_ub))

display as text "Pooled RR (95% CI): " as result %5.2f `pooled_rr'" (" %5.2f `pooled_lci' "–" %5.2f `pooled_uci' ")"
	
scalar list pooled_rr pooled_lci pooled_uci
	
evalue rr `=scalar(pooled_rr)', lcl(`=scalar(pooled_lci)') ucl(`=scalar(pooled_uci)')

meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline


/*BMI adjusted*/
import excel "C:\Users\WWI\WWI_meta.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if full_model == 1
keep if minimum == 1
meta set coef se, studylabel(Studyname)

meta summarize, random(reml) se(khartung)

scalar pooled_rr  = exp(r(theta))
scalar pooled_lci = exp(r(ci_lb))
scalar pooled_uci = exp(r(ci_ub))

display as text "Pooled RR (95% CI): " as result %5.2f `pooled_rr'" (" %5.2f `pooled_lci' "–" %5.2f `pooled_uci' ")"
	
scalar list pooled_rr pooled_lci pooled_uci
	
evalue rr `=scalar(pooled_rr)', lcl(`=scalar(pooled_lci)') ucl(`=scalar(pooled_uci)')

meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 1 2)) nullrefline


/*Nonlinear*/
/*Main*/
import excel "C:\Users\WWI\WWI_meta.xlsx", sheet("categorical") firstrow clear

gen double logrr   = ln(RR)
gen double logrrL  = ln(LCI)
gen double logrrU  = ln(UCI)
gen double selogrr = (logrrU - logrrL)/(2 * invnormal(.975))

keep if bmi_unadjusted == 1
keep if full_model == 1
keep if minimum == 1
drop if missing(id, dose, RR, LCI, UCI, logrr, selogrr)

gen byte drtype = 2

_pctile dose, p(5 10 25 50 90 95)

local p5 = r(r1)
local p10 = r(r2)
local p25 = r(r3)
local p50 = r(r4)
local p90 = r(r5)
local p95 = r(r6)

display "P5 = " %6.2f `p5'
display "P10 = " %6.2f `p10'
display "P25 = " %6.2f `p25'
display "P50 = " %6.2f `p50'
display "P90 = " %6.2f `p90'
display "P95 = " %6.2f `p95'

mkspline doses = dose, knots(`p10' `p50' `p90') cubic displayknots
matrix knots = r(knots)

drmeta logrr doses*, se(selogrr) data(person_years case) id(id) type(drtype) 2stage reml hamling

test doses2
display "P for nonlinearity = " %6.4f r(p)

tab study
tab drtype

local search_min  8
local search_max 13
local gridstep  0.001

local knot1 = el(knots, 1, 1)
local knot2 = el(knots, 1, 2)
local knot3 = el(knots, 1, 3)

local beta1 = _b[doses1]
local beta2 = _b[doses2]

local ngrid = round((`search_max' - `search_min') / `gridstep') + 1

preserve

clear
set obs `ngrid'

gen double dose_grid = `search_min' + (`gridstep' * (_n - 1))

mkspline nad = dose_grid, knots(`knot1' `knot2' `knot3') cubic

gen double eta = `beta1' * nad1 + `beta2' * nad2

sort eta dose_grid

scalar nadir_exact = dose_grid[1]
scalar eta_min     = eta[1]

restore

local nadir = scalar(nadir_exact)

display as text "Estimated nadir = " ///
    as result %6.2f `nadir' ///
	as text " "

local refdose = `nadir'

gen byte refcat = abs(logrr) < 1e-10 & abs(selogrr) < 1e-10

gen double rug_all_y = 1 if inrange(dose, 8, 13)
gen double rug_ref_y = 1 if refcat & inrange(dose, 8, 13)
	
drmeta_graph, matk(knots) dose(8(0.01)13) list ref(`nadir') eform ///
    xtitle("WWI", size(large)) ///
    ytitle("RR", size(large)) ///
    yline(1, lcolor(gs10) lpattern(line)) ///
    ylabel(0.6 0.8 1 (0.5) 4.0, labsize(large)) ///
    xlabel(8(1)13, labsize(large)) ///
    yscale(range(0.6 0.8 4.0))

addplot: (scatter rug_all_y dose if !missing(rug_all_y), msymbol(|) mcolor(gs10) ///
        msize(medium) ///
        legend(off)) ///
    (scatter rug_ref_y dose if !missing(rug_ref_y), ///
        msymbol(|) ///
        mcolor(black) ///
        msize(large) ///
        legend(off)), ///
    norescaling