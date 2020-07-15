## IMPORT STATEMENTS

# This imports the cohort extractor package. This can be downloaded via pip
from cohortextractor import (
    StudyDefinition,
    patients,
    codelist_from_csv,
    codelist,
    filter_codes_by_category,
)

# IMPORT CODELIST DEFINITIONS FROM CODELIST.PY (WHICH PULLS THEM FROM
# CODELIST FOLDER
from codelists import *


## STUDY POPULATION

# Defines both the study population and points to the important covariates

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1970-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.2,
    },

    # STUDY POPULATION
    population=patients.satisfying(
        """
        (age >=18 AND age <= 105) AND
        (household_size <= 10) AND
        """,
        alive_at_cohort_start=patients.registered_with_one_practice_between(
            "2020-02-29", "2020-03-01"
        ),


    # OUTCOMES
    died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_codelist,
        on_or_before="2020-06-07",
        match_only_underlying_cause=False,
        return_expectations={"date": {"earliest": "2020-03-01"}},
    ),
    died_date_ons=patients.died_from_any_cause(
        on_or_before="2020-06-07",
        returning="date_of_death",
        include_month=True,
        include_day=True,
    ),

    ### GEOGRAPHICAL AREA AND DEPRIVATION

    # RURAL/URBAN
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/37
    rural_urban=patients.address_as_of(
        "2020-03-01",
        returning="rural_urban_classification",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"rural": 0.1, "urban": 0.9}},
        },
    ),
    # GEOGRAPHICAL AREA - SUSTAINABILITY AND TRANSFORMATION PARTNERSHIP
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/54
    stp=patients.registered_practice_as_of(
        "2020-03-01",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "STP1": 0.1,
                    "STP2": 0.1,
                    "STP3": 0.1,
                    "STP4": 0.1,
                    "STP5": 0.1,
                    "STP6": 0.1,
                    "STP7": 0.1,
                    "STP8": 0.1,
                    "STP9": 0.1,
                    "STP10": 0.1,
                }
            },
        },
    ),
    # GEOGRAPHICAL AREA - NHS England 9 regions
    region=patients.registered_practice_as_of(
        "2020-03-01",
        returning="nuts1_region_name",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and The Humber": 0.1,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East": 0.1,
                    "London": 0.2,
                    "South East": 0.2,
                },
            },
        },
    ),

    # DEPRIVATION
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/52
    imd=patients.address_as_of(
        "2020-03-01",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ),

    ### HOUSEHOLD INFORMATION
    # HOUSEHOLD ID
    household_id=patients.household_as_of(
        "2020-02-01",
        returning="pseudo_id",
        return_expectations={
            "int": {"distribution": "normal", "mean": 1000, "stddev": 200},
            "incidence": 1,
        },
    ),
    # HOUSEHOLD SIZE
    household_size=patients.household_as_of(
        "2020-02-01",
        returning="household_size",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
    ),

    # DEMOGRAPHIC COVARIATES

    # AGE
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/33
    age=patients.age_as_of(
        "2020-03-01",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    # SEX
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/46
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    # ETHNICITY
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/27
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        on_or_before="2020-03-01",
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
            "incidence": 0.75,
        },
    ),
    ethnicity_16=patients.with_these_clinical_events(
        ethnicity_codes_16,
        returning="category",
        find_last_match_in_period=True,
        on_or_before="2020-03-01",
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
            "incidence": 0.75,
        },
    ),
    # SMOKING STATUS
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/6
    smoking_status_1=patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S' OR smoked_last_18_months",
            "E": """
                 (most_recent_smoking_code = 'E' OR (
                   most_recent_smoking_code = 'N' AND ever_smoked
                   )
                 ) AND NOT smoked_last_18_months
            """,
            "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
            "M": "DEFAULT",
        },
        return_expectations={
            "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
        },
        most_recent_smoking_code=patients.with_these_clinical_events(
            clear_smoking_codes,
            find_last_match_in_period=True,
            on_or_before="2020-03-01",
            returning="category",
        ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
            on_or_before="2020-03-01",
        ),
        smoked_last_18_months=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S"]),
            between=["2018-09-01", "2020-03-01"],
        ),
    ),
    # Time-updated: Smoking status as of 1 April 2020
    smoking_status_2=patients.categorised_as(
            {
                "S": "most_recent_smoking_code_2 = 'S' OR smoked_last_18_months_2",
                "E": """
                     (most_recent_smoking_code_2 = 'E' OR (
                       most_recent_smoking_code_2 = 'N' AND ever_smoked_2
                       )
                     ) AND NOT smoked_last_18_months_2
                """,
                "N": "most_recent_smoking_code_2 = 'N' AND NOT ever_smoked_2",
                "M": "DEFAULT",
            },
            return_expectations={
                "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
            },
            most_recent_smoking_code_2=patients.with_these_clinical_events(
                clear_smoking_codes,
                find_last_match_in_period=True,
                on_or_before="2020-04-01",
                returning="category",
            ),
            ever_smoked_2=patients.with_these_clinical_events(
                filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
                on_or_before="2020-04-01",
            ),
            smoked_last_18_months_2=patients.with_these_clinical_events(
                filter_codes_by_category(clear_smoking_codes, include=["S"]),
                between=["2018-10-01", "2020-04-01"],
            ),
        ),
    # Time-updated: Smoking status as of 12 April 2020
     smoking_status_3=patients.categorised_as(
             {
                 "S": "most_recent_smoking_code_3 = 'S' OR smoked_last_18_months_3",
                 "E": """
                      (most_recent_smoking_code_3 = 'E' OR (
                        most_recent_smoking_code_3 = 'N' AND ever_smoked_3
                        )
                      ) AND NOT smoked_last_18_months_3
                 """,
                 "N": "most_recent_smoking_code_3 = 'N' AND NOT ever_smoked_3",
                 "M": "DEFAULT",
             },
             return_expectations={
                 "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
             },
             most_recent_smoking_code_3=patients.with_these_clinical_events(
                 clear_smoking_codes,
                 find_last_match_in_period=True,
                 on_or_before="2020-04-12",
                 returning="category",
             ),
             ever_smoked_3=patients.with_these_clinical_events(
                 filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
                 on_or_before="2020-04-12",
             ),
             smoked_last_18_months_3=patients.with_these_clinical_events(
                 filter_codes_by_category(clear_smoking_codes, include=["S"]),
                 between=["2018-10-12", "2020-04-12"],
             ),
         ),
     # Time-updated: Smoking status as of 11 May 2020
     smoking_status_4=patients.categorised_as(
             {
                 "S": "most_recent_smoking_code_4 = 'S' OR smoked_last_18_months_4",
                 "E": """
                      (most_recent_smoking_code_4 = 'E' OR (
                        most_recent_smoking_code_4 = 'N' AND ever_smoked_4
                        )
                      ) AND NOT smoked_last_18_months_4
                 """,
                 "N": "most_recent_smoking_code_4 = 'N' AND NOT ever_smoked_4",
                 "M": "DEFAULT",
             },
             return_expectations={
                 "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
             },
             most_recent_smoking_code_4=patients.with_these_clinical_events(
                 clear_smoking_codes,
                 find_last_match_in_period=True,
                 on_or_before="2020-05-11",
                 returning="category",
             ),
             ever_smoked_4=patients.with_these_clinical_events(
                 filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
                 on_or_before="2020-05-11",
             ),
             smoked_last_18_months_4=patients.with_these_clinical_events(
                 filter_codes_by_category(clear_smoking_codes, include=["S"]),
                 between=["2018-11-11", "2020-05-11"],
             ),
         ),

    # CLINICAL MEASUREMENTS

    # BMI
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/10
    bmi_1=patients.most_recent_bmi(
        on_or_before="2010-03-01",
        minimum_age_at_measurement=16,
        include_measurement_date=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
            "incidence": 0.95,
        },
    ),
    # Time-updated: BMI as of 1 April 2020
    bmi_2=patients.most_recent_bmi(
        on_or_before="2010-04-01",
        minimum_age_at_measurement=16,
        include_measurement_date=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
            "incidence": 0.95,
        },
    ),
    # Time-updated: BMI as of 12 April 2020
    bmi_3=patients.most_recent_bmi(
        on_or_before="2010-04-12",
        minimum_age_at_measurement=16,
        include_measurement_date=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
            "incidence": 0.95,
        },
    ),
    # Time-updated: BMI as of 11 May 2020
    bmi_4=patients.most_recent_bmi(
        on_or_before="2010-05-11",
        minimum_age_at_measurement=16,
        include_measurement_date=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
            "incidence": 0.95,
        },
    ),


    # Chronic kidney disease
    # Most recent creatinine within 2 years (not inc. last fortnight)
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/17
    creatinine_1=patients.with_these_clinical_events(
        creatinine_codes,
        find_last_match_in_period=True,
        between=["2018-03-01", "2020-02-16"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
            "incidence": 0.95,
        },
    ),

    # Time-updated: Most recent creatinine as of 1 April 2020
    creatinine_2=patients.with_these_clinical_events(
        creatinine_codes,
        find_last_match_in_period=True,
        between=["2018-04-01", "2020-03-18"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
            "incidence": 0.95,
        },
    ),
    # Time-updated: Most recent creatinine  as of 12 April 2020
    creatinine_3=patients.with_these_clinical_events(
        creatinine_codes,
        find_last_match_in_period=True,
        between=["2018-04-12", "2020-03-29"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
            "incidence": 0.95,
        },
    ),
    # Time-updated: Most recent creatinine as of 11 May 2020
    creatinine_4=patients.with_these_clinical_events(
        creatinine_codes,
        find_last_match_in_period=True,
        between=["2018-05-11", "2020-04-27"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
            "incidence": 0.95,
        },
    ),

    # Blood pressure
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/35
    bp_sys=patients.mean_recorded_value(
        systolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="2020-02-15",
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "float": {"distribution": "normal", "mean": 80, "stddev": 10},
            "date": {"latest": "2020-02-15"},
            "incidence": 0.95,
        },
    ),
    bp_dias=patients.mean_recorded_value(
        diastolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="2020-02-15",
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "float": {"distribution": "normal", "mean": 120, "stddev": 10},
            "date": {"latest": "2020-02-15"},
            "incidence": 0.95,
        },
    ),
    # Hba1c - most recent measurement within 15 months - mmol/mol or %
    hba1c_mmol_per_mol_1=patients.with_these_clinical_events(
        hba1c_new_codes,
        find_last_match_in_period=True,
        between=["2018-12-01", "2020-03-01"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    hba1c_percentage_1=patients.with_these_clinical_events(
        hba1c_old_codes,
        find_last_match_in_period=True,
        between=["2018-12-01", "2020-03-01"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),
    # Time-updated: Most recent creatinine as of 1 April 2020
    hba1c_mmol_per_mol_2=patients.with_these_clinical_events(
        hba1c_new_codes,
        find_last_match_in_period=True,
        between=["2019-01-01", "2020-04-01"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    hba1c_percentage_2=patients.with_these_clinical_events(
        hba1c_old_codes,
        find_last_match_in_period=True,
        between=["2019-01-01", "2020-04-01"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),
    # Time-updated: Most recent creatinine as of 12 April 2020
    hba1c_mmol_per_mol_3=patients.with_these_clinical_events(
        hba1c_new_codes,
        find_last_match_in_period=True,
        between=["2019-01-12", "2020-04-12"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    hba1c_percentage_3=patients.with_these_clinical_events(
        hba1c_old_codes,
        find_last_match_in_period=True,
        between=["2019-01-12", "2020-04-12"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),
    # Time-updated: Most recent creatinine as of 11 May 2020
    hba1c_mmol_per_mol_4=patients.with_these_clinical_events(
        hba1c_new_codes,
        find_last_match_in_period=True,
        between=["2019-02-11", "2020-05-11"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    hba1c_percentage_4=patients.with_these_clinical_events(
        hba1c_old_codes,
        find_last_match_in_period=True,
        between=["2019-02-11", "2020-05-11"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),

    # ASTHMA
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/55
    asthma_severity_1=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                (
                  recent_asthma_code OR (
                    asthma_code_ever AND NOT
                    copd_code_ever
                  )
                ) AND (
                  prednisolone_last_year < 2
                )
            """,
            "2": """
                (
                  recent_asthma_code OR (
                    asthma_code_ever AND NOT
                    copd_code_ever
                  )
                ) AND
                prednisolone_last_year >= 2

            """,
        },
        return_expectations={"category": {"ratios": {"0": 0.8, "1": 0.1, "2": 0.1}},},
        recent_asthma_code=patients.with_these_clinical_events(
            asthma_codes, between=["2017-03-01", "2020-03-01"],
        ),
        asthma_code_ever=patients.with_these_clinical_events(asthma_codes),
        copd_code_ever=patients.with_these_clinical_events(
            chronic_respiratory_disease_codes
        ),
        prednisolone_last_year=patients.with_these_medications(
            pred_codes,
            between=["2019-03-01", "2020-03-01"],
            returning="number_of_matches_in_period",
        ),
    ),

    # Time-updated: Most recent creatinine as of 1 April 2020
    asthma_severity_2=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                (
                  recent_asthma_code_2 OR (
                    asthma_code_ever_2 AND NOT
                    copd_code_ever_2
                  )
                ) AND (
                  prednisolone_last_year_2 < 2
                )
            """,
            "2": """
                (
                  recent_asthma_code_2 OR (
                    asthma_code_ever_2 AND NOT
                    copd_code_ever_2
                  )
                ) AND
                prednisolone_last_year_2 >= 2

            """,
        },
        return_expectations={"category": {"ratios": {"0": 0.8, "1": 0.1, "2": 0.1}},},
        recent_asthma_code_2=patients.with_these_clinical_events(
            asthma_codes, between=["2017-04-01", "2020-04-01"],
        ),
        asthma_code_ever_2=patients.with_these_clinical_events(asthma_codes),
        copd_code_ever_2=patients.with_these_clinical_events(
            chronic_respiratory_disease_codes
        ),
        prednisolone_last_year_2=patients.with_these_medications(
            pred_codes,
            between=["2019-04-01", "2020-04-01"],
            returning="number_of_matches_in_period",
        ),
    ),

    # Time-updated: Most recent creatinine as of 12 April 2020
    asthma_severity_3=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                (
                  recent_asthma_code_3 OR (
                    asthma_code_ever_3 AND NOT
                    copd_code_ever_3
                  )
                ) AND (
                  prednisolone_last_year_3 < 2
                )
            """,
            "2": """
                (
                  recent_asthma_code_3 OR (
                    asthma_code_ever_3 AND NOT
                    copd_code_ever_3
                  )
                ) AND
                prednisolone_last_year_3 >= 2

            """,
        },
        return_expectations={"category": {"ratios": {"0": 0.8, "1": 0.1, "2": 0.1}},},
        recent_asthma_code_3=patients.with_these_clinical_events(
            asthma_codes, between=["2017-04-12", "2020-04-12"],
        ),
        asthma_code_ever_3=patients.with_these_clinical_events(asthma_codes),
        copd_code_ever_3=patients.with_these_clinical_events(
            chronic_respiratory_disease_codes
        ),
        prednisolone_last_year_3=patients.with_these_medications(
            pred_codes,
            between=["2019-04-12", "2020-04-12"],
            returning="number_of_matches_in_period",
        ),
    ),

    # Time-updated: Most recent creatinine as of 11 May 2020
    asthma_severity_4=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                (
                  recent_asthma_code_4 OR (
                    asthma_code_ever_4 AND NOT
                    copd_code_ever_4
                  )
                ) AND (
                  prednisolone_last_year_4 < 2
                )
            """,
            "2": """
                (
                  recent_asthma_code_4 OR (
                    asthma_code_ever_4 AND NOT
                    copd_code_ever_4
                  )
                ) AND
                prednisolone_last_year_4 >= 2

            """,
        },
        return_expectations={"category": {"ratios": {"0": 0.8, "1": 0.1, "2": 0.1}},},
        recent_asthma_code_4=patients.with_these_clinical_events(
            asthma_codes, between=["2017-05-11", "2020-05-11"],
        ),
        asthma_code_ever_4=patients.with_these_clinical_events(asthma_codes),
        copd_code_ever_4=patients.with_these_clinical_events(
            chronic_respiratory_disease_codes
        ),
        prednisolone_last_year_4=patients.with_these_medications(
            pred_codes,
            between=["2019-05-11", "2020-05-11"],
            returning="number_of_matches_in_period",
        ),
    ),


    ### COMORBIDITIES - FIRST DIAGNOSIS DATE

    # RESPIRATORY - ASTHMA, CYSTIC FIBROSIS, OTHER (largely COPD)
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/55
    chronic_respiratory_disease=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    # CARDIAC - CARDIAC DISEASE, DIABETES
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/7
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    # ATRIAL FIBRILLATION
    af=patients.with_these_clinical_events(
        af_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    # PVD
    pvd=patients.with_these_clinical_events(
        pvd_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    # ADD DEEP VEIN THROMBOSIS/PULMONARY EMBOLISM HERE WHEN READY

    # Diabetes
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/30
    diabetes=patients.with_these_clinical_events(
        diabetes_codes,
        on_or_before="2020-06-07",
        return_first_date_in_period=True,
        include_month=True,
    ),
    # Hypertension
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/23
    hypertension=patients.with_these_clinical_events(
        hypertension_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    # STROKE, DEMENTIA, OTHER NEUROLOGICAL
    stroke=patients.with_these_clinical_events(
        stroke,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    dementia=patients.with_these_clinical_events(
        dementia,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/14
    other_neuro=patients.with_these_clinical_events(
        other_neuro,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    # CANCER
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/32
    lung_cancer=patients.with_these_clinical_events(
        lung_cancer_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    haem_cancer=patients.with_these_clinical_events(
        haem_cancer_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    other_cancer=patients.with_these_clinical_events(
        other_cancer_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    # LIVER DISEASE, DIALYSIS AND TRANSPLANT
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/12
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    transplant_notkidney=patients.with_these_clinical_events(
        transplant_notkidney_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),

    # SPLEEN PROBLEMS, HIV, IMMUNODEFICIENCY
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/13
    dysplenia=patients.with_these_clinical_events(
        spleen_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    sickle_cell=patients.with_these_clinical_events(
        sickle_cell_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    hiv=patients.with_these_clinical_events(
        hiv_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    permanent_immunodeficiency=patients.with_these_clinical_events(
        permanent_immune_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    # # https://github.com/ebmdatalab/tpp-sql-notebook/issues/49
    ra_sle_psoriasis=patients.with_these_clinical_events(
        ra_sle_psoriasis_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    # Inflammatory bowel disease
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/50
    ibd=patients.with_these_clinical_events(
        inflammatory_bowel_disease_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    # Severe Mental Illness
    smi=patients.with_these_clinical_events(
        smi_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),
    # ADD INTELLECTUAL DISABILITY HERE WHEN READY

    # Frailty - osteoporosis
    osteo=patients.with_these_clinical_events(
        osteo_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-07",
        include_month=True,
    ),


    ### TRANSIENT COMORBIDITIES - MOST RECENT DIAGNOSIS DATE

    # Aplastic anaemia and temporary immunosuppression
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/36
    aplastic_anaemia_1=patients.with_these_clinical_events(
        aplastic_codes,
        return_last_date_in_period=True,
        between=["2019-03-01", "2020-03-01"],
        include_month=True,
    ),
    temporary_immunodeficiency_1=patients.with_these_clinical_events(
        temp_immune_codes,
        return_last_date_in_period=True,
        between=["2019-03-01", "2020-03-01"],
        include_month=True,
    ),
    # Time update: Aplastic anaemia as of 1 April 2020
        aplastic_anaemia_2=patients.with_these_clinical_events(
        aplastic_codes,
        return_last_date_in_period=True,
        between=["2019-04-01", "2020-04-01"],
        include_month=True,
    ),
    temporary_immunodeficiency_2=patients.with_these_clinical_events(
        temp_immune_codes,
        return_last_date_in_period=True,
        between=["2019-04-01", "2020-04-01"],
        include_month=True,
    ),
    # Time update: Aplastic anaemia as of 12 April 2020
    aplastic_anaemia_3=patients.with_these_clinical_events(
        aplastic_codes,
        return_last_date_in_period=True,
        between=["2019-04-12", "2020-04-12"],
        include_month=True,
    ),
    temporary_immunodeficiency_3=patients.with_these_clinical_events(
        temp_immune_codes,
        return_last_date_in_period=True,
        between=["2019-04-12", "2020-04-12"],
        include_month=True,
    ),
    # Time update: Aplastic anaemia as of 11 May 2020
    aplastic_anaemia_4=patients.with_these_clinical_events(
        aplastic_codes,
        return_last_date_in_period=True,
        between=["2019-05-11", "2020-05-11"],
        include_month=True,
    ),
    temporary_immunodeficiency_4=patients.with_these_clinical_events(
        temp_immune_codes,
        return_last_date_in_period=True,
        between=["2019-05-11", "2020-05-11"],
        include_month=True,
    ),
    # Fragility fracture in last year
    fracture_1=patients.with_these_clinical_events(
        fracture_codes,
        return_last_date_in_period=True,
        between=["2019-03-01", "2020-03-01"],
        include_month=True,
    ),
    # Time update: Fragility fracture as of 1 April 2020
    fracture_2=patients.with_these_clinical_events(
        fracture_codes,
        return_last_date_in_period=True,
        between=["2019-04-01", "2020-04-01"],
        include_month=True,
    ),
    # Time update: Fragility fracture as of 12 April 2020
    fracture_3=patients.with_these_clinical_events(
        fracture_codes,
        return_last_date_in_period=True,
        between=["2019-04-12", "2020-04-12"],
        include_month=True,
    ),
    # Time update: Fragility fracture as of 11 May 2020
    fracture_4=patients.with_these_clinical_events(
        fracture_codes,
        return_last_date_in_period=True,
        between=["2019-05-11", "2020-05-11"],
        include_month=True,
    ),


    #  KIDNEY TRANSPLANT AND DIALYSIS (most recent)
    #  https://github.com/ebmdatalab/tpp-sql-notebook/issues/31
    transplant_kidney_1=patients.with_these_clinical_events(
        transplant_kidney_codes,
        return_last_date_in_period=True,
        on_or_before="2020-03-01",
        include_month=True,
    ),
    dialysis_1=patients.with_these_clinical_events(
        dialysis_codes,
        return_first_date_in_period=True,
        on_or_before="2020-03-01",
        include_month=True,
    ),
    # Time-update: Most recent kidney transplant and dialysis as of 1 April
    transplant_kidney_2=patients.with_these_clinical_events(
        transplant_kidney_codes,
        return_last_date_in_period=True,
        on_or_before="2020-04-01",
        include_month=True,
    ),
    dialysis_2=patients.with_these_clinical_events(
        dialysis_codes,
        return_first_date_in_period=True,
        on_or_before="2020-04-01",
        include_month=True,
    ),
    # Time-update: Most recent kidney transplant and dialysis as of 12 April
    transplant_kidney_3=patients.with_these_clinical_events(
        transplant_kidney_codes,
        return_last_date_in_period=True,
        on_or_before="2020-04-12",
        include_month=True,
    ),
    dialysis_3=patients.with_these_clinical_events(
        dialysis_codes,
        return_first_date_in_period=True,
        on_or_before="2020-04-12",
        include_month=True,
    ),
    # Time-update: Most recent kidney transplant and dialysis as of 11 May
    transplant_kidney_4=patients.with_these_clinical_events(
        transplant_kidney_codes,
        return_last_date_in_period=True,
        on_or_before="2020-05-11",
        include_month=True,
    ),
    dialysis_4=patients.with_these_clinical_events(
        dialysis_codes,
        return_first_date_in_period=True,
        on_or_before="2020-05-11",
        include_month=True,
    ),


)
