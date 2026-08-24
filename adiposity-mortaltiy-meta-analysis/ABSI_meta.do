/*ABSI subgroup data integration*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("continuous") firstrow clear

keep if inlist(id, , )

gen double logrr = ln(RR)
gen double loglci = log(LCI)
gen double loguci = log(UCI)
gen double selogrr = (ln(UCI) - ln(LCI)) / (2*invnormal(.975))

meta set logrr selogrr
meta summarize, fixed eform

///Continous///
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("continuous") firstrow clear

destring RR LCI UCI, replace

gen double logrr = ln(RR)
gen double loglci = log(LCI)
gen double loguci = log(UCI)
gen double selogrr = (ln(UCI) - ln(LCI)) / (2*invnormal(.975))

list logrr selogrr loglci loguci


///GLST///
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical") firstrow clear

keep if id == 

gen double logrr = ln(RR)
gen double selogrr = (ln(UCI) - ln(LCI)) / (2*invnormal(.975))

gen double dose005 = dose / 0.005

gen byte ref = RR == 1 & LCI == 1 & UCI == 1

gsort -ref dose005

gen double dose005c = dose005 - dose005[1]

assert ref[1] == 1
assert abs(dose005c[1]) < 1e-10
assert abs(logrr[1]) < 1e-10
assert abs(selogrr[1]) < 1e-10

glst logrr dose005c, se(selogrr) cov(person_years case) ir


///linear///
/*HKSJ method*/
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if full_model == 1
keep if minimum == 1
meta set coef se, studylabel(Studyname)

meta summarize, random(reml) se(khartung)

scalar pooled_rr  = exp(r(theta))
scalar pooled_lci = exp(r(ci_lb))
scalar pooled_uci = exp(r(ci_ub))

scalar tau2  = r(tau2)
scalar I2    = r(I2)
scalar H2    = r(H2)
scalar Q     = r(Q)
scalar dfQ   = r(df_Q)
scalar phet  = r(p_Q)

scalar t_overall  = r(t)
scalar df_overall = r(df)
scalar p_overall  = r(p)

local tau2_txt : display %6.4f scalar(tau2)
local I2_txt   : display %6.2f scalar(I2)
local H2_txt   : display %6.2f scalar(H2)
local Q_txt    : display %8.2f scalar(Q)
local dfQ_txt  : display %3.0f scalar(dfQ)

if scalar(phet) < 0.001 {
    local phet_txt "< 0.001"
}
else {
    local pnum : display %5.3f scalar(phet)
    local phet_txt "= `pnum'"
}

local t_txt  : display %5.2f scalar(t_overall)
local dft_txt : display %3.0f scalar(df_overall)

if scalar(p_overall) < 0.001 {
    local poverall_txt "< 0.001"
}
else {
    local pnum_overall : display %5.3f scalar(p_overall)
    local poverall_txt "= `pnum_overall'"
}

display as text "Pooled RR (95% CI): " as result %5.2f `pooled_rr'" (" %5.2f `pooled_lci' "–" %5.2f `pooled_uci' ")"
	
scalar list pooled_rr pooled_lci pooled_uci
	
evalue rr `=scalar(pooled_rr)', lcl(`=scalar(pooled_lci)') ucl(`=scalar(pooled_uci)')

meta forestplot _id _plot _esci _weight, ///
    random(reml) se(khartung) eform ///
    columnopts(_id, title("Author, year")) ///
    columnopts(_esci, supertitle("RR") title("(95% CI)")) ///
    xlabel(0.5 1 1.5 2) ///
    xscale(range(0.5 2)) ///
    nullrefline ///
    ohetstatstext("Heterogeneity: {&tau}{sup:2} = `tau2_txt', I{sup:2} = `I2_txt'%, H{sup:2} = `H2_txt'") ///
    ohomtesttext("Test of {&theta}{sub:i} = {&theta}{sub:j}: Q(`dfQ_txt') = `Q_txt', p `phet_txt'") ///
    osigtesttext("Test of {&theta} = 0: t(`dft_txt') = `t_txt', p `poverall_txt'")


/// Leave-one-out sensitivity analysis///
meta summarize, leaveoneout random(reml) se(khartung) eform
meta forestplot _id _plot _esci, leaveoneout random(reml) se(khartung) eform columnopts(_id, title("Study omitted")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(1 1.1 1.2) xscale(range(1 1.1 1.2)) nullrefline

/*bias check*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if full_model == 1
keep if minimum == 1
drop if missing(coef, se)
assert se > 0
label variable coef "Log RR"
label variable se "Standard error"
meta set coef se, studylabel(Studyname)
meta funnelplot, random(reml) xtitle("Log RR") ytitle("Standard error") title("Funnel plot with pseudo 95% confidence limits") legend(off)
meta bias, egger random(reml) se(khartung)

/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if full_model == 1
keep if minimum == 1
meta set coef se, studylabel(Studyname)

meta summarize, random(reml) se(khartung)

scalar pooled_rr  = exp(r(theta))
scalar pooled_lci = exp(r(ci_lb))
scalar pooled_uci = exp(r(ci_ub))

scalar tau2  = r(tau2)
scalar I2    = r(I2)
scalar H2    = r(H2)
scalar Q     = r(Q)
scalar dfQ   = r(df_Q)
scalar phet  = r(p_Q)

scalar t_overall  = r(t)
scalar df_overall = r(df)
scalar p_overall  = r(p)

local tau2_txt : display %6.4f scalar(tau2)
local I2_txt   : display %6.2f scalar(I2)
local H2_txt   : display %6.2f scalar(H2)
local Q_txt    : display %8.2f scalar(Q)
local dfQ_txt  : display %3.0f scalar(dfQ)

if scalar(phet) < 0.001 {
    local phet_txt "< 0.001"
}
else {
    local pnum : display %5.3f scalar(phet)
    local phet_txt "= `pnum'"
}

local t_txt  : display %5.2f scalar(t_overall)
local dft_txt : display %3.0f scalar(df_overall)

if scalar(p_overall) < 0.001 {
    local poverall_txt "< 0.001"
}
else {
    local pnum_overall : display %5.3f scalar(p_overall)
    local poverall_txt "= `pnum_overall'"
}

display as text "Pooled RR (95% CI): " as result %5.2f `pooled_rr'" (" %5.2f `pooled_lci' "–" %5.2f `pooled_uci' ")"
	
scalar list pooled_rr pooled_lci pooled_uci
	
evalue rr `=scalar(pooled_rr)', lcl(`=scalar(pooled_lci)') ucl(`=scalar(pooled_uci)')

meta forestplot _id _plot _esci _weight, ///
    random(reml) se(khartung) eform ///
    columnopts(_id, title("Author, year")) ///
    columnopts(_esci, supertitle("RR") title("(95% CI)")) ///
    xlabel(0.5 1 1.5 2) ///
    xscale(range(0.5 2)) ///
    nullrefline ///
    ohetstatstext("Heterogeneity: {&tau}{sup:2} = `tau2_txt', I{sup:2} = `I2_txt'%, H{sup:2} = `H2_txt'") ///
    ohomtesttext("Test of {&theta}{sub:i} = {&theta}{sub:j}: Q(`dfQ_txt') = `Q_txt', p `phet_txt'") ///
    osigtesttext("Test of {&theta} = 0: t(`dft_txt') = `t_txt', p `poverall_txt'")


/// Leave-one-out sensitivity analysis///
meta summarize, leaveoneout random(reml) se(khartung) eform
meta forestplot _id _plot _esci, leaveoneout random(reml) se(khartung) eform columnopts(_id, title("Study omitted")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(1 1.15 1.3) xscale(range(1 1.15 1.3)) nullrefline

/*bias check*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if full_model == 1
keep if minimum == 1
drop if missing(coef, se)
assert se > 0
label variable coef "Log RR"
label variable se "Standard error"
meta set coef se, studylabel(Studyname)
meta funnelplot, random(reml) xtitle("Log RR") ytitle("Standard error") title("Funnel plot with pseudo 95% confidence limits") legend(off)
meta bias, egger random(reml) se(khartung)


///Sensitivity: restricted to continuous and quantile based studies///
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if minimum == 1
keep if quantile_based == 1 | continuous == 1
keep if full_model == 1
meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung)

scalar pooled_rr  = exp(r(theta))
scalar pooled_lci = exp(r(ci_lb))
scalar pooled_uci = exp(r(ci_ub))

scalar tau2  = r(tau2)
scalar I2    = r(I2)
scalar H2    = r(H2)
scalar Q     = r(Q)
scalar dfQ   = r(df_Q)
scalar phet  = r(p_Q)

scalar t_overall  = r(t)
scalar df_overall = r(df)
scalar p_overall  = r(p)

local tau2_txt : display %6.4f scalar(tau2)
local I2_txt   : display %6.2f scalar(I2)
local H2_txt   : display %6.2f scalar(H2)
local Q_txt    : display %8.2f scalar(Q)
local dfQ_txt  : display %3.0f scalar(dfQ)

if scalar(phet) < 0.001 {
    local phet_txt "< 0.001"
}
else {
    local pnum : display %5.3f scalar(phet)
    local phet_txt "= `pnum'"
}

local t_txt  : display %5.2f scalar(t_overall)
local dft_txt : display %3.0f scalar(df_overall)

if scalar(p_overall) < 0.001 {
    local poverall_txt "< 0.001"
}
else {
    local pnum_overall : display %5.3f scalar(p_overall)
    local poverall_txt "= `pnum_overall'"
}


meta forestplot _id _plot _esci _weight, ///
    random(reml) se(khartung) eform ///
    columnopts(_id, title("Author, year")) ///
    columnopts(_esci, supertitle("RR") title("(95% CI)")) ///
    xlabel(0.5 1 1.5 2) ///
    xscale(range(0.5 2)) ///
    nullrefline ///
    ohetstatstext("Heterogeneity: {&tau}{sup:2} = `tau2_txt', I{sup:2} = `I2_txt'%, H{sup:2} = `H2_txt'") ///
    ohomtesttext("Test of {&theta}{sub:i} = {&theta}{sub:j}: Q(`dfQ_txt') = `Q_txt', p `phet_txt'") ///
    osigtesttext("Test of {&theta} = 0: t(`dft_txt') = `t_txt', p `poverall_txt'")

/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if minimum == 1
keep if quantile_based == 1 | continuous == 1
keep if full_model == 1
meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung)

scalar pooled_rr  = exp(r(theta))
scalar pooled_lci = exp(r(ci_lb))
scalar pooled_uci = exp(r(ci_ub))

scalar tau2  = r(tau2)
scalar I2    = r(I2)
scalar H2    = r(H2)
scalar Q     = r(Q)
scalar dfQ   = r(df_Q)
scalar phet  = r(p_Q)

scalar t_overall  = r(t)
scalar df_overall = r(df)
scalar p_overall  = r(p)

local tau2_txt : display %6.4f scalar(tau2)
local I2_txt   : display %6.2f scalar(I2)
local H2_txt   : display %6.2f scalar(H2)
local Q_txt    : display %8.2f scalar(Q)
local dfQ_txt  : display %3.0f scalar(dfQ)

if scalar(phet) < 0.001 {
    local phet_txt "< 0.001"
}
else {
    local pnum : display %5.3f scalar(phet)
    local phet_txt "= `pnum'"
}

local t_txt  : display %5.2f scalar(t_overall)
local dft_txt : display %3.0f scalar(df_overall)

if scalar(p_overall) < 0.001 {
    local poverall_txt "< 0.001"
}
else {
    local pnum_overall : display %5.3f scalar(p_overall)
    local poverall_txt "= `pnum_overall'"
}


meta forestplot _id _plot _esci _weight, ///
    random(reml) se(khartung) eform ///
    columnopts(_id, title("Author, year")) ///
    columnopts(_esci, supertitle("RR") title("(95% CI)")) ///
    xlabel(0.5 1 1.5 2) ///
    xscale(range(0.5 2)) ///
    nullrefline ///
    ohetstatstext("Heterogeneity: {&tau}{sup:2} = `tau2_txt', I{sup:2} = `I2_txt'%, H{sup:2} = `H2_txt'") ///
    ohomtesttext("Test of {&theta}{sub:i} = {&theta}{sub:j}: Q(`dfQ_txt') = `Q_txt', p `phet_txt'") ///
    osigtesttext("Test of {&theta} = 0: t(`dft_txt') = `t_txt', p `poverall_txt'")
	

/*Sensitivity: open ended category*/
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_open") firstrow clear
keep if bmi_unadjusted == 1
keep if minimum == 1
meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung)

