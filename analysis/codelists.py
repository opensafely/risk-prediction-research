from cohortextractor import (
    codelist,
    codelist_from_csv,
)


### TO UPDATE: Still using local codelists:
# cf_codes
# other_respiratory
# af_codes
# pvd_codes
# hiv_codes
# fracture_codes
# osteo_codes (maybe not wanted)
# smi_codes
# Learning disability - not even in here yet!


# Outcomes
covid_codelist = codelist(["U071", "U072"], system="icd10")


# Demographics
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
    "local_codelists/CTV3-cystic-fibrosis-17072020.csv", system="ctv3", column="CTV3ID"
)
other_respiratory_codes = codelist_from_csv(
    "local_codelists/CTV3-other-chronic-respiratory-disease-17072020.csv",
    system="ctv3",
    column="CTV3ID",
)

# Cardiac
chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv", system="ctv3", column="CTV3ID"
)
diabetes_codes = codelist_from_csv(
    "codelists/opensafely-diabetes.csv", system="ctv3", column="CTV3ID"
)
hypertension_codes = codelist_from_csv(
    "codelists/opensafely-hypertension.csv", system="ctv3", column="CTV3ID"
)
af_codes = codelist_from_csv(
    "local_codelists/OpenSAFELY_eFI_Codes_AF.csv", system="ctv3", column="CTV3ID"
)
pvd_codes = codelist_from_csv(
    "local_codelists/OpenSAFELY_eFI_Codes_PVD.csv", system="ctv3", column="CTV3ID"
)

# Neurological
stroke = codelist_from_csv(
    "codelists/opensafely-stroke-updated.csv", system="ctv3", column="CTV3ID"
)
dementia = codelist_from_csv(
    "codelists/opensafely-dementia.csv", system="ctv3", column="CTV3ID"
)
other_neuro = codelist_from_csv(
    "codelists/opensafely-other-neurological-conditions.csv",
    system="ctv3",
    column="CTV3ID",
)

# Cancer
lung_cancer_codes = codelist_from_csv(
    "codelists/opensafely-lung-cancer.csv", system="ctv3", column="CTV3ID"
)
haem_cancer_codes = codelist_from_csv(
    "codelists/opensafely-haematological-cancer.csv", system="ctv3", column="CTV3ID"
)
other_cancer_codes = codelist_from_csv(
    "codelists/opensafely-cancer-excluding-lung-and-haematological.csv",
    system="ctv3",
    column="CTV3ID",
)


# Liver and kidney and transplant
chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", system="ctv3", column="CTV3ID"
)
transplant_kidney_codes = codelist_from_csv(
    "codelists/opensafely-kidney-transplant.csv", system="ctv3", column="CTV3ID"
)
transplant_notkidney_codes = codelist_from_csv(
    "codelists/opensafely-other-organ-transplant.csv", system="ctv3", column="CTV3ID"
)
dialysis_codes = codelist_from_csv(
    "codelists/opensafely-dialysis.csv", system="ctv3", column="CTV3ID"
)


# Immunosuppression
hiv_codes = codelist_from_csv(
    "local_codelists/hiv_corrected.csv", system="ctv3", column="CTV3ID"
)
aplastic_codes = codelist_from_csv(
    "codelists/opensafely-aplastic-anaemia.csv", system="ctv3", column="CTV3ID"
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
    "codelists/opensafely-asplenia.csv", system="ctv3", column="CTV3ID"
)
sickle_cell_codes = codelist_from_csv(
    "codelists/opensafely-sickle-cell-disease.csv", system="ctv3", column="CTV3ID"
)
ra_sle_psoriasis_codes = codelist_from_csv(
    "codelists/opensafely-ra-sle-psoriasis.csv", system="ctv3", column="CTV3ID"
)
inflammatory_bowel_disease_codes = codelist_from_csv(
    "codelists/opensafely-inflammatory-bowel-disease.csv",
    system="ctv3",
    column="CTV3ID",
)

# Frailty
fracture_codes = codelist_from_csv(
    "local_codelists/OpenSAFELY_eFI_Codes_Fragility.csv", system="ctv3", column="CTV3ID"
)
osteo_codes = codelist_from_csv(
    "local_codelists/OpenSAFELY_eFI_Codes_Osteoporosis.csv",
    system="ctv3",
    column="CTV3ID",
)

# Mental illness and learning disability
smi_codes = codelist_from_csv(
    "local_codelists/opensafely_smi_UPDATE.csv", system="ctv3", column="CTV3ID"
)

covid_suspected_codes = codelist_from_csv(
    "local_codelists/exploratory_covid_suspected_codes.csv",
    system="ctv3",
    column="CTV3ID",
)
