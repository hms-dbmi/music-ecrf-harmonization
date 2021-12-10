rm(list=ls())
musicDataDictionary <- read.csv("../../common_ref/MUSIC_DataDictionary_V3_4Dec20_final version_clean_0.csv", header = TRUE)
our_lab_extraction <- read.csv('../local_ref/redcap_output_laboratory_values_updated.csv')

labs_ecrf_variables <- musicDataDictionary %>%
  filter( Form.Name == "laboratory_values") %>%
  select( Variables = Variable...Field.Name) %>%
  unique()

#this count include as different variables labXX_value, labXX_unit, labXX_date... etc

#remove value, unit, date and obtained
labs_ecrf_variables_uniques <- labs_ecrf_variables %>%
  mutate( Variables2 = gsub("_value|_unit|_date|_obtained|", "", Variables)) %>%
  unique()

#this count only look for real different laboratories
print( length(unique(labs_ecrf_variables_uniques$Variables) ) )
print( length(unique(labs_ecrf_variables_uniques$Variables2) ) )

our_labs_variables_extracted <- colnames( our_lab_extraction )[5:ncol(our_lab_extraction )]
print( length(our_labs_variables_extracted) )

#how many are missing?
autocalculatedInRedcap <- c("anc", "alc", "nl_ratio")
missing <- labs_ecrf_variables_uniques[ ! labs_ecrf_variables_uniques$Variables %in% our_labs_variables_extracted, ]

### we want to count the variables that are distinct than "other"
others <- missing[ grep("other", missing$Variables2), ] 
realmissing <- missing[ - grep("other", missing$Variables2),  ] 
realmissing <- realmissing[ !  realmissing$Variables2 %in% autocalculatedInRedcap,  ]
print(length(unique(realmissing$Variables)))
print(length(unique(realmissing$Variables2)))

write.csv(realmissing, file="../local_ref/missingVariables.csv", row.names = FALSE)

present <- labs_ecrf_variables_uniques[  labs_ecrf_variables_uniques$Variables %in% c(our_labs_variables_extracted, autocalculatedInRedcap), ]

### find the "others"
allOthers <- labs_ecrf_variables_uniques[ grep("other", labs_ecrf_variables_uniques$Variables2), ]
labs_ecrf_variables_uniques_no_others <- labs_ecrf_variables_uniques[ -grep("other", labs_ecrf_variables_uniques$Variables2),  ]


### estimate total values present, missing and %
print( paste0( "Total variables in the labs eCRF: ",length(unique(labs_ecrf_variables_uniques$Variables)) , ", representing ", 
               length(unique(labs_ecrf_variables_uniques$Variables2)), " distinct laboratory test"))

print( paste0( "Total variables in the labs eCRF (distinct than \"others\": ",length(unique(labs_ecrf_variables_uniques_no_others$Variables)) , ", representing ", 
               length(unique(labs_ecrf_variables_uniques_no_others$Variables2)), " distinct laboratory test"))

print( paste0( "Total variables extracted in BCH: ",length(unique(present$Variables)) , ", representing ", 
               length(unique(present$Variables2)), " distinct laboratory test"))

percentage_covered_from_distinct_than_others <- round(100*(length(unique(present$Variables2)) / length(unique(labs_ecrf_variables_uniques_no_others$Variables2))), 2)
print( paste0( "Percentage covered (excluding the \"other\" variables): ", percentage_covered_from_distinct_than_others, "%" ))

percentage_covered_from_total <- round(100*(length(unique(present$Variables2)) / length(unique(labs_ecrf_variables_uniques$Variables2))), 2)
print( paste0( "Percentage covered (considering all variables): ", percentage_covered_from_total, "%" ))
