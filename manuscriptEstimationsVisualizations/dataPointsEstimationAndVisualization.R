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
                             color = "#E7B800", 
                             title = "Data Points Per Form")
