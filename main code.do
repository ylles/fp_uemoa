clear all
set more off
capture log close
log using "Protection_financiere_UEMOA_2018_2021.log", replace

/*==============================================================================
                    SECTION 1: PARAMÈTRES GLOBAUX
==============================================================================*/

global pays_2018 "BEN BFA CIV GNB MLI NER SEN TGO"
global pays_2021 "ben bfa civ gnb mli ner sen tgo"
global annees "2018 2021"
global path_base_2018 "C:\Users\xxxxxx\Enquete menages\EHCVM\2018-2019"
global path_base_2021 "C:\Users\xxxxxx\Enquete menages\EHCVM\2021-2022"

/*==============================================================================
        SECTION 2: PROGRAMMES DE PRÉPARATION DES DONNÉES
==============================================================================*/

program define prepare_individual_data
    args pays_code annee
    
    if "`annee'" == "2018" {
        local path_base "$path_base_2018"
        local id_var "s01q00a"
    }
    else {
        local path_base "$path_base_2021"
        local id_var "membres__id"
    }
    
    local pays_lower = lower("`pays_code'")
    
    cd "`path_base'\_`pays_code'"
    
    use "ehcvm_individu_`pays_code'`annee'.dta", clear
    merge m:1 hhid using "ehcvm_welfare_`pays_code'`annee'"
    drop _merge
    
    tostring grappe menage numind, replace force
    egen hhidd = concat(grappe menage numind), punct("_")
    lab var hhidd "Code individu unique"
    
    save "agregats_indiv_revise`pays_code'`annee'", replace
    
    use s03_me_`pays_code'`annee', clear
    tostring grappe menage `id_var', replace force
    egen hhidd = concat(grappe menage `id_var'), punct("_")
    
    merge 1:1 hhidd using "agregats_indiv_revise`pays_code'`annee'"
    drop _merge
    
    save "base_sante_revise`pays_code'`annee'", replace
end

program define recode_health_vars
    args annee
    
    if "`annee'" == "2018" {
        gen use = 0
        replace use = 1 if s03q05==1 | s03q12==1 | s03q19==1 | s03q25==1 | s03q28==1
    }
    else {
        gen use = 0
        replace use = 1 if (s03q05==1 | s03q12==1 | s03q19==1 | s03q25==1 | s03q28==1 | s03q31a==1) ///
                        | (!missing(s03q48) & s03q48 > 0) ///
                        | (!missing(s03q50) & s03q50 > 0)
    }
    
    if "`annee'" == "2018" {
        local vars_montant "s03q13 s03q14 s03q15 s03q16 s03q17 s03q18 s03q24 s03q26 s03q27 s03q29 s03q30 s03q31"
    }
    else {
        local vars_montant "s03q50 s03q13 s03q14 s03q15 s03q16 s03q17 s03q18a s03q18b s03q18c"
        local vars_montant "`vars_montant' s03q24 s03q26 s03q27 s03q29 s03q30 s03q31 s03q31b s03q48 s03q51"
    }
    
    foreach var of local vars_montant {
        capture recode `var' (. 99 999 9999 99999 999999 = 0)
        if "`annee'" == "2021" {
            capture recode `var' (.n = 0)
        }
    }
    
    if "`annee'" == "2018" {
        local vars_binaires "s03q01 s03q05 s03q12 s03q19 s03q32 s03q36"
    }
    else {
        local vars_binaires "s03q01 s03q05 s03q12 s03q19 s03q32 s03q36"
    }
    
    foreach var of local vars_binaires {
        capture recode `var' (2 = 0)
        capture lab def `var' 0 "Non" 1 "Oui", replace
        capture lab val `var' `var'
    }
    
    rename s03q01 malade30
    rename s03q03 malade_ar
    rename s03q05 use30
    rename s03q07 use30_prest
    rename s03q08 use30_praticien
    rename s03q12 use90
    rename s03q13 oop_consult_gen
    rename s03q14 oop_consult_spe
    rename s03q15 oop_consult_dent
    rename s03q16 oop_consult_tradi
    rename s03q17 oop_exam_soin
    
    if "`annee'" == "2018" {
        rename s03q18 oop_drug
    }
    else {
        rename s03q18a oop_drug_trad
        rename s03q18b oop_drug_pub
        rename s03q18c oop_drug_priv
    }
    
    rename s03q19 use365
    rename s03q20 use365_freq
    rename s03q23 use365_prest
    rename s03q24 oop_inpatient
    rename s03q26 oop_glasses
    rename s03q27 oop_materiel
    rename s03q29 oop_vaccination
    rename s03q30 oop_circon
    rename s03q31 oop_bilan
    
    if "`annee'" == "2021" {
        rename s03q31b oop_covid
        rename s03q48 oop_birth
        rename s03q51 oop_cpn
    }
    
    lab var malade30 "Besoin de santé dans les 30 jours"
    lab var oop_bilan "OOP bilan de santé"
    lab var oop_circon "OOP circoncision"
    lab var oop_consult_dent "OOP consultation odonto"
    lab var oop_consult_gen "OOP consultation générale"
    lab var oop_consult_spe "OOP consultation spécialisée"
    lab var oop_consult_tradi "OOP tradiparaticien"
    
    if "`annee'" == "2018" {
        lab var oop_drug "OOP médicaments"
    }
    else {
        lab var oop_drug_trad "OOP médicaments traditionnels"
        lab var oop_drug_pub "OOP médicaments publics"
        lab var oop_drug_priv "OOP médicaments privés"
    }
    
    lab var oop_exam_soin "OOP examens médicaux et soins"
    lab var oop_glasses "OOP lunettes et montures"
    lab var oop_inpatient "OOP hospitalisation"
    lab var oop_materiel "OOP appareil orthopédiques et prothèses"
    lab var oop_vaccination "OOP vaccination"
    lab var use30 "Utilisation des soins dans les 30 jours"
    lab var use30_praticien "Professionnel vu dans les 30 jours"
    lab var use30_prest "Prestataire vu dans les 30 jours"
    lab var use365 "Hospitalisation dans les 12 mois"
    lab var use365_freq "Nombre d'hospitalisation dans les 12 mois"
    lab var use365_prest "Lieu d'hospitalisation"
    lab var use90 "Utilisation dans les 90 jours si aucune utilisation dans les 30 jours"
    
    if "`annee'" == "2021" {
        lab var oop_covid "OOP covid"
        lab var oop_birth "OOP accouchement"
        lab var oop_cpn "OOP consultation prénatale"
    }
