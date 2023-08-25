############################
##### Load R libraries #####
############################
library(dplyr)
library(stringr)
library(fmsb)

###############################
##### Read the dictionary #####
###############################
datadict <- read.csv('../../common_ref/MUSIC_DataDictionary_V3_4Dec20_final version_clean_0.csv')

#### get the number of data points per form
perFormSummary <- as.data.frame( summary( as.factor( datadict$Form.Name)))
# change colname 
colnames(perFormSummary) <- "dataPoints"
# get a more readable form name (no _ and spaces etc)
perFormSummary$Form <- str_to_title( gsub( "_", " ", row.names( perFormSummary )) )
# remove row names
rownames(perFormSummary) <- NULL
# add two columns, one for max and one for min values (requirement for the spider plot)
perFormSummary$min <- 0
perFormSummary$max <- max( perFormSummary$dataPoints)


###############################################
##### Format the data for the spider plot #####
###############################################
# The input format is a data frame with as many columns as variables to be plot
# 3 rows:
#     - the first one with the max value (356, that is the max data points a MUSIC form has)
#     - the second one with min values (all 0s)
#     - the third one with the actual data points per form

# Since there are 47 forms in MUSIC, we will be filtering 
# to those that have at least 35 data points

# first row (max value)
perFormSummaryToPlot_max <- perFormSummary %>%
  dplyr::filter( dataPoints > 35) %>%
  dplyr::select( - dataPoints, -min ) %>%
  tidyr::pivot_wider( names_from = Form, 
                      values_from = max ) 
# second row (min value)
perFormSummaryToPlot_min <- perFormSummary %>%
  dplyr::filter( dataPoints > 35) %>%
  dplyr::select( - dataPoints, -max ) %>%
  tidyr::pivot_wider( names_from = Form, 
                      values_from = min )

# third row (actual values)
perFormSummaryToPlot <- perFormSummary %>%
  dplyr::filter( dataPoints > 35) %>%
  dplyr::select( - min, - max  ) %>%
  tidyr::pivot_wider( names_from = Form, 
                      values_from = dataPoints )


# combine the 3 of them in a single data.frame
# note that the order of the rows matters
perFormSummaryToPlot <- rbind( perFormSummaryToPlot_max, 
                               perFormSummaryToPlot_min, 
                               perFormSummaryToPlot)

# add row.names 
row.names( perFormSummaryToPlot ) <- c("max", "min", "dataPoints") 

# simplest radarchar using fmsb package
radarchart(perFormSummaryToPlot)


# to make it nicer we use the create_beautiful_radarchart function 
# extracted from here: https://www.datanovia.com/en/blog/beautiful-radar-chart-in-r-using-fmsb-and-ggplot-packages/ 
create_beautiful_radarchart <- function(data, color = "#00AFBB", 
                                        vlabels = colnames(data), vlcex = 0.7,
                                        caxislabels = NULL, title = NULL, ...){
  radarchart(
    data, axistype = 1,
    # Customize the polygon
    pcol = color, pfcol = scales::alpha(color, 0.5), plwd = 2, plty = 1,
    # Customize the grid
    cglcol = "grey", cglty = 1, cglwd = 0.8,
    # Customize the axis
    axislabcol = "grey", 
    # Variable labels
    vlcex = vlcex, vlabels = vlabels,
    caxislabels = caxislabels, title = title, ...
  )
}


# change the axis labels to see which is row value is, the color and add title
create_beautiful_radarchart( data = perFormSummaryToPlot, 
                             caxislabels = c(0, 100, 200, 300, 400), 
                             vlcex = 1,
                             color = "#E7B800", 
                             title = "Data Points Per Form")

#########################################################################
##### Lab Form: max. data points vs. per site & patient data points #####
#########################################################################

