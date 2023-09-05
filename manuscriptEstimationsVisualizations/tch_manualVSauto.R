############################
##### Load R libraries #####
############################
library(dplyr)

######################
##### Load files #####
######################
# tch automatic file generated with our etl pipeline
auto_tch <- read.csv('../../laboratory_values/local_ref/lab_output_texas.csv', colClasses ="character")

# tch manual file downloaded from GitHub and located in the local ref folder, in the texas children subfolder
manual_tch <- read.csv("../../laboratory_values/local_ref/texasChildren/MUSIC_DATA_2023-09-01_1508.csv", colClasses =  "character") %>%
  filter( record_id %in% auto_tch$record_id ) #filtering by the common patients


# MUSIC data dictionary from the general common_ref folder
datadict <- read.csv('../../common_ref/MUSIC_DataDictionary_V3_4Dec20_final version_clean_0.csv')


#######################################
##### Laboratory values selection #####
#######################################
datadict <- datadict %>% 
  dplyr::filter(Form.Name == "laboratory_values") 

manual_tch <- manual_tch %>%
  dplyr::filter( redcap_repeat_instrument == "laboratory_values")

auto_tch <- auto_tch %>%
  dplyr::filter( redcap_repeat_instrument == "laboratory_values")

### Transform the data dictionary laboratory values do remove the "other" variables 
datadict <- datadict %>%
  dplyr::select( "Variable...Field.Name",  "Form.Name" )%>%
  dplyr::mutate( type = sapply(strsplit( Variable...Field.Name, "_"), tail, 1), 
               var_name = gsub( "_", " ", sub('[_][^_]+$', ' ', Variable...Field.Name)), 
               var_other = sapply(strsplit( Variable...Field.Name, "_"), head, 1), 
               var_other = gsub("other1", "other", var_other), 
               var_other = gsub("other2", "other", var_other), 
               var_other = gsub("other3", "other", var_other), 
               var_other = gsub("other4", "other", var_other), 
               var_other = gsub("other5", "other", var_other)
               ) %>% 
  dplyr::filter( var_other != "other")


#################################################################################
##### Select automatic filling variables from the auto and manual TCH files #####
#################################################################################
# in both cases we create a id that is a combination of the patient id and the lab_values_visit

manual_tch <- manual_tch %>%
  dplyr::select( c("record_id", datadict$Variable...Field.Name) ) %>%
  dplyr::mutate( id=paste0( record_id, "-",lab_values_visit)) %>%
  dplyr::select( -record_id, - lab_values_na, - lab_values_visit ) 

manual_tch <- manual_tch %>% # remove columns that are not needed
  tidyr::pivot_longer( cols = c(1:ncol( manual_tch) - 1), 
                       names_to = "variable", 
                       values_to = "value_manual") %>%
  dplyr::filter( value_manual != "") 

auto_tch <-  auto_tch %>%
  dplyr::mutate( id=paste0( record_id, "-",lab_values_visit)) %>%
  dplyr::select( -record_id, -lab_values_visit, - redcap_event_name, - redcap_repeat_instrument,-redcap_repeat_instance ) # remove columns that are not needed

auto_tch <- auto_tch %>%
  tidyr::pivot_longer( cols = c(1:ncol(auto_tch)-1), 
                       names_to = "variable", 
                       values_to = "value_auto") %>%
  dplyr::filter( value_auto != "") 

# select in the manual only the variables that we can automatically extract 
nrow(manual_tch)
manual_tch <- manual_tch %>%
  dplyr::filter( variable %in% auto_tch$variable )
nrow(manual_tch)

###################################################################
##### Merge auto and manual extraction to get the performance #####
###################################################################
# merge both files by the id we have created and the variable name
manualVsauto <- full_join( manual_tch, auto_tch, by =c("id", "variable"))

#re-format dates
#changing NA auto values to 0 when manual is 0 and auto is NA 
manualVsauto <- manualVsauto %>%
  dplyr::mutate( type = sapply(strsplit( variable, "_"), tail, 1),
                 value_auto =  ifelse( type == "date",  
                               as.character( as.Date( value_auto, format = "%m/%d/%Y")),
                               value_auto), 
                 value_manual = as.character( trimws( value_manual)), 
                 value_auto = as.character( trimws( value_auto)), 
                 value_auto = ifelse( value_manual == 0 & is.na(value_auto), 0, value_auto ),
                 concordance = ifelse( value_manual == value_auto, "same", "different"))

results <- summary(as.factor( manualVsauto$concordance))
results
round(as.numeric(100* results["same"]/(results["same"]+results["different"])), 2)

