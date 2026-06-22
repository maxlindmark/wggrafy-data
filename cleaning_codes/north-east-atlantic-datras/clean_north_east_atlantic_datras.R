# Purpose:   Filter and clean DATRAS output from
#            get_north_east_atlantic_datras.R.
#
# Input:     cleaning_codes/north-east-atlantic-datras/merged_survey_data.rds
#
# Output:    outputs/nea_datras_length_clean.rds
#            outputs/nea_datras_catch_clean.rds
#            cleaning_codes/north-east-atlantic-datras/check_species_laa/*.png
#            information for metadata_docs
#
# Modified:  2026-06-22
# Author:    Max Lindmark

library(tidyr)
library(dplyr)
library(lubridate)
library(ggplot2)
theme_set(theme_light())
library(here)
library(writexl)
home <- here::here()

results <- readRDS(file.path(home, "cleaning_codes/north-east-atlantic-datras/merged_survey_data.rds"))

# -----------------------------------------------------------------------------
# Load processed survey data
# -----------------------------------------------------------------------------
ca_all <- bind_rows(lapply(names(results), function(s) {
  df <- results[[s]]$ca
  if (nrow(df) == 0) {
    return(NULL)
  }
  df |> mutate(
    survey = s, lngt_code = as.character(lngt_code),
    year = year(date)
  )
}))

head(ca_all$year)

hl_all <- bind_rows(lapply(names(results), function(s) {
  df <- results[[s]]$hl
  if (nrow(df) == 0) {
    return(NULL)
  }
  df |> mutate(survey = s)
}))

# -----------------------------------------------------------------------------
# Hard filters
# -----------------------------------------------------------------------------

# Age must be a non-negative integer; age == 0 (0-group) is valid
ca_all <- ca_all |> filter(!is.na(age), age >= 0)

# Drop hauls with missing coordinates (small number of DATRAS source gaps)
ca_all <- ca_all |> filter(!is.na(lon), !is.na(lat))

# Lon/lat sanity (Atlantic + European shelf)
# ca_all <- ca_all |> filter(lon > -40, lon < 40, lat > 30, lat < 90)

# Drop species with fewer than 100 individuals total across all surveys
ca_all <- ca_all |>
  add_count(species, name = "n_total") |>
  filter(n_total >= 100) |>
  dplyr::select(-n_total)

# -----------------------------------------------------------------------------
# Look for errors in data (specifically length codes).
# -----------------------------------------------------------------------------
# We are not necessarily removing outliers here unless they are obvious and
# obscure visual comparison

# Length
ggplot(ca_all, aes(lngt_cm)) +
  geom_histogram(bins = 80) +
  facet_wrap(~species, scales = "free") +
  labs(title = "Length distribution by species")

# Age
ggplot(ca_all, aes(age)) +
  geom_histogram(binwidth = 1) +
  facet_wrap(~species, scales = "free") +
  labs(title = "Age distribution by species")

# Weight (many NAs expected)
ca_all |>
  filter(!is.na(ind_wgt)) |>
  ggplot(aes(ind_wgt)) +
  geom_histogram(bins = 60) +
  facet_wrap(~species, scales = "free") +
  labs(title = "Individual weight distribution by species")

# Length vs age per species, coloured by lngt_code, saved individually so
# unit mismatches are easy to spot and fix species by species
dir.create(file.path(home, "cleaning_codes/north-east-atlantic-datras/check_species_laa"), recursive = TRUE, showWarnings = FALSE)

for (sp in sort(unique(ca_all$species))) {
  p <- ca_all |>
    filter(species == sp) |>
    ggplot(aes(age, lngt_cm, color = lngt_code)) +
    geom_jitter(width = 0.2, height = 0) +
    facet_wrap(~survey, scales = "free") +
    labs(title = sp, x = "Age", y = "Length (cm)", color = "LngtCode")

  fname <- file.path(
    home, "cleaning_codes/north-east-atlantic-datras/check_species_laa",
    paste0(gsub(" ", "_", sp), ".png")
  )
  ggsave(fname, p, width = 10, height = 6, dpi = 150)
}

# Species-specific unit fixes identified from check_species_laa/problem plots.
# Pattern: lngt_code == 1 but lngt_clas stored in mm — divide lngt_cm by 10
# where values exceed a species-specific plausible maximum.

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
    home, "cleaning_codes/north-east-atlantic-datras/check_species_laa",
    paste0(gsub(" ", "_", sp), "_fixed.png")
  )
  ggsave(fname, p, width = 10, height = 6, dpi = 150)
}

# Add region label before saving
ca_all <- ca_all |> mutate(region = "North East Atlantic (DATRAS)")
hl_all <- hl_all |>
  mutate(region = "North East Atlantic (DATRAS)") |>
  filter(species %in% unique(ca_all$species))

saveRDS(ca_all, file.path(home, "outputs/nea_datras_length_clean.rds"))
saveRDS(hl_all, file.path(home, "outputs/nea_datras_catch_clean.rds"))
