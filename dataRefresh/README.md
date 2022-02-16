# Data Refresh


This repository contains:

- **R**
  - `dataRefresh.Rmd` : R and SQL code to regenerate the required data for running the pipelines. It requires as input having an updated list of patient IDs (study ID and mapping) and admission and discharge date for the first study admission.
  - `elt_during_refresh.Rmd` : R code, same as `elt_during.Rmd` to get the medication during hospitalization output for REDCap. It contains some additional code to ONLY get the data for the new patients added, and a QC step to check that nothing changed for the previous patients.  


- **local_ref**

  *This directory is not tracked by GitHub; it contains patient-level data intermediates and outputs. Some scripts may reference it, you may want to create a corresponding directory in your local copy of the repository.*
  - `ag440_music_labs_feb22.csv` : Lab patient level data extracted from BCH database
  - `ag440_music_meds_feb22.csv` : Meds patient level data extracted from BCH database
  - `concept_dimensionLabs_feb22.csv` and `concept_dimensionMeds_feb22.csv` : Concepts data extracted from BCH database for QC
  - `music_patients_feb22.csv` : Patient list received from the clinicians 

