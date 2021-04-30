rm(list=ls())
############################
## Libraries installation ##
############################
library(curl)
library(devtools)
library(DBI)
library(ROracle)
library(data.table)
library(plyr)
library(tidyr)
library(scales)
library(readxl)
library(tidyverse)
library(dplyr)

###########################
## Set up the connection ##
###########################
# con <- dbConnect(drv, "user-id", "password", dbname="dbhostnameorIP[:port]/dbservice")
source("connection.R")

miscPatients <- dbGetQuery( con, "select * from sa_diag_mis_c_patients")
miscPatients <- miscPatients[, c("PATIENT_NUM", "ADMISSION_DATE", "DISCHARGE_DATE")]

lab_dictionary <- read.delim("MUSIC/labDictionary.txt", header = TRUE)

patients <- paste( miscPatients$PATIENT_NUM, collapse = "','")
concepts <- paste(lab_dictionary$concept_cd, collapse = "','")

subset_df <- dbGetQuery( con, paste0("select obs.patient_num, obs.concept_cd, obs.start_date, obs.tval_char, 
                                    obs.nval_num, obs.units_cd, pat.admission_date, pat.discharge_date 
                                    from observation_fact obs, 
                                    sa_diag_mis_c_patients pat 
                                    where obs.patient_num = pat.patient_num and 
                                     obs.concept_cd in ('", concepts, "') and 
                                     obs.start_date >= pat.admission_date" ))

subset_df$date <- sapply(strsplit( as.character(subset_df$START_DATE), " "), '[', 1)
subset_df$time <- sapply(strsplit( as.character(subset_df$START_DATE), " "), '[', 2)

finalTable <- left_join( subset_df, lab_dictionary, by = c("CONCEPT_CD" = "concept_cd") )
finalTable$date <- as.Date( finalTable$date)
finalTable$ADMISSION_DATE <- as.Date( finalTable$ADMISSION_DATE)
finalTable$DISCHARGE_DATE <- as.Date( finalTable$DISCHARGE_DATE)
finalTable$days_after_admission <- finalTable$date - finalTable$ADMISSION_DATE
finalTable$days_after_discharge <- finalTable$date - finalTable$DISCHARGE_DATE

#a. Admission/first obtained during MIS-C hospitalization
#b. Closest to discharge during MIS-C hospitalization
#c. Worst values (highest or lowest depending on lab) during MIS-C hospitalization
#d. 2 week visit
#e. 6 week visit
#f. 6 month visit
#g. Hospital readmission (worst values)

group_A <- finalTable %>% 
  group_by(PATIENT_NUM, variableName) %>%
  filter(START_DATE == min(START_DATE)) %>%
  mutate(metadata_column_ifany = 'a')


group_A$value <- ifelse( is.na( group_A$NVAL_NUM ),tolower( group_A$TVAL_CHAR), group_A$NVAL_NUM )
group_A$UNITS_CD <- ifelse( is.na( group_A$NVAL_NUM ), NA, group_A$UNITS_CD )
group_A$value <- ifelse( group_A$value %in% c("tnp", "not performed"), "test not performed", group_A$value ) 

group_A <- group_A[ , c("PATIENT_NUM", "variableName", "CONCEPT_CD", "value", "UNITS_CD", "date", "time", "metadata_column_ifany")]
group_A$obtained <- 'Y'
group_A$site_id <- 'BCH'

group_A_value <- group_A[ , c("PATIENT_NUM", "variableName", "value", "metadata_column_ifany", "site_id")]
group_A_value$variableName <- paste0(str_replace(group_A_value$variableName, '_obtained', ''), '_value')

group_A_obtained <- group_A[ , c("PATIENT_NUM", "variableName", "obtained", "metadata_column_ifany", "site_id")]
colnames( group_A_obtained ) <- c("PATIENT_NUM", "variableName", "value", "metadata_column_ifany", "site_id")


group_A_date <- group_A[ , c("PATIENT_NUM", "variableName", "date", "metadata_column_ifany", "site_id")]
group_A_date$variableName <- paste0(str_replace(group_A_date$variableName, '_obtained', ''), '_date')
colnames( group_A_date ) <- c("PATIENT_NUM", "variableName",  "value", "metadata_column_ifany", "site_id")
group_A_date$value <- as.character( group_A_date$value )

group_A_unit <- group_A[ , c("PATIENT_NUM", "variableName", "UNITS_CD", "metadata_column_ifany", "site_id")]
group_A_unit$variableName <- paste0(str_replace(group_A_unit$variableName, '_obtained', ''), '_unit')
colnames( group_A_unit ) <- c("PATIENT_NUM", "variableName", "value", "metadata_column_ifany", "site_id")


output <- bind_rows( group_A_obtained, group_A_value, group_A_unit, group_A_date)
output <- unique( output[ order( output$PATIENT_NUM, output$variableName), ] )

