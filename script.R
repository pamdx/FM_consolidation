# CAUTION: MAKE SURE ORIGINAL DATA IS ENCODED IN UTF-8, OTHERWISE ISSUES WILL OCCUR WITH SPECIAL CHARACTERS IN COUNTRY NAMES (E.G. RÉUNION)

library(tidyverse)

source("parameters_consolidation.R")

# Import original data and duplicate to insert imputed data

original <- readRDS(paste0(path_emputator_inputs, "FM_DB.rds")) %>%
  add_column(timestamp = as.POSIXct(NA))

final <- original

# Import imputed data

filenames = dir(path = path_emputator_outputs, pattern = "*.csv")

for(i in filenames){
  
  imputed <- read_csv(paste0(path_emputator_outputs, i), col_types = "ccccciiccT")
  stop_for_problems(imputed) # Most parsing issues are due to Excel changing the date format under the timestamp column of imputed CSVs. Fix in Excel by converting the date field to ISO 8601 with the function =TEXT(A1,"yyyy-mm-ddThh:MM:ss")
  country <- str_split(i, "_")[[1]][1]
  sector <- str_split(i, "_")[[1]][2]
  
  if (country %in% country_change_name) {country <- gsub("-", "/", country)} # fix country names for those with characters not allowed in file names
  
  # Replace imputed data in original data
  
  final <- final %>% 
    filter(!(geographic_area == country & OC2 == sector & between(year, year_min, year_max))) %>%
    rbind(imputed)
  
}

final <- final %>%
  arrange(geographic_area, OC2, year, OC3, working_time, sex)

if (export_as_csv) {
 
  write_csv(final, paste0("FM_DB_imputed_", year_min, "-", year_max, ".csv"), na = "")
   
}