end

program define calculate_indicators
    args annee
    
    capture drop couvmal
    gen couvmal = 1 if s03q32==1 | s03q36==1
    replace couvmal = 0 if couvmal==. | s03q33==0
    lab var couvmal "Assurance ou gratuité"
    
    gen non_soins = 1 if use30==0 & malade30==1
    replace non_soins = 0 if non_soins==.
    lab var non_soins "Renonciation aux soins"
    
    gen non_soins_ar = 1 if use30==0 & malade_ar==1
    replace non_soins_ar = 0 if non_soins_ar==.
    
    replace handit = 0 if handit==.
    replace handig = 0 if handig==.
    
    if "`annee'" == "2021" {
        egen oop_drug = rowtotal(oop_drug_trad oop_drug_pub oop_drug_priv)
        drop oop_drug_trad oop_drug_pub oop_drug_priv
    }
    
    local oop_trim "oop_consult_gen oop_consult_spe oop_consult_dent oop_consult_tradi oop_exam_soin oop_drug"
    foreach var of local oop_trim {
        replace `var' = `var' * 4
    }
    
    if "`annee'" == "2021" {
        capture replace oop_cpn = s03q50 * oop_cpn
    }
    
    egen oop = rsum(oop_*)
    lab var oop "Dépenses individuelles de santé"
    
    if "`annee'" == "2021" {
        gen no__oop = 0 if !missing(oop) & oop > 0
        replace no__oop = 1 if no__oop == .
        
        gen use__no_oop = 1 if use==1 & oop==0
        replace use__no_oop = 0 if use__no_oop==.
    }
end

