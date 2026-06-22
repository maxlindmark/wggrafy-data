# Purpose:   Generate Excel format templates for the ind_age and len_freq tables.
#            Re-run whenever column definitions change.
#
# Output:    standard_formats/ind_age_template.xlsx
#            standard_formats/len_freq_template.xlsx
#
# Modified:  2026-06-22
# Author:    Max Lindmark

library(here)
library(writexl)

home <- here::here()

# Data format template — printed as tables for documentation
ind_age_template <- data.frame(
  Column = c(
    "haul_id", "species", "valid_aphia", "survey", "region",
    "date",
    "lon", "lat",
    "age", "lngt_cm", "lngt_clas", "lngt_code", "ind_wgt", "n_k"
  ),
  Type = c(
    "character", "character", "integer", "character", "character",
    "Date",
    "numeric", "numeric",
    "integer", "numeric", "numeric", "character", "numeric", "numeric"
  ),
  Required = c(
    "yes", "yes", "no", "yes", "yes",
    "yes",
    "yes", "yes",
    "yes", "yes", "no", "no", "no", "yes"
  ),
  Description = c(
    "Unique haul identifier",
    "Scientific name (e.g. Gadus morhua)",
    "WoRMS AphiaID; NA if unavailable",
    "Survey name (e.g. NS-IBTS)",
    "Broad region label (e.g. North East Atlantic)",
    "Sample date (YYYY-MM-DD). If day not recorded set day to 01. Year and month are derived from this column.",
    "Haul midpoint longitude (decimal degrees, WGS84)",
    "Haul midpoint latitude (decimal degrees, WGS84)",
    "Otolith age in years; 0 = 0-group",
    "Total length (cm)",
    "Raw length class bin as recorded (cm or mm; see lngt_code)",
    "Unit of lngt_clas: 'cm' or 'mm'. Note: in DATRAS this is inherited from the exchange format ('1' = 1 cm bins; '0'/'.'/'2'/'5' = mm bins) to help diagnose unit errors.",
    "Individual wet weight (g); NA where not measured",
    "Total number of fish in this length class in this haul (N_k in Perreault et al. 2020), joined from the length-frequency data. Used as the sampling weight in the EP likelihood. In DATRAS: sum of HLNoAtLngt x SubFactor from the HL exchange table."
  )
)

len_freq_template <- data.frame(
  Column = c(
    "haul_id", "species", "valid_aphia", "survey", "region",
    "lngt_clas", "lngt_code", "n_k"
  ),
  Type = c(
    "character", "character", "integer", "character", "character",
    "numeric", "character", "numeric"
  ),
  Required = c(
    "yes", "yes", "no", "yes", "yes",
    "yes", "yes", "yes"
  ),
  Description = c(
    "Unique haul identifier (joins to ind_age$haul_id)",
    "Scientific name",
    "WoRMS AphiaID; NA if unavailable",
    "Survey name",
    "Broad region label",
    "Length class bin as recorded (cm or mm; see lngt_code)",
    "Unit of lngt_clas (same coding as ind_age$lngt_code)",
    "Total number of fish in this length class in this haul (N_k in Perreault et al. 2020). Must include all length classes present in the haul, even those where no fish were aged (needed for EP empty-stratum terms). In DATRAS: sum of HLNoAtLngt x SubFactor from the HL exchange table."
  )
)

write_xlsx(ind_age_template, path = file.path(home, "standard_formats/ind_age_template.xlsx"))
write_xlsx(len_freq_template, path = file.path(home, "standard_formats/len_freq_template.xlsx"))