scalar pooled_rr  = exp(r(theta))
scalar pooled_lci = exp(r(ci_lb))
scalar pooled_uci = exp(r(ci_ub))

scalar tau2  = r(tau2)
scalar I2    = r(I2)
scalar H2    = r(H2)
scalar Q     = r(Q)
scalar dfQ   = r(df_Q)
scalar phet  = r(p_Q)

scalar t_overall  = r(t)
scalar df_overall = r(df)
scalar p_overall  = r(p)

local tau2_txt : display %6.4f scalar(tau2)
local I2_txt   : display %6.2f scalar(I2)
local H2_txt   : display %6.2f scalar(H2)
local Q_txt    : display %8.2f scalar(Q)
local dfQ_txt  : display %3.0f scalar(dfQ)

if scalar(phet) < 0.001 {
    local phet_txt "< 0.001"
}
else {
    local pnum : display %5.3f scalar(phet)
    local phet_txt "= `pnum'"
}

local t_txt  : display %5.2f scalar(t_overall)
local dft_txt : display %3.0f scalar(df_overall)

if scalar(p_overall) < 0.001 {
    local poverall_txt "< 0.001"
}
else {
    local pnum_overall : display %5.3f scalar(p_overall)
    local poverall_txt "= `pnum_overall'"
}


meta forestplot _id _plot _esci _weight, ///
    random(reml) se(khartung) eform ///
    columnopts(_id, title("Author, year")) ///
    columnopts(_esci, supertitle("RR") title("(95% CI)")) ///
    xlabel(0.5 1 1.5 2) ///
    xscale(range(0.5 2)) ///
    nullrefline ///
    ohetstatstext("Heterogeneity: {&tau}{sup:2} = `tau2_txt', I{sup:2} = `I2_txt'%, H{sup:2} = `H2_txt'") ///
    ohomtesttext("Test of {&theta}{sub:i} = {&theta}{sub:j}: Q(`dfQ_txt') = `Q_txt', p `phet_txt'") ///
    osigtesttext("Test of {&theta} = 0: t(`dft_txt') = `t_txt', p `poverall_txt'")

drop if missing(coef, se)
assert se > 0
label variable coef "Log RR"
label variable se "Standard error"
metafunnel coef se, xtitle("Log RR") ytitle("Standard error")
metabias coef se, egger


/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_open") firstrow clear
keep if bmi_adjusted == 1
keep if minimum == 1
meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung)

scalar pooled_rr  = exp(r(theta))
scalar pooled_lci = exp(r(ci_lb))
scalar pooled_uci = exp(r(ci_ub))

scalar tau2  = r(tau2)
scalar I2    = r(I2)
scalar H2    = r(H2)
scalar Q     = r(Q)
scalar dfQ   = r(df_Q)
scalar phet  = r(p_Q)

scalar t_overall  = r(t)
scalar df_overall = r(df)
scalar p_overall  = r(p)

local tau2_txt : display %6.4f scalar(tau2)
local I2_txt   : display %6.2f scalar(I2)
local H2_txt   : display %6.2f scalar(H2)
local Q_txt    : display %8.2f scalar(Q)
local dfQ_txt  : display %3.0f scalar(dfQ)

if scalar(phet) < 0.001 {
    local phet_txt "< 0.001"
}
else {
    local pnum : display %5.3f scalar(phet)
    local phet_txt "= `pnum'"
}

local t_txt  : display %5.2f scalar(t_overall)
local dft_txt : display %3.0f scalar(df_overall)

if scalar(p_overall) < 0.001 {
    local poverall_txt "< 0.001"
}
else {
    local pnum_overall : display %5.3f scalar(p_overall)
    local poverall_txt "= `pnum_overall'"
}


meta forestplot _id _plot _esci _weight, ///
    random(reml) se(khartung) eform ///
    columnopts(_id, title("Author, year")) ///
    columnopts(_esci, supertitle("RR") title("(95% CI)")) ///
    xlabel(0.5 1 1.5 2) ///
    xscale(range(0.5 2)) ///
    nullrefline ///
    ohetstatstext("Heterogeneity: {&tau}{sup:2} = `tau2_txt', I{sup:2} = `I2_txt'%, H{sup:2} = `H2_txt'") ///
    ohomtesttext("Test of {&theta}{sub:i} = {&theta}{sub:j}: Q(`dfQ_txt') = `Q_txt', p `phet_txt'") ///
    osigtesttext("Test of {&theta} = 0: t(`dft_txt') = `t_txt', p `poverall_txt'")


*Subgroup*/
/*by sex*/
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if minimum == 1
drop if sex == .
capture label drop sexlbl
label define sexlbl 1 "Men" 2 "Women"
label values sex sexlbl
label variable sex "Sex"
tab sex
duplicates report cohort sex
drop if inlist(id, 3, 9, 10, 12, 13)
duplicates report cohort sex

meta set coef se, studylabel(Studyname)
meta summarize, subgroup(sex) random(reml) se(khartung) eform cformat(%9.4f)

meta forestplot _id _plot _esci _weight, subgroup(sex) random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2))nullrefline


/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if minimum == 1
drop if sex == .
capture label drop sexlbl
label define sexlbl 1 "Men" 2 "Women"
label values sex sexlbl
label variable sex "Sex"
tab sex
duplicates report cohort sex

meta set coef se, studylabel(Studyname)
meta summarize, subgroup(sex) random(reml) se(khartung) eform cformat(%9.4f)

meta forestplot _id _plot _esci _weight, subgroup(sex) random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2))nullrefline


///by continent///
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if full_model == 1
keep if bmi_unadjusted == 1
keep if minimum == 1
capture label drop countrylbl
label define countrylbl 1 "Asia" 2 "Europe" 3 "North America" 4 "Other regions"
label values country countrylbl
label variable country "Region"
tab country
duplicates report cohort country
drop if inlist(country, 2, 4)

meta set coef se, studylabel(Studyname)
meta summarize, subgroup(country) random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, subgroup(country) random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2))nullrefline

/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if full_model == 1
keep if bmi_adjusted == 1
keep if minimum == 1
capture label drop countrylbl
label define countrylbl 1 "Asia" 2 "Europe" 3 "North America" 4 "Other regions"
label values country countrylbl
label variable country "Region"
tab country
duplicates report cohort country

meta set coef se, studylabel(Studyname)
meta summarize, subgroup(country) random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, subgroup(country) random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2))nullrefline


///Additional adjustment///
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if full_model == 1
keep if bmi_unadjusted == 1
keep if minimum == 1
destring ad_cov, replace

gen ad_cov_cat = .
replace ad_cov_cat = 0 if inlist(ad_cov, 0, 1)
replace ad_cov_cat = 1 if inlist(ad_cov, 2, 3)
replace ad_cov_cat = 2 if ad_cov >= 4 & !missing(ad_cov)

label define ad_cov_lbl 0 "0-1" 1 "2–3" 2 "≥4"
label values ad_cov_cat ad_cov_lbl
label variable ad_cov_cat "Number of additional covariates"

tab ad_cov ad_cov_cat, missing

meta set coef se, studylabel(Studyname)
meta summarize, subgroup(ad_cov_cat) random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, subgroup(ad_cov_cat) random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2))nullrefline

/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if full_model == 1
keep if bmi_adjusted == 1
keep if minimum == 1
destring ad_cov, replace

gen ad_cov_cat = .
replace ad_cov_cat = 0 if inlist(ad_cov, 0, 1)
replace ad_cov_cat = 1 if inlist(ad_cov, 2, 3)
replace ad_cov_cat = 2 if ad_cov >= 4 & !missing(ad_cov)

label define ad_cov_lbl 0 "0-1" 1 "2–3" 2 "≥4"
label values ad_cov_cat ad_cov_lbl
label variable ad_cov_cat "Number of additional covariates"

tab ad_cov ad_cov_cat, missing

meta set coef se, studylabel(Studyname)
meta summarize, subgroup(ad_cov_cat) random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, subgroup(ad_cov_cat) random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2))nullrefline


