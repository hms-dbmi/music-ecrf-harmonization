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
ehr_data <- read.delim("../local_ref/EHR_MUSICpatients_data.dsv")

#######################################################
##### Total distinct concepts and counts per type #####
#######################################################
ehr_data <- ehr_data %>%
  dplyr::mutate( type = sapply(strsplit( CONCEPT_CD, ":"), head, 1))

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
ehr_data_over_time <- ehr_data_over_time %>%
  dplyr::filter( date > "2000-01-01") %>%
  dplyr::mutate( during_admission = ifelse( date >= admission_date & date <= discharge_date, "during", 
                                            ifelse( date < admission_date, "before", "after")), 
                 months_diff = ifelse( during_admission == "before", lubridate::interval( admission_date, date ) %/% months(1), 
                                       lubridate::interval( discharge_date, date ) %/% months(1)))

# count concepts per month and patient
concepts_month_patient <- ehr_data_over_time %>%
  dplyr::group_by( PATIENT_NUM, months_diff ) %>%
  dplyr::summarise( n = n())

average_per_month <- concepts_month_patient %>%
  dplyr::group_by( months_diff ) %>%
  dplyr::summarise( average = mean( n ))

# plot the values in a histogram
average_per_month %>%
  ggplot2::ggplot(ggplot2::aes( x = months_diff, y = average)) +
  ggplot2::geom_point()



