rm(list=ls())
library(tidyverse)
library(tidyr)
library(dplyr)

#create table meds_concepts as
#select * from concept_dimension where concept_cd like 'HOMEMED:%' or concept_cd like 'ADMINMED:%';
#create table umls_meds_subset as 
#select * from mrconso where sab = 'RXNORM' or sab = 'MMSL';


allMeds <- read.delim("./Desktop/allMeds.dsv")
allMeds$MULTUM <-sapply(strsplit(as.character(allMeds$CONCEPT_PATH), 
                              split = '[\\]'), 
                     function(x) x[length(x)-1])

allMeds$firstMultum <- substr(allMeds$MULTUM, 1,1)
allMedsWithMultum <- allMeds[ allMeds$firstMultum == "d", ]

umlsMultumRxnorm <- read.delim("./Desktop/umlsMeds.dsv")

multum <- umlsMultumRxnorm %>% 
  filter( CODE %in% allMedsWithMultum$MULTUM, 
          SAB == "MMSL") %>%
  select( CUI, MULTUM = CODE, MULTUM_STR = STR)

rxnorm <- umlsMultumRxnorm %>%
  filter( CUI %in% multum$CUI, 
          SAB == "RXNORM") %>%
  select( CUI, RXNORM = CODE, RXNORM_STR = STR )

allMedsWithMultumMap <- left_join( allMedsWithMultum, multum, by= "MULTUM")
allMedsWithMultumMap <- left_join( allMedsWithMultumMap, rxnorm, by= "CUI")

###compare with our previous mapping
manualMap <- read.delim("./Desktop/MUSIC Medications_ mapping from eCRF generic names and trades to BCH variables - BCH med concept summary updated 07-20-21.tsv")

manualMap <- unique(manualMap[, c("CONCEPT_CD", "RXNORM_CODES")])
manualMap <- as.data.frame(manualMap %>%
  filter( RXNORM_CODES != "greater than 5 RXNORM codes mapped to BCH code") %>%
  mutate(RXNORM_CODES = strsplit(as.character(RXNORM_CODES), ",")) %>% 
  unnest(RXNORM_CODES))

multumMapSubset <- unique(allMedsWithMultumMap %>%
  filter( CONCEPT_CD %in% manualMap$CONCEPT_CD) %>%
  select( CONCEPT_CD, RXNORM_MULTUMMAP = RXNORM ))

finalCheck <- inner_join( manualMap, multumMapSubset)
finalCheck$diff <- as.numeric(finalCheck$RXNORM_CODES) - as.numeric(finalCheck$RXNORM_MULTUMMAP)


#### check with mohamad mapping file
m_mapping <- read.csv("./Desktop/P00036898_EVENT_CATALOG_SYN_RXNORM_CODES.csv")
adminMed <- m_mapping %>%
  mutate( CONCEPT_CD = paste0("ADMINMED:", EVENT_CD), 
          MULTUM_CD = gsub("MUL.ORD!", "", RXNORM_CODE), 
          RXNORM_CD = gsub("RXNORM!", "", RXNORM_DISPLAY)) %>%
  select( CONCEPT_CD,MULTUM_CD, RXNORM_CD, DESCR_CD = DNUM )

homeMed <- m_mapping %>%
  mutate( CONCEPT_CD = paste0("HOMEMED:", SYNONYM_ID), 
          MULTUM_CD = gsub("MUL.ORD!", "", RXNORM_CODE), 
          RXNORM_CD = gsub("RXNORM!", "", RXNORM_DISPLAY)) %>%
  select( CONCEPT_CD,MULTUM_CD, RXNORM_CD, DESCR_CD = DNUM )

mMapping <- unique( rbind( adminMed, homeMed ))
secondCheck <- inner_join( manualMap, mMapping)
secondCheck$diff <- as.numeric(secondCheck$RXNORM_CODES) - as.numeric(secondCheck$RXNORM_CD)
secondCheck$DESCR_CD <- tolower( str_trim( secondCheck$DESCR_CD ) )
secondCheck <- secondCheck[!duplicated( secondCheck), ]
