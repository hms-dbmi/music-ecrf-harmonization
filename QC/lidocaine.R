library(tidyverse)
library(lubridate)

# latest redcap prod 
redcap <- read.csv("../local_ref//MUSIC_DATA_2022-03-22_1920.csv") %>%
  filter( 
    #redcap_repeat_instance == 1, 
          redcap_repeat_instrument == "additional_medications_during_hospitalization")%>%
  select( record_id, redcap_event_name, redcap_repeat_instrument, redcap_repeat_instance, medhosp1_code_antiarr ) %>%
  unique()

redcap_lidocaine <- redcap %>%
  filter( !is.na( medhosp1_code_antiarr) )

misc_mapping <- read.csv("../dataRefresh/local_ref/music_id_mapping_feb22.csv") %>%
  filter( MUSIC_ID %in% redcap_lidocaine$record_id )


bch_med_concept_summary <- read_csv('../medications_before_and_after/data/bch_med_concept_summary_toReview.csv') %>%
  filter( ECRF_CODE == "02.09") %>%
  select( CONCEPT_CD, BCH_CONCEPT_DESCRIPTION, MEDICATION_ROUTE ) %>%
  unique()

df <- read.delim('../dataRefresh/local_ref/ag440_music_meds_feb22.dsv') %>%
  filter( PATIENT_NUM %in% misc_mapping$PAT_NUM , 
          CONCEPT_CD %in% bch_med_concept_summary$CONCEPT_CD ) %>%
  mutate( START_DATE = dmy(sapply(strsplit( as.character(START_DATE), " "), '[', 1))) %>%
  select( PATIENT_NUM, CONCEPT_CD, START_DATE, ADMISSIONDATE, DISCHARGE_DATE ) %>%
  unique() %>%
  left_join( bch_med_concept_summary )
  

lidocaine_topical <- df %>%
  filter( MEDICATION_ROUTE != "IV") %>%
  left_join( misc_mapping, by =  c("PATIENT_NUM" = "PAT_NUM"))
  
lidocaine_iv <- df %>%
  filter( MEDICATION_ROUTE == "IV") %>%
  left_join( misc_mapping, by =  c("PATIENT_NUM" = "PAT_NUM"))