program define aggregate_household
    args annee
    
    local vars_first "grappe menage milieu region hhsize dali dnal dtot pcexp hhweight country zref def_spa"
    
    local vars_sum "eqadu1 oop_consult_gen oop_consult_spe oop_consult_dent oop_consult_tradi oop_exam_soin"
    local vars_sum "`vars_sum' oop_drug oop_inpatient oop_glasses oop_materiel oop_vaccination oop_circon oop_bilan oop"
    
    if "`annee'" == "2021" {
        local vars_sum "`vars_sum' oop_covid oop_birth oop_cpn no__oop"
    }
    
    local vars_sum "`vars_sum' use* malade30 malade_ar"
    
    local vars_mean "non_soins"
    
    collapse (first) `vars_first' (sum) `vars_sum' (mean) `vars_mean', by(hhid)
    
    quietly regr dtot oop [pw=hhweight]
    
    gen dtet = dtot/hhsize
    replace dtet = dtet/def_spa
    
    gen subsist = zref*hhsize
    replace subsist = subsist*def_spa
    
    gen ctp = dtot - subsist
    gen ctp_bis = dtot - subsist
    gen poor = dtet < zref
    replace ctp_bis = dtot - dali if poor==1
    
    gen oopctp_bis = oop/ctp_bis
    gen oopctp = oop/ctp
    gen oopdtot = oop/dtot
    gen oopdnal = oop/dnal
    gen pcoop = oop/hhsize
    
    gen wts = hhweight*hhsize
    
    xtile quintile = dtot/hhsize [aw=hhsize*hhweight], nq(5)
    tab quintile, generate(quintile)
    lab def quintile 1"Très pauvre" 2"Pauvre" 3"Moyen" 4"Riche" 5"Très riche"
    lab val quintile quintile
    
    gen cata_dtot10 = cond(oopdtot>0.1, 1, 0)
    gen cata_dtot25 = cond(oopdtot>0.25, 1, 0)
    gen cata_ctp_b40 = cond(oopctp_bis>0.40, 1, 0)
    
    gen impoor = 1 if oopctp>1
    replace impoor = 0 if impoor==.
    
    gen immi = 1 if oopctp<0
    replace immi = 0 if immi==.
    
    gen acces_no_oop = 1 if use > 0 & oop==0
    replace acces_no_oop = 0 if acces_no_oop==.
    
    gen fp_oms = (immi == 1 | cata_dtot10 == 1 | impoor == 1)
    
    capture drop ea em ej
end

/*==============================================================================
                SECTION 3: EXÉCUTION DE LA PRÉPARATION
==============================================================================*/

