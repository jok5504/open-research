///RFM subgroup data intergration///
///Categorical///
import excel "C:\Users\RFM\RFM_meta_final.xlsx", sheet("categorical") firstrow clear

keep if inlist(id, , )

gen double logrr = ln(RR)
gen double loglci = log(LCI)
gen double loguci = log(UCI)
gen double selogrr = (ln(UCI) - ln(LCI)) / (2*invnormal(.975))

drop if RR == 1

meta set logrr selogrr
meta summarize if category == 2, fixed eform
meta summarize if category == 3, fixed eform
meta summarize if category == 4, fixed eform


///Continous///
import excel "C:\Users\RFM\RFM_meta_final.xlsx", sheet("continuous") firstrow clear

keep if inlist(id, 2, 3)

gen double logrr = ln(RR)
gen double loglci = log(LCI)
gen double loguci = log(UCI)
gen double selogrr = (ln(UCI) - ln(LCI)) / (2*invnormal(.975))

meta set logrr selogrr
meta summarize, fixed eform


import excel "C:\Users\RFM\RFM_meta_final.xlsx", sheet("continuous") firstrow clear

destring RR LCI UCI, replace

gen double logrr = ln(RR)
gen double loglci = log(LCI)
gen double loguci = log(UCI)
gen double selogrr = (ln(UCI) - ln(LCI)) / (2*invnormal(.975))

list logrr selogrr loglci loguci


/*GLST*/
import excel "C:\Users\RFM\RFM_meta_final.xlsx", sheet("categorical") firstrow clear

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

glst logrr dose10c, se(selogrr) cov(person_years case) ir


/*linear*/
/*BMI unadjusted*/
import excel "C:\Users\RFM\RFM_meta_final.xlsx", sheet("linear_main") firstrow clear

keep if bmi_unadjusted == 1
keep if full_model == 1
keep if minimum == 1
meta set coef se, studylabel(studyname)

meta summarize, random(reml) se(khartung)

scalar pooled_rr  = exp(r(theta))
scalar pooled_lci = exp(r(ci_lb))
scalar pooled_uci = exp(r(ci_ub))

display as text "Pooled RR (95% CI): " as result %5.2f `pooled_rr'" (" %5.2f `pooled_lci' "–" %5.2f `pooled_uci' ")"
	
scalar list pooled_rr pooled_lci pooled_uci
	
evalue rr `=scalar(pooled_rr)', lcl(`=scalar(pooled_lci)') ucl(`=scalar(pooled_uci)')

meta forestplot _id _plot _esci _weight, random(reml) se(khartung) eform columnopts(_id, title("Author, year")) columnopts(_esci, supertitle("RR") title("(95% CI)")) xlabel(0.5 1 1.5 2) xscale(range(0.5 2)) nullrefline