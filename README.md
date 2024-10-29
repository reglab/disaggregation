# Enabling Data Disaggregation of Asian American Subgroups: A Dataset of Wikidata Names for Race Imputation
This repository contains code and data related to our work on using Wikidata to derive name-race distributions for race imputation of Asian American subgroups. Please reach out to Derek Ouyang at douyang1@stanford.edu with any questions or feedback.

# Quick Start Guide
If you would like perform predictions on your own data immediately, the best place to start is [notebooks/0_starter_code.Rmd](https://github.com/reglab/disaggregation/blob/main/notebooks/0_starter_code.Rmd). 

The two key data files we generated through this work are:

- [data/name_race_data/disagg_name_priors_main.rda](https://github.com/reglab/disaggregation/blob/main/data/name_race_data/disagg_name_priors_main.rda): contains multiple dataframes like `p_race_given_surname`.
- [data/geography/geo_race_table.rds](https://github.com/reglab/disaggregation/blob/main/data/geography/geo_race_table.rds): a list object containing multiple dataframes like `p_county_given_race`.

These are also available at Harvard Dataverse: https://doi.org/10.7910/DVN/LEOECM

# Full File Structure

## notebooks

- [0_starter_code.Rmd](https://github.com/reglab/disaggregation/blob/main/notebooks/0_starter_code.Rmd): A template for users to prepare their own data and perform predictions.
- [1_run_wqs.Rmd](https://github.com/reglab/disaggregation/blob/main/notebooks/1_run_wqs.Rmd): Generates the raw Wikidata queries. See `scripts/subgroup_queries.json`, `scripts/wikidata_query_helper_functions.R`, and `data/raw_wikidata/`.
- [2_process_wiki_result.Rmd](https://github.com/reglab/disaggregation/blob/main/notebooks/2_process_wiki_result.Rmd): Processes the raw Wikidata queries into first name and surname lists. See `scripts/name_cleaning_helper_functions.R`, `external_data/`, and `data/intermediate_data/`.
- [3_process_ipums.Rmd](https://github.com/reglab/disaggregation/blob/main/notebooks/3_process_ipums.Rmd): Processes the raw IPUMS extracts into first name and surname lists. See `external_data/` and `data/intermediate_data/`.
- [4_create_disagg_geo_tables.Rmd](https://github.com/reglab/disaggregation/blob/main/notebooks/4_create_disagg_geo_tables.Rmd): Processes raw American Community Survey data into geography-race tables. See `external_data/` and `data/geography/`.
- [5_create_name_prior_tables.Rmd](https://github.com/reglab/disaggregation/blob/main/notebooks/5_create_name_prior_tables.Rmd): Processes first name and surname lists into name-race tables. See `scripts/name_table_helper_functions.R` and `data/name_race_data/`.
- [6_validate_afc.Rmd](https://github.com/reglab/disaggregation/blob/main/notebooks/6_validate_afc.Rmd): Conducts the validation on EHR data presented in the paper. Note that the EHR data itself is not publicly available. See `scripts/imputation_helper_functions.R` and `output/results/`. 
- [7_create_results.Rmd](https://github.com/reglab/disaggregation/blob/main/notebooks/7_create_results.Rmd): Produces the figures and tables presented in the paper. See `output/figures/`.

## scripts

- [subgroup_queries.json](https://github.com/reglab/disaggregation/blob/main/scripts/subgroup_queries.json)
- [wikidata_query_helper_functions.R](https://github.com/reglab/disaggregation/blob/main/scripts/wikidata_query_helper_functions.R)
- [name_table_helper_functions.R](https://github.com/reglab/disaggregation/blob/main/scripts/name_table_helper_functions.R)
- [name_cleaning_helper_functions.R](https://github.com/reglab/disaggregation/blob/main/scripts/name_cleaning_helper_functions.R)
- [imputation_helper_functions.R](https://github.com/reglab/disaggregation/blob/main/scripts/imputation_helper_functions.R): Contains the key function `predict_disagg_race()`.

## external_data

- [census_surnames.rds](https://github.com/reglab/disaggregation/blob/main/external_data/census_surnames.rds): Surnames from the Census 2010 Surname list.
- [surname_census_L2.rda](https://github.com/reglab/disaggregation/blob/main/external_data/surname_census_L2.rda): Surnames from Rosenman et al., 2022: https://doi.org/10.7910/DVN/SGKW0K
- [ipums_race.xml](https://github.com/reglab/disaggregation/blob/main/external_data/ipums_race.xml) and [ipums_race.dat.gz](https://github.com/reglab/disaggregation/blob/main/external_data/ipums_race.dat.gz): Extract from IPUMS of Asian Americans from historical censuses with detailed Asian subgroup information.
- [ipums_bpl.xml](https://github.com/reglab/disaggregation/blob/main/external_data/ipums_bpl.xml) and [ipums_bpl.dat.gz](https://github.com/reglab/disaggregation/blob/main/external_data/ipums_bpl.dat.gz): Extract from IPUMS of Asian Americans from historical censuses with detailed birthplace information.
- [ipums_fbpl.xml](https://github.com/reglab/disaggregation/blob/main/external_data/ipums_fbpl.xml) and [ipums_fbpl.dat.gz](https://github.com/reglab/disaggregation/blob/main/external_data/ipums_fbpl.dat.gz): Extract from IPUMS of Asian Americans from historical censuses with detailed father's birthplace information.

There are two additional SSA name list files that can be added to `external_data/`, with the filenames below to be correctly loaded in `notebooks/6_validate_afc.Rmd` and `notebooks/7_create_results.Rmd`. In particular, these files will enable you to generate the hybrid approach described in the paper. These SAS name list files are not available for direct public download, but can be requested from the original author at lauderdale@health.bsd.uchicago.edu. 

- `external_data/SSA_Givennames.csv`
- `external_data/SSA_Surnames.csv`

## data

- [raw_wikidata/](https://github.com/reglab/disaggregation/tree/main/data/raw_wikidata): The rawest form of Wikidata query outputs as separate .rds files for each subgroup.
- [geography/](https://github.com/reglab/disaggregation/tree/main/data/geography): Geography-race information from ACS, in raw count form and as distribution tables.
- [intermediate_data/](https://github.com/reglab/disaggregation/tree/main/data/intermediate_data): Various intermediate files in the processing pipeline from raw Wikidata queries to name-race tables.
- [name_race_data/](https://github.com/reglab/disaggregation/tree/main/data/name_race_data): The final name-race tables, including alternative versions.

## output

- [results/](https://github.com/reglab/disaggregation/tree/main/output/results): Various .rds files holding the input data necessary to produce the figures in the paper.
- [figures/](https://github.com/reglab/disaggregation/tree/main/output/figures): PNG files of figures in the paper.
