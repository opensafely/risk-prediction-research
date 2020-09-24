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
        (age >=0 AND age <= 105)
        AND alive_at_cohort_start
        """,
        age=patients.age_as_of(
            "2020-03-01",
            return_expectations={
                "rate": "universal",
                "int": {"distribution": "population_ages"},
            },
        ),
        alive_at_cohort_start=patients.registered_with_one_practice_between(
            "2020-02-29", "2020-03-01"
        ),
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
    covid_suspected=patients.with_these_clinical_events(
        covid_suspected_codes,
        returning="date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-03-01"},
            "category": {"ratios": {"XaaNq": 0.5, "Y20cf": 0.5}},
        },
    ),
)
