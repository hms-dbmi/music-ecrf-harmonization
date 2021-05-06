# music-ecrf-harmonization

This repository contains:

- **R**
  - `exploringMapping.Rmd` : Check consistency of data units and ranges between BCH and eCRFs
  - `data_dictionary_extraction.Rmd`: Extract metadata from variables specific to the laboratory_values form to determine which variables to use in first iteration of MUSIC ETL
  - `lab_value_etl.Rmd`: Use identified variables from `data_dictionary_extraction.Rmd` to query database and reformat results to satisfy RedCap specifications
  - `music_lab_values.R` : Initial code for extracting internal and external tables

- **data**
  - `MUSIC_DataDictionary_V3_4Dec20_final version_clean_0.csv` : Original data dictionary from HealthCore
  - `eCRF to BCH mapping.csv` : Mapping of eCRF variable names to BCH concepts
  - `labDictionary.txt` : subset of variables for testing

- **local_ref**
  - This directory is not tracked by GitHub; it contains data intermediates and outputs.
  - Some scripts may reference it, you may want to create a corresponding directory in your local copy of the repository.
