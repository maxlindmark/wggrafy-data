# Purpose:   Calculate mean length at age (with SE) by survey, species, year, quarter,
#            age and sex for the cleaned NEA DATRAS data.
#
#            In case we want to work with aggregated data, such as mean length-at-age,
#            we will get biased estimates if we calculate a naive mean on the aged
#            subsample unless its randomly sampled. In the case of length-stratified
#            sampling, the correct way is to extrapolate the subsample to the catch, i.e.
#            to calculate an inverse-sampling-fraction weighted mean length at age.
#            (Bettoli & Miranda 2001)
#
#            The column sampling_type says how the aged fish were sampled. If it is
#            "random", the aged subsample represents the catch and the plain mean is
#            used (Bettoli & Miranda 2001, eqs. 1 and 2), which needs no catch data.
#            Otherwise ("length-stratified" or "unknown") the weighted mean is used,
#            except for aged fish in length bins where the catch is unknown, which
#            get weight 1 so that they are not discarded.
#
#            We do this by 1 cm length bins, where the weight is
#            (no. fish caught in its 1 cm length bin) / (no. fish aged in that bin).
#
#            We also carry the sex of the individuals, because fish typically exhibit
#            sexual dimorphism in growth. However, the catch has almost no sex information.
#            Instead, we calculate the fraction of each sex in each
#            length bin in the aged sub-sample, and use that as the fraction of the
#            catch of that sex in that bin. The mean length at age for a sex is then
#            calculated using weights based on assumed sex-specific numbers-at-age.
#            Rows with sex = "all" use all aged fish.
#
# Input:     outputs/north-east-atlantic-datras/nea_datras_length_clean.rds
#            outputs/north-east-atlantic-datras/nea_datras_catch_clean.rds
#
# Output:    outputs/north-east-atlantic-datras/nea_datras_mean_length_at_age.rds
#            One row per survey x species x year x quarter x age x sex
#            (sex = F, M, U or all).
#
# Modified:  2026-09-21
# Author:    Max Lindmark

library(dplyr)
library(tidyr)
library(here)
home <- here::here()

ca <- readRDS(file.path(home, "outputs/north-east-atlantic-datras/nea_datras_length_clean.rds"))
hl <- readRDS(file.path(home, "outputs/north-east-atlantic-datras/nea_datras_catch_clean.rds"))

# -----------------------------------------------------------------------------
# Sample = survey x species x year_num, where year_num = year_quarter.
# Year and quarter are parsed from the DATRAS haul id
# (Survey:Year:Quarter:Country:Ship:Gear:StNo:HaulNo). The catch table has
# neither column, and it includes hauls with no aged fish.
# -----------------------------------------------------------------------------
ca <- ca |>
  separate(haul_id, into = c(NA, "year", "quarter"), sep = ":", extra = "drop", remove = FALSE, convert = TRUE) |>
  mutate(year_num = paste(year, quarter, sep = "_"))

hl <- hl |>
  separate(haul_id, into = c(NA, "year", "quarter"), sep = ":", extra = "drop", remove = FALSE, convert = TRUE) |>
  mutate(year_num = paste(year, quarter, sep = "_"))

# -----------------------------------------------------------------------------
# N_j: fish in the catch in 1 cm length bin j, pooled over hauls in the sample
# n_j: aged fish in bin j (all ages and sexes)
# -----------------------------------------------------------------------------
catch_bin <- hl |>
  filter(!is.na(lngt_cm)) |>
  mutate(lngt_bin = floor(lngt_cm)) |>
  summarise(N_j = sum(n_entire_bin), .by = c(survey, valid_aphia, year_num, lngt_bin))

aged <- ca |>
  mutate(lngt_bin = floor(lngt_cm)) |>
  mutate(n_j = n(), .by = c(survey, valid_aphia, year_num, lngt_bin)) |>
  left_join(catch_bin, by = c("survey", "valid_aphia", "year_num", "lngt_bin"))

# Each aged fish stands for w = N_j / n_j fish in its bin, so that
# N_ij = N_j * n_ij / n_j = sum of w over aged fish of age i in bin j
# w = 1 for random sampling, and where the catch is unknown (no catch in the
# bin); the estimates below are then the plain mean and variance
# (Bettoli & Miranda eqs. 1 and 2). No aged fish are excluded.
aged <- aged |>
  mutate(w = if_else(sampling_type %in% "random" | is.na(N_j) | N_j == 0, 1, N_j / n_j))

# -----------------------------------------------------------------------------
# Bettoli & Miranda (2001):
#   N_i   = sum_j N_ij
#   L_i   = sum_j N_ij * mean(l_ij) / N_i                                 (eq. 3)
#   S2_i  = sum_j N_ij * [sum_k (l_ijk - L_i)^2 / n_ij] / (N_i - 1)       (eq. 4a)
#   SE_i  = sqrt(S2_i / N_i)
# With w = N_j / n_j these are the weighted mean and variance below.
# For a sex, n_ij is the number of aged fish of that sex (n_j still counts all
# aged fish in the bin, sexed and unsexed).
# -----------------------------------------------------------------------------
laa <- function(d, by) {
  d |>
    summarise(
      n_fish = n(),
      N_i = sum(w),
      mean_lngt_cm = sum(w * lngt_cm) / N_i,
      var_lngt = if_else(N_i > 1, sum(w * (lngt_cm - mean_lngt_cm)^2) / (N_i - 1), NA_real_),
      .by = all_of(by)
    )
}

by_sample <- c("species", "valid_aphia", "survey", "region", "year", "quarter", "year_num", "age", "sampling_type")

rows_all <- laa(aged, by_sample) |> mutate(sex = "all")
rows_sex <- laa(aged, c(by_sample, "sex"))

mean_length_at_age <- bind_rows(rows_sex, rows_all) |>
  # SE needs at least two aged fish (and N_i > 1, otherwise var_lngt is NA)
  mutate(se_lngt_cm = if_else(n_fish >= 2, sqrt(var_lngt / N_i), NA_real_)) |>
  select(
    species, valid_aphia, survey, region, year, quarter, year_num, age, sex,
    sampling_type, mean_lngt_cm, se_lngt_cm, n_fish
  ) |>
  arrange(survey, species, year, quarter, age, sex)

saveRDS(mean_length_at_age, file.path(home, "outputs/north-east-atlantic-datras/nea_datras_mean_length_at_age.rds"))
