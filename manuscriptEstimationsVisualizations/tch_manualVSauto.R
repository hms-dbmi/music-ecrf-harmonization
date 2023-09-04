############################
##### Load R libraries #####
############################
library(dplyr)

######################
##### Load files #####
######################
# tch manual file downloaded from GitHub and located in the local ref folder, in the texas children subfolder
manual_tch <- read.csv("../../laboratory_values/local_ref/texasChildren/MUSIC_DATA_2023-09-01_1508.csv", colClasses =  "character")

# tch automatic file generated with our etl pipeline
auto_tch <- read.csv('../../laboratory_values/local_ref/lab_output_texas.csv', colClasses ="character")

# MUSIC data dictionary from the general common_ref folder
datadict <- read.csv('../../common_ref/MUSIC_DataDictionary_V3_4Dec20_final version_clean_0.csv')


#######################################
##### Laboratory values selection #####
#######################################
manual_tch <- manual_tch %>%
  dplyr::filter( redcap_repeat_instrument == "laboratory_values")

auto_tch <- auto_tch %>%
  dplyr::filter( redcap_repeat_instrument == "laboratory_values")

datadict <- datadict %>% 
  dplyr::filter(Form.Name == "laboratory_values") 

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
  dplyr::select( -record_id, - lab_values_na, - lab_values_visit ) %>% # remove columns that are not needed
  tidyr::pivot_longer( cols = c(1:313), 
                       names_to = "variable", 
                       values_to = "value_manual") %>%
  dplyr::filter( value_manual != "") 

auto_tch <-  auto_tch %>%
  dplyr::mutate( id=paste0( record_id, "-",lab_values_visit)) %>%
  dplyr::select( -record_id, -lab_values_visit, - redcap_event_name, - redcap_repeat_instrument,-redcap_repeat_instance ) %>% # remove columns that are not needed
  tidyr::pivot_longer( cols = c(1:228), 
                       names_to = "variable", 
                       values_to = "value_auto") %>%
  dplyr::filter( value_auto != "") 

###################################################################
##### Merge auto and manual extraction to get the performance #####
###################################################################
# merge both files by the id we have created and the variable name
manualVsauto <- merge( auto_tch, manual_tch, by =c("id", "variable"))

#re-format dates
manualVsauto <- manualVsauto %>%
  dplyr::mutate( type = sapply(strsplit( variable, "_"), tail, 1),
                 value_auto =  ifelse( type == "date",  
                               as.character( as.Date( value_auto, format = "%m/%d/%Y")),
                               value_auto), 
                 value_manual = as.character( trimws( value_manual)), 
                 value_auto = as.character( trimws( value_auto)), 
                 concordance = ifelse( value_manual == value_auto, "same", "different"))

summary(as.factor( manualVsauto$concordance))


