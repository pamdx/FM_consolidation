# CAUTION: MAKE SURE ORIGINAL DATA IS ENCODED IN UTF-8, OTHERWISE ISSUES WILL OCCUR WITH SPECIAL CHARACTERS IN COUNTRY NAMES (E.G. RÉUNION)

library(tidyverse)

source("./parameters/parameters_FM_consolidation.R")

# Import original data and duplicate to insert imputed data

data_pre_imputation <- readRDS(paste0(path_emputator_inputs, "FM_DB.rds")) %>%
  add_column(timestamp = as.POSIXct(NA))

data_consolidated <- data_pre_imputation

# Import imputed data

filenames = dir(path = path_emputator_outputs, pattern = "*.csv")

for(i in filenames){
  
  imputed <- read_csv(paste0(path_emputator_outputs, i), col_types = "ccccciiccT")
  stop_for_problems(imputed) # Most parsing issues are due to Excel changing the date format under the timestamp column of imputed CSVs. Fix in Excel by converting the date field to ISO 8601 with the function =TEXT(A1,"yyyy-mm-ddThh:MM:ss")
  country <- str_split(i, "_")[[1]][1]
  sector <- str_split(i, "_")[[1]][2]
  
  if (country %in% country_change_name) {country <- gsub("-", "/", country)} # fix country names for those with characters not allowed in file names
  
  if (single_questionnaire) {
    
    if (country %in% unique(data_pre_imputation$geographic_area)) {
      
      data_consolidated <- data_consolidated %>% 
        filter(!(geographic_area == country & OC2 == sector & between(year, year_min, year_max))) %>%
        rbind(imputed)
      
    } 
    
  } else {
    
    # Replace imputed data in original data
    data_consolidated <- data_consolidated %>% 
      filter(!(geographic_area == country & OC2 == sector & between(year, year_min, year_max))) %>%
      rbind(imputed) 
    
  }
  
}

data_consolidated <- data_consolidated %>%
  arrange(geographic_area, OC2, year, OC3, working_time, sex)

if (single_questionnaire) {
  
  write_csv(data_consolidated, paste0("FM_DB_imputed_consolidated", year_min, "-", year_max, ".csv"), na = "")

}