///by age group///
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if full_model == 1
keep if bmi_unadjusted == 1
keep if minimum == 1
destring(mean_age), replace
recode mean_age (min/59 = 1)(60/max = 2), gen(age_group)
capture label drop age_grouplbl
label define age_grouplbl 1 "<60" 2 "≥60"
label value age_group age_grouplbl
tab age_group
duplicates report cohort age_group

meta set coef se, studylabel(Studyname)
meta summarize, subgroup(age_group) random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, subgroup(age_group) random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2))nullrefline

/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if full_model == 1
keep if bmi_adjusted == 1
keep if minimum == 1
destring(mean_age), replace
recode mean_age (min/59 = 1)(60/max = 2), gen(age_group)
capture label drop age_grouplbl
label define age_grouplbl 1 "<60" 2 "≥60"
label value age_group age_grouplbl
tab age_group
duplicates report cohort age_group

meta set coef se, studylabel(Studyname)
meta summarize, subgroup(age_group) random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, subgroup(age_group) random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2))nullrefline


///Exclusion of early death///
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if minimum == 1
destring early_death, replace force
drop if missing(early_death)
drop if inlist(id, 12, 13)
gen byte early_death_grp = .
replace early_death_grp = 0 if early_death < 1
replace early_death_grp = 1 if early_death >= 1
label define early_death_lbl 0 "Not applied" 1 "Applied"

label values early_death_grp early_death_lbl
label variable early_death_grp "Early-death exclusion"
tab early_death early_death_grp, missing

meta set coef se, studylabel(Studyname)
meta summarize, subgroup(early_death_grp) random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, subgroup(early_death_grp) random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline


/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if minimum == 1
destring early_death, replace force
drop if missing(early_death)
drop if id == 29
gen byte early_death_grp = .
replace early_death_grp = 0 if early_death < 1
replace early_death_grp = 1 if early_death >= 1
label define early_death_lbl 0 "Not applied" 1 "Applied"

label values early_death_grp early_death_lbl
label variable early_death_grp "Early-death exclusion"
tab early_death early_death_grp, missing

meta set coef se, studylabel(Studyname)
meta summarize, subgroup(early_death_grp) random(reml) se(khartung) eform
meta forestplot _id _plot _esci _weight, subgroup(early_death_grp) random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline


///Restriction to studies with older population///
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if minimum == 1
destring(older_age), replace
drop if older_age == .
drop if inlist(id, 9, 10)

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline

import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if minimum == 1
destring(older_age), replace
drop if older_age == .
drop if inlist(id, 9, 10)
drop if older_age < 60

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline

/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if minimum == 1
destring(older_age), replace
drop if older_age == .

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline


///Restriction based on follow up duration///
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if minimum == 1
keep if full_model == 1
drop if follow_up < 5

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline

import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if minimum == 1
keep if full_model == 1
drop if follow_up < 10

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline

/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if minimum == 1
keep if full_model == 1
drop if follow_up < 5

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline

import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if minimum == 1
keep if full_model == 1
drop if follow_up < 10

meta set coef se, studylabel(Studyname)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline


///Restriction to never smokers///
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if minimum == 1
destring(neversmoker), replace
keep if neversmoker == 1

meta set coef se, studylabel(Studyname)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline


/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if minimum == 1
destring(neversmoker), replace
keep if neversmoker == 1

meta set coef se, studylabel(Studyname)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline


///Restriction to healthy_adults///
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if minimum == 1
destring(healthy), replace
keep if healthy == 1
drop if inlist(id, 3)

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline

/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if minimum == 1
destring(healthy), replace
keep if healthy == 1

meta set coef se, studylabel(Studyname)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline


/*Restricted to measured anthropometric data*/
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if full_model == 1
keep if minimum == 1
keep if self_report == 0

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline


/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if full_model == 1
keep if minimum == 1
keep if self_report == 0

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline


///Excluding studies adjusted for intermediate variables///
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if full_model == 1
keep if minimum == 1
drop if mediator == 1

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline

/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if full_model == 1
keep if minimum == 1
drop if mediator == 1

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline

///Excluding studies with high risk of bias///
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_unadjusted == 1
keep if full_model == 1
keep if minimum == 1
drop if high_risk == 1

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline

/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("linear_main") firstrow clear
keep if bmi_adjusted == 1
keep if full_model == 1
keep if minimum == 1
drop if high_risk == 1

meta set coef se, studylabel(Studyname)
meta summarize, random(reml) se(khartung) eform cformat(%9.4f)
meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline


