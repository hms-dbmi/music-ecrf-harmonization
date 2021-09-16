###########################################################
## SQL query to generate the patient's table information ##
###########################################################
#create table ag440_misc_patients_september as 
#select m.mrn, mp.PAT_NUM as PATIENT_NUM, m.ADMISSION_DATE_FORMATTED as ADMISSIONDATE, m.DISCHARGE_DATE_FORMATTED, v.START_DATE, v.END_DATE, 
#m.ADMISSION_DATE_FORMATTED -1 as datemin,  m.ADMISSION_DATE_FORMATTED + 1 as datemax, v.inout_cd, v.length_of_stay 
#from MUSIC_PATIENTSLIST_SEPTEMBER m, MRN_PATUUID_PATNUM mp, visit_dimension v where m.MRN =  mp.MRN and mp.PAT_NUM =  v.patient_num and 
#v.start_date >= m.ADMISSION_DATE_FORMATTED -1  and v.start_date <= m.ADMISSION_DATE_FORMATTED +1 and 
#v.END_DATE >= m.DISCHARGE_DATE_FORMATTED -1  and v.END_DATE <= m.DISCHARGE_DATE_FORMATTED +1 and 
#v.inout_cd = 'Inpatient';

########################################################
## SQL query to generate the patient's timeline table ##
########################################################
#create table misc_patient_timeline as
#select mp.PAT_NUM as PATIENT_NUM, m.ADMISSION_DATE_FORMATTED as ADMISSIONDATE, v.START_DATE, v.END_DATE,  
#m.ADMISSION_DATE_FORMATTED -1 as datemin,  m.ADMISSION_DATE_FORMATTED + 1 as datemax, 
#v.inout_cd, v.length_of_stay, v.location_path 
#from MUSIC_PATIENTSLIST_SEPTEMBER m, MRN_PATUUID_PATNUM mp, visit_dimension v 
#where m.MRN =  mp.MRN and mp.PAT_NUM =  v.patient_num 
#and v.start_date >= m.ADMISSION_DATE_FORMATTED -1 order by mp.PAT_NUM, v.START_DATE;  

###########
## Labs ##
##########
lab_dictionary <- read.delim("../data/labDictionary.txt", header = TRUE, sep = ' ')
query_first_part <- "select obs.patient_num, obs.concept_cd, obs.start_date, obs.tval_char, 
  obs.nval_num, obs.units_cd, pat.admission_date, pat.discharge_date 
  from observation_fact obs, 
  ag440_misc_patients_september pat 
  where obs.patient_num = pat.patient_num and 
  obs.concept_cd in ('"
query_second_part <- "') and obs.start_date >= pat.admission_date"
bch_codes <- paste0(lab_dictionary$concept_cd, collapse = "', '")
lab_query <- paste0(query_first_part, bch_codes, query_second_part)


###########
## Meds ##
##########
bch_med_concept_summary <- read_csv('../data/bch_med_concept_summary_toReview.csv')
query_a <- "select obs.patient_num, obs.concept_cd, obs.start_date, misc.admissiondate, misc.end_date, misc.length_of_stay from observation_fact obs, ag440_misc_patients_september misc where (concept_cd in ('"
query_b <- "')) and obs.patient_num = misc.patient_num;"
bch_codes <- paste0(bch_med_concept_summary$CONCEPT_CD, collapse = "', '")
query <- paste0(query_a, bch_codes, query_b)
query

### SQL query to have a table with all the medication info, including med_route, in MISC patients
#create table ag440_music_meds as 
#select obs.patient_num, obs.concept_cd, obs.modifier_cd, obs.tval_char, obs.start_date, misc.start_date as admissiondate, misc.end_date, misc.length_of_stay 
#from observation_fact obs, ag440_misc_patients_september misc 
#where (concept_cd like 'HOMEMED:%' or concept_cd like 'ADMINMED:%' or concept_cd like 'AG:%') 
#and modifier_cd = 'MED:ROUTE'
#and obs.patient_num = misc.patient_num;
