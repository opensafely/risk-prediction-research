# OpenSAFELY Risk Prediction Repository

[View on OpenSAFELY](https://jobs.opensafely.org/lshtm/risk-prediction/)

This is a repository for the OpenSAFELY risk prediction modelling. Details of the purpose of this project can be found at the link above. The repository contains the code and configuration for the published output from this project, which can be found [here](https://diagnprognres.biomedcentral.com/articles/10.1186/s41512-022-00120-2). 

A quick summary of the contents of the repository:
* Model outputs, including charts, crosstabs, etc, are in `released_analysis_results/`
* If you are interested in how we defined our covariates, take a look at the [study definition](analysis/study_definition.py); this is written in `python`, but non-programmers should be able to understand what is going on there
* If you are interested in how we defined our code lists, look in the [codelists folder](./codelists/).
* Developers and epidemiologists interested in the code should review
[DEVELOPERS.md](./DEVELOPERS.md).

## About the OpenSAFELY framework

The OpenSAFELY framework is a secure analytics platform for
electronic health records research in the NHS.

Instead of requesting access for slices of patient data and
transporting them elsewhere for analysis, the framework supports
developing analytics against dummy data, and then running against the
real data *within the same infrastructure that the data is stored*.
Read more at [OpenSAFELY.org](https://opensafely.org).


## Licences

As standard, research projects have a MIT license.