foreach annee of global annees {
    
    di _n "===== TRAITEMENT DE L'ANNÉE `annee' =====" _n
    
    if "`annee'" == "2018" {
        local path_base "$path_base_2018"
        local pays_list "$pays_2018"
    }
    else {
        local path_base "$path_base_2021"
        local pays_list "$pays_2021"
    }
    
    capture mkdir "`path_base'\interm"
    capture mkdir "`path_base'\output"
    
    foreach pays of local pays_list {
        
        di _n "===== Traitement du pays: `pays' - Année: `annee' =====" _n
        
        prepare_individual_data `pays' `annee'
        
        use "base_sante_revise`pays'`annee'", clear
        recode_health_vars `annee'
        calculate_indicators `annee'
        
        save "`path_base'\interm\P`pays'`annee'_individus", replace
        
        aggregate_household `annee'
        save "`path_base'\interm\A`pays'`annee'_menages", replace
    }
    
    di _n "===== FUSION DES DONNÉES INDIVIDUELLES AVEC MÉNAGES - `annee' =====" _n
    
    foreach pays of local pays_list {
        
        use "`path_base'\interm\A`pays'`annee'_menages.dta", clear
        
        drop eqadu1 oop_consult_gen oop_consult_spe oop_consult_dent oop_consult_tradi 
        drop oop_exam_soin oop_drug oop_inpatient oop_glasses oop_materiel 
        drop oop_vaccination oop_circon oop_bilan oop
        
        if "`annee'" == "2021" {
            capture drop oop_covid oop_birth oop_cpn
        }
        
        drop use30 use30_prest use30_praticien use90 use365 use365_freq use365_prest use 
        drop non_soins malade30 malade_ar
        
        if "`annee'" == "2021" {
            capture drop use__no_oop no__oop
        }
        
        merge 1:m hhid using "`path_base'\interm\P`pays'`annee'_individus"
        keep if _merge == 3
        drop _merge
        
        rename s03q32 assu_soc
        rename s03q36 assu_ext
        
        drop non_soins*
        gen non_soins = 1 if use30==0 & malade30==1
        replace non_soins = 0 if non_soins==.
        lab var non_soins "Renonciation aux soins"
        
        gen non_soins_fin = 1 if use30==0 & malade30==1 & (s03q06==2 | s03q06==8)
        replace non_soins_fin = 0 if non_soins_fin==.
        
        if "`annee'" == "2021" {
            gen non_soins_fin2 = 1 if use30==0 & malade30==1 & (s03q06==2 | s03q06==8)
            replace non_soins_fin2 = 0 if non_soins_fin2==.
        }
        
        drop use
        gen use = 1 if use30==1 | use90==1 | use365==1
        replace use = 0 if use==.
        
        if "`annee'" == "2018" {
            gen use_noop = 1 if use==1 & oop_consult_gen==0 & oop_consult_spe==0 & ///
                             oop_consult_dent==0 & oop_consult_tradi==0 & ///
                             oop_exam_soin==0 & oop_inpatient==0
        }
        else {
            gen use_noop = 1 if use==1 & oop_consult_gen==0 & oop_consult_spe==0 & ///
                             oop_consult_dent==0 & oop_consult_tradi==0 & ///
                             oop_exam_soin==0 & oop_inpatient==0 & ///
                             oop_covid==0 & oop_birth==0 & oop_cpn==0
        }
        replace use_noop = 0 if use_noop==.
        
        lab var use "Soins ambulatoires ou hospitalisation"
        lab var use_noop "Exemption de paiements (outpatient/inpatient)"
        
        capture confirm variable commune
        if !_rc {
            tostring commune, replace force
        }
        
        di _n "===== CRÉATION DES VARIABLES DUMMY - `pays' `annee' =====" _n
        
        di _n "Tabulation use30_prest:"
        tab use30_prest, missing
        
        quietly levelsof use30_prest, local(levels_prest30)
        foreach val of local levels_prest30 {
            gen use30_prest_`val' = (use30_prest == `val') if !missing(use30_prest)
            replace use30_prest_`val' = 0 if missing(use30_prest_`val')
            label var use30_prest_`val' "use30_prest modalité `val'"
        }
        
        di _n "Tabulation use30_praticien:"
        tab use30_praticien, missing
        
        quietly levelsof use30_praticien, local(levels_prat30)
        foreach val of local levels_prat30 {
            gen use30_praticien_`val' = (use30_praticien == `val') if !missing(use30_praticien)
            replace use30_praticien_`val' = 0 if missing(use30_praticien_`val')
            label var use30_praticien_`val' "use30_praticien modalité `val'"
        }
        
        di _n "Tabulation use365_prest:"
        tab use365_prest, missing
        
        quietly levelsof use365_prest, local(levels_prest365)
        foreach val of local levels_prest365 {
            gen use365_prest_`val' = (use365_prest == `val') if !missing(use365_prest)
            replace use365_prest_`val' = 0 if missing(use365_prest_`val')
            label var use365_prest_`val' "use365_prest modalité `val'"
        }
        
        if "`annee'" == "2018" {
            gen fp_oms_eur = (immi == 1 | cata_dtot10 == 1 | impoor == 1 | non_soins_fin == 1)
        }
        else {
            gen fp_oms_eur = (immi == 1 | cata_dtot10 == 1 | impoor == 1 | non_soins_fin2 == 1)
        }
        
        gen non_soinstt = 1 if use30==0 & malade30==1
        replace non_soinstt = 0 if use30==1 & malade30==1
        
        gen non_soinsttfin = 1 if use30==0 & malade30==1 & (s03q06==2 | s03q06==8)
        replace non_soinsttfin = 0 if use30==1 & malade30==1
        replace non_soinsttfin = 2 if non_soinsttfin==. & non_soins==1
        
        rename s03q02 maladie
        
        save "`path_base'\interm\A`pays'`annee'_individus", replace
    }
    
    di _n "===== COMPILATION BASE UEMOA NIVEAU MÉNAGE - `annee' =====" _n
    
    clear
    foreach pays of local pays_list {
        append using "`path_base'\interm\A`pays'`annee'_menages"
        capture drop ea em ej
    }
    
    replace country = "BFA" if country == "bfa"
    sort hhid
    
    gen cou = country
    capture drop hhidd
    egen hhidd = concat(cou hhid), punct("")
    drop cou
    
    tabulate country, generate(country)
    gen pays = .
    forvalues i = 1/8 {
        replace pays = `i' if country`i' == 1
    }
    
    lab def pays 1"Bénin" 2"Burkina Faso" 3"Côte d'Ivoire" 4"Guinée-Bissau" ///
                 5"Mali" 6"Niger" 7"Sénégal" 8"Togo"
    lab val pays pays
    
    save "`path_base'\AUEMOA`annee'_menages", replace
    
    di _n "===== COMPILATION BASE UEMOA NIVEAU INDIVIDUEL - `annee' =====" _n
    
    clear
    foreach pays of local pays_list {
        append using "`path_base'\interm\A`pays'`annee'_individus", force
        capture drop ea em
    }
    
    replace country = "BFA" if country == "bfa"
    sort hhid
    
    gen cou = country
    capture drop hhidd
    egen hhidd = concat(cou hhid), punct("")
    drop cou
    
    tabulate country, generate(country)
    gen pays = .
    forvalues i = 1/8 {
        replace pays = `i' if country`i' == 1
    }
    
    lab val pays pays
    
    save "`path_base'\AUEMOA`annee'_individus", replace
}

/*==============================================================================
            SECTION 4: ANALYSE DES RÉSULTATS
==============================================================================*/

foreach annee of global annees {
    
    di _n "===== ANALYSES DE PROTECTION FINANCIÈRE - `annee' =====" _n
    
    if "`annee'" == "2018" {
        local path_base "$path_base_2018"
        local path_output "$path_base_2018\output"
    }
    else {
        local path_base "$path_base_2021"
        local path_output "$path_base_2021\output"
    }
    
    use "`path_base'\AUEMOA`annee'_individus", clear
    
    capture drop prop_oop_*
    
    gen non_soinsttfin_binary = (non_soinsttfin == 1) if !missing(non_soinsttfin)
    label variable non_soinsttfin_binary "Forgone care for financial reasons (binary)"
    
    svyset grappe [pw=hhweight], strata(region)
    
    di _n "===== ANALYSE DE LA STRUCTURE DES DÉPENSES AVEC SD - `annee' =====" _n
    
    if "`annee'" == "2018" {
        foreach var of varlist oop_consult_gen oop_consult_spe oop_consult_dent ///
            oop_consult_tradi oop_exam_soin oop_inpatient oop_glasses oop_materiel ///
            oop_vaccination oop_circon oop_bilan oop_drug {
            gen prop_`var' = `var' / oop if oop > 0
        }
    }
    else {
        foreach var of varlist oop_consult_gen oop_consult_spe oop_consult_dent ///
            oop_consult_tradi oop_exam_soin oop_inpatient oop_glasses oop_materiel ///
            oop_vaccination oop_circon oop_bilan oop_drug oop_covid oop_birth oop_cpn {
            gen prop_`var' = `var' / oop if oop > 0
        }
    }
    
    gen prop_outpatient = prop_oop_consult_gen + prop_oop_consult_spe + ///
                          prop_oop_consult_dent + prop_oop_consult_tradi + ///
                          prop_oop_exam_soin + prop_oop_circon + prop_oop_bilan ///
                          if oop > 0
                          
    gen prop_equipment = prop_oop_glasses + prop_oop_materiel if oop > 0
    
    if "`annee'" == "2021" {
        gen prop_delivery = prop_oop_birth + prop_oop_cpn if oop > 0
    }
    
    preserve
    
    keep if fp_oms_eur == 1
    
    if "`annee'" == "2018" {
        collapse (mean) mean_drug=prop_oop_drug mean_out=prop_outpatient mean_inp=prop_oop_inpatient ///
                        mean_equip=prop_equipment mean_vacc=prop_oop_vaccination ///
                 (sd) sd_drug=prop_oop_drug sd_out=prop_outpatient sd_inp=prop_oop_inpatient ///
                      sd_equip=prop_equipment sd_vacc=prop_oop_vaccination, by(pays)
    }
    else {
        collapse (mean) mean_drug=prop_oop_drug mean_out=prop_outpatient mean_inp=prop_oop_inpatient ///
                        mean_equip=prop_equipment mean_vacc=prop_oop_vaccination ///
                        mean_covid=prop_oop_covid mean_deliv=prop_delivery ///
                 (sd) sd_drug=prop_oop_drug sd_out=prop_outpatient sd_inp=prop_oop_inpatient ///
                      sd_equip=prop_equipment sd_vacc=prop_oop_vaccination ///
                      sd_covid=prop_oop_covid sd_deliv=prop_delivery, by(pays)
    }
    
    gen Drugs = string(mean_drug*100, "%5.2f") + " (" + string(sd_drug*100, "%5.2f") + ")"
    gen Outpatient = string(mean_out*100, "%5.2f") + " (" + string(sd_out*100, "%5.2f") + ")"
    gen Inpatient = string(mean_inp*100, "%5.2f") + " (" + string(sd_inp*100, "%5.2f") + ")"
    gen Equipment = string(mean_equip*100, "%5.2f") + " (" + string(sd_equip*100, "%5.2f") + ")"
    gen Vaccination = string(mean_vacc*100, "%5.2f") + " (" + string(sd_vacc*100, "%5.2f") + ")"
    
    if "`annee'" == "2021" {
        gen COVID_care = string(mean_covid*100, "%5.2f") + " (" + string(sd_covid*100, "%5.2f") + ")"
        gen Delivery = string(mean_deliv*100, "%5.2f") + " (" + string(sd_deliv*100, "%5.2f") + ")"
    }
    
    gen Country = ""
    replace Country = "Benin" if pays == 1
    replace Country = "Burkina Faso" if pays == 2
    replace Country = "Côte d'Ivoire" if pays == 3
    replace Country = "Guinea-Bissau" if pays == 4
    replace Country = "Mali" if pays == 5
    replace Country = "Niger" if pays == 6
    replace Country = "Senegal" if pays == 7
    replace Country = "Togo" if pays == 8
    
    if "`annee'" == "2018" {
        keep Country Drugs Outpatient Inpatient Equipment Vaccination
        order Country Drugs Outpatient Inpatient Equipment Vaccination
    }
    else {
        keep Country Drugs Outpatient Inpatient Equipment Vaccination COVID_care Delivery
        order Country Drugs Outpatient Inpatient Equipment Vaccination COVID_care Delivery
    }
    
    export excel using "`path_output'\Health_expenditure_structure_with_SD_`annee'.xlsx", ///
        sheet("Financial_hardship_mean_SD") sheetreplace firstrow(variables)
    
    restore
    
    di _n "===== CALCUL DES INDICATEURS DE PROTECTION FINANCIÈRE - `annee' =====" _n
    
    local vars "assu_soc assu_ext couvmal fp_oms fp_oms_eur immi impoor cata_dtot10 cata_dtot25 cata_ctp_b40 poor use_noop non_soinstt non_soinsttfin_binary"
    
    local var_labels `" "Social insurance" "Extension insurance schemes" "Health insurance coverage (all)" "Catastrophic+Impoverishing (no double counting)" "Forgone+Catastrophic+Impoverishing (no double counting)" "Impoverishment (aggravation)" "Impoverishment (poverty)" "Catastrophic expenditure (10%)" "Catastrophic expenditure (25%)" "Catastrophic expenditure (40% non-food)" "Poverty" "Use without payment" "Forgone care (all reasons)" "Forgone care (financial reasons)" "'
    
    putexcel set "`path_output'\Financial_protection_indicators_`annee'.xlsx", replace
    
    putexcel A1 = "Financial Protection Indicators in Health - UEMOA `annee'"
    putexcel A2 = "Means and standard errors by country"
    
    putexcel A4 = "Country" 
    putexcel B4 = "Indicator" 
    putexcel C4 = "Mean (%)" 
    putexcel D4 = "Standard error"
    putexcel E4 = "95% CI lower"
    putexcel F4 = "95% CI upper"
    
    putexcel A4:F4, bold border(bottom, thick)
    
    matrix define results_mean = J(8*14, 1, .)
    matrix define results_se = J(8*14, 1, .)
    matrix define results_ci_low = J(8*14, 1, .)
    matrix define results_ci_high = J(8*14, 1, .)
    
    local row = 5
    local mat_row = 1
    
    forvalues p = 1/8 {
        local country_name = ""
        if `p' == 1 local country_name = "Benin"
        if `p' == 2 local country_name = "Burkina Faso"
        if `p' == 3 local country_name = "Côte d'Ivoire"
        if `p' == 4 local country_name = "Guinea-Bissau"
        if `p' == 5 local country_name = "Mali"
        if `p' == 6 local country_name = "Niger"
        if `p' == 7 local country_name = "Senegal"
        if `p' == 8 local country_name = "Togo"
        
        putexcel A`row' = "`country_name'", bold
        putexcel A`row':F`row', border(top, thin)
        local row = `row' + 1
        
        local i = 1
        foreach var of local vars {
            local var_label : word `i' of `var_labels'
            
            quietly svy: mean `var' if pays == `p'
            matrix results = r(table)
            
            local mean = results[1,1] * 100
            local se = results[2,1] * 100
            local ci_low = results[5,1] * 100
            local ci_high = results[6,1] * 100
            
            matrix results_mean[`mat_row',1] = `mean'
            matrix results_se[`mat_row',1] = `se'
            matrix results_ci_low[`mat_row',1] = `ci_low'
            matrix results_ci_high[`mat_row',1] = `ci_high'
            
            putexcel A`row' = ""
            putexcel B`row' = "`var_label'"
            putexcel C`row' = `mean', nformat(number_d2)
            putexcel D`row' = `se', nformat(number_d2)
            putexcel E`row' = `ci_low', nformat(number_d2)
            putexcel F`row' = `ci_high', nformat(number_d2)
            
            local row = `row' + 1
            local i = `i' + 1
            local mat_row = `mat_row' + 1
        }
    }
    
    local row = `row' + 2
    putexcel A`row' = "Notes:"
    local row = `row' + 1
    putexcel A`row' = "- All indicators are weighted according to the survey design"
    local row = `row' + 1
    putexcel A`row' = "- fp_oms: Catastrophic + impoverishing expenditures (no double counting)"
    local row = `row' + 1
    putexcel A`row' = "- fp_oms_eur: Forgone care + catastrophic + impoverishing (no double counting)"
    local row = `row' + 1
    putexcel A`row' = "- Forgone care (financial reasons) includes only financial barriers"
    
    putexcel set "`path_output'\Financial_protection_indicators_`annee'.xlsx", sheet("Synthetic_Format") modify
    
    putexcel A1 = "Financial Protection Indicators in Health - UEMOA `annee'"
    putexcel A2 = "% (95% CI)"
    
    putexcel A4 = "Indicator"
    putexcel B4 = "Benin"
    putexcel C4 = "Burkina Faso"
    putexcel D4 = "Côte d'Ivoire"
    putexcel E4 = "Guinea-Bissau"
    putexcel F4 = "Mali"
    putexcel G4 = "Niger"
    putexcel H4 = "Senegal"
    putexcel I4 = "Togo"
    
    putexcel A4:I4, bold border(bottom, thick)
    
    local row = 5
    local mat_row = 1
    
    local i = 1
    foreach var of local vars {
        local var_label : word `i' of `var_labels'
        
        putexcel A`row' = "`var_label'"
        
        forvalues p = 1/8 {
            local pos = (`p'-1)*14 + `i'
            
            local mean = results_mean[`pos',1]
            local ci_low = results_ci_low[`pos',1]
            local ci_high = results_ci_high[`pos',1]
            
            local formatted = string(`mean', "%4.1f") + " (" + string(`ci_low', "%4.1f") + "-" + string(`ci_high', "%4.1f") + ")"
            
            if `p' == 1 putexcel B`row' = "`formatted'"
            if `p' == 2 putexcel C`row' = "`formatted'"
            if `p' == 3 putexcel D`row' = "`formatted'"
            if `p' == 4 putexcel E`row' = "`formatted'"
            if `p' == 5 putexcel F`row' = "`formatted'"
            if `p' == 6 putexcel G`row' = "`formatted'"
            if `p' == 7 putexcel H`row' = "`formatted'"
            if `p' == 8 putexcel I`row' = "`formatted'"
        }
        
        if inlist(`i', 5, 7, 10, 12) {
            putexcel A`row':I`row', border(bottom, thin)
        }
        
        local row = `row' + 1
        local i = `i' + 1
    }
    
    local row = `row' + 2
    putexcel A`row' = "Notes:"
    local row = `row' + 1
    putexcel A`row' = "CI = Confidence Interval"
    local row = `row' + 1
    putexcel A`row' = "All values are percentages with 95% confidence intervals in parentheses"
    
    putexcel set "`path_output'\Financial_protection_indicators_`annee'.xlsx", sheet("Key_Indicators") modify
    
    putexcel A1 = "Key Financial Protection Indicators - UEMOA `annee'"
    putexcel A2 = "% (95% CI)"
    
    putexcel A4 = "Country"
    putexcel B4 = "Forgone care (financial)"
    putexcel C4 = "Catastrophic (10%)"
    putexcel D4 = "Impoverishing"
    putexcel E4 = "Total hardship"
    putexcel F4 = "Insurance coverage"
    
    putexcel A4:F4, bold border(bottom, thick)
    
    local key_positions "14 8 4 5 3"
    
    local row = 5
    forvalues p = 1/8 {
        local country_name = ""
        if `p' == 1 local country_name = "Benin"
        if `p' == 2 local country_name = "Burkina Faso"
        if `p' == 3 local country_name = "Côte d'Ivoire"
        if `p' == 4 local country_name = "Guinea-Bissau"
        if `p' == 5 local country_name = "Mali"
        if `p' == 6 local country_name = "Niger"
        if `p' == 7 local country_name = "Senegal"
        if `p' == 8 local country_name = "Togo"
        
        putexcel A`row' = "`country_name'"
        
        local col = 2
        foreach ind_pos of local key_positions {
            local pos = (`p'-1)*14 + `ind_pos'
            
            local mean = results_mean[`pos',1]
            local ci_low = results_ci_low[`pos',1]
            local ci_high = results_ci_high[`pos',1]
            
            local formatted = string(`mean', "%4.1f") + " (" + string(`ci_low', "%4.1f") + "-" + string(`ci_high', "%4.1f") + ")"
            
            if `col' == 2 putexcel B`row' = "`formatted'"
            if `col' == 3 putexcel C`row' = "`formatted'"
            if `col' == 4 putexcel D`row' = "`formatted'"
            if `col' == 5 putexcel E`row' = "`formatted'"
            if `col' == 6 putexcel F`row' = "`formatted'"
            
            local col = `col' + 1
        }
        
        local row = `row' + 1
    }
    
    local row = `row' + 1
    putexcel A`row':F`row', border(top, thick)
    putexcel A`row' = "UEMOA Average", bold
    
    local row = `row' + 2
    putexcel A`row' = "Notes:"
    local row = `row' + 1
    putexcel A`row' = "Total hardship = Forgone care + Catastrophic + Impoverishing (no double counting)"
    local row = `row' + 1
    putexcel A`row' = "All values weighted by survey design"
    
    putexcel close
    
    di "Tableau de protection financière créé avec 3 onglets: `path_output'\Financial_protection_indicators_`annee'.xlsx"
    
    di _n "===== PRÉPARATION DONNÉES POUR ANALYSE ASSURANCE - `annee' =====" _n
    
    global vars_assu "hhid hhidd hhweight cata_dtot10 grappe oop dtet region"
    global vars_assu "$vars_assu couvmal assu_ext assu_soc non_soinsttfin milieu"
    global vars_assu "$vars_assu hhsize dtot pcexp quintile poor sexe age lien mstat"
    global vars_assu "$vars_assu religion nation handit handig educ_hi diplome"
    global vars_assu "$vars_assu activ7j activ12m branch sectins csp hgender hage"
    global vars_assu "$vars_assu hmstat hreligion hnation heduc hdiploma hhandig"
    global vars_assu "$vars_assu hactiv7j hactiv12m hbranch hsectins hcsp maladie use365"    
    global vars_assu "$vars_assu use use30_prest_* use30_praticien_* use365_prest_* malade30"
    
    if "`annee'" == "2021" {
        global vars_assu "$vars_assu ethnie hethnie"
    }
    
    if "`annee'" == "2018" {
        local pays_list "$pays_2018"
    }
    else {
        local pays_list "$pays_2021"
    }
    
    foreach pays of local pays_list {
        use "`path_base'\interm\A`pays'`annee'_individus.dta", clear
        
        keep $vars_assu
        
        if "`annee'" == "2018" & "`pays'" == "SEN" {
            replace educ_hi = 0 if educ_hi==. & diplome==0
            drop if educ_hi==.
        }
        
        if "`annee'" == "2021" {
            if "`pays'" == "civ" {
                drop if hhid==.
                drop if heduc==.
            }
            if "`pays'" == "ner" {
                drop if sexe==.
            }
            if "`pays'" == "sen" {
                drop if mstat==.
            }
        }
        
        save "`path_base'\interm\A`pays'`annee'_individus_assu.dta", replace
    }
    
    di "Données préparées pour analyse assurance future: `path_base'\interm\"
}


log close
