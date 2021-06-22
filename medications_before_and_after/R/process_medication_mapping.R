# This code is used to convert the list of medication mapping found in eCRF to BCH mapping_ medications - medications_before_and_after_hosp.csv into a list of concepts to test query

library(tidyverse)
data <- read.csv('../data/eCRF to BCH mapping_ medications - medications_before_and_after_hosp.csv')

subdf <- data %>% 
  filter(Notes == '') %>%
  select(Variable...Field.Name,concept_cd,expected.value,expected.value.description)

sample_subdf <- sample_n(subdf, 50, replace = FALSE)

sample_concepts <- sample_subdf %>% pull(concept_cd) %>% paste0(collapse = "', '")

sample_query <- paste0("select obs.patient_num, obs.concept_cd, obs.start_date, obs.tval_char, obs.nval_num, obs.units_cd, pat.admission_date, pat.discharge_date 
  from observation_fact obs, sa_diag_mis_c_patients pat 
  where obs.patient_num = pat.patient_num 
  and obs.concept_cd in ('", 
                       sample_concepts, 
                       "');")
                       
#                       "') and obs.start_date >= pat.admission_date;")    # note: this line has been commented out. the medications are listed before admission date...
                    
write.table(sample_query, '../local_ref/initial_extraction.sql.txt', row.names = FALSE, quote = FALSE, col.names = FALSE)