# identify the differences 
differences <- manualVsauto %>% 
  dplyr::mutate( concordance = ifelse( is.na( concordance), "different", concordance)) %>%
  dplyr::filter( concordance != "same" )

# adding info vs. missing info
adding_info <- differences %>%
  dplyr::filter( is.na( value_manual ))
nrow(adding_info)

missing_info <- differences %>%
  dplyr::filter( is.na( value_auto ))

nrow( missing_info)

# evaluate the obtained differences
# in how many cases the automatic extraction found a value that was not entered manual and vice-versa
obtained_differences <- missing_info %>%
  dplyr::filter( type == "obtained" ) %>%
  dplyr::mutate( visit_num = sapply(strsplit( id, "-"), tail, 1),
                 patient_num = sapply(strsplit( id, "-"), head, 1))

summary(as.factor( obtained_differences$visit_num))

visit <- obtained_differences %>% filter( visit_num == 6)
summary(as.factor(visit$variable))


dates_differences <- differences %>%
  dplyr::filter( type == "date" ) %>%
  dplyr::mutate( days_dif = as.Date(value_manual) - as.Date(value_auto))
summary(as.numeric( dates_differences$days_dif))

##############################
##### Add the statistics #####
##############################
# binomial test
# proportions and 95% CI 

#remmove everything from the environment 
rm(list=ls())

#########################
##### Re-Load files #####
#########################
# tch automatic file generated with our etl pipeline
auto_tch <- read.csv('../../medications_during/local_ref/tch_medications_during.csv', colClasses ="character")

# tch manual file downloaded from GitHub and located in the local ref folder, in the texas children subfolder
manual_tch <- read.csv("../../laboratory_values/local_ref/texasChildren/MUSIC_DATA_2023-09-01_1508.csv", colClasses =  "character") %>%
  filter( record_id %in% auto_tch$record_id ) #filtering by the common patients


# MUSIC data dictionary from the general common_ref folder
datadict <- read.csv('../../common_ref/MUSIC_DataDictionary_V3_4Dec20_final version_clean_0.csv')


#######################################
##### Medication values selection #####
#######################################
datadict <- datadict %>% 
  dplyr::filter(Form.Name == "additional_medications_during_hospitalization") 

manual_tch <- manual_tch %>%
  dplyr::filter( redcap_repeat_instrument == "additional_medications_during_hospitalization")

auto_tch <- auto_tch %>%
  dplyr::filter( redcap_repeat_instrument == "additional_medications_during_hospitalization")

###########################################
##### Transform the tables to compare #####
###########################################
auto_tch <-  auto_tch %>%
  dplyr::mutate( id=paste0( record_id, "-",redcap_repeat_instance)) %>%
  dplyr::select( -record_id, -redcap_repeat_instance, - redcap_event_name, - redcap_repeat_instrument,-redcap_repeat_instance ) # remove columns that are not needed

auto_tch <- auto_tch %>%
  tidyr::pivot_longer( cols = c(1:ncol(auto_tch)-1), 
                       names_to = "variable", 
                       values_to = "value_auto") %>%
  dplyr::filter( value_auto != "") 

manual_tch <- manual_tch %>%
  dplyr::select( c("record_id", "redcap_repeat_instance", datadict$Variable...Field.Name) ) %>%
  dplyr::mutate( id=paste0( record_id, "-",redcap_repeat_instance)) %>%
  dplyr::select( -record_id, -redcap_repeat_instance ) 

manual_tch <- manual_tch %>% # remove columns that are not needed
  tidyr::pivot_longer( cols = c(1:ncol( manual_tch) - 1), 
                       names_to = "variable", 
                       values_to = "value_manual") %>%
  dplyr::filter( value_manual != "") 




###################################################################
##### Merge auto and manual extraction to get the performance #####
###################################################################
# merge both files by the id we have created and the variable name
manualVsauto <- full_join( manual_tch, auto_tch, by =c("id", "variable"))

# if manual is 0 and auto is NA transform NA into 0
manualVsauto <- manualVsauto %>%
  dplyr::mutate( type = sapply(strsplit( variable, "_"), tail, 1), 
                 value_manual = as.character( trimws( value_manual)), 
                 value_auto = as.character( trimws( value_auto)), 
                 value_auto = ifelse( value_manual == 0 & is.na(value_auto), 0, value_auto ),
                 concordance = ifelse( value_manual == value_auto, "same", "different")) %>%
  dplyr::filter( type !=  "name")

results <- summary(as.factor( manualVsauto$concordance))
results
round(as.numeric(100* results["same"]/(results["same"]+results["different"])), 2)

