# Purpose:   Share of hauls with more aged than caught fish (for at least one
#            species) per survey and year, NEA DATRAS. Figure for
#            cleaning_codes/north_east_atlantic_datras/cleaning_notes/nea_datras_n_k_issue.md.
#
# Input:     outputs/north_east_atlantic_datras/nea_datras_ind_age.rds
#            outputs/north_east_atlantic_datras/nea_datras_len_freq.rds
#
# Output:    cleaning_codes/north_east_atlantic_datras/cleaning_notes/figures/n_k_trend_nea_datras.png
#
# Modified:  2026-11-20
# Author:    Max Lindmark

library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_light())
library(here)
home <- here::here()

ind_age <- readRDS(file.path(home, "outputs/north_east_atlantic_datras/nea_datras_ind_age.rds"))
len_freq <- readRDS(file.path(home, "outputs/north_east_atlantic_datras/nea_datras_len_freq.rds"))

# Haul x species with unknown catch (NA rows) are left out; not in len_freq = 0 caught
catch_unknown <- len_freq |>
  filter(is.na(num)) |>
  distinct(haul_id, aphia_id) |>
  mutate(unknown = TRUE)

caught <- len_freq |>
  filter(!is.na(num)) |>
  summarise(caught = sum(num), .by = c(haul_id, aphia_id))

# Aged fish with a pooled haul id (haul unknown) are left out
hauls <- ind_age |>
  filter(!grepl(":pooled:", haul_id)) |>
  summarise(aged = sum(n), .by = c(haul_id, aphia_id)) |>
  left_join(catch_unknown, by = c("haul_id", "aphia_id")) |>
  filter(is.na(unknown)) |>
  left_join(caught, by = c("haul_id", "aphia_id")) |>
  mutate(caught = coalesce(caught, 0)) |>
  summarise(more_aged = any(aged > caught), .by = haul_id) |>
  separate_wider_delim(haul_id, delim = ":", names = c("survey", "year", "quarter", "country"), too_many = "drop", cols_remove = FALSE) |>
  mutate(across(c(year, quarter), as.integer))

# Surveys with 2% or more of hauls affected; BTS and DYFS split into Dutch and other hauls
top <- hauls |>
  summarise(pct = 100 * mean(more_aged), .by = survey) |>
  filter(pct >= 2) |>
  pull(survey)

trend <- hauls |>
  filter(survey %in% top) |>
  mutate(group = case_when(
    survey %in% c("BTS", "DYFS") & country == "NL" ~ paste(survey, "(NL)"),
    survey %in% c("BTS", "DYFS") ~ paste(survey, "(other countries)"),
    TRUE ~ survey
  )) |>
  summarise(hauls = n(), pct = 100 * mean(more_aged), .by = c(group, year)) |>
  filter(hauls >= 10)

ggplot(trend, aes(year, pct)) +
  geom_line(color = "grey60") +
  geom_point(aes(size = hauls), alpha = 0.6) +
  facet_wrap(~group, ncol = 3) +
  scale_size_area(max_size = 3) +
  labs(
    x = "Year",
    y = "% of hauls with more aged than caught fish",
    size = "Hauls with aged fish",
    caption = "Years with at least 10 hauls with aged fish"
  ) +
  theme(legend.position = "bottom")

ggsave(file.path(home, "cleaning_codes/north_east_atlantic_datras/cleaning_notes/figures/n_k_trend_nea_datras.png"), width = 20, height = 20, unit = "cm")
