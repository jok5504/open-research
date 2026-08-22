/*HC subgroup data integration*/
import excel "C:\Users\HC\HC_meta_final.xlsx", sheet("categorical") firstrow clear

keep if inlist(id, , )

gen double logrr = ln(RR)
gen double loglci = log(LCI)
gen double loguci = log(UCI)
gen double selogrr = (ln(UCI) - ln(LCI)) / (2*invnormal(.975))

drop if RR == 1
meta set logrr selogrr

meta summarize if category == 1, fixed eform
meta summarize if category == 3, fixed eform
meta summarize if category == 4, fixed eform
meta summarize if category == 5, fixed eform

///Continous///
import excel "C:\Users\HC\HC_meta_final.xlsx", sheet("continuous") firstrow clear

keep if inlist(id, , )

gen double logrr = ln(RR)
gen double loglci = log(LCI)
gen double loguci = log(UCI)
gen double selogrr = (ln(UCI) - ln(LCI)) / (2*invnormal(.975))

meta set logrr selogrr
meta summarize, fixed eform

import excel "C:\Users\HC\HC_meta_final.xlsx", sheet("continuous") firstrow clear

gen double logrr = ln(RR)
gen double loglci = log(LCI)
gen double loguci = log(UCI)
gen double selogrr = (ln(UCI) - ln(LCI)) / (2*invnormal(.975))

list logrr loglci loguci selogrr

///GLST///
import excel "C:\Users\HC\HC_meta_final.xlsx", sheet("categorical") firstrow clear

keep if id == 

gen double logrr = ln(RR)
gen double selogrr = (ln(UCI) - ln(LCI))/(2 * invnormal(.975))

gen byte ref = abs(RR - 1) < 1e-10 & abs(LCI - 1) < 1e-10 & abs(UCI - 1) < 1e-10

count if ref
assert r(N) == 1

gsort -ref dose

gen double dose10c = (dose - dose[1])/10

assert ref[1] == 1
assert abs(dose10c[1]) < 1e-10
assert abs(logrr[1]) < 1e-10
assert abs(selogrr[1]) < 1e-10

glst logrr dose10c, se(selogrr) cov(personyears case) ir


///linear///
/*BMI unadjusted*/
import excel "C:\Users\HC\HC_meta_final.xlsx", sheet("linear_main") firstrow clear

keep if bmi_unadjusted == 1
keep if full_model == 1
keep if minimum == 1
destring(se), replace
meta set coef se, studylabel(study_name)

meta summarize, random(reml) se(khartung) eform

/*BMI adjusted*/
import excel "C:\Users\HC\HC_meta_final.xlsx", sheet("linear_main") firstrow clear

keep if bmi_adjusted == 1
keep if full_model == 1
keep if minimum == 1
destring(se), replace
meta set coef se, studylabel(study_name)
meta summarize, random(reml) se(khartung)