# data points per type in lab values 
# get the variable name (first part of the Variable...Field.Name)
# get the data point type (the last part of the Variable...Field.Name that specify if it is date, units, etc)
# identify the variables that are distinct than "other"
datadict <- read.csv('../../common_ref/MUSIC_DataDictionary_V3_4Dec20_final version_clean_0.csv')

datadict_labonly <- datadict %>% 
  dplyr::filter(Form.Name == "laboratory_values") %>%
  dplyr::select( "Variable...Field.Name",  "Form.Name" ) %>%
  dplyr::mutate( type = sapply(strsplit( Variable...Field.Name, "_"), tail, 1), 
                 var_name = gsub( "_", " ", sub('[_][^_]+$', ' ', Variable...Field.Name)), 
                 var_other = sapply(strsplit( Variable...Field.Name, "_"), head, 1)) 

# replace other1, other2, other3, other4 by other
datadict_labonly$var_other <- gsub("other1", "other", datadict_labonly$var_other)
datadict_labonly$var_other <- gsub("other2", "other", datadict_labonly$var_other)
datadict_labonly$var_other <- gsub("other3", "other", datadict_labonly$var_other)
datadict_labonly$var_other <- gsub("other4", "other", datadict_labonly$var_other)
datadict_labonly$var_other <- gsub("other5", "other", datadict_labonly$var_other)

# get some counts
print( paste0( "There are a total of ", 
               length(unique( datadict_labonly$var_name)), 
               " distinct lab variables") ) 

print( paste0( "There are a maximum of ", 
               length(unique( datadict_labonly$Variable...Field.Name)), 
               " data points collected for each patient in the lab form") ) 

# remove the variables that begin or end with "other"
datadict_labonly_noOther <- datadict_labonly %>%
  dplyr::filter( type != "other" & var_other != "other")

# get some counts after filtering the "other values"
print( paste0( "There are a total of ", 
               length(unique( datadict_labonly_noOther$var_name)), 
               " distinct lab variables (distinct than other") ) 

print( paste0( "There are a maximum of ", 
               length(unique( datadict_labonly_noOther$Variable...Field.Name)), 
               " data points collected for each patient in the lab form (excluding the other values)") ) 


# make some edits
#alc and anc change the type to calculated
datadict_labonly_noOther[ datadict_labonly_noOther$type == "alc", "type"] <- "Calculated"
datadict_labonly_noOther[ datadict_labonly_noOther$type == "anc", "type"] <- "Calculated"
datadict_labonly_noOther[ datadict_labonly_noOther$type == "ratio", "type"] <- "Calculated"
datadict_labonly_noOther$type <- gsub( "man",  "Manufacturer", datadict_labonly_noOther$type)
datadict_labonly_noOther$type <- gsub( "date",  "Date", datadict_labonly_noOther$type)
datadict_labonly_noOther$type <- gsub( "obtained",  "Obtained", datadict_labonly_noOther$type)
datadict_labonly_noOther$type <- gsub( "unit",  "Unit", datadict_labonly_noOther$type)
datadict_labonly_noOther$type <- gsub( "value",  "Value", datadict_labonly_noOther$type)

# get data points per subtype (unit, value, date)
lab_dataPoints <- as.data.frame( summary( as.factor( datadict_labonly_noOther$type)))
colnames(lab_dataPoints) <- "dataPoints"
lab_dataPoints$Form <- str_to_title( gsub( "_", " ", row.names( lab_dataPoints )) )
rownames(lab_dataPoints) <- NULL
lab_dataPoints$min <- 0
lab_dataPoints$max <- max( lab_dataPoints$dataPoints)

###############################################
##### Format the data for the spider plot #####
###############################################
# same steps as for the first spider plot
lab_dataPointsToPlot_max <- lab_dataPoints %>%
  dplyr::select( - dataPoints, -min ) %>%
  tidyr::pivot_wider( names_from = Form, 
                      values_from = max ) 
# second row (min value)
lab_dataPointsToPlot_min <- lab_dataPoints %>%
  dplyr::select( - dataPoints, -max ) %>%
  tidyr::pivot_wider( names_from = Form, 
                      values_from = min )

# third row (actual values)
lab_dataPointsToPlot <- lab_dataPoints %>%
  dplyr::select( - min, - max  ) %>%
  tidyr::pivot_wider( names_from = Form, 
                      values_from = dataPoints )

# combine the 3 of them in a single data.frame
# note that the order of the rows matters
lab_dataPointsToPlot <- rbind( lab_dataPointsToPlot_max, 
                               lab_dataPointsToPlot_min, 
                               lab_dataPointsToPlot)

# add row.names 
row.names( lab_dataPointsToPlot ) <- c("max", "min", "dataPoints") 

create_beautiful_radarchart( data = lab_dataPointsToPlot, 
                             caxislabels = c(0, 20, 40, 60, 80), 
                             vlcex = 0.8,
                             color = "#00AFBB", 
                             title = "Data Points Type Per Form \n (max values per patient)")



##################################################################
##### Lab Form: data points extracted for BCH (at admission) #####
##################################################################
# Read the redcap output file generated by our etl pipeline
bch_labs <- read.csv("../local_ref/redcap_output_laboratory_values_updated.csv", 
                     colClasses = "character")

# Filter by at admission ( identified by lab_values_visit)
bch_labs <- bch_labs %>%
  dplyr::filter( lab_values_visit == 1 )

# Print number of patients and number of total data points
print( paste0("There were a total of ", 
              length(unique( bch_labs$record_id)), 
              " MISC patients in BCH at the time of running the pipeline"))

vars <- colnames( bch_labs )[!  colnames( bch_labs) %in% c("record_id", "redcap_event_name", "redcap_repeat_instrument", "redcap_repeat_instance")]
print( paste0( "There are a maximum of ", 
               length(unique( vars)), 
               " data points collected for BCH MUSIC patients") ) 


# Pivot the data to do estimations
# remove empty values (should we remove obtained = 0), I did not since it was information about the patient
# add the var type and var name
bch_labs_pivot <- bch_labs %>%
  dplyr::select( -lab_values_visit, - redcap_event_name, - redcap_repeat_instrument, - redcap_repeat_instance) %>% # remove columns that are not needed
  tidyr::pivot_longer( cols = c(2:284), 
                       names_to = "variable", 
                       values_to = "value") %>%
  dplyr::filter( value != "") %>%
  dplyr::mutate( type = sapply(strsplit( variable, "_"), tail, 1), 
                 var_name = gsub( "_", " ", sub('[_][^_]+$', ' ', variable)), 
                 dp = 1) 

print( paste0( "There are a total of ", 
               nrow( bch_labs_pivot ), 
               " lab-related data points collected for BCH") ) 

### estimate average number of data points per patient (not per type)
dp_per_patient <- bch_labs_pivot %>% 
  dplyr::group_by( record_id ) %>% 
  dplyr::summarise( totals = sum(dp))

summary(dp_per_patient)

# group by record_id (patient id) and type and get the number of data points filled per type
bch_lab_dp <- bch_labs_pivot %>%
  dplyr::select( - variable, - value ) %>%
  dplyr::group_by( record_id, type ) %>%
  dplyr::summarise( total_dp = sum( dp ))

# estimate the average, min and max by type
bch_lab_dp_average <- bch_lab_dp %>%
  dplyr::group_by( type ) %>%
  dplyr::summarise( average_pat_dp = round( mean( total_dp )), 
                    min_pat_dp = round( min(total_dp)), 
                    max_pat_dp = round( max( total_dp ))) %>%
  dplyr::mutate( min = 0, 
                 max = 80)

# re-format to plot the spider plot
bch_lab_dp_ToPlot_meanPatient <- bch_lab_dp_average %>%
  dplyr::select( - min_pat_dp, -max_pat_dp, -min, -max ) %>%
  tidyr::pivot_wider( names_from = type, values_from = average_pat_dp)

