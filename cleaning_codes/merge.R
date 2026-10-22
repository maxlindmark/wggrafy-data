# Purpose:   Bind-row cleaned outputs from all regional pipelines into a single
#            dataset conforming to the standard format defined in
#            standard_formats/data_format_template.xlsx.
#
# Input:     outputs/<region>/<prefix>_length_clean.rds
#            outputs/<region>/<prefix>_catch_clean.rds
#            outputs/<region>/<prefix>_mean_length_at_age.rds
#            [outputs from future regional pipelines]
#
# Output:    outputs/length_all.rds
#            outputs/catch_all.rds
#            outputs/mean_length_all.rds
#            updated README (data availability)
#
# Modified:  2026-10-22
# Author:    Max Lindmark

library(dplyr)
library(here)

home <- here::here()

# -----------------------------------------------------------------------------
# Load regional outputs
# -----------------------------------------------------------------------------
nea_datras_length <- readRDS(file.path(home, "outputs/north-east-atlantic-datras/nea_datras_length_clean.rds"))
nea_datras_catch <- readRDS(file.path(home, "outputs/north-east-atlantic-datras/nea_datras_catch_clean.rds"))
nea_datras_mean_length <- readRDS(file.path(home, "outputs/north-east-atlantic-datras/nea_datras_mean_length_at_age.rds"))

# [add further regions here as new get_*.R pipelines are added]

# -----------------------------------------------------------------------------
# Bind and save
# -----------------------------------------------------------------------------
length_all <- bind_rows(nea_datras_length)
catch_all <- bind_rows(nea_datras_catch)
mean_length_all <- bind_rows(nea_datras_mean_length)

saveRDS(length_all, file.path(home, "outputs/length_all.rds"))
saveRDS(catch_all, file.path(home, "outputs/catch_all.rds"))
saveRDS(mean_length_all, file.path(home, "outputs/mean_length_all.rds"))

# -----------------------------------------------------------------------------
# Update README Regions & Surveys table from actual data
# -----------------------------------------------------------------------------
# Lookup: region label (as it appears in the data) -> data source + script folder
region_meta <- tibble(
  region        = "North East Atlantic (DATRAS)",
  data_source   = "DATRAS",
  output_prefix = "`nea_datras`",
  script_folder = "`cleaning_codes/north-east-atlantic-datras/`"
)

survey_rows <- length_all |>
  summarise(surveys = paste(sort(unique(survey)), collapse = ", "), .by = region) |>
  left_join(region_meta, by = "region") |>
  mutate(line = paste0("| ", region, " | ", data_source, " | ", output_prefix, " | ", surveys, " | ", script_folder, " |")) |>
  pull(line)

new_section <- c(
  "## Regions & Surveys",
  "",
  "This table is populated automatically by `cleaning_codes/merge.R` from the merged data.",
  "",
  "| Region | Data source | Output prefix | Surveys | Script folder |",
  "|---|---|---|---|---|",
  survey_rows
)

readme <- readLines(file.path(home, "README.md"))
sec_start <- which(grepl("^## Regions & Surveys", readme))
next_sec <- which(grepl("^## ", readme))
sec_end <- next_sec[next_sec > sec_start][1] - 1

writeLines(
  c(readme[seq_len(sec_start - 1)], new_section, "", readme[seq(sec_end + 1, length(readme))]),
  file.path(home, "README.md")
)
