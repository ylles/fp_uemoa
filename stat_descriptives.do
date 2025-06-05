clear all
set more off
set dp period

global path_base "C:\xxxxx\Senegal\Enquete menages\EHCVM"
global path_2018 "$path_base\2018-2019"
global path_2021 "$path_base\2021-2022"
global path_output "$path_base\Descriptive_Statistics"

capture mkdir "$path_output"

global file_2018 "AUEMOA2018_individus.dta"
global file_2021 "AUEMOA2021_individus.dta"

log using "$path_output\Descriptive_statistics_final.log", replace

/*==============================================================================
    DÉFINITION DES NOMS DE PAYS
==============================================================================*/

capture program drop get_country_name
program define get_country_name, rclass
    args pays_num
    
    if `pays_num' == 1 local name = "Benin"
    else if `pays_num' == 2 local name = "Burkina Faso"
    else if `pays_num' == 3 local name = "Côte d'Ivoire"
    else if `pays_num' == 4 local name = "Guinea-Bissau"
    else if `pays_num' == 5 local name = "Mali"
    else if `pays_num' == 6 local name = "Niger"
    else if `pays_num' == 7 local name = "Senegal"
    else if `pays_num' == 8 local name = "Togo"
    else local name = "Unknown"
    
    return local name = "`name'"
end

/*==============================================================================
    PART 1: PRÉPARATION DES DONNÉES
==============================================================================*/

di _n "{hline 80}"
di "PREPARING DATA FOR TABLE 1: SAMPLE CHARACTERISTICS BY COUNTRY"
di "{hline 80}" _n

use "$path_2018\\$file_2018", clear
capture drop year

drop if missing(sexe) | missing(age) | missing(milieu) | missing(hhsize) | missing(poor)

tempfile data2018_clean
save `data2018_clean'

use "$path_2021\\$file_2021", clear
capture drop year

drop if missing(sexe) | missing(age) | missing(milieu) | missing(hhsize) | missing(poor)

tempfile data2021_clean
save `data2021_clean'

/*==============================================================================
    PART 2: STATISTIQUES PAR PAYS AVEC SD
==============================================================================*/

di _n "{hline 80}"
di "GENERATING STATISTICS BY COUNTRY"
di "{hline 80}" _n

matrix stats_2018 = J(8, 20, .)
matrix colnames stats_2018 = n_total n_male n_female n_urban n_rural n_poor pct_male sd_male pct_female sd_female pct_urban sd_urban pct_rural sd_rural pct_poor sd_poor age_median age_p25 age_p75 hhsize_mean
matrix rownames stats_2018 = Benin BurkinaFaso CoteIvoire GuineaBissau Mali Niger Senegal Togo

matrix stats_2021 = J(8, 20, .)
matrix colnames stats_2021 = n_total n_male n_female n_urban n_rural n_poor pct_male sd_male pct_female sd_female pct_urban sd_urban pct_rural sd_rural pct_poor sd_poor age_median age_p25 age_p75 hhsize_mean
matrix rownames stats_2021 = Benin BurkinaFaso CoteIvoire GuineaBissau Mali Niger Senegal Togo

matrix hhsize_2018 = J(8, 2, .)
matrix colnames hhsize_2018 = mean sd
matrix rownames hhsize_2018 = Benin BurkinaFaso CoteIvoire GuineaBissau Mali Niger Senegal Togo

matrix hhsize_2021 = J(8, 2, .)
matrix colnames hhsize_2021 = mean sd
matrix rownames hhsize_2021 = Benin BurkinaFaso CoteIvoire GuineaBissau Mali Niger Senegal Togo

