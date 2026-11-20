# Purpose:   Generate Excel format templates for the haul, len_freq,
#            ind_age and mean_length_at_age tables. Re-run whenever
#            column definitions change.
#
# Output:    standard_formats/haul_template.xlsx
#            standard_formats/len_freq_template.xlsx
#            standard_formats/ind_age_template.xlsx
#            standard_formats/mean_length_at_age_template.xlsx
#
# Modified:  2026-11-20
# Author:    Max Lindmark

library(here)
library(writexl)

home <- here::here()

# Data format template — printed as tables for documentation
haul_template <- data.frame(
  Column = c(
    "haul_id", "survey", "region", "date", "latitude", "longitude",
    "gear", "depth", "effort", "effort_type"
  ),
  Type = c(
    "character", "character", "character", "Date", "numeric", "numeric",
    "character", "numeric", "numeric", "character"
  ),
  Required = c(
    "yes", "yes", "yes", "yes", "yes", "yes",
    "if available", "if available", "if available", "if available"
  ),
  Description = c(
    "Unique haul identifier",
    "Survey name (e.g. NS-IBTS)",
    "Broad region label (e.g. North East Atlantic)",
    "Sample date (YYYY-MM-DD). If day not recorded set day to 01.",
    "Haul latitude (decimal degrees, WGS84); in DATRAS the shooting position (the hauling position where it is missing)",
    "Haul longitude (decimal degrees, WGS84); as latitude",
    "Gear code",
    "Bottom depth (m)",
    "Fishing effort of the haul, in the unit given by effort_type",
    "Type and unit of effort, e.g. 'swept_area_km2'"
  )
)

len_freq_template <- data.frame(
  Column = c("haul_id", "aphia_id", "lngt", "length_type", "num", "wgt"),
  Type = c("character", "integer", "numeric", "character", "numeric", "numeric"),
  Required = c("yes", "yes", "yes", "yes", "yes", "if available"),
  Description = c(
    "Unique haul identifier (joins to haul)",
    "WoRMS AphiaID",
    "Length bin in cm, lower bound of the 1 cm bin (fish of lngt to lngt + 1 cm). All regions use 1 cm bins; aged fish in ind_age are matched to the bin their length falls in. In DATRAS: DATRASextra::add_numbers_at_length() with 1 cm breaks (its default would be the coarsest length class of the survey x species, 0.1 to 5 cm); lengths in mm are summed into 1 cm bins, and catch in 2 and 5 cm classes is spread over their 1 cm bins (see cleaning_codes/north_east_atlantic_datras/cleaning_notes/nea_datras_catch_zeros.md).",
    "Type of length measurement (same coding as ind_age$length_type). In DATRAS, 'total' is assumed for all records (LenMeasType is mostly blank or total length; the few other codes look mislabeled).",
    "Number of fish in the entire sample (the catch) in this length bin in this haul. Only bins with fish; hauls where the species was not caught are not stored (zeros are created by a join with haul). NA (with lngt and wgt NA) where the catch of the species in the haul is unknown (not recorded, invalid catch records, or catch recorded without lengths): one such row per haul x species, kept as NA when creating zeros. In DATRAS: numbers at length from DATRASextra::add_numbers_at_length() (HLNoAtLngt x SubFactor, x HaulDur / 60 for DataType C, summed per 1 cm bin and rounded to whole fish). Catch in 5 cm classes (NS-IBTS 1966-2001) is spread over 1 cm bins before the rounding: first at the cm of the aged fish of the haul, the rest as whole fish at random cm. Same name and unit as FISHGLOB's num, which is per haul x species (the sum over the length bins).",
    "Weight (kg) of the fish in this length bin in this haul; summed over bins it gives the catch weight of the species in the haul. In DATRAS: from DATRASextra::add_total_weight_by_haul(), a x (bin midpoint)^b x num, with a and b from DATRASextra's species_info (a = 0.01, b = 3 where missing). Same name and unit as FISHGLOB's wgt, which is per haul x species (the sum over the length bins)."
  )
)

ind_age_template <- data.frame(
  Column = c(
    "haul_id", "aphia_id", "species", "lngt", "age", "sex", "ind_wgt",
    "sampling_type", "length_type", "n"
  ),
  Type = c(
    "character", "integer", "character", "numeric", "integer", "character", "numeric",
    "character", "character", "integer"
  ),
  Required = c(
    "yes", "yes", "yes", "yes", "yes", "no", "no",
    "no", "yes", "yes"
  ),
  Description = c(
    "Unique haul identifier (joins to haul); contains 'pooled' for aged fish whose haul is unknown (not in haul; survey, year and quarter are in the id)",
    "WoRMS AphiaID",
    "Scientific name (e.g. Gadus morhua). Only stored here; other tables get it by aphia_id, e.g. distinct(ind_age, aphia_id, species)",
    "Length (cm); the type of length is given in length_type",
    "Otolith age in years; 0 = 0-group",
    "Sex of the aged fish: 'F', 'M' or 'U' (unsexed, including blank and other codes)",
    "Individual wet weight (g); NA where not measured",
    "How the aged fish were sampled: 'unknown', 'random', 'length-stratified' (other types may be added). Determines which records need weighting for length-stratified subsampling. 'unknown' where not yet determined.",
    "Type of length measurement: 'total', 'fork', 'standard' (other types may be added). In DATRAS, LenMeasType exists only in the HL table, not in CA, so 'total' is assumed for all records.",
    "Number of aged fish with exactly these values (haul, species, length, age, sex, weight, ...)"
  )
)

mean_length_at_age_template <- data.frame(
  Column = c(
    "aphia_id", "survey", "region",
    "year", "quarter", "age", "sex", "sampling_type", "length_type",
    "mean_lngt", "se_lngt", "n_fish"
  ),
  Type = c(
    "integer", "character", "character",
    "integer", "integer", "integer", "character", "character", "character",
    "numeric", "numeric", "integer"
  ),
  Required = c(
    "yes", "yes", "yes",
    "yes", "yes", "yes", "yes", "yes", "yes",
    "yes", "no", "yes"
  ),
  Description = c(
    "WoRMS AphiaID",
    "Survey name",
    "Broad region label",
    "Year of the survey",
    "Survey quarter (in DATRAS the survey's quarter label, which can differ from the calendar quarter of the date). A sample is all hauls in a survey x species x year x quarter.",
    "Otolith age in years; 0 = 0-group",
    "'F', 'M', 'U' (unsexed) or 'all' (sexes pooled)",
    "How the aged fish were sampled (from ind_age$sampling_type). 'random' uses the plain mean; 'length-stratified' and 'unknown' use the mean weighted by the inverse sampling fraction (fish caught in the length bin / fish aged in the bin).",
    "Type of length measurement (from ind_age$length_type)",
    "Mean length (cm) at this age (see the main README for how the aged fish are weighted)",
    "Standard error of the mean length (cm); NA where there are fewer than two aged fish, or (in DATRAS) where more fish were aged than caught in their length bins, so that they stand for one fish or less in the catch",
    "Number of aged fish behind the mean"
  )
)

write_xlsx(haul_template, path = file.path(home, "standard_formats/haul_template.xlsx"))
write_xlsx(len_freq_template, path = file.path(home, "standard_formats/len_freq_template.xlsx"))
write_xlsx(ind_age_template, path = file.path(home, "standard_formats/ind_age_template.xlsx"))
write_xlsx(mean_length_at_age_template, path = file.path(home, "standard_formats/mean_length_at_age_template.xlsx"))
