# Medications Before and After Hospitalization eCRF

This repository contains the files and code used to extract and transform MUSIC participant data for REDCap import.

Steps:

1. Create eCRF to RXNORM mapping file
  - code: map_eCRF_to_RXNORM.Rmd
  - input: rxnorm.dsv, CodeListD(Meds) MUSIC 9-7-20.csv, manual_keywords_eCRF_to_RXNORM.csv
  - output: ecrf_to_rxnorm_mapping.csv
  - note: this step only needs to be run once

2. Map eCRF codes to site-specific codes (example: BCH)
  - code: map_eCRF_to_BCH.Rmd
  - input: incorrect_mappings_eCRF_to_BCH.csv, MedicationsMapBCH.csv
  - output: bch_med_concept_summary_toReview.csv, bch_med_concept_summary_with_concept_paths.csv,  ecrf_med_concept_summary_toReview.csv

3. ETL: extract data by querying database using specified site-specific codes, transform to meet REDCap specifications, and prepare for loading into REDCap.
   - code: etl.Rmd
   - input: agg40_music_meds_filtered.csv, bch_med_concept_summary_toReview.csv
   - output: redcap_output_medications_before_and_after.csv
