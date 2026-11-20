# Purpose:   Filter and clean DATRAS output from
#            get_north_east_atlantic_datras.R.
#
# Input:     cleaning_codes/north_east_atlantic_datras/merged_survey_data.rds
#
# Output:    outputs/north_east_atlantic_datras/nea_datras_haul.rds
#            outputs/north_east_atlantic_datras/nea_datras_len_freq.rds
#            outputs/north_east_atlantic_datras/nea_datras_ind_age.rds
#            cleaning_codes/north_east_atlantic_datras/check_species_laa/*.png
#            information for cleaning_codes/north_east_atlantic_datras/cleaning_notes
#
# Modified:  2026-11-20
# Author:    Max Lindmark

library(tidyr)
library(dplyr)
library(lubridate)
library(ggplot2)
theme_set(theme_light())
library(here)
library(writexl)
library(tidylog)
home <- here::here()

results <- readRDS(file.path(home, "cleaning_codes/north_east_atlantic_datras/merged_survey_data.rds"))

# -----------------------------------------------------------------------------
# Load processed survey data
# -----------------------------------------------------------------------------
ca_all <- bind_rows(lapply(names(results), function(s) {
  df <- results[[s]]$ca
  if (nrow(df) == 0) {
    return(NULL)
  }
  df |> mutate(survey = s, lngt_code = as.character(lngt_code))
}))

hl_all <- bind_rows(lapply(names(results), function(s) {
  df <- results[[s]]$hl
  if (nrow(df) == 0) {
    return(NULL)
  }
  df |> mutate(survey = s)
}))

haul_all <- bind_rows(lapply(names(results), function(s) {
  results[[s]]$haul |> mutate(survey = s)
}))

# Haul x species with only invalid catch records (SpecVal 0, 3, 9)
hl_invalid_all <- bind_rows(lapply(names(results), function(s) {
  results[[s]]$hl_invalid |> mutate(survey = s)
}))

# Haul x species with valid catch records but no lengths (e.g. SpecVal 4, total number only)
hl_nolength_all <- bind_rows(lapply(names(results), function(s) {
  results[[s]]$hl_nolength |> mutate(survey = s)
}))
stopifnot(nrow(hl_nolength_all) > 0)

# -----------------------------------------------------------------------------
# Hard filters
# -----------------------------------------------------------------------------

# Age must be a non-negative integer; age == 0 (0-group) is valid
ca_all <- ca_all |> filter(!is.na(age), age >= 0)

# Missing number of fish in a record (one in NS-IBTS) is one fish
ca_all <- ca_all |> mutate(n = if_else(is.na(n), 1L, n))

# Length must be known (a handful of aged fish have no length)
ca_all <- ca_all |> filter(!is.na(lngt_cm))

# Drop hauls with missing coordinates from all tables (see cleaning_codes/north_east_atlantic_datras/cleaning_notes/nea_datras_missing_positions.md)
haul_all <- haul_all |> filter(!is.na(lon), !is.na(lat))
# Aged fish with a pooled haul id (haul unknown, not in haul) are kept
ca_all <- ca_all |> filter(haul_id %in% haul_all$haul_id | grepl(":pooled:", haul_id))
hl_all <- hl_all |> filter(haul_id %in% haul_all$haul_id)

# Lon/lat sanity (Atlantic + European shelf)
# haul_all <- haul_all |> filter(lon > -40, lon < 40, lat > 30, lat < 90)

# Drop species with fewer than 100 individuals total across all surveys (n = number of fish per record)
ca_all <- ca_all |>
  mutate(n_total = sum(n), .by = species) |>
  filter(n_total >= 100) |>
  dplyr::select(-n_total)

# -----------------------------------------------------------------------------
# Look for errors in data (specifically length codes).
# -----------------------------------------------------------------------------
# We are not necessarily removing outliers here unless they are obvious and
# obscure visual comparison

# Length
ggplot(ca_all, aes(lngt_cm, weight = n)) +
  geom_histogram(bins = 80) +
  facet_wrap(~species, scales = "free") +
  labs(title = "Length distribution by species")

# Age
ggplot(ca_all, aes(age, weight = n)) +
  geom_histogram(binwidth = 1) +
  facet_wrap(~species, scales = "free") +
  labs(title = "Age distribution by species")

# Weight (many NAs expected)
ca_all |>
  filter(!is.na(ind_wgt)) |>
  ggplot(aes(ind_wgt, weight = n)) +
  geom_histogram(bins = 60) +
  facet_wrap(~species, scales = "free") +
  labs(title = "Individual weight distribution by species")

