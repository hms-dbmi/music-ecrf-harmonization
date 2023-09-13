############################
##### Load R libraries #####
############################
library(dplyr)
library(readxl)
library(lubridate)
library(ggplot2)

setwd("/Users/alba/Desktop/music-ecrf-harmonization/manuscriptEstimationsVisualizations/")

######################
##### Load files #####
######################
#for reference, SQL code to generate this data

#create table MISC_patients_data_mapped as
#select o.encounter_num, o.patient_num, o.concept_cd, o.start_date, p.mrn 
#from observation_fact o 
#inner join MRN_PATUUID_PATNUM p
#on o.patient_num = p.pat_num
#where patient_num in (select pat_num from MRN_PATUUID_PATNUM where MRN in (select MRN from MUSIC_PATIENTSLIST));

ehr_data <- read.delim("../local_ref/EHR_MUSICpatients_data.dsv")

# read one of the output files to get the 55 patients that were included
music_bch_patients_included <- read.csv("../laboratory_values/local_ref/redcap_output_laboratory_values_updated.csv")
length(unique(music_bch_patients_included$record_id))

misc_patients <- read.delim("../local_ref/MUSIC enrolled patients 9.8.2021.txt") %>%
  filter( MUSIC.ID %in% music_bch_patients_included$record_id )

#######################################################
##### Total distinct concepts and counts per type #####
#######################################################
ehr_data <- ehr_data %>%
  dplyr::mutate( type = sapply(strsplit( CONCEPT_CD, ":"), head, 1)) %>%
  dplyr::filter( MRN %in% misc_patients$MRN )

distinct_concepts <- ehr_data %>%
  dplyr::select( CONCEPT_CD, type ) %>%
  unique()

print(paste0("There are a total of ", nrow( distinct_concepts), " concepts for the MISC patients"))

by_type <- distinct_concepts %>%
  dplyr::group_by( type ) %>%
  dplyr::summarise( n = n_distinct(CONCEPT_CD), 
                    perc = round(100*n_distinct(CONCEPT_CD)/nrow(distinct_concepts), 2)) %>%
  dplyr::arrange( desc(n))

########################################################################################################
##### Amount of data over time per patient (distinguishing the study period vs. out of the period) #####
########################################################################################################
patientAdmissionDates <- read.delim("../local_ref/MUSIC enrolled patients 9.8.2021.txt")

#format the dates
patientAdmissionDates <- patientAdmissionDates %>%
  dplyr::mutate( admission_date = as.Date( Admission.Date,format = "%m/%d/%y"), 
                 discharge_date = as.Date( Discharge.Date,format = "%m/%d/%y")) %>%
  dplyr::select( -Admission.Date, -Discharge.Date )

#format the dates on the ehr extract and add admission/discharge
ehr_data_over_time <- ehr_data %>%
  dplyr::mutate( date = sapply(strsplit( START_DATE, " "), head, 1), 
                 date = as.Date( date, format = "%d-%B-%y")) %>%
  dplyr::left_join( patientAdmissionDates, by = "MRN") %>%
  dplyr::select( -ENCOUNTER_NUM, -START_DATE, -`MUSIC.ID`, -type) %>%
  unique()

# add a flag to know if each concept was during the MISC admission, or before or after
ehr_data_over_timeToPlot <- ehr_data_over_time %>%
  dplyr::filter( date > "2000-01-01") %>%
  dplyr::mutate( during_admission = ifelse( date >= admission_date & date <= discharge_date, "during", 
                                            ifelse( date < admission_date, "before", "after")), 
                 months_diff = ifelse( during_admission == "before", lubridate::interval( admission_date, date ) %/% months(1), 
                                       lubridate::interval( discharge_date, date ) %/% months(1)), 
                 value_toPlot = ifelse( during_admission == "before" & months_diff == 0, -0.5, 
                                        ifelse( during_admission == "after" & months_diff == 0, 0.5, months_diff )))

# count concepts per value and patient
concepts_month_patient <- ehr_data_over_timeToPlot %>%
  dplyr::group_by( PATIENT_NUM, value_toPlot ) %>%
  dplyr::summarise( n = n())

average_per_month <- concepts_month_patient %>%
  dplyr::group_by( value_toPlot ) %>%
  dplyr::summarise( average = mean( n ))

# plot the values in a histogram
#select 2 years before and after
average_per_monthSubset <- average_per_month %>%
  dplyr::filter( value_toPlot >= -24 & value_toPlot <= 24 ) %>%
  dplyr::mutate( period = ifelse( value_toPlot > 6, "after study period", 
                                 ifelse( value_toPlot < -0.5, "before study period", "study period")))

ggplot2::ggplot(data = average_per_monthSubset, ggplot2::aes( x = value_toPlot, y = average)) +
  ggplot2::geom_point( size = 0.1) +
  ggplot2::geom_ribbon(aes(ymin = 0, ymax = average, fill = period), alpha = 0.2) +
  ggplot2::scale_fill_manual(values = c("before study period"="darkgrey", 
                                        "study period"="blue", 
                                        "after study period"="darkgrey")) +
  ggplot2::theme_bw() + 
  ggplot2::theme(panel.border = element_blank(), 
                 panel.grid.major = element_blank(), 
                 panel.grid.minor = element_blank(), 
                 legend.position="bottom",
                 plot.title = element_text(hjust = 0.5)) +
  ggplot2::ggtitle("Average concepts in the EHR for MISC patients (per month)") +
  xlab("months") + ylab("average concepts (55 patients)")