bch_lab_dp_ToPlot_minPatient <- bch_lab_dp_average %>%
  dplyr::select( - average_pat_dp, -max_pat_dp, -min, -max ) %>%
  tidyr::pivot_wider( names_from = type, values_from = min_pat_dp)

bch_lab_dp_ToPlot_maxPatient <- bch_lab_dp_average %>%
  dplyr::select( - average_pat_dp, -min_pat_dp, -min, -max ) %>%
  tidyr::pivot_wider( names_from = type, values_from = max_pat_dp)

bch_lab_dp_ToPlot_min <- bch_lab_dp_average %>%
  dplyr::select( - average_pat_dp, -max_pat_dp,-min_pat_dp, -max ) %>%
  tidyr::pivot_wider( names_from = type, values_from = min)

bch_lab_dp_ToPlot_max <- bch_lab_dp_average %>%
  dplyr::select( - average_pat_dp,-max_pat_dp, -min_pat_dp, -min ) %>%
  tidyr::pivot_wider( names_from = type, values_from = max)


bch_dataPointsToPlot <- rbind( bch_lab_dp_ToPlot_max,
                               bch_lab_dp_ToPlot_min,
                               bch_lab_dp_ToPlot_meanPatient,
                               bch_lab_dp_ToPlot_maxPatient, 
                               bch_lab_dp_ToPlot_minPatient)

# add row.names 
row.names( bch_dataPointsToPlot ) <- c("max", "min", "mean_patient", "max_patient", "min_patient") 

create_beautiful_radarchart( data = bch_dataPointsToPlot, 
                             caxislabels = c(0, 20, 40, 60, 80), 
                             vlcex = 0.8,
                             color = c("#00AFBB", "#E7B800", "#FC4E07"),
                             title = "Data Points Type Extracted in BCH Patients")
# Add an horizontal legend
legend(
  x = "bottom", legend = c("average values", "max values", "min values"), 
  horiz = TRUE,
  bty = "n", pch = 20 , col = c("#00AFBB", "#E7B800", "#FC4E07"),
  text.col = "black", cex = 1, pt.cex = 1.5
)


###################################################
##### Medications During Hospitalization Form #####
###################################################
datadict <- read.csv('../../common_ref/MUSIC_DataDictionary_V3_4Dec20_final version_clean_0.csv')

datadict_med_only <- datadict %>% 
  dplyr::filter(Form.Name == "additional_medications_during_hospitalization") %>%
  dplyr::select( "Variable...Field.Name",  "Form.Name" ) %>%
  dplyr::mutate( type = sapply(strsplit( Variable...Field.Name, "_"), tail, 1), 
                 var_name = gsub( "_", " ", sub('[_][^_]+$', ' ', Variable...Field.Name)), 
                 var_other = sapply(strsplit( Variable...Field.Name, "_"), head, 1)) 

## meds
meds_bch <- read.csv("medications_during/local_ref/redcap_output_medications_during.csv", 
                     colClasses = "character") 

#meds_data_point <- meds_bch %>%
#  dplyr::select( -redcap_repeat_instance, -redcap_event_name, -redcap_repeat_instrument,
#                 -medhosp1_name, -medhosp2_name,  -medhosp3_name, -medhosp4_name,
#                 -medhosp5_name, -medhosp6_name,  -medhosp7_name, -medhosp8_name,
#                 -medhosp9_name, -medhosp10_name)

meds_data_point <- meds_bch %>%
  dplyr::select( -redcap_repeat_instance, -redcap_event_name, -redcap_repeat_instrument)

meds_data_point_filtered <- meds_data_point %>%
  tidyr::pivot_longer( cols = c(2:ncol(meds_data_point)), 
                       names_to = "variable", 
                       values_to = "value") %>%
  dplyr::filter( value != "")
  
  ##medhos