# Length vs age per species, coloured by lngt_code, saved individually so
# unit mismatches are easy to spot and fix species by species
dir.create(file.path(home, "cleaning_codes/north_east_atlantic_datras/check_species_laa"), recursive = TRUE, showWarnings = FALSE)

for (sp in sort(unique(ca_all$species))) {
  p <- ca_all |>
    filter(species == sp) |>
    ggplot(aes(age, lngt_cm, color = lngt_code)) +
    geom_jitter(width = 0.2, height = 0) +
    facet_wrap(~survey, scales = "free") +
    labs(title = sp, x = "Age", y = "Length (cm)", color = "LngtCode")

  fname <- file.path(
    home, "cleaning_codes/north_east_atlantic_datras/check_species_laa",
    paste0(gsub(" ", "_", sp), ".png")
  )
  ggsave(fname, p, width = 10, height = 6, dpi = 150)
}

# Species-specific unit fixes identified from check_species_laa/problem plots saved above.
# E.g., lngt_code == 1 but lngt_clas stored in mm — divide lngt_cm by 10

# Zeus faber (max ~90 cm): first fix unit mismatch, then remove residual
# implausible values above 75 cm (age-1 fish seen above 75 cm in plots)
ca_all <- ca_all |>
  mutate(lngt_cm = if_else(species == "Zeus faber" & lngt_cm > 100,
    lngt_cm / 10, lngt_cm
  )) |>
  filter(!(species == "Zeus faber" & lngt_cm > 75))

# Trisopterus luscus (max ~45 cm)
ca_all <- ca_all |>
  mutate(lngt_cm = if_else(species == "Trisopterus luscus" & lngt_cm > 50,
    lngt_cm / 10, lngt_cm
  ))

# Platichthys flesus (max ~60 cm) — lngt_code 1 in mm, BITS survey only
ca_all <- ca_all |>
  mutate(lngt_cm = if_else(species == "Platichthys flesus" & survey == "BITS" & lngt_cm > 70,
    lngt_cm / 10, lngt_cm
  )) |>
  filter(!(species == "Platichthys flesus" & age > 30))

# Lepidorhombus boscii (max ~45 cm) — horizontal bands at 50-90 in SP-NORTH,
# not a unit fix (dividing gives biologically implausible tiny old fish); remove
ca_all <- ca_all |>
  filter(!(species == "Lepidorhombus boscii" & survey == "SP-NORTH" & lngt_cm > 45))

# Lepidorhombus whiffiagonis (max ~60 cm) — outliers > 65 cm in SP-NORTH and SP-PORC
# Still looks relatively odd...
ca_all <- ca_all |>
  filter(!(species == "Lepidorhombus whiffiagonis" & survey %in% c("SP-NORTH", "SP-PORC") & lngt_cm > 65))

# Lophius piscatorius (NS-IBTS): age-0 fish above 40 cm are impossible for 0-group
ca_all <- ca_all |>
  filter(!(species == "Lophius piscatorius" & survey == "NS-IBTS" & age == 0 & lngt_cm > 40))

# Clupea harengus (NS-IBTS): lngt_code 1 outliers at young ages stored in mm
ca_all <- ca_all |>
  mutate(lngt_cm = if_else(
    species == "Clupea harengus" & survey == "NS-IBTS" & lngt_cm > 60,
    lngt_cm / 10, lngt_cm
  ))

# Conger conger (max ~300 cm): values above 400 are mm not converted
ca_all <- ca_all |>
  mutate(lngt_cm = if_else(
    species == "Conger conger" & lngt_cm > 400,
    lngt_cm / 10, lngt_cm
  ))

# Engraulis encrasicolus (NS-IBTS): lngt_code 1 cloud at age 1 sits at 20-37 cm,
# above species max (~20 cm). Dividing by 10 gives 2-4 cm at age 1 which is too
# small — not a simple unit fix. Remove lngt_code 1 records above species max.
ca_all <- ca_all |>
  filter(!(species == "Engraulis encrasicolus" & survey == "NS-IBTS" &
    lngt_code == "1" & lngt_cm > 20))

# Gadus morhua (BITS): cod max ~150 cm; values above 200 cm are erroneous
ca_all <- ca_all |>
  filter(!(species == "Gadus morhua" & survey == "BITS" & lngt_cm > 200))

# Pleuronectes platessa (max ~95 cm): values above 100 cm are erroneous
ca_all <- ca_all |>
  filter(!(species == "Pleuronectes platessa" & lngt_cm > 100))

