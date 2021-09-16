# Medications During Hospitalization eCRF

This repository contains the files and code used to extract and transform MUSIC participant data for REDCap import.

Steps:

1. Use eCRF to RXNORM mapping file created by medications_before_and_after
  - music-ecrf-harmonization/medications_before_and_after/data/ecrf_to_rxnorm_mapping.csv
  - note: this step only needs to be run once

2. Use eCRF to BCH site-specific code mapping created by medications_before_and_after
  - code: map_eCRF_to_BCH.Rmd
  - file location: music-ecrf-harmonization/medications_before_and_after/data/
  - bch_med_concept_summary_toReview.csv, bch_med_concept_summary_with_concept_paths.csv,  ecrf_med_concept_summary_toReview.csv

3. ETL: extract data by querying database using specified site-specific codes, transform to meet REDCap specifications, and prepare for loading into REDCap.
   - code: etl.Rmd
   - input: agg40_music_meds_filtered.csv, bch_med_concept_summary_toReview.csv
   - output: redcap_output_medications_during.csv
