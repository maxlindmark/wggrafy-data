# Purpose:   Generate Excel format templates for the ind_age, len_freq and
#            mean_length_at_age tables. Re-run whenever column definitions change.
#
# Output:    standard_formats/ind_age_template.xlsx
#            standard_formats/len_freq_template.xlsx
#            standard_formats/mean_length_at_age_template.xlsx
#
# Modified:  2026-09-21
# Author:    Max Lindmark

library(here)
library(writexl)

home <- here::here()

# Data format template — printed as tables for documentation
ind_age_template <- data.frame(
  Column = c(
    "haul_id", "species", "valid_aphia", "survey", "region",
    "date", "year",
    "lon", "lat",
    "age", "lngt_cm", "lngt_clas", "lngt_code", "ind_wgt", "sex", "sampling_type",
    "n_entire_bin", "n_entire", "n_aged_bin", "n_aged"
  ),
  Type = c(
    "character", "character", "integer", "character", "character",
    "Date", "integer",
    "numeric", "numeric",
    "integer", "numeric", "numeric", "character", "numeric", "character", "character",
    "numeric", "numeric", "integer", "integer"
  ),
  Required = c(
    "yes", "yes", "no", "yes", "yes",
    "yes", "no",
    "yes", "yes",
    "yes", "yes", "no", "no", "no", "no", "no",
    "if available", "if available", "yes", "yes"
  ),
  Description = c(
    "Unique haul identifier",
    "Scientific name (e.g. Gadus morhua)",
    "WoRMS AphiaID; NA if unavailable",
    "Survey name (e.g. NS-IBTS)",
    "Broad region label (e.g. North East Atlantic)",
    "Sample date (YYYY-MM-DD). If day not recorded set day to 01. Year and month are derived from this column.",
    "Sample year (derived from date)",
    "Haul midpoint longitude (decimal degrees, WGS84)",
    "Haul midpoint latitude (decimal degrees, WGS84)",
    "Otolith age in years; 0 = 0-group",
    "Total length (cm)",
    "Raw length class bin as recorded (cm or mm; see lngt_code)",
    "Unit of lngt_clas. In DATRAS, inherited from the exchange format: '.' = 1 mm and '0' = 0.5 cm (lngt_clas in mm), '1' = 1 cm (lngt_clas in cm), and a small amount of '5' = 5 cm (lngt_clas in cm). Kept to help diagnose unit errors. CA and HL can use different codes within a haul, so they are matched on lngt_cm, not on lngt_clas/lngt_code.",
    "Individual wet weight (g); NA where not measured",
    "Sex of the aged fish: 'F', 'M' or 'U' (unsexed, including blank and other codes)",
    "How the aged fish were sampled: 'unknown', 'random', 'length-stratified' (other types may be added). Determines which records need weighting for length-stratified subsampling. 'unknown' where not yet determined.",
    "Number of fish in the entire sample (the catch) in this fish's haul, species and 1 cm length bin (floor of lngt_cm). Used in the reweighting method. NA where no catch data exist for the bin. In DATRAS: sum of HLNoAtLngt x SubFactor from the HL exchange table.",
    "Number of fish in the entire sample (the catch) in this fish's haul and species, summed over all length bins with a known length. NA where no catch data exist.",
    "Number of aged fish in this fish's haul, species and 1 cm length bin (floor of lngt_cm), counted in the cleaned data.",
    "Number of aged fish in this fish's haul and species, counted in the cleaned data."
  )
)

len_freq_template <- data.frame(
  Column = c(
    "haul_id", "species", "valid_aphia", "survey", "region",
    "lngt_clas", "lngt_code", "lngt_cm", "n_entire_bin"
  ),
  Type = c(
    "character", "character", "integer", "character", "character",
    "numeric", "character", "numeric", "numeric"
  ),
  Required = c(
    "yes", "yes", "no", "yes", "yes",
    "yes", "yes", "yes", "yes"
  ),
  Description = c(
    "Unique haul identifier (joins to ind_age$haul_id)",
    "Scientific name",
    "WoRMS AphiaID; NA if unavailable",
    "Survey name",
    "Broad region label",
    "Length class bin as recorded (cm or mm; see lngt_code)",
    "Unit of lngt_clas (same coding as ind_age$lngt_code)",
    "Length class in cm (mm and 0.5 cm classes converted; cm classes as is). Used to match to ind_age on a common 1 cm bin (floor of lngt_cm). NA where the length code is missing.",
    "Number of fish in the entire sample (the catch) in this length class in this haul, summed over sex. Must include all length classes present in the haul, even those where no fish were aged. In DATRAS: sum of HLNoAtLngt x SubFactor from the HL exchange table."
  )
)

mean_length_at_age_template <- data.frame(
  Column = c(
    "species", "valid_aphia", "survey", "region",
    "year", "quarter", "year_num", "age", "sex", "sampling_type",
    "mean_lngt_cm", "se_lngt_cm", "n_fish"
  ),
  Type = c(
    "character", "integer", "character", "character",
    "integer", "integer", "character", "integer", "character", "character",
    "numeric", "numeric", "integer"
  ),
  Required = c(
    "yes", "no", "yes", "yes",
    "yes", "yes", "yes", "yes", "yes", "yes",
    "yes", "no", "yes"
  ),
  Description = c(
    "Scientific name",
    "WoRMS AphiaID; NA if unavailable",
    "Survey name",
    "Broad region label",
    "Sample year",
    "Sample quarter (1 to 4)",
    "Year and quarter, paste(year, quarter, sep = '_'). A sample is all hauls in a survey x species x year_num.",
    "Otolith age in years; 0 = 0-group",
    "'F', 'M', 'U' (unsexed) or 'all' (sexes pooled)",
    "How the aged fish were sampled (from ind_age$sampling_type). 'random' uses the plain mean; 'length-stratified' and 'unknown' use the mean weighted by the inverse sampling fraction (fish caught in the length bin / fish aged in the bin).",
    "Mean length (cm) of the aged fish at this age",
    "Standard error of the mean length (cm); NA where there are fewer than two aged fish",
    "Number of aged fish behind the mean"
  )
)

write_xlsx(ind_age_template, path = file.path(home, "standard_formats/ind_age_template.xlsx"))
write_xlsx(len_freq_template, path = file.path(home, "standard_formats/len_freq_template.xlsx"))
write_xlsx(mean_length_at_age_template, path = file.path(home, "standard_formats/mean_length_at_age_template.xlsx"))