# Sardina pilchardus (NS-IBTS): lngt_code 1 cloud at age 1 sits at 19-34 cm,
# far above lngt_code 0 at same age (7-17 cm); ages 3+ overlap fine so only
# age-1 lngt_code 1 records above 17 cm are removed
ca_all <- ca_all |>
  filter(!(species == "Sardina pilchardus" & survey == "NS-IBTS" &
    lngt_code == "1" & age == 1 & lngt_cm > 17))

# Scophthalmus maximus (max ~100 cm): values above 100 cm are erroneous
ca_all <- ca_all |>
  filter(!(species == "Scophthalmus maximus" & lngt_cm > 100))

# Sprattus sprattus (BITS): handful of lngt_code 1 dots at 16-30 cm at age 1-2;
# sprat max ~19 cm and /10 gives 1.6-3 cm (too small) — remove them
ca_all <- ca_all |>
  filter(!(species == "Sprattus sprattus" & survey == "BITS" &
    lngt_code == "1" & lngt_cm > 20))

# Phycis blennoides: no clear fix identified from plots

# Replot fixed species to verify
problem_species <- c(
  "Zeus faber", "Trisopterus luscus", "Platichthys flesus",
  "Lepidorhombus boscii", "Lepidorhombus whiffiagonis",
  "Lophius piscatorius", "Clupea harengus", "Conger conger",
  "Engraulis encrasicolus", "Gadus morhua", "Pleuronectes platessa",
  "Sardina pilchardus", "Scophthalmus maximus", "Sprattus sprattus"
)

for (sp in problem_species) {
  sp_data <- ca_all |> filter(species == sp)
  if (nrow(sp_data) == 0) next

  p <- sp_data |>
    ggplot(aes(age, lngt_cm, color = lngt_code)) +
    geom_point(alpha = 0.75) +
    facet_wrap(~survey, scales = "free") +
    labs(title = paste(sp, "(fixed)"), x = "Age", y = "Length (cm)", color = "LngtCode")

  fname <- file.path(
    home, "cleaning_codes/north_east_atlantic_datras/check_species_laa",
    paste0(gsub(" ", "_", sp), "_fixed.png")
  )
  ggsave(fname, p, width = 10, height = 6, dpi = 150)
}

# Sex of the aged fish: F, M or U (unsexed, including blank and other codes)
ca_all <- ca_all |> mutate(sex = if_else(sex %in% c("F", "M"), sex, "U"))

# Sampling type of the aged fish (unknown, random, length-stratified, ...).
# This matters for if the individual-level analysis needs to to be weighted or not
# TODO: for each survey, we'll make a lookup-table with that information and join
# in here. For now, unknown (but most likely dominated by length-stratfied sampling)
ca_all <- ca_all |> mutate(sampling_type = "unknown")

# Length type: assumed total length for all records (see cleaning_codes/north_east_atlantic_datras/cleaning_notes/nea_datras_length_type.md)
ca_all <- ca_all |> mutate(length_type = "total")
hl_all <- hl_all |> mutate(length_type = "total")

# Keep length frequencies only for the species kept in the aged data
hl_all <- hl_all |> filter(species %in% unique(ca_all$species))

# Same length cuts in the catch as in the aged fish above, where the catch has these errors too (other rules: none beyond, or age-specific)
hl_all <- hl_all |>
  filter(!(species == "Sprattus sprattus" & survey == "BITS" & lngt > 20)) |>
  filter(!(species == "Engraulis encrasicolus" & survey == "NS-IBTS" & lngt > 20))

# -----------------------------------------------------------------------------
# Catch unknown (NA) instead of zero (see cleaning_codes/north_east_atlantic_datras/cleaning_notes/nea_datras_catch_zeros.md)
# -----------------------------------------------------------------------------
# Standard species per survey: list on the DATRAS download form (scraped 2026-11-14)
standard_species <- read.csv(file.path(home, "cleaning_codes/north_east_atlantic_datras/datras_standard_species.csv")) |>
  mutate(standard = TRUE)

# Taxonomic order, for gadoids (BySpecRecCode 3) and flatfish (4)
data("species_info", package = "DATRASextra")
taxon_order <- species_info |>
  distinct(valid_aphia = WoRMS_AphiaID, order) |>
  distinct(valid_aphia, .keep_all = TRUE)

# Species of each survey (those with length frequencies)
survey_species <- hl_all |> distinct(survey, valid_aphia, species)

# Haul x species in the HL table (valid catch records with or without lengths, or invalid catch records)
in_hl <- bind_rows(
  hl_all |> distinct(haul_id, valid_aphia),
  hl_invalid_all |> distinct(haul_id, valid_aphia),
  hl_nolength_all |> distinct(haul_id, valid_aphia)
) |>
  distinct() |>
  mutate(in_hl = TRUE)

