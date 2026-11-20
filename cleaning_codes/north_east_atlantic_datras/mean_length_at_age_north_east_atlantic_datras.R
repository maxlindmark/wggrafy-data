# Purpose:   Calculate mean length at age (with SE) by survey, species, year,
#            quarter, age and sex for the cleaned NEA DATRAS data.
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
#            get weight 1 so that they are not discarded. Aged fish from haul x species
#            with unknown catch (NA rows in len_freq) are not counted in the number of
#            aged fish per bin, but get the weight of their bin.
#
#            We do this by the 1 cm length bins of len_freq, where the weight is
#            (no. fish caught in its length bin) / (no. fish aged in that bin).
#            Each aged fish is placed in the len_freq bin its length falls in.
#
#            We also carry the sex of the individuals, because fish typically exhibit
#            sexual dimorphism in growth. However, the catch has almost no sex information.
#            Instead, we calculate the fraction of each sex in each
#            length bin in the aged sub-sample, and use that as the fraction of the
#            catch of that sex in that bin. The mean length at age for a sex is then
#            calculated using weights based on assumed sex-specific numbers-at-age.
#            Rows with sex = "all" use all aged fish.
#
# Input:     outputs/north_east_atlantic_datras/nea_datras_ind_age.rds
#            outputs/north_east_atlantic_datras/nea_datras_len_freq.rds
#
# Output:    outputs/north_east_atlantic_datras/nea_datras_mean_length_at_age.rds
#            One row per survey x species x year x quarter x age x sex
#            (sex = F, M, U or all).
#
# Modified:  2026-11-20
# Author:    Max Lindmark

library(dplyr)
library(tidyr)
library(here)
home <- here::here()

# -----------------------------------------------------------------------------
# Sample = survey x species x year x quarter. Survey, year and quarter are parsed
# from the DATRAS haul id (Survey:Year:Quarter:Country:Ship:Gear:StNo:HaulNo).
# Quarter is the DATRAS survey quarter, not the calendar quarter of the date.
# -----------------------------------------------------------------------------
ca <- readRDS(file.path(home, "outputs/north_east_atlantic_datras/nea_datras_ind_age.rds")) |>
  separate_wider_delim(haul_id, delim = ":", names = c("survey", "year", "quarter"), too_many = "drop", cols_remove = FALSE) |>
  mutate(across(c(year, quarter), as.integer))

len_freq <- readRDS(file.path(home, "outputs/north_east_atlantic_datras/nea_datras_len_freq.rds")) |>
  separate_wider_delim(haul_id, delim = ":", names = c("survey", "year", "quarter"), too_many = "drop", cols_remove = FALSE) |>
  mutate(across(c(year, quarter), as.integer))

# Haul x species with catch unknown (NA rows in len_freq); the rest is the known catch
catch_unknown <- len_freq |>
  filter(is.na(num)) |>
  distinct(haul_id, aphia_id) |>
  mutate(catch_unknown = TRUE)
hl <- len_freq |> filter(!is.na(num))

# -----------------------------------------------------------------------------
# N_j: fish in the catch in length bin j, pooled over hauls in the sample
# n_j: aged fish in bin j (all ages and sexes)
# Bins: the 1 cm bins of len_freq (lngt to lngt + 1)
# -----------------------------------------------------------------------------
stopifnot(all(hl$lngt == floor(hl$lngt)))
catch_bin <- hl |>
  rename(lngt_bin = lngt) |>
  summarise(N_j = sum(num), .by = c(survey, aphia_id, year, quarter, lngt_bin))

# Aged fish in the 1 cm bin their length falls in.
# n_j counts only aged fish from haul x species with known catch, as N_j has only their catch
aged <- ca |>
  left_join(catch_unknown, by = c("haul_id", "aphia_id")) |>
  mutate(
    catch_unknown = coalesce(catch_unknown, FALSE),
    lngt_bin = floor(lngt + 1e-9)
  ) |>
  mutate(n_j = sum(n[!catch_unknown]), .by = c(survey, aphia_id, year, quarter, lngt_bin)) |>
  left_join(catch_bin, by = c("survey", "aphia_id", "year", "quarter", "lngt_bin"))

# Each aged fish stands for w = N_j / n_j fish in its bin, so that
# N_ij = N_j * n_ij / n_j = sum of w over aged fish of age i in bin j.
# Aged fish from haul x species with unknown catch get the w of their bin.
# w = 1 for random sampling, and where the catch is unknown (no catch in the
# bin, or no aged fish with known catch in it); the estimates below are then
# the plain mean and variance (Bettoli & Miranda eqs. 1 and 2). No aged fish are excluded.
aged <- aged |>
  mutate(w = if_else(sampling_type %in% "random" | is.na(N_j) | N_j == 0 | n_j == 0, 1, N_j / n_j))

# -----------------------------------------------------------------------------
# Bettoli & Miranda (2001):
#   N_i   = sum_j N_ij
#   L_i   = sum_j N_ij * mean(l_ij) / N_i                                 (eq. 3)
#   S2_i  = sum_j N_ij * [sum_k (l_ijk - L_i)^2 / n_ij] / (N_i - 1)       (eq. 4a)
#   SE_i  = sqrt(S2_i / N_i)
# With w = N_j / n_j these are the weighted mean and variance below (rows weighted by n * w).
# For a sex, n_ij is the number of aged fish of that sex (n_j still counts all
# aged fish in the bin, sexed and unsexed).
# -----------------------------------------------------------------------------
laa <- function(d, by) {
  d |>
    summarise(
      n_fish = sum(n),
      N_i = sum(n * w),
      mean_lngt = sum(n * w * lngt) / N_i,
      var_lngt = if_else(N_i > 1, sum(n * w * (lngt - mean_lngt)^2) / (N_i - 1), NA_real_),
      .by = all_of(by)
    )
}

by_sample <- c("aphia_id", "survey", "year", "quarter", "age", "sampling_type", "length_type")

rows_all <- laa(aged, by_sample) |> mutate(sex = "all")
rows_sex <- laa(aged, c(by_sample, "sex"))

mean_length_at_age <- bind_rows(rows_sex, rows_all) |>
  mutate(region = "North East Atlantic (DATRAS)") |>
  # SE needs at least two aged fish (and N_i > 1, otherwise var_lngt is NA)
  mutate(se_lngt = if_else(n_fish >= 2, sqrt(var_lngt / N_i), NA_real_)) |>
  select(
    aphia_id, survey, region, year, quarter, age, sex,
    sampling_type, length_type, mean_lngt, se_lngt, n_fish
  ) |>
  arrange(survey, aphia_id, year, quarter, age, sex) |>
  # Plain data frame, as all outputs (same behaviour with or without tibble loaded)
  as.data.frame()

saveRDS(mean_length_at_age, file.path(home, "outputs/north_east_atlantic_datras/nea_datras_mean_length_at_age.rds"))