/*==============================Nonlinear====================================*/
/*BMI unadjusted*/
/*Main*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical") firstrow clear

assert RR > 0 & LCI > 0 & UCI > 0 if !missing(RR, LCI, UCI)
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

tab study
tab drtype

drmeta logrr doses*, se(selogrr) data(person_years case) id(id) type(drtype) 2stage reml hamling

test doses2
display "P for nonlinearity = " %6.4f r(p)

local search_min  0.060
local search_max 0.1
local gridstep     0.001

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

local xmin    0.06
local xmax   0.1
local step   0.00001
local refdose `nadir'

local ymin    0.6
local ymax    4.0

tempname B V b1 b2 v11 v12 v22 r1 r2

matrix `B' = e(b)
matrix `V' = e(V)

local c1 = colnumb(`B', "doses1")
local c2 = colnumb(`B', "doses2")

scalar `b1'  = `B'[1, `c1']
scalar `b2'  = `B'[1, `c2']

scalar `v11' = `V'[`c1', `c1']
scalar `v12' = `V'[`c1', `c2']
scalar `v22' = `V'[`c2', `c2']

tempfile curve

preserve

clear

local ngrid = round((`xmax' - `xmin') / `step') + 1
local nall  = `ngrid' + 1

set obs `nall'

gen double dose_curve = ///
    `xmin' + `step' * (_n - 1) in 1/`ngrid'

replace dose_curve = `refdose' in `nall'

local k1 = el(knots, 1, 1)
local k2 = el(knots, 1, 2)
local k3 = el(knots, 1, 3)

mkspline sp = dose_curve, ///
    knots(`k1' `k2' `k3') cubic

scalar `r1' = sp1[`nall']
scalar `r2' = sp2[`nall']

gen double d1 = sp1 - scalar(`r1')
gen double d2 = sp2 - scalar(`r2')

gen double fit_logrr = ///
      scalar(`b1') * d1 ///
    + scalar(`b2') * d2

gen double fit_var = ///
      d1^2 * scalar(`v11') ///
    + d2^2 * scalar(`v22') ///
    + 2*d1*d2 * scalar(`v12')

replace fit_var = 0 ///
    if fit_var < 0 & fit_var > -1e-12

gen double fit_rr = exp(fit_logrr)
gen double fit_lo = exp(fit_logrr - invnormal(.975)*sqrt(fit_var))
gen double fit_hi = exp(fit_logrr + invnormal(.975)*sqrt(fit_var))

drop in `nall'

sort dose_curve

foreach y in fit_rr fit_lo fit_hi {

    gen double `y'_plot = `y'

    gen byte cross_upper_`y' = ///
        `y' > `ymax' & ///
        ( ///
            (_n > 1  & `y'[_n-1] <= `ymax') | ///
            (_n < _N & `y'[_n+1] <= `ymax') ///
        )

    replace `y'_plot = `ymax' ///
        if cross_upper_`y'

    replace `y'_plot = . ///
        if `y' > `ymax' & !cross_upper_`y'

    gen byte cross_lower_`y' = ///
        `y' < `ymin' & ///
        ( ///
            (_n > 1  & `y'[_n-1] >= `ymin') | ///
            (_n < _N & `y'[_n+1] >= `ymin') ///
        )

    replace `y'_plot = `ymin' ///
        if cross_lower_`y'

    replace `y'_plot = . ///
        if `y' < `ymin' & !cross_lower_`y'
}

gen byte curveobs = 1

keep dose_curve ///
     fit_rr_plot fit_lo_plot fit_hi_plot ///
     curveobs

save `curve', replace

restore


capture confirm variable refcat
if _rc {
    gen byte refcat = ///
        abs(logrr) < 1e-10 & abs(selogrr) < 1e-10
}

capture confirm variable rug_all_y
if _rc {
    gen double rug_all_y = 1 ///
        if inrange(dose, `xmin', `xmax')
}

capture confirm variable rug_ref_y
if _rc {
    gen double rug_ref_y = 1 ///
        if refcat & inrange(dose, `xmin', `xmax')
}

preserve

gen byte curveobs = 0
append using `curve'

twoway ///
	(line fit_hi_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
	(line fit_lo_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
    (line fit_rr_plot dose_curve if curveobs == 1, ///
        sort lcolor(black) lpattern(solid) lwidth(medium)) ///
    (scatter rug_all_y dose if curveobs == 0 & !missing(rug_all_y), ///
        msymbol(|) mcolor(gs10) msize(medium)) ///
    (scatter rug_ref_y dose if curveobs == 0 & !missing(rug_ref_y), ///
        msymbol(|) mcolor(black) msize(large)), ///
    xtitle("ABSI", size(large)) ///
    ytitle("RR", size(large)) ///
    xlabel(0.06(0.01)0.1, labsize(large) norescale) ///
    ylabel(0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0, ///
        format(%3.1f) labsize(large) angle(horizontal) norescale) ///
    xscale(range(0.06 0.1)) ///
    yscale(log range(0.6 4.0)) ///
    yline(1, lcolor(gs10) lpattern(solid)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white))

restore
	

/*Quantile based*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical") firstrow clear

assert RR > 0 & LCI > 0 & UCI > 0 if !missing(RR, LCI, UCI)
gen double logrr   = ln(RR)
gen double logrrL  = ln(LCI)
gen double logrrU  = ln(UCI)
gen double selogrr = (logrrU - logrrL)/(2 * invnormal(.975))

keep if bmi_unadjusted == 1
keep if full_model == 1
keep if minimum == 1
keep if quantile_based == 1
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

tab study
tab drtype

drmeta logrr doses*, se(selogrr) data(person_years case) id(id) type(drtype) 2stage reml hamling

test doses2
display "P for nonlinearity = " %6.4f r(p)

local xmin   0.06
local xmax   0.1
local step   0.00001
local refdose = `p25'
local ymin    0.6
local ymax    4.0

tempname B V b1 b2 v11 v12 v22 r1 r2

matrix `B' = e(b)
matrix `V' = e(V)

local c1 = colnumb(`B', "doses1")
local c2 = colnumb(`B', "doses2")

scalar `b1'  = `B'[1, `c1']
scalar `b2'  = `B'[1, `c2']

scalar `v11' = `V'[`c1', `c1']
scalar `v12' = `V'[`c1', `c2']
scalar `v22' = `V'[`c2', `c2']

tempfile curve

preserve

clear

local ngrid = round((`xmax' - `xmin') / `step') + 1
local nall  = `ngrid' + 1

set obs `nall'

gen double dose_curve = ///
    `xmin' + `step' * (_n - 1) in 1/`ngrid'

replace dose_curve = `refdose' in `nall'

local k1 = el(knots, 1, 1)
local k2 = el(knots, 1, 2)
local k3 = el(knots, 1, 3)

mkspline sp = dose_curve, ///
    knots(`k1' `k2' `k3') cubic

scalar `r1' = sp1[`nall']
scalar `r2' = sp2[`nall']

gen double d1 = sp1 - scalar(`r1')
gen double d2 = sp2 - scalar(`r2')

gen double fit_logrr = ///
      scalar(`b1') * d1 ///
    + scalar(`b2') * d2

gen double fit_var = ///
      d1^2 * scalar(`v11') ///
    + d2^2 * scalar(`v22') ///
    + 2*d1*d2 * scalar(`v12')

replace fit_var = 0 ///
    if fit_var < 0 & fit_var > -1e-12

gen double fit_rr = exp(fit_logrr)
gen double fit_lo = exp(fit_logrr - invnormal(.975)*sqrt(fit_var))
gen double fit_hi = exp(fit_logrr + invnormal(.975)*sqrt(fit_var))

drop in `nall'

sort dose_curve

foreach y in fit_rr fit_lo fit_hi {

    gen double `y'_plot = `y'

    gen byte cross_upper_`y' = ///
        `y' > `ymax' & ///
        ( ///
            (_n > 1  & `y'[_n-1] <= `ymax') | ///
            (_n < _N & `y'[_n+1] <= `ymax') ///
        )

    replace `y'_plot = `ymax' ///
        if cross_upper_`y'

    replace `y'_plot = . ///
        if `y' > `ymax' & !cross_upper_`y'

    gen byte cross_lower_`y' = ///
        `y' < `ymin' & ///
        ( ///
            (_n > 1  & `y'[_n-1] >= `ymin') | ///
            (_n < _N & `y'[_n+1] >= `ymin') ///
        )

    replace `y'_plot = `ymin' ///
        if cross_lower_`y'

    replace `y'_plot = . ///
        if `y' < `ymin' & !cross_lower_`y'
}

gen byte curveobs = 1

keep dose_curve ///
     fit_rr_plot fit_lo_plot fit_hi_plot ///
     curveobs

save `curve', replace

restore


capture confirm variable refcat
if _rc {
    gen byte refcat = ///
        abs(logrr) < 1e-10 & abs(selogrr) < 1e-10
}

capture confirm variable rug_all_y
if _rc {
    gen double rug_all_y = 1 ///
        if inrange(dose, `xmin', `xmax')
}

capture confirm variable rug_ref_y
if _rc {
    gen double rug_ref_y = 1 ///
        if refcat & inrange(dose, `xmin', `xmax')
}

preserve

gen byte curveobs = 0
append using `curve'

twoway ///
	(line fit_hi_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
	(line fit_lo_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
    (line fit_rr_plot dose_curve if curveobs == 1, ///
        sort lcolor(black) lpattern(solid) lwidth(medium)) ///
    (scatter rug_all_y dose if curveobs == 0 & !missing(rug_all_y), ///
        msymbol(|) mcolor(gs10) msize(medium)) ///
    (scatter rug_ref_y dose if curveobs == 0 & !missing(rug_ref_y), ///
        msymbol(|) mcolor(black) msize(large)), ///
    xtitle("ABSI", size(large)) ///
    ytitle("RR", size(large)) ///
    xlabel(0.06(0.01)0.1, labsize(large) norescale) ///
    ylabel(0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0, ///
        format(%3.1f) labsize(large) angle(horizontal) norescale) ///
    xscale(range(0.06 0.1)) ///
    yscale(log range(0.6 4.0)) ///
    yline(1, lcolor(gs10) lpattern(solid)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white))

restore

	
/*Open ended*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical_open") firstrow clear

assert RR > 0 & LCI > 0 & UCI > 0 if !missing(RR, LCI, UCI)
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

tab study
tab drtype

drmeta logrr doses*, se(selogrr) data(person_years case) id(id) type(drtype) 2stage reml hamling

test doses2
display "P for nonlinearity = " %6.4f r(p)

local search_min  0.06
local search_max 0.1
local gridstep     0.001

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

local xmin    0.06
local xmax   0.1
local step   0.00001
local refdose `nadir'
local ymin    0.6
local ymax    4.0

tempname B V b1 b2 v11 v12 v22 r1 r2

matrix `B' = e(b)
matrix `V' = e(V)

local c1 = colnumb(`B', "doses1")
local c2 = colnumb(`B', "doses2")

scalar `b1'  = `B'[1, `c1']
scalar `b2'  = `B'[1, `c2']

scalar `v11' = `V'[`c1', `c1']
scalar `v12' = `V'[`c1', `c2']
scalar `v22' = `V'[`c2', `c2']

tempfile curve

preserve

clear

local ngrid = round((`xmax' - `xmin') / `step') + 1
local nall  = `ngrid' + 1

set obs `nall'

gen double dose_curve = ///
    `xmin' + `step' * (_n - 1) in 1/`ngrid'

replace dose_curve = `refdose' in `nall'

local k1 = el(knots, 1, 1)
local k2 = el(knots, 1, 2)
local k3 = el(knots, 1, 3)

mkspline sp = dose_curve, ///
    knots(`k1' `k2' `k3') cubic

scalar `r1' = sp1[`nall']
scalar `r2' = sp2[`nall']

gen double d1 = sp1 - scalar(`r1')
gen double d2 = sp2 - scalar(`r2')

gen double fit_logrr = ///
      scalar(`b1') * d1 ///
    + scalar(`b2') * d2

gen double fit_var = ///
      d1^2 * scalar(`v11') ///
    + d2^2 * scalar(`v22') ///
    + 2*d1*d2 * scalar(`v12')

replace fit_var = 0 ///
    if fit_var < 0 & fit_var > -1e-12

gen double fit_rr = exp(fit_logrr)
gen double fit_lo = exp(fit_logrr - invnormal(.975)*sqrt(fit_var))
gen double fit_hi = exp(fit_logrr + invnormal(.975)*sqrt(fit_var))

drop in `nall'

sort dose_curve

foreach y in fit_rr fit_lo fit_hi {

    gen double `y'_plot = `y'

    gen byte cross_upper_`y' = ///
        `y' > `ymax' & ///
        ( ///
            (_n > 1  & `y'[_n-1] <= `ymax') | ///
            (_n < _N & `y'[_n+1] <= `ymax') ///
        )

    replace `y'_plot = `ymax' ///
        if cross_upper_`y'

    replace `y'_plot = . ///
        if `y' > `ymax' & !cross_upper_`y'

    gen byte cross_lower_`y' = ///
        `y' < `ymin' & ///
        ( ///
            (_n > 1  & `y'[_n-1] >= `ymin') | ///
            (_n < _N & `y'[_n+1] >= `ymin') ///
        )

    replace `y'_plot = `ymin' ///
        if cross_lower_`y'

    replace `y'_plot = . ///
        if `y' < `ymin' & !cross_lower_`y'
}

gen byte curveobs = 1

keep dose_curve ///
     fit_rr_plot fit_lo_plot fit_hi_plot ///
     curveobs

save `curve', replace

restore


capture confirm variable refcat
if _rc {
    gen byte refcat = ///
        abs(logrr) < 1e-10 & abs(selogrr) < 1e-10
}

capture confirm variable rug_all_y
if _rc {
    gen double rug_all_y = 1 ///
        if inrange(dose, `xmin', `xmax')
}

capture confirm variable rug_ref_y
if _rc {
    gen double rug_ref_y = 1 ///
        if refcat & inrange(dose, `xmin', `xmax')
}

preserve

gen byte curveobs = 0
append using `curve'

twoway ///
	(line fit_hi_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
	(line fit_lo_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
    (line fit_rr_plot dose_curve if curveobs == 1, ///
        sort lcolor(black) lpattern(solid) lwidth(medium)) ///
    (scatter rug_all_y dose if curveobs == 0 & !missing(rug_all_y), ///
        msymbol(|) mcolor(gs10) msize(medium)) ///
    (scatter rug_ref_y dose if curveobs == 0 & !missing(rug_ref_y), ///
        msymbol(|) mcolor(black) msize(large)), ///
    xtitle("ABSI", size(large)) ///
    ytitle("RR", size(large)) ///
    xlabel(0.06(0.01)0.1, labsize(large) norescale) ///
    ylabel(0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0, ///
        format(%3.1f) labsize(large) angle(horizontal) norescale) ///
    xscale(range(0.06 0.1)) ///
    yscale(log range(0.6 4.0)) ///
    yline(1, lcolor(gs10) lpattern(solid)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white))

restore	



/*BMI adjusted*/
/*Main*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical") firstrow clear

gen double logrr   = ln(RR)
gen double logrrL  = ln(LCI)
gen double logrrU  = ln(UCI)
gen double selogrr = (logrrU - logrrL)/(2 * invnormal(.975))

keep if bmi_adjusted == 1
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

local search_min  0.06
local search_max 0.1
local gridstep     0.001

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

local xmin    0.06
local xmax   0.1
local step   0.00001
local refdose `nadir'
local ymin    0.6
local ymax    4.0

tempname B V b1 b2 v11 v12 v22 r1 r2

matrix `B' = e(b)
matrix `V' = e(V)

local c1 = colnumb(`B', "doses1")
local c2 = colnumb(`B', "doses2")

scalar `b1'  = `B'[1, `c1']
scalar `b2'  = `B'[1, `c2']

scalar `v11' = `V'[`c1', `c1']
scalar `v12' = `V'[`c1', `c2']
scalar `v22' = `V'[`c2', `c2']

tempfile curve

preserve

clear

local ngrid = round((`xmax' - `xmin') / `step') + 1
local nall  = `ngrid' + 1

set obs `nall'

gen double dose_curve = ///
    `xmin' + `step' * (_n - 1) in 1/`ngrid'

replace dose_curve = `refdose' in `nall'

local k1 = el(knots, 1, 1)
local k2 = el(knots, 1, 2)
local k3 = el(knots, 1, 3)

mkspline sp = dose_curve, ///
    knots(`k1' `k2' `k3') cubic

scalar `r1' = sp1[`nall']
scalar `r2' = sp2[`nall']

gen double d1 = sp1 - scalar(`r1')
gen double d2 = sp2 - scalar(`r2')

gen double fit_logrr = ///
      scalar(`b1') * d1 ///
    + scalar(`b2') * d2

gen double fit_var = ///
      d1^2 * scalar(`v11') ///
    + d2^2 * scalar(`v22') ///
    + 2*d1*d2 * scalar(`v12')

replace fit_var = 0 ///
    if fit_var < 0 & fit_var > -1e-12

gen double fit_rr = exp(fit_logrr)
gen double fit_lo = exp(fit_logrr - invnormal(.975)*sqrt(fit_var))
gen double fit_hi = exp(fit_logrr + invnormal(.975)*sqrt(fit_var))

drop in `nall'

sort dose_curve

foreach y in fit_rr fit_lo fit_hi {

    gen double `y'_plot = `y'

    gen byte cross_upper_`y' = ///
        `y' > `ymax' & ///
        ( ///
            (_n > 1  & `y'[_n-1] <= `ymax') | ///
            (_n < _N & `y'[_n+1] <= `ymax') ///
        )

    replace `y'_plot = `ymax' ///
        if cross_upper_`y'

    replace `y'_plot = . ///
        if `y' > `ymax' & !cross_upper_`y'

    gen byte cross_lower_`y' = ///
        `y' < `ymin' & ///
        ( ///
            (_n > 1  & `y'[_n-1] >= `ymin') | ///
            (_n < _N & `y'[_n+1] >= `ymin') ///
        )

    replace `y'_plot = `ymin' ///
        if cross_lower_`y'

    replace `y'_plot = . ///
        if `y' < `ymin' & !cross_lower_`y'
}

gen byte curveobs = 1

keep dose_curve ///
     fit_rr_plot fit_lo_plot fit_hi_plot ///
     curveobs

save `curve', replace

restore


capture confirm variable refcat
if _rc {
    gen byte refcat = ///
        abs(logrr) < 1e-10 & abs(selogrr) < 1e-10
}

capture confirm variable rug_all_y
if _rc {
    gen double rug_all_y = 1 ///
        if inrange(dose, `xmin', `xmax')
}

capture confirm variable rug_ref_y
if _rc {
    gen double rug_ref_y = 1 ///
        if refcat & inrange(dose, `xmin', `xmax')
}

preserve

gen byte curveobs = 0
append using `curve'

twoway ///
	(line fit_hi_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
	(line fit_lo_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
    (line fit_rr_plot dose_curve if curveobs == 1, ///
        sort lcolor(black) lpattern(solid) lwidth(medium)) ///
    (scatter rug_all_y dose if curveobs == 0 & !missing(rug_all_y), ///
        msymbol(|) mcolor(gs10) msize(medium)) ///
    (scatter rug_ref_y dose if curveobs == 0 & !missing(rug_ref_y), ///
        msymbol(|) mcolor(black) msize(large)), ///
    xtitle("ABSI", size(large)) ///
    ytitle("RR", size(large)) ///
    xlabel(0.06(0.01)0.1, labsize(large) norescale) ///
    ylabel(0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0, ///
        format(%3.1f) labsize(large) angle(horizontal) norescale) ///
    xscale(range(0.06 0.1)) ///
    yscale(log range(0.6 4.0)) ///
    yline(1, lcolor(gs10) lpattern(solid)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white))

restore	
	

/*Quantile based*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical") firstrow clear

gen double logrr   = ln(RR)
gen double logrrL  = ln(LCI)
gen double logrrU  = ln(UCI)
gen double selogrr = (logrrU - logrrL)/(2 * invnormal(.975))

keep if bmi_adjusted == 1
keep if full_model == 1
keep if minimum == 1
keep if quantile_based == 1
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

local search_min  0.06
local search_max 0.1
local gridstep     0.001

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

local xmin    0.06
local xmax   0.1
local step   0.00001
local refdose `nadir'
local ymin    0.6
local ymax    4.0

tempname B V b1 b2 v11 v12 v22 r1 r2

matrix `B' = e(b)
matrix `V' = e(V)

local c1 = colnumb(`B', "doses1")
local c2 = colnumb(`B', "doses2")

scalar `b1'  = `B'[1, `c1']
scalar `b2'  = `B'[1, `c2']

scalar `v11' = `V'[`c1', `c1']
scalar `v12' = `V'[`c1', `c2']
scalar `v22' = `V'[`c2', `c2']

tempfile curve

preserve

clear

local ngrid = round((`xmax' - `xmin') / `step') + 1
local nall  = `ngrid' + 1

set obs `nall'

gen double dose_curve = ///
    `xmin' + `step' * (_n - 1) in 1/`ngrid'

replace dose_curve = `refdose' in `nall'

local k1 = el(knots, 1, 1)
local k2 = el(knots, 1, 2)
local k3 = el(knots, 1, 3)

mkspline sp = dose_curve, ///
    knots(`k1' `k2' `k3') cubic

scalar `r1' = sp1[`nall']
scalar `r2' = sp2[`nall']

gen double d1 = sp1 - scalar(`r1')
gen double d2 = sp2 - scalar(`r2')

gen double fit_logrr = ///
      scalar(`b1') * d1 ///
    + scalar(`b2') * d2

gen double fit_var = ///
      d1^2 * scalar(`v11') ///
    + d2^2 * scalar(`v22') ///
    + 2*d1*d2 * scalar(`v12')

replace fit_var = 0 ///
    if fit_var < 0 & fit_var > -1e-12

gen double fit_rr = exp(fit_logrr)
gen double fit_lo = exp(fit_logrr - invnormal(.975)*sqrt(fit_var))
gen double fit_hi = exp(fit_logrr + invnormal(.975)*sqrt(fit_var))

drop in `nall'

sort dose_curve

foreach y in fit_rr fit_lo fit_hi {

    gen double `y'_plot = `y'

    gen byte cross_upper_`y' = ///
        `y' > `ymax' & ///
        ( ///
            (_n > 1  & `y'[_n-1] <= `ymax') | ///
            (_n < _N & `y'[_n+1] <= `ymax') ///
        )

    replace `y'_plot = `ymax' ///
        if cross_upper_`y'

    replace `y'_plot = . ///
        if `y' > `ymax' & !cross_upper_`y'

    gen byte cross_lower_`y' = ///
        `y' < `ymin' & ///
        ( ///
            (_n > 1  & `y'[_n-1] >= `ymin') | ///
            (_n < _N & `y'[_n+1] >= `ymin') ///
        )

    replace `y'_plot = `ymin' ///
        if cross_lower_`y'

    replace `y'_plot = . ///
        if `y' < `ymin' & !cross_lower_`y'
}

gen byte curveobs = 1

keep dose_curve ///
     fit_rr_plot fit_lo_plot fit_hi_plot ///
     curveobs

save `curve', replace

restore


capture confirm variable refcat
if _rc {
    gen byte refcat = ///
        abs(logrr) < 1e-10 & abs(selogrr) < 1e-10
}

capture confirm variable rug_all_y
if _rc {
    gen double rug_all_y = 1 ///
        if inrange(dose, `xmin', `xmax')
}

capture confirm variable rug_ref_y
if _rc {
    gen double rug_ref_y = 1 ///
        if refcat & inrange(dose, `xmin', `xmax')
}

preserve

gen byte curveobs = 0
append using `curve'

twoway ///
	(line fit_hi_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
	(line fit_lo_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
    (line fit_rr_plot dose_curve if curveobs == 1, ///
        sort lcolor(black) lpattern(solid) lwidth(medium)) ///
    (scatter rug_all_y dose if curveobs == 0 & !missing(rug_all_y), ///
        msymbol(|) mcolor(gs10) msize(medium)) ///
    (scatter rug_ref_y dose if curveobs == 0 & !missing(rug_ref_y), ///
        msymbol(|) mcolor(black) msize(large)), ///
    xtitle("ABSI", size(large)) ///
    ytitle("RR", size(large)) ///
    xlabel(0.06(0.01)0.1, labsize(large) norescale) ///
    ylabel(0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0, ///
        format(%3.1f) labsize(large) angle(horizontal) norescale) ///
    xscale(range(0.06 0.1)) ///
    yscale(log range(0.6 4.0)) ///
    yline(1, lcolor(gs10) lpattern(solid)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white))

restore	
	

/*open ended*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical_open") firstrow clear

gen double logrr   = ln(RR)
gen double logrrL  = ln(LCI)
gen double logrrU  = ln(UCI)
gen double selogrr = (logrrU - logrrL)/(2 * invnormal(.975))

keep if bmi_adjusted == 1
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

local search_min  0.06
local search_max 0.1
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

gen double rug_all_y = 1 if inrange(dose, 0.06, 0.10)
gen double rug_ref_y = 1 if refcat & inrange(dose, 0.06, 0.10)
	
drmeta_graph, matk(knots) dose(0.06(0.001)0.10) list ref(`nadir') eform ///
    xtitle("ABSI", size(large)) ///
    ytitle("RR", size(large)) ///
    yline(1, lcolor(gs10) lpattern(line)) ///
    ylabel(0.6 0.8 1 (0.5) 4.0, labsize(large)) ///
    xlabel(0.06(0.01)0.10, labsize(large)) ///
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



/*Follow-up*/
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical") firstrow clear