# All haul x species of each survey, with BySpecRecCode, year and country of the haul
by_catch_partial <- c(0, 3, 4, 5)

grid <- haul_all |>
  mutate(
    haul_id = as.character(haul_id),
    year = as.integer(sub("^[^:]*:([0-9]+):.*", "\\1", haul_id)),
    partial = by_spec_rec_code %in% by_catch_partial
  ) |>
  dplyr::select(haul_id, survey, country, year, partial, by_spec_rec_code) |>
  left_join(survey_species, by = "survey", relationship = "many-to-many") |>
  filter(!is.na(valid_aphia)) |>
  left_join(in_hl, by = c("haul_id", "valid_aphia")) |>
  left_join(standard_species, by = c("survey", "species")) |>
  left_join(taxon_order, by = "valid_aphia") |>
  mutate(
    in_hl = coalesce(in_hl, FALSE),
    standard = coalesce(standard, FALSE),
    survey_has_standard = survey %in% standard_species$survey
  ) |>
  # Caught in hauls with BySpecRecCode 0, 3, 4 or 5 of the same survey x year x country
  mutate(caught_in_partial = any(in_hl & partial), .by = c(survey, year, country, valid_aphia))

# Not recorded: not in HL, by-catch not or only partly recorded, and none of the exceptions
not_recorded <- grid |>
  filter(
    !in_hl, partial, survey_has_standard, !standard, !caught_in_partial,
    !(by_spec_rec_code %in% 3 & order %in% "Gadiformes"),
    !(by_spec_rec_code %in% 4 & order %in% "Pleuronectiformes")
  ) |>
  distinct(haul_id, valid_aphia)

# Catch unknown: only invalid catch records, valid catch records without lengths, or not recorded
catch_unknown <- bind_rows(
  bind_rows(hl_invalid_all, hl_nolength_all) |>
    left_join(survey_species |> distinct(survey, valid_aphia) |> mutate(kept = TRUE), by = c("survey", "valid_aphia")) |>
    filter(kept) |>
    distinct(haul_id, valid_aphia),
  not_recorded
) |>
  filter(haul_id %in% as.character(haul_all$haul_id)) |>
  distinct()

# -----------------------------------------------------------------------------
# Build the output tables (names follow FISHGLOB; length only in cm)
# -----------------------------------------------------------------------------

# Aged fish: identical records merged, n summed; the only table with the scientific name
ind_age <- ca_all |>
  count(haul_id, valid_aphia, species, lngt_cm, age, sex, ind_wgt, sampling_type, length_type, wt = n, name = "n") |>
  dplyr::rename(aphia_id = valid_aphia, lngt = lngt_cm) |>
  # haul_id is a factor in the DATRAS data; character as in the template
  mutate(haul_id = as.character(haul_id))

# Length frequencies: one row per haul x species x 1 cm bin where caught (lngt = lower bound), and one NA row per haul x species with catch unknown (zeros: join with haul)
# num: whole fish (rounded per bin by DATRASextra)
stopifnot(all(hl_all$num == round(hl_all$num)), all(hl_all$lngt == floor(hl_all$lngt)))
len_freq <- hl_all |>
  dplyr::select(haul_id, aphia_id = valid_aphia, lngt, length_type, num, wgt) |>
  mutate(num = as.integer(num)) |>
  bind_rows(catch_unknown |> dplyr::select(haul_id, aphia_id = valid_aphia) |> mutate(length_type = "total")) |>
  # Sorted rows compress better
  arrange(haul_id, aphia_id, lngt) |>
  # Plain data frame, as all outputs (same behaviour with or without tibble loaded)
  as.data.frame()

# Hauls: all hauls kept by clean_datras() in surveys with length frequencies (needed to create zeros)
haul <- haul_all |>
  filter(survey %in% survey[haul_id %in% len_freq$haul_id]) |>
  mutate(haul_id = as.character(haul_id), region = "North East Atlantic (DATRAS)") |>
  dplyr::select(haul_id, survey, region, date, latitude = lat, longitude = lon, gear, depth, effort, effort_type)

dir.create(file.path(home, "outputs/north_east_atlantic_datras"), recursive = TRUE, showWarnings = FALSE)
saveRDS(haul, file.path(home, "outputs/north_east_atlantic_datras/nea_datras_haul.rds"))
saveRDS(len_freq, file.path(home, "outputs/north_east_atlantic_datras/nea_datras_len_freq.rds"))
saveRDS(ind_age, file.path(home, "outputs/north_east_atlantic_datras/nea_datras_ind_age.rds"))
