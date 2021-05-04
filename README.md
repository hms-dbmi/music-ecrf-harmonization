# music-ecrf-harmonization

This repo contains:
- `labDictionary.txt` : subset of variables for testing
- `mustic_lab_values.R` : initial code for extracting internal and external tables
- `data_dictionary_extraction.Rmd`: Extract metadata from variables specific to the laboratory_values form to determine which variables to use in first iteration of MUSIC ETL
- `lab_value_etl`: Use identified variables from `data_dictionary_extraction.Rmd` to query database and reformat results to satisfy RedCap specifications
