from cohortextractor import (
    codelist,
    codelist_from_csv,
)


##############################################################################
### TO UPDATE: Still using local codelists:

# pvd_codes (local version used below)
# fracture_codes (local version used below)

# DVT/PE (completely made up ones below)
# Learning disability (completely made up ones below)
# In each case need to:
# (i) change the link
# (ii) add the OS codelist to the codelists.txt
# (iii) run cohortextractor update_codelists in Anaconda prompt

### THEN DELETE THIS SECTION!!!!
##############################################################################


### Outcomes

# COVID death
covid_codelist = codelist(["U071", "U072"], system="icd10")


### Demographics

# Smoking
clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)
unclear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-unclear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)

# Ethnicity
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)
ethnicity_codes_16 = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_16",
)


### Clinical measurements

systolic_blood_pressure_codes = codelist(["2469."], system="ctv3")
diastolic_blood_pressure_codes = codelist(["246A."], system="ctv3")
creatinine_codes = codelist(["XE2q5"], system="ctv3")
hba1c_new_codes = codelist(["XaPbt", "Xaeze", "Xaezd"], system="ctv3")
hba1c_old_codes = codelist(["X772q", "XaERo", "XaERp"], system="ctv3")


### Comorbidities

# Respiratory
asthma_codes = codelist_from_csv(
    "codelists/opensafely-asthma-diagnosis.csv", system="ctv3", column="CTV3ID"
)
pred_codes = codelist_from_csv(
    "codelists/opensafely-asthma-oral-prednisolone-medication.csv",
    system="snomed",
    column="snomed_id",
)
cf_codes = codelist_from_csv(
    "codelists/opensafely-cystic-fibrosis.csv", system="ctv3", column="CTV3ID",
)
other_respiratory_codes = codelist_from_csv(
    "codelists/opensafely-other-chronic-respiratory-disease.csv",
    system="ctv3",
    column="CTV3ID",
)

# Cardiac
chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv", system="ctv3", column="CTV3ID",
)
diabetes_codes = codelist_from_csv(
    "codelists/opensafely-diabetes.csv", system="ctv3", column="CTV3ID",
)
hypertension_codes = codelist_from_csv(
    "codelists/opensafely-hypertension.csv", system="ctv3", column="CTV3ID",
)
af_codes = codelist_from_csv(
    "codelists/opensafely-atrial-fibrillation-or-flutter.csv",
    system="ctv3",
    column="CTV3Code",
)
dvt_pe_codes = codelist_from_csv(
    "codelists/opensafely-venous-thromboembolic-disease.csv",
    system="ctv3",
    column="CTV3Code",
)
pad_surg_codes = codelist_from_csv(
    "codelists/opensafely-surgery-for-peripheral-artery-disease.csv",
    system="ctv3",
    column="CTV3Code",
)
amputate_codes = codelist_from_csv(
    "codelists/opensafely-amputation.csv",
    system="ctv3",
    column="CTV3Code",
)

# Neurological
stroke = codelist_from_csv(
    "codelists/opensafely-stroke-updated.csv", system="ctv3", column="CTV3ID",
)
dementia = codelist_from_csv(
    "codelists/opensafely-dementia.csv", system="ctv3", column="CTV3ID",
)
other_neuro = codelist_from_csv(
    "codelists/opensafely-other-neurological-conditions.csv",
    system="ctv3",
    column="CTV3ID",
)

# Cancer
lung_cancer_codes = codelist_from_csv(
    "codelists/opensafely-lung-cancer.csv", system="ctv3", column="CTV3ID",
)
haem_cancer_codes = codelist_from_csv(
    "codelists/opensafely-haematological-cancer.csv", system="ctv3", column="CTV3ID",
)
other_cancer_codes = codelist_from_csv(
    "codelists/opensafely-cancer-excluding-lung-and-haematological.csv",
    system="ctv3",
    column="CTV3ID",
)


# Liver and kidney and transplant
chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", system="ctv3", column="CTV3ID",
)
transplant_kidney_codes = codelist_from_csv(
    "codelists/opensafely-kidney-transplant.csv", system="ctv3", column="CTV3ID",
)
transplant_notkidney_codes = codelist_from_csv(
    "codelists/opensafely-other-organ-transplant.csv", system="ctv3", column="CTV3ID",
)
dialysis_codes = codelist_from_csv(
    "codelists/opensafely-dialysis.csv", system="ctv3", column="CTV3ID",
)


# Immunosuppression
hiv_codes = codelist_from_csv(
    "codelists/opensafely-hiv.csv", system="ctv3", column="CTV3ID",
)
aplastic_codes = codelist_from_csv(
    "codelists/opensafely-aplastic-anaemia.csv", system="ctv3", column="CTV3ID",
)
temp_immune_codes = codelist_from_csv(
    "codelists/opensafely-temporary-immunosuppression.csv",
    system="ctv3",
    column="CTV3ID",
)
permanent_immune_codes = codelist_from_csv(
    "codelists/opensafely-permanent-immunosuppression.csv",
    system="ctv3",
    column="CTV3ID",
)
spleen_codes = codelist_from_csv(
    "codelists/opensafely-asplenia.csv", system="ctv3", column="CTV3ID",
)
sickle_cell_codes = codelist_from_csv(
    "codelists/opensafely-sickle-cell-disease.csv", system="ctv3", column="CTV3ID",
)
ra_sle_psoriasis_codes = codelist_from_csv(
    "codelists/opensafely-ra-sle-psoriasis.csv", system="ctv3", column="CTV3ID",
)
inflammatory_bowel_disease_codes = codelist_from_csv(
    "codelists/opensafely-inflammatory-bowel-disease.csv",
    system="ctv3",
    column="CTV3ID",
)

# Frailty
fracture_codes = codelist_from_csv(
    "codelists/opensafely-fragility.csv",
     system="ctv3",
     column="CTV3Code",
)

# Mental illness and learning disability
smi_codes = codelist_from_csv(
    "codelists/opensafely-psychosis-schizophrenia-bipolar-affective-disease.csv",
    system="ctv3",
    column="CTV3Code",
)
ld_codes = codelist_from_csv(
    "codelists/opensafely-intellectual-disability-including-downs-syndrome.csv",
    system="ctv3",
    column="CTV3ID",
)
