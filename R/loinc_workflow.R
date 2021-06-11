rm(list=ls())
library(dplyr)
library(lubridate)
#read the file from UMLS that contains those loincs that are clinical attributes
# #SQL code to generate the subset
# create table ag440_loinc_clinicalAttributes as
# select conso.cui, conso.lat, conso.sab, conso.tty, conso.code, conso.str, sty.sty 
# from mrconso conso, mrsty sty 
# where conso.cui = sty.cui and
# conso.sab = 'LNC' and conso.tty = 'LN' and sty.sty = 'Clinical Attribute';

umls_subset <- read.delim("../local_ref/loinc_clinicalAttributes.dsv")

#load the keywords (manually checked previously)
lab_keywords <- read.delim("../local_ref/lab_keywords_sm.tsv" )   #loading sm
lab_keywords <- lab_keywords %>%
  dplyr::filter( Position %in% c('beginning', 'anywhere'))
cutOff <- 10

#extract the loincs that contain the keywords
for( i in 1:nrow(lab_keywords)){
  position <- lab_keywords$Position[i]
  if( position == "anywhere"){
    generalQ<- umls_subset %>% 
      dplyr::filter( grepl( lab_keywords$Keyword[i], STR))
    }else if(position == "beginning"){
      generalQ<- umls_subset %>% 
        dplyr::filter( grepl( paste0("^", lab_keywords$Keyword[i]), STR))
  }
  
  narrowQ <- generalQ %>% 
    dplyr::filter( grepl( paste(c("*Ser/Plas:Qn", "*Pt:Bld:Qn"), collapse = "|"), STR))
  
  if(i==1){
    if( nrow(narrowQ) == 0 ){
      output <- generalQ
    }else if( nrow( generalQ ) > cutOff ){
      output <- narrowQ
    }else if( nrow( generalQ) > 0 ){
      output <- generalQ
    }else{
      print( paste0("No entry found for keyword: ", lab_keywords$Keyword[i]))
    }
    print( paste0( nrow( output), " LOINC terms found for keyword: ", lab_keywords$Keyword[i]))
    output$Section.Header <- lab_keywords$Section.Header[i]
  }else{
    if( nrow(narrowQ) == 0 ){
      int_output <- generalQ
    }else if( nrow( generalQ ) > cutOff ){
      int_output <- narrowQ
    }else if( nrow( generalQ) > 0 ){
      int_output <- generalQ
    }else{
      print( paste0("No entry found for keyword: ", lab_keywords$Keyword[i]))
    }
    print( paste0( nrow( int_output), " LOINC terms found for keyword: ", lab_keywords$Keyword[i]))
    int_output$Section.Header <- lab_keywords$Section.Header[i]
    output <- rbind( output, int_output)
  }
}

output <- unique( output )
ranked_list_sm <- output %>% group_by(Section.Header) %>% summarise(n = n_distinct(CODE)) %>% arrange(desc(n)) # testing

# check how many map to BCH
bch_loinc_map <- read.csv("../local_ref/BCH_Lab_Loinc_cd_Map_data.csv")

mappingToBch <- bch_loinc_map %>%
  dplyr::filter( LOINC_LAB_CODE %in% output$CODE)

# check how many in MISC patients
observationFactsLabs <- read.delim("../local_ref/music_labs_observation_withUnits.dsv")
observationFactsLabs$date <- sapply(strsplit( as.character(observationFactsLabs$START_DATE), "[ ]"), '[', 1)
colnames( observationFactsLabs ) <- tolower( colnames( observationFactsLabs ) )

labs_in_misc <- observationFactsLabs %>%
  dplyr::filter( concept_cd %in% mappingToBch$BCH_LAB_CODE )

labs_in_misc$units_cd <- gsub( "MMOL/L", "mmol/L", labs_in_misc$units_cd)
labs_in_misc$units_cd <- gsub( "MG/DL", "mg/dL", labs_in_misc$units_cd)
labs_in_misc$units_cd <- gsub( "G/DL", "g/dL", labs_in_misc$units_cd)

check_summary <- labs_in_misc %>%
  dplyr::group_by(concept_cd, units_cd) %>%
  dplyr::summarise( min_val = min(nval_num, na.rm = TRUE), 
                    max_val = max(nval_num, na.rm = TRUE), 
                    min_date = min( dmy( date ) ), 
                    max_date = max( dmy( date ) ), 
                    distinct_patients = length(unique(patient_num)), 
                    distinct_observations = length(patient_num)) %>%
  dplyr::select( concept_cd, min_date, max_date, 
                 distinct_patients, distinct_observations, 
                 min_val, max_val, units_cd)

colnames(mappingToBch) <- c("concept_cd", "CODE")
check_summary <- left_join( check_summary, mappingToBch )
check_summary <- left_join( check_summary, output )

check_summary <- check_summary %>% 
  dplyr::filter( units_cd != 'NOT DEFINED IN SOURCE')