use `data2018_clean', clear

forvalues p = 1/8 {
    quietly count if pays == `p'
    local n = r(N)
    matrix stats_2018[`p',1] = `n'
    
    if `n' > 0 {
        gen male_p = (sexe == 1) if pays == `p'
        gen female_p = (sexe == 2) if pays == `p'
        gen urban_p = (milieu == 1) if pays == `p'
        gen rural_p = (milieu == 2) if pays == `p'
        
        quietly summarize male_p
        matrix stats_2018[`p',2] = r(N)*r(mean)
        matrix stats_2018[`p',7] = r(mean)*100
        matrix stats_2018[`p',8] = r(sd)*100
        
        quietly summarize female_p
        matrix stats_2018[`p',3] = r(N)*r(mean)
        matrix stats_2018[`p',9] = r(mean)*100
        matrix stats_2018[`p',10] = r(sd)*100
        
        quietly summarize urban_p
        matrix stats_2018[`p',4] = r(N)*r(mean)
        matrix stats_2018[`p',11] = r(mean)*100
        matrix stats_2018[`p',12] = r(sd)*100
        
        quietly summarize rural_p
        matrix stats_2018[`p',5] = r(N)*r(mean)
        matrix stats_2018[`p',13] = r(mean)*100
        matrix stats_2018[`p',14] = r(sd)*100
        
        quietly summarize poor if pays == `p'
        matrix stats_2018[`p',6] = r(N)*r(mean)
        matrix stats_2018[`p',15] = r(mean)*100
        matrix stats_2018[`p',16] = r(sd)*100
        
        quietly summarize age if pays == `p', detail
        matrix stats_2018[`p',17] = r(p50)
        matrix stats_2018[`p',18] = r(p25)
        matrix stats_2018[`p',19] = r(p75)
        
        quietly summarize hhsize if pays == `p'
        matrix hhsize_2018[`p',1] = r(mean)
        matrix hhsize_2018[`p',2] = r(sd)
        
        drop male_p female_p urban_p rural_p
    }
}

use `data2021_clean', clear

forvalues p = 1/8 {
    quietly count if pays == `p'
    local n = r(N)
    matrix stats_2021[`p',1] = `n'
    
    if `n' > 0 {
        gen male_p = (sexe == 1) if pays == `p'
        gen female_p = (sexe == 2) if pays == `p'
        gen urban_p = (milieu == 1) if pays == `p'
        gen rural_p = (milieu == 2) if pays == `p'
        
        quietly summarize male_p
        matrix stats_2021[`p',2] = r(N)*r(mean)
        matrix stats_2021[`p',7] = r(mean)*100
        matrix stats_2021[`p',8] = r(sd)*100
        
        quietly summarize female_p
        matrix stats_2021[`p',3] = r(N)*r(mean)
        matrix stats_2021[`p',9] = r(mean)*100
        matrix stats_2021[`p',10] = r(sd)*100
        
        quietly summarize urban_p
        matrix stats_2021[`p',4] = r(N)*r(mean)
        matrix stats_2021[`p',11] = r(mean)*100
        matrix stats_2021[`p',12] = r(sd)*100
        
        quietly summarize rural_p
        matrix stats_2021[`p',5] = r(N)*r(mean)
        matrix stats_2021[`p',13] = r(mean)*100
        matrix stats_2021[`p',14] = r(sd)*100
        
        quietly summarize poor if pays == `p'
        matrix stats_2021[`p',6] = r(N)*r(mean)
        matrix stats_2021[`p',15] = r(mean)*100
        matrix stats_2021[`p',16] = r(sd)*100
        
        quietly summarize age if pays == `p', detail
        matrix stats_2021[`p',17] = r(p50)
        matrix stats_2021[`p',18] = r(p25)
        matrix stats_2021[`p',19] = r(p75)
        
        quietly summarize hhsize if pays == `p'
        matrix hhsize_2021[`p',1] = r(mean)
        matrix hhsize_2021[`p',2] = r(sd)
        
        drop male_p female_p urban_p rural_p
    }
}

/*==============================================================================
    PART 3: EXPORT TABLE 1
==============================================================================*/

putexcel set "$path_output\Table1_Descriptive_Statistics_By_Country.xlsx", replace

putexcel A1 = "Table 1: Sample Characteristics by Country"
putexcel A2 = "(Unweighted data, missing values excluded)"

putexcel A4 = "Country"
putexcel B4 = "Period"
putexcel C4 = "N"
putexcel D4 = "Age median (IQR)"
putexcel E4 = "Male % (SD)"
putexcel F4 = "Female % (SD)"
putexcel G4 = "Urban % (SD)"
putexcel H4 = "Rural % (SD)"
putexcel I4 = "HH size mean (SD)"
putexcel J4 = "Poverty % (SD)"
putexcel A4:J4, bold border(bottom, thick)

local row = 5
forvalues p = 1/8 {
    get_country_name `p'
    local country_name = r(name)
    
    putexcel A`row' = "`country_name'"
    putexcel B`row' = "2018/19"
    
    putexcel C`row' = stats_2018[`p',1], nformat("#,##0")
    
    local age_med = stats_2018[`p',17]
    local age_p25 = stats_2018[`p',18]
    local age_p75 = stats_2018[`p',19]
    local age_med_str = string(`age_med', "%2.0f")
    local age_p25_str = string(`age_p25', "%2.0f")
    local age_p75_str = string(`age_p75', "%2.0f")
    local age_str = "`age_med_str' (`age_p25_str'–`age_p75_str')"
    putexcel D`row' = "`age_str'"
    
    local pct_male = stats_2018[`p',7]
    local sd_male = stats_2018[`p',8]
    local male_str = string(`pct_male', "%4.1f") + " (" + string(`sd_male', "%4.1f") + ")"
    putexcel E`row' = "`male_str'"
    
    local pct_female = stats_2018[`p',9]
    local sd_female = stats_2018[`p',10]
    local female_str = string(`pct_female', "%4.1f") + " (" + string(`sd_female', "%4.1f") + ")"
    putexcel F`row' = "`female_str'"
    
    local pct_urban = stats_2018[`p',11]
    local sd_urban = stats_2018[`p',12]
    local urban_str = string(`pct_urban', "%4.1f") + " (" + string(`sd_urban', "%4.1f") + ")"
    putexcel G`row' = "`urban_str'"
    
    local pct_rural = stats_2018[`p',13]
    local sd_rural = stats_2018[`p',14]
    local rural_str = string(`pct_rural', "%4.1f") + " (" + string(`sd_rural', "%4.1f") + ")"
    putexcel H`row' = "`rural_str'"
    
    local hhsize_mean = hhsize_2018[`p',1]
    local hhsize_sd = hhsize_2018[`p',2]
    local hhsize_mean_str = string(`hhsize_mean', "%4.1f")
    local hhsize_sd_str = string(`hhsize_sd', "%4.1f")
    local hhsize_str = "`hhsize_mean_str' (`hhsize_sd_str')"
    putexcel I`row' = "`hhsize_str'"
    
    local pct_poor = stats_2018[`p',15]
    local sd_poor = stats_2018[`p',16]
    local poor_str = string(`pct_poor', "%4.1f") + " (" + string(`sd_poor', "%4.1f") + ")"
    putexcel J`row' = "`poor_str'"
    
    local row = `row' + 1
    
    putexcel A`row' = ""
    putexcel B`row' = "2021/22"
    
    putexcel C`row' = stats_2021[`p',1], nformat("#,##0")
    
    local age_med = stats_2021[`p',17]
    local age_p25 = stats_2021[`p',18]
    local age_p75 = stats_2021[`p',19]
    local age_med_str = string(`age_med', "%2.0f")
    local age_p25_str = string(`age_p25', "%2.0f")
    local age_p75_str = string(`age_p75', "%2.0f")
    local age_str = "`age_med_str' (`age_p25_str'–`age_p75_str')"
    putexcel D`row' = "`age_str'"
    
    local pct_male = stats_2021[`p',7]
    local sd_male = stats_2021[`p',8]
    local male_str = string(`pct_male', "%4.1f") + " (" + string(`sd_male', "%4.1f") + ")"
    putexcel E`row' = "`male_str'"
    
    local pct_female = stats_2021[`p',9]
    local sd_female = stats_2021[`p',10]
    local female_str = string(`pct_female', "%4.1f") + " (" + string(`sd_female', "%4.1f") + ")"
    putexcel F`row' = "`female_str'"
    
    local pct_urban = stats_2021[`p',11]
    local sd_urban = stats_2021[`p',12]
    local urban_str = string(`pct_urban', "%4.1f") + " (" + string(`sd_urban', "%4.1f") + ")"
    putexcel G`row' = "`urban_str'"
    
    local pct_rural = stats_2021[`p',13]
    local sd_rural = stats_2021[`p',14]
    local rural_str = string(`pct_rural', "%4.1f") + " (" + string(`sd_rural', "%4.1f") + ")"
    putexcel H`row' = "`rural_str'"
    
    local hhsize_mean = hhsize_2021[`p',1]
    local hhsize_sd = hhsize_2021[`p',2]
    local hhsize_mean_str = string(`hhsize_mean', "%4.1f")
    local hhsize_sd_str = string(`hhsize_sd', "%4.1f")
    local hhsize_str = "`hhsize_mean_str' (`hhsize_sd_str')"
    putexcel I`row' = "`hhsize_str'"
    
    local pct_poor = stats_2021[`p',15]
    local sd_poor = stats_2021[`p',16]
    local poor_str = string(`pct_poor', "%4.1f") + " (" + string(`sd_poor', "%4.1f") + ")"
    putexcel J`row' = "`poor_str'"
    
    local row = `row' + 1
    putexcel A`row':J`row', border(bottom, thin)
    local row = `row' + 1
}

local row = `row' + 1
putexcel A`row' = "Notes:"
local row = `row' + 1
putexcel A`row' = "IQR = interquartile range; SD = standard deviation; HH = household"
local row = `row' + 1
putexcel A`row' = "All percentages calculated based on country-specific sample sizes"
local row = `row' + 1
putexcel A`row' = "Standard deviations calculated using the formula: SD = sqrt(p*(1-p)) for proportions"

/*==============================================================================
    PART 4: TABLE 2 - WHO HEALTH SYSTEM INDICATORS
==============================================================================*/

di _n "{hline 80}"
di "GENERATING TABLE 2: WHO HEALTH SYSTEM INDICATORS FROM GHED DATA"
di "{hline 80}" _n

import excel "$path_base\GHED_data.xlsx", sheet("Sheet1") firstrow clear

keep if inlist(country, "Benin", "Burkina Faso", "Côte d'Ivoire", "Guinea-Bissau", "Mali", "Niger", "Senegal", "Togo")
keep if inlist(year, 2019, 2022)

gen pays = .
replace pays = 1 if country == "Benin"
replace pays = 2 if country == "Burkina Faso"
replace pays = 3 if country == "Côte d'Ivoire"
replace pays = 4 if country == "Guinea-Bissau"
replace pays = 5 if country == "Mali"
replace pays = 6 if country == "Niger"
replace pays = 7 if country == "Senegal"
replace pays = 8 if country == "Togo"

sort pays year

tempfile ghed_data
save `ghed_data'

matrix who_2019 = J(8, 8, .)
matrix colnames who_2019 = che_pc che_gdp gghed_che oops_che ext_che gghed_gge vhi_che shi_che
matrix rownames who_2019 = Benin BurkinaFaso CoteIvoire GuineaBissau Mali Niger Senegal Togo

matrix who_2022 = J(8, 8, .)
matrix colnames who_2022 = che_pc che_gdp gghed_che oops_che ext_che gghed_gge vhi_che shi_che
matrix rownames who_2022 = Benin BurkinaFaso CoteIvoire GuineaBissau Mali Niger Senegal Togo

forvalues p = 1/8 {
    quietly summarize che_pc if pays == `p' & year == 2019
    if r(N) > 0 matrix who_2019[`p',1] = r(mean)
    
    quietly summarize che_gdp if pays == `p' & year == 2019
    if r(N) > 0 matrix who_2019[`p',2] = r(mean)
    
    quietly summarize gghed_che if pays == `p' & year == 2019
    if r(N) > 0 matrix who_2019[`p',3] = r(mean)
    
    quietly summarize oops_che if pays == `p' & year == 2019
    if r(N) > 0 matrix who_2019[`p',4] = r(mean)
    
    quietly summarize ext_che if pays == `p' & year == 2019
    if r(N) > 0 matrix who_2019[`p',5] = r(mean)
    
    quietly summarize gghed_gge if pays == `p' & year == 2019
    if r(N) > 0 matrix who_2019[`p',6] = r(mean)
    
    quietly summarize vhi_che if pays == `p' & year == 2019
    if r(N) > 0 matrix who_2019[`p',7] = r(mean)
    
    quietly summarize shi_che if pays == `p' & year == 2019
    if r(N) > 0 matrix who_2019[`p',8] = r(mean)
    
    quietly summarize che_pc if pays == `p' & year == 2022
    if r(N) > 0 matrix who_2022[`p',1] = r(mean)
    
    quietly summarize che_gdp if pays == `p' & year == 2022
    if r(N) > 0 matrix who_2022[`p',2] = r(mean)
    
    quietly summarize gghed_che if pays == `p' & year == 2022
    if r(N) > 0 matrix who_2022[`p',3] = r(mean)
    
    quietly summarize oops_che if pays == `p' & year == 2022
    if r(N) > 0 matrix who_2022[`p',4] = r(mean)
    
    quietly summarize ext_che if pays == `p' & year == 2022
    if r(N) > 0 matrix who_2022[`p',5] = r(mean)
    
    quietly summarize gghed_gge if pays == `p' & year == 2022
    if r(N) > 0 matrix who_2022[`p',6] = r(mean)
    
    quietly summarize vhi_che if pays == `p' & year == 2022
    if r(N) > 0 matrix who_2022[`p',7] = r(mean)
    
    quietly summarize shi_che if pays == `p' & year == 2022
    if r(N) > 0 matrix who_2022[`p',8] = r(mean)
}

putexcel set "$path_output\Table2_WHO_Health_System_Indicators.xlsx", replace

putexcel A1 = "Table 2: Health system indicators for UEMOA countries"
putexcel A2 = "Source: WHO Global Health Expenditure Database"
putexcel A3 = "Note: 2022 data (latest available) used instead of 2021"

putexcel A5 = "Country"
putexcel B5 = "CHE per capita (USD)" C5 = ""
putexcel D5 = "CHE as % GDP" E5 = ""
putexcel F5 = "GGHE-D as % CHE" G5 = ""
putexcel H5 = "OOPS as % CHE" I5 = ""
putexcel J5 = "EXT as % CHE" K5 = ""
putexcel L5 = "GGHE-D as % GGE" M5 = ""
putexcel N5 = "VHI as % CHE" O5 = ""
putexcel P5 = "SHI as % CHE" Q5 = ""

putexcel B6 = "2019" C6 = "2022"
putexcel D6 = "2019" E6 = "2022"
putexcel F6 = "2019" G6 = "2022"
putexcel H6 = "2019" I6 = "2022"
putexcel J6 = "2019" K6 = "2022"
putexcel L6 = "2019" M6 = "2022"
putexcel N6 = "2019" O6 = "2022"
putexcel P6 = "2019" Q6 = "2022"

putexcel A5:Q6, bold border(bottom, medium)

local row = 7
local country_names `""Benin" "Burkina Faso" "Côte d'Ivoire" "Guinea-Bissau" "Mali" "Niger" "Senegal" "Togo""'

forvalues p = 1/8 {
    local country_name : word `p' of `country_names'
    putexcel A`row' = "`country_name'"
    
    putexcel B`row' = who_2019[`p',1], nformat("0.0")
    putexcel C`row' = who_2022[`p',1], nformat("0.0")
    
    putexcel D`row' = who_2019[`p',2], nformat("0.00")
    putexcel E`row' = who_2022[`p',2], nformat("0.00")
    
    putexcel F`row' = who_2019[`p',3], nformat("0.0")
    putexcel G`row' = who_2022[`p',3], nformat("0.0")
    
    putexcel H`row' = who_2019[`p',4], nformat("0.0")
    putexcel I`row' = who_2022[`p',4], nformat("0.0")
    
    putexcel J`row' = who_2019[`p',5], nformat("0.0")
    putexcel K`row' = who_2022[`p',5], nformat("0.0")
    
    putexcel L`row' = who_2019[`p',6], nformat("0.00")
    putexcel M`row' = who_2022[`p',6], nformat("0.00")
    
    putexcel N`row' = who_2019[`p',7], nformat("0.0")
    putexcel O`row' = who_2022[`p',7], nformat("0.0")
    
    putexcel P`row' = who_2019[`p',8], nformat("0.0")
    putexcel Q`row' = who_2022[`p',8], nformat("0.0")
    
    local row = `row' + 1
}

local row = `row' + 2
putexcel A`row' = "ABBREVIATIONS:"
local row = `row' + 1
putexcel A`row' = "CHE = Current health expenditure"
local row = `row' + 1
putexcel A`row' = "GGHE-D = Domestic general government health expenditure"
local row = `row' + 1
putexcel A`row' = "OOPS = Out-of-pocket spending"
local row = `row' + 1
putexcel A`row' = "EXT = External health expenditure"
local row = `row' + 1
putexcel A`row' = "GGE = General government expenditure"
local row = `row' + 1
putexcel A`row' = "VHI = Voluntary health insurance"
local row = `row' + 1
putexcel A`row' = "SHI = Social health insurance"

putexcel close

log close
