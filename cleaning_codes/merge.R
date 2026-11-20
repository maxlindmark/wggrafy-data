# Purpose:   Bind-row cleaned outputs from all regional pipelines into a single
#            dataset conforming to the standard format defined in
#            standard_formats/data_format_template.xlsx.
#
# Input:     outputs/<region>/<prefix>_haul.rds
#            outputs/<region>/<prefix>_len_freq.rds
#            outputs/<region>/<prefix>_ind_age.rds
#            outputs/<region>/<prefix>_mean_length_at_age.rds
#            [outputs from future regional pipelines]
#
# Output:    outputs/haul_all.rds
#            outputs/len_freq_all.rds
#            outputs/ind_age_all.rds
#            outputs/mean_length_all.rds
#            updated README (data availability)
#
# Modified:  2026-11-20
# Author:    Max Lindmark

library(dplyr)
library(here)

home <- here::here()

# -----------------------------------------------------------------------------
# Load regional outputs
# -----------------------------------------------------------------------------
nea_datras_haul <- readRDS(file.path(home, "outputs/north_east_atlantic_datras/nea_datras_haul.rds"))
nea_datras_len_freq <- readRDS(file.path(home, "outputs/north_east_atlantic_datras/nea_datras_len_freq.rds"))
nea_datras_ind_age <- readRDS(file.path(home, "outputs/north_east_atlantic_datras/nea_datras_ind_age.rds"))
nea_datras_mean_length <- readRDS(file.path(home, "outputs/north_east_atlantic_datras/nea_datras_mean_length_at_age.rds"))

# [add further regions here as new get_*.R pipelines are added]

# -----------------------------------------------------------------------------
# Bind and save
# -----------------------------------------------------------------------------
haul_all <- bind_rows(nea_datras_haul)
len_freq_all <- bind_rows(nea_datras_len_freq)
ind_age_all <- bind_rows(nea_datras_ind_age)
mean_length_all <- bind_rows(nea_datras_mean_length)

saveRDS(haul_all, file.path(home, "outputs/haul_all.rds"))
saveRDS(len_freq_all, file.path(home, "outputs/len_freq_all.rds"))
saveRDS(ind_age_all, file.path(home, "outputs/ind_age_all.rds"))
saveRDS(mean_length_all, file.path(home, "outputs/mean_length_all.rds"))

# -----------------------------------------------------------------------------
# Update the README table of regions and surveys from actual data
# -----------------------------------------------------------------------------
# Lookup: region label (as it appears in the data) -> data source + script folder
region_meta <- tibble(
  region        = "North East Atlantic (DATRAS)",
  data_source   = "DATRAS",
  output_prefix = "`nea_datras`",
  script_folder = "`cleaning_codes/north_east_atlantic_datras/`"
)

survey_rows <- haul_all |>
  summarise(surveys = paste(sort(unique(survey)), collapse = ", "), .by = region) |>
  left_join(region_meta, by = "region") |>
  mutate(line = paste0("| ", region, " | ", data_source, " | ", output_prefix, " | ", surveys, " | ", script_folder, " |")) |>
  pull(line)

new_section <- c(
  "## Current regions & surveys in the repository",
  "",
  "This table is populated automatically by `cleaning_codes/merge.R` from the merged data.",
  "",
  "| Region | Data source | Output prefix | Surveys | Script folder |",
  "|---|---|---|---|---|",
  survey_rows
)

readme <- readLines(file.path(home, "README.md"))
sec_start <- which(readme == "## Current regions & surveys in the repository")
stopifnot(length(sec_start) == 1)
next_sec <- which(grepl("^## ", readme))
sec_end <- next_sec[next_sec > sec_start][1] - 1

writeLines(
  c(readme[seq_len(sec_start - 1)], new_section, "", readme[seq(sec_end + 1, length(readme))]),
  file.path(home, "README.md")
)