assert RR > 0 & LCI > 0 & UCI > 0 if !missing(RR, LCI, UCI)
gen double logrr   = ln(RR)
gen double logrrL  = ln(LCI)
gen double logrrU  = ln(UCI)
gen double selogrr = (logrrU - logrrL)/(2 * invnormal(.975))

keep if bmi_unadjusted == 1
keep if minimum == 1
keep if full_model == 1
drop if follow_up < 5
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

tab study
tab drtype

drmeta logrr doses*, se(selogrr) data(person_years case) id(id) type(drtype) 2stage reml hamling

test doses2
display "P for nonlinearity = " %6.4f r(p)

local search_min  0.06
local search_max 0.1
local gridstep     0.001

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

local xmin    0.06
local xmax   0.1
local step   0.00001
local refdose `nadir'
local ymin    0.6
local ymax    4.0

tempname B V b1 b2 v11 v12 v22 r1 r2

matrix `B' = e(b)
matrix `V' = e(V)

local c1 = colnumb(`B', "doses1")
local c2 = colnumb(`B', "doses2")

scalar `b1'  = `B'[1, `c1']
scalar `b2'  = `B'[1, `c2']

scalar `v11' = `V'[`c1', `c1']
scalar `v12' = `V'[`c1', `c2']
scalar `v22' = `V'[`c2', `c2']

tempfile curve

preserve

clear

local ngrid = round((`xmax' - `xmin') / `step') + 1
local nall  = `ngrid' + 1

set obs `nall'

gen double dose_curve = ///
    `xmin' + `step' * (_n - 1) in 1/`ngrid'

replace dose_curve = `refdose' in `nall'

local k1 = el(knots, 1, 1)
local k2 = el(knots, 1, 2)
local k3 = el(knots, 1, 3)

mkspline sp = dose_curve, ///
    knots(`k1' `k2' `k3') cubic

scalar `r1' = sp1[`nall']
scalar `r2' = sp2[`nall']

gen double d1 = sp1 - scalar(`r1')
gen double d2 = sp2 - scalar(`r2')

gen double fit_logrr = ///
      scalar(`b1') * d1 ///
    + scalar(`b2') * d2

gen double fit_var = ///
      d1^2 * scalar(`v11') ///
    + d2^2 * scalar(`v22') ///
    + 2*d1*d2 * scalar(`v12')

replace fit_var = 0 ///
    if fit_var < 0 & fit_var > -1e-12

gen double fit_rr = exp(fit_logrr)
gen double fit_lo = exp(fit_logrr - invnormal(.975)*sqrt(fit_var))
gen double fit_hi = exp(fit_logrr + invnormal(.975)*sqrt(fit_var))

drop in `nall'

sort dose_curve

foreach y in fit_rr fit_lo fit_hi {

    gen double `y'_plot = `y'

    gen byte cross_upper_`y' = ///
        `y' > `ymax' & ///
        ( ///
            (_n > 1  & `y'[_n-1] <= `ymax') | ///
            (_n < _N & `y'[_n+1] <= `ymax') ///
        )

    replace `y'_plot = `ymax' ///
        if cross_upper_`y'

    replace `y'_plot = . ///
        if `y' > `ymax' & !cross_upper_`y'

    gen byte cross_lower_`y' = ///
        `y' < `ymin' & ///
        ( ///
            (_n > 1  & `y'[_n-1] >= `ymin') | ///
            (_n < _N & `y'[_n+1] >= `ymin') ///
        )

    replace `y'_plot = `ymin' ///
        if cross_lower_`y'

    replace `y'_plot = . ///
        if `y' < `ymin' & !cross_lower_`y'
}

gen byte curveobs = 1

keep dose_curve ///
     fit_rr_plot fit_lo_plot fit_hi_plot ///
     curveobs

save `curve', replace

restore


capture confirm variable refcat
if _rc {
    gen byte refcat = ///
        abs(logrr) < 1e-10 & abs(selogrr) < 1e-10
}

capture confirm variable rug_all_y
if _rc {
    gen double rug_all_y = 1 ///
        if inrange(dose, `xmin', `xmax')
}

capture confirm variable rug_ref_y
if _rc {
    gen double rug_ref_y = 1 ///
        if refcat & inrange(dose, `xmin', `xmax')
}

preserve

gen byte curveobs = 0
append using `curve'

twoway ///
	(line fit_hi_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
	(line fit_lo_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
    (line fit_rr_plot dose_curve if curveobs == 1, ///
        sort lcolor(black) lpattern(solid) lwidth(medium)) ///
    (scatter rug_all_y dose if curveobs == 0 & !missing(rug_all_y), ///
        msymbol(|) mcolor(gs10) msize(medium)) ///
    (scatter rug_ref_y dose if curveobs == 0 & !missing(rug_ref_y), ///
        msymbol(|) mcolor(black) msize(large)), ///
    xtitle("ABSI", size(large)) ///
    ytitle("RR", size(large)) ///
    xlabel(0.06(0.01)0.1, labsize(large) norescale) ///
    ylabel(0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0, ///
        format(%3.1f) labsize(large) angle(horizontal) norescale) ///
    xscale(range(0.06 0.1)) ///
    yscale(log range(0.6 4.0)) ///
    yline(1, lcolor(gs10) lpattern(solid)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white))

restore


/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical") firstrow clear

assert RR > 0 & LCI > 0 & UCI > 0 if !missing(RR, LCI, UCI)
gen double logrr   = ln(RR)
gen double logrrL  = ln(LCI)
gen double logrrU  = ln(UCI)
gen double selogrr = (logrrU - logrrL)/(2 * invnormal(.975))

keep if bmi_adjusted == 1
keep if minimum == 1
keep if full_model == 1
drop if follow_up < 5
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

tab study
tab drtype

drmeta logrr doses*, se(selogrr) data(person_years case) id(id) type(drtype) 2stage reml hamling

test doses2
display "P for nonlinearity = " %6.4f r(p)

local search_min  0.06
local search_max 0.1
local gridstep     0.001

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

local xmin    0.06
local xmax   0.1
local step   0.00001
local refdose `nadir'
local ymin    0.6
local ymax    4.0

tempname B V b1 b2 v11 v12 v22 r1 r2

matrix `B' = e(b)
matrix `V' = e(V)

local c1 = colnumb(`B', "doses1")
local c2 = colnumb(`B', "doses2")

scalar `b1'  = `B'[1, `c1']
scalar `b2'  = `B'[1, `c2']

scalar `v11' = `V'[`c1', `c1']
scalar `v12' = `V'[`c1', `c2']
scalar `v22' = `V'[`c2', `c2']

tempfile curve

preserve

clear

local ngrid = round((`xmax' - `xmin') / `step') + 1
local nall  = `ngrid' + 1

set obs `nall'

gen double dose_curve = ///
    `xmin' + `step' * (_n - 1) in 1/`ngrid'

replace dose_curve = `refdose' in `nall'

local k1 = el(knots, 1, 1)
local k2 = el(knots, 1, 2)
local k3 = el(knots, 1, 3)

mkspline sp = dose_curve, ///
    knots(`k1' `k2' `k3') cubic

scalar `r1' = sp1[`nall']
scalar `r2' = sp2[`nall']

gen double d1 = sp1 - scalar(`r1')
gen double d2 = sp2 - scalar(`r2')

gen double fit_logrr = ///
      scalar(`b1') * d1 ///
    + scalar(`b2') * d2

gen double fit_var = ///
      d1^2 * scalar(`v11') ///
    + d2^2 * scalar(`v22') ///
    + 2*d1*d2 * scalar(`v12')

replace fit_var = 0 ///
    if fit_var < 0 & fit_var > -1e-12

gen double fit_rr = exp(fit_logrr)
gen double fit_lo = exp(fit_logrr - invnormal(.975)*sqrt(fit_var))
gen double fit_hi = exp(fit_logrr + invnormal(.975)*sqrt(fit_var))

drop in `nall'

sort dose_curve

foreach y in fit_rr fit_lo fit_hi {

    gen double `y'_plot = `y'

    gen byte cross_upper_`y' = ///
        `y' > `ymax' & ///
        ( ///
            (_n > 1  & `y'[_n-1] <= `ymax') | ///
            (_n < _N & `y'[_n+1] <= `ymax') ///
        )

    replace `y'_plot = `ymax' ///
        if cross_upper_`y'

    replace `y'_plot = . ///
        if `y' > `ymax' & !cross_upper_`y'

    gen byte cross_lower_`y' = ///
        `y' < `ymin' & ///
        ( ///
            (_n > 1  & `y'[_n-1] >= `ymin') | ///
            (_n < _N & `y'[_n+1] >= `ymin') ///
        )

    replace `y'_plot = `ymin' ///
        if cross_lower_`y'

    replace `y'_plot = . ///
        if `y' < `ymin' & !cross_lower_`y'
}

gen byte curveobs = 1

keep dose_curve ///
     fit_rr_plot fit_lo_plot fit_hi_plot ///
     curveobs

save `curve', replace

restore


capture confirm variable refcat
if _rc {
    gen byte refcat = ///
        abs(logrr) < 1e-10 & abs(selogrr) < 1e-10
}

capture confirm variable rug_all_y
if _rc {
    gen double rug_all_y = 1 ///
        if inrange(dose, `xmin', `xmax')
}

capture confirm variable rug_ref_y
if _rc {
    gen double rug_ref_y = 1 ///
        if refcat & inrange(dose, `xmin', `xmax')
}

preserve

gen byte curveobs = 0
append using `curve'

twoway ///
	(line fit_hi_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
	(line fit_lo_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
    (line fit_rr_plot dose_curve if curveobs == 1, ///
        sort lcolor(black) lpattern(solid) lwidth(medium)) ///
    (scatter rug_all_y dose if curveobs == 0 & !missing(rug_all_y), ///
        msymbol(|) mcolor(gs10) msize(medium)) ///
    (scatter rug_ref_y dose if curveobs == 0 & !missing(rug_ref_y), ///
        msymbol(|) mcolor(black) msize(large)), ///
    xtitle("ABSI", size(large)) ///
    ytitle("RR", size(large)) ///
    xlabel(0.06(0.01)0.1, labsize(large) norescale) ///
    ylabel(0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0, ///
        format(%3.1f) labsize(large) angle(horizontal) norescale) ///
    xscale(range(0.06 0.1)) ///
    yscale(log range(0.6 4.0)) ///
    yline(1, lcolor(gs10) lpattern(solid)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white))

restore


/*healthy*/
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical") firstrow clear

assert RR > 0 & LCI > 0 & UCI > 0 if !missing(RR, LCI, UCI)
gen double logrr   = ln(RR)
gen double logrrL  = ln(LCI)
gen double logrrU  = ln(UCI)
gen double selogrr = (logrrU - logrrL)/(2 * invnormal(.975))

keep if bmi_unadjusted == 1
keep if full_model == 1
keep if healthy == 1
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

tab study
tab drtype

drmeta logrr doses*, se(selogrr) data(person_years case) id(id) type(drtype) 2stage reml hamling

test doses2
display "P for nonlinearity = " %6.4f r(p)

local xmin    0.06
local xmax   0.1
local step   0.00001
local refdose `p25'
local ymin    0.6
local ymax    4.0

tempname B V b1 b2 v11 v12 v22 r1 r2

matrix `B' = e(b)
matrix `V' = e(V)

local c1 = colnumb(`B', "doses1")
local c2 = colnumb(`B', "doses2")

scalar `b1'  = `B'[1, `c1']
scalar `b2'  = `B'[1, `c2']

scalar `v11' = `V'[`c1', `c1']
scalar `v12' = `V'[`c1', `c2']
scalar `v22' = `V'[`c2', `c2']

tempfile curve

preserve

clear

local ngrid = round((`xmax' - `xmin') / `step') + 1
local nall  = `ngrid' + 1

set obs `nall'

gen double dose_curve = ///
    `xmin' + `step' * (_n - 1) in 1/`ngrid'

replace dose_curve = `refdose' in `nall'

local k1 = el(knots, 1, 1)
local k2 = el(knots, 1, 2)
local k3 = el(knots, 1, 3)

mkspline sp = dose_curve, ///
    knots(`k1' `k2' `k3') cubic

scalar `r1' = sp1[`nall']
scalar `r2' = sp2[`nall']

gen double d1 = sp1 - scalar(`r1')
gen double d2 = sp2 - scalar(`r2')

gen double fit_logrr = ///
      scalar(`b1') * d1 ///
    + scalar(`b2') * d2

gen double fit_var = ///
      d1^2 * scalar(`v11') ///
    + d2^2 * scalar(`v22') ///
    + 2*d1*d2 * scalar(`v12')

replace fit_var = 0 ///
    if fit_var < 0 & fit_var > -1e-12

gen double fit_rr = exp(fit_logrr)
gen double fit_lo = exp(fit_logrr - invnormal(.975)*sqrt(fit_var))
gen double fit_hi = exp(fit_logrr + invnormal(.975)*sqrt(fit_var))

drop in `nall'

sort dose_curve

foreach y in fit_rr fit_lo fit_hi {

    gen double `y'_plot = `y'

    gen byte cross_upper_`y' = ///
        `y' > `ymax' & ///
        ( ///
            (_n > 1  & `y'[_n-1] <= `ymax') | ///
            (_n < _N & `y'[_n+1] <= `ymax') ///
        )

    replace `y'_plot = `ymax' ///
        if cross_upper_`y'

    replace `y'_plot = . ///
        if `y' > `ymax' & !cross_upper_`y'

    gen byte cross_lower_`y' = ///
        `y' < `ymin' & ///
        ( ///
            (_n > 1  & `y'[_n-1] >= `ymin') | ///
            (_n < _N & `y'[_n+1] >= `ymin') ///
        )

    replace `y'_plot = `ymin' ///
        if cross_lower_`y'

    replace `y'_plot = . ///
        if `y' < `ymin' & !cross_lower_`y'
}

gen byte curveobs = 1

keep dose_curve ///
     fit_rr_plot fit_lo_plot fit_hi_plot ///
     curveobs

save `curve', replace

restore


capture confirm variable refcat
if _rc {
    gen byte refcat = ///
        abs(logrr) < 1e-10 & abs(selogrr) < 1e-10
}

capture confirm variable rug_all_y
if _rc {
    gen double rug_all_y = 1 ///
        if inrange(dose, `xmin', `xmax')
}

capture confirm variable rug_ref_y
if _rc {
    gen double rug_ref_y = 1 ///
        if refcat & inrange(dose, `xmin', `xmax')
}

preserve

gen byte curveobs = 0
append using `curve'

twoway ///
	(line fit_hi_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
	(line fit_lo_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
    (line fit_rr_plot dose_curve if curveobs == 1, ///
        sort lcolor(black) lpattern(solid) lwidth(medium)) ///
    (scatter rug_all_y dose if curveobs == 0 & !missing(rug_all_y), ///
        msymbol(|) mcolor(gs10) msize(medium)) ///
    (scatter rug_ref_y dose if curveobs == 0 & !missing(rug_ref_y), ///
        msymbol(|) mcolor(black) msize(large)), ///
    xtitle("ABSI", size(large)) ///
    ytitle("RR", size(large)) ///
    xlabel(0.06(0.01)0.1, labsize(large) norescale) ///
    ylabel(0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0, ///
        format(%3.1f) labsize(large) angle(horizontal) norescale) ///
    xscale(range(0.06 0.1)) ///
    yscale(log range(0.6 4.0)) ///
    yline(1, lcolor(gs10) lpattern(solid)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white))

restore

/*Excluding study with intermediates*/
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical") firstrow clear

assert RR > 0 & LCI > 0 & UCI > 0 if !missing(RR, LCI, UCI)
gen double logrr   = ln(RR)
gen double logrrL  = ln(LCI)
gen double logrrU  = ln(UCI)
gen double selogrr = (logrrU - logrrL)/(2 * invnormal(.975))

keep if bmi_unadjusted == 1
keep if full_model == 1
drop if mediator == 1
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

tab study
tab drtype

drmeta logrr doses*, se(selogrr) data(person_years case) id(id) type(drtype) 2stage reml hamling

test doses2
display "P for nonlinearity = " %6.4f r(p)

local search_min  0.06
local search_max 0.1
local gridstep     0.001

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

local xmin    0.06
local xmax   0.1
local step   0.00001
local refdose `nadir'
local ymin    0.6
local ymax    4.0

tempname B V b1 b2 v11 v12 v22 r1 r2

matrix `B' = e(b)
matrix `V' = e(V)

local c1 = colnumb(`B', "doses1")
local c2 = colnumb(`B', "doses2")

scalar `b1'  = `B'[1, `c1']
scalar `b2'  = `B'[1, `c2']

scalar `v11' = `V'[`c1', `c1']
scalar `v12' = `V'[`c1', `c2']
scalar `v22' = `V'[`c2', `c2']

tempfile curve

preserve

clear

local ngrid = round((`xmax' - `xmin') / `step') + 1
local nall  = `ngrid' + 1

set obs `nall'

gen double dose_curve = ///
    `xmin' + `step' * (_n - 1) in 1/`ngrid'

replace dose_curve = `refdose' in `nall'

local k1 = el(knots, 1, 1)
local k2 = el(knots, 1, 2)
local k3 = el(knots, 1, 3)

mkspline sp = dose_curve, ///
    knots(`k1' `k2' `k3') cubic

scalar `r1' = sp1[`nall']
scalar `r2' = sp2[`nall']

gen double d1 = sp1 - scalar(`r1')
gen double d2 = sp2 - scalar(`r2')

gen double fit_logrr = ///
      scalar(`b1') * d1 ///
    + scalar(`b2') * d2

gen double fit_var = ///
      d1^2 * scalar(`v11') ///
    + d2^2 * scalar(`v22') ///
    + 2*d1*d2 * scalar(`v12')

replace fit_var = 0 ///
    if fit_var < 0 & fit_var > -1e-12

gen double fit_rr = exp(fit_logrr)
gen double fit_lo = exp(fit_logrr - invnormal(.975)*sqrt(fit_var))
gen double fit_hi = exp(fit_logrr + invnormal(.975)*sqrt(fit_var))

drop in `nall'

sort dose_curve

foreach y in fit_rr fit_lo fit_hi {

    gen double `y'_plot = `y'

    gen byte cross_upper_`y' = ///
        `y' > `ymax' & ///
        ( ///
            (_n > 1  & `y'[_n-1] <= `ymax') | ///
            (_n < _N & `y'[_n+1] <= `ymax') ///
        )

    replace `y'_plot = `ymax' ///
        if cross_upper_`y'

    replace `y'_plot = . ///
        if `y' > `ymax' & !cross_upper_`y'

    gen byte cross_lower_`y' = ///
        `y' < `ymin' & ///
        ( ///
            (_n > 1  & `y'[_n-1] >= `ymin') | ///
            (_n < _N & `y'[_n+1] >= `ymin') ///
        )

    replace `y'_plot = `ymin' ///
        if cross_lower_`y'

    replace `y'_plot = . ///
        if `y' < `ymin' & !cross_lower_`y'
}

gen byte curveobs = 1

keep dose_curve ///
     fit_rr_plot fit_lo_plot fit_hi_plot ///
     curveobs

save `curve', replace

restore


capture confirm variable refcat
if _rc {
    gen byte refcat = ///
        abs(logrr) < 1e-10 & abs(selogrr) < 1e-10
}

capture confirm variable rug_all_y
if _rc {
    gen double rug_all_y = 1 ///
        if inrange(dose, `xmin', `xmax')
}

capture confirm variable rug_ref_y
if _rc {
    gen double rug_ref_y = 1 ///
        if refcat & inrange(dose, `xmin', `xmax')
}

preserve

gen byte curveobs = 0
append using `curve'

twoway ///
	(line fit_hi_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
	(line fit_lo_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
    (line fit_rr_plot dose_curve if curveobs == 1, ///
        sort lcolor(black) lpattern(solid) lwidth(medium)) ///
    (scatter rug_all_y dose if curveobs == 0 & !missing(rug_all_y), ///
        msymbol(|) mcolor(gs10) msize(medium)) ///
    (scatter rug_ref_y dose if curveobs == 0 & !missing(rug_ref_y), ///
        msymbol(|) mcolor(black) msize(large)), ///
    xtitle("ABSI", size(large)) ///
    ytitle("RR", size(large)) ///
    xlabel(0.06(0.01)0.1, labsize(large) norescale) ///
    ylabel(0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0, ///
        format(%3.1f) labsize(large) angle(horizontal) norescale) ///
    xscale(range(0.06 0.1)) ///
    yscale(log range(0.6 4.0)) ///
    yline(1, lcolor(gs10) lpattern(solid)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white))

restore


/*Excluding study with high risk of bias*/
/*BMI unadjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical") firstrow clear

assert RR > 0 & LCI > 0 & UCI > 0 if !missing(RR, LCI, UCI)
gen double logrr   = ln(RR)
gen double logrrL  = ln(LCI)
gen double logrrU  = ln(UCI)
gen double selogrr = (logrrU - logrrL)/(2 * invnormal(.975))

keep if bmi_unadjusted == 1
keep if full_model == 1
drop if high_risk == 1
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

tab study
tab drtype

drmeta logrr doses*, se(selogrr) data(person_years case) id(id) type(drtype) 2stage reml hamling

test doses2
display "P for nonlinearity = " %6.4f r(p)

local search_min  0.06
local search_max 0.1
local gridstep     0.001

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

local xmin    0.06
local xmax   0.1
local step   0.00001
local refdose `nadir'
local ymin    0.6
local ymax    4.0
tempname B V b1 b2 v11 v12 v22 r1 r2

matrix `B' = e(b)
matrix `V' = e(V)

local c1 = colnumb(`B', "doses1")
local c2 = colnumb(`B', "doses2")

scalar `b1'  = `B'[1, `c1']
scalar `b2'  = `B'[1, `c2']

scalar `v11' = `V'[`c1', `c1']
scalar `v12' = `V'[`c1', `c2']
scalar `v22' = `V'[`c2', `c2']

tempfile curve

preserve

clear

local ngrid = round((`xmax' - `xmin') / `step') + 1
local nall  = `ngrid' + 1

set obs `nall'

gen double dose_curve = ///
    `xmin' + `step' * (_n - 1) in 1/`ngrid'

replace dose_curve = `refdose' in `nall'

local k1 = el(knots, 1, 1)
local k2 = el(knots, 1, 2)
local k3 = el(knots, 1, 3)

mkspline sp = dose_curve, ///
    knots(`k1' `k2' `k3') cubic

scalar `r1' = sp1[`nall']
scalar `r2' = sp2[`nall']

gen double d1 = sp1 - scalar(`r1')
gen double d2 = sp2 - scalar(`r2')

gen double fit_logrr = ///
      scalar(`b1') * d1 ///
    + scalar(`b2') * d2

gen double fit_var = ///
      d1^2 * scalar(`v11') ///
    + d2^2 * scalar(`v22') ///
    + 2*d1*d2 * scalar(`v12')

replace fit_var = 0 ///
    if fit_var < 0 & fit_var > -1e-12

gen double fit_rr = exp(fit_logrr)
gen double fit_lo = exp(fit_logrr - invnormal(.975)*sqrt(fit_var))
gen double fit_hi = exp(fit_logrr + invnormal(.975)*sqrt(fit_var))

drop in `nall'

sort dose_curve

foreach y in fit_rr fit_lo fit_hi {

    gen double `y'_plot = `y'

    gen byte cross_upper_`y' = ///
        `y' > `ymax' & ///
        ( ///
            (_n > 1  & `y'[_n-1] <= `ymax') | ///
            (_n < _N & `y'[_n+1] <= `ymax') ///
        )

    replace `y'_plot = `ymax' ///
        if cross_upper_`y'

    replace `y'_plot = . ///
        if `y' > `ymax' & !cross_upper_`y'

    gen byte cross_lower_`y' = ///
        `y' < `ymin' & ///
        ( ///
            (_n > 1  & `y'[_n-1] >= `ymin') | ///
            (_n < _N & `y'[_n+1] >= `ymin') ///
        )

    replace `y'_plot = `ymin' ///
        if cross_lower_`y'

    replace `y'_plot = . ///
        if `y' < `ymin' & !cross_lower_`y'
}

gen byte curveobs = 1

keep dose_curve ///
     fit_rr_plot fit_lo_plot fit_hi_plot ///
     curveobs

save `curve', replace

restore


capture confirm variable refcat
if _rc {
    gen byte refcat = ///
        abs(logrr) < 1e-10 & abs(selogrr) < 1e-10
}

capture confirm variable rug_all_y
if _rc {
    gen double rug_all_y = 1 ///
        if inrange(dose, `xmin', `xmax')
}

capture confirm variable rug_ref_y
if _rc {
    gen double rug_ref_y = 1 ///
        if refcat & inrange(dose, `xmin', `xmax')
}

preserve

gen byte curveobs = 0
append using `curve'

twoway ///
	(line fit_hi_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
	(line fit_lo_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
    (line fit_rr_plot dose_curve if curveobs == 1, ///
        sort lcolor(black) lpattern(solid) lwidth(medium)) ///
    (scatter rug_all_y dose if curveobs == 0 & !missing(rug_all_y), ///
        msymbol(|) mcolor(gs10) msize(medium)) ///
    (scatter rug_ref_y dose if curveobs == 0 & !missing(rug_ref_y), ///
        msymbol(|) mcolor(black) msize(large)), ///
    xtitle("ABSI", size(large)) ///
    ytitle("RR", size(large)) ///
    xlabel(0.06(0.01)0.1, labsize(large) norescale) ///
    ylabel(0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0, ///
        format(%3.1f) labsize(large) angle(horizontal) norescale) ///
    xscale(range(0.06 0.1)) ///
    yscale(log range(0.6 4.0)) ///
    yline(1, lcolor(gs10) lpattern(solid)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white))

restore

/*BMI adjusted*/
import excel "C:\Users\ABSI\ABSI_meta_final.xlsx", sheet("categorical") firstrow clear

assert RR > 0 & LCI > 0 & UCI > 0 if !missing(RR, LCI, UCI)
gen double logrr   = ln(RR)
gen double logrrL  = ln(LCI)
gen double logrrU  = ln(UCI)
gen double selogrr = (logrrU - logrrL)/(2 * invnormal(.975))

keep if bmi_adjusted == 1
keep if full_model == 1
drop if high_risk == 1
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

tab study
tab drtype

drmeta logrr doses*, se(selogrr) data(person_years case) id(id) type(drtype) 2stage reml hamling

test doses2
display "P for nonlinearity = " %6.4f r(p)

local search_min 0.06
local search_max 0.1
local gridstep 0.001

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

local xmin    0.06
local xmax   0.1
local step   0.00001
local refdose `nadir'
local ymin    0.6
local ymax    4.0
tempname B V b1 b2 v11 v12 v22 r1 r2

matrix `B' = e(b)
matrix `V' = e(V)

local c1 = colnumb(`B', "doses1")
local c2 = colnumb(`B', "doses2")

scalar `b1'  = `B'[1, `c1']
scalar `b2'  = `B'[1, `c2']

scalar `v11' = `V'[`c1', `c1']
scalar `v12' = `V'[`c1', `c2']
scalar `v22' = `V'[`c2', `c2']

tempfile curve

preserve

clear

local ngrid = round((`xmax' - `xmin') / `step') + 1
local nall  = `ngrid' + 1

set obs `nall'

gen double dose_curve = ///
    `xmin' + `step' * (_n - 1) in 1/`ngrid'

replace dose_curve = `refdose' in `nall'

local k1 = el(knots, 1, 1)
local k2 = el(knots, 1, 2)
local k3 = el(knots, 1, 3)

mkspline sp = dose_curve, ///
    knots(`k1' `k2' `k3') cubic

scalar `r1' = sp1[`nall']
scalar `r2' = sp2[`nall']

gen double d1 = sp1 - scalar(`r1')
gen double d2 = sp2 - scalar(`r2')

gen double fit_logrr = ///
      scalar(`b1') * d1 ///
    + scalar(`b2') * d2

gen double fit_var = ///
      d1^2 * scalar(`v11') ///
    + d2^2 * scalar(`v22') ///
    + 2*d1*d2 * scalar(`v12')

replace fit_var = 0 ///
    if fit_var < 0 & fit_var > -1e-12

gen double fit_rr = exp(fit_logrr)
gen double fit_lo = exp(fit_logrr - invnormal(.975)*sqrt(fit_var))
gen double fit_hi = exp(fit_logrr + invnormal(.975)*sqrt(fit_var))

drop in `nall'

sort dose_curve

foreach y in fit_rr fit_lo fit_hi {

    gen double `y'_plot = `y'

    gen byte cross_upper_`y' = ///
        `y' > `ymax' & ///
        ( ///
            (_n > 1  & `y'[_n-1] <= `ymax') | ///
            (_n < _N & `y'[_n+1] <= `ymax') ///
        )

    replace `y'_plot = `ymax' ///
        if cross_upper_`y'

    replace `y'_plot = . ///
        if `y' > `ymax' & !cross_upper_`y'

    gen byte cross_lower_`y' = ///
        `y' < `ymin' & ///
        ( ///
            (_n > 1  & `y'[_n-1] >= `ymin') | ///
            (_n < _N & `y'[_n+1] >= `ymin') ///
        )

    replace `y'_plot = `ymin' ///
        if cross_lower_`y'

    replace `y'_plot = . ///
        if `y' < `ymin' & !cross_lower_`y'
}

gen byte curveobs = 1

keep dose_curve ///
     fit_rr_plot fit_lo_plot fit_hi_plot ///
     curveobs

save `curve', replace

restore


capture confirm variable refcat
if _rc {
    gen byte refcat = ///
        abs(logrr) < 1e-10 & abs(selogrr) < 1e-10
}

capture confirm variable rug_all_y
if _rc {
    gen double rug_all_y = 1 ///
        if inrange(dose, `xmin', `xmax')
}

capture confirm variable rug_ref_y
if _rc {
    gen double rug_ref_y = 1 ///
        if refcat & inrange(dose, `xmin', `xmax')
}

preserve

gen byte curveobs = 0
append using `curve'

twoway ///
	(line fit_hi_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
	(line fit_lo_plot dose_curve if curveobs == 1, ///
    sort lcolor(black) lpattern("-#") lwidth(medthick)) ///
    (line fit_rr_plot dose_curve if curveobs == 1, ///
        sort lcolor(black) lpattern(solid) lwidth(medium)) ///
    (scatter rug_all_y dose if curveobs == 0 & !missing(rug_all_y), ///
        msymbol(|) mcolor(gs10) msize(medium)) ///
    (scatter rug_ref_y dose if curveobs == 0 & !missing(rug_ref_y), ///
        msymbol(|) mcolor(black) msize(large)), ///
    xtitle("ABSI", size(large)) ///
    ytitle("RR", size(large)) ///
    xlabel(0.06(0.01)0.1, labsize(large) norescale) ///
    ylabel(0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0, ///
        format(%3.1f) labsize(large) angle(horizontal) norescale) ///
    xscale(range(0.06 0.1)) ///
    yscale(log range(0.6 4.0)) ///
    yline(1, lcolor(gs10) lpattern(solid)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white))

restore