# Purpose:   Summary plots and data coverage table for cleaned NEA DATRAS data.
#
# Input:     outputs/nea_datras_length_clean.rds
#
# Output:    summary/species_overview_nea_datras.png
#            (meta table printed to console)
#
# Modified:  2026-06-22
# Author:    Max Lindmark

library(dplyr)
library(ggplot2)
theme_set(theme_light())
library(ggtext)
library(here)
home <- here::here()

ca_all <- readRDS(file.path(home, "outputs/nea_datras_length_clean.rds"))

# -----------------------------------------------------------------------------
# Species × year coverage bubble plot
# -----------------------------------------------------------------------------
ca_all |>
  summarise(
    n = n(),
    n_surveys = n_distinct(survey),
    .by = c(species, year)
  ) |>
  mutate(
    tot_n = sum(n),
    .by = species
  ) |>
  mutate(species = paste0("*", species, "*")) |>
  ggplot(
    aes(
      x = as.numeric(as.character(year)),
      y = reorder(species, tot_n),
      size = log10(n + 1),
      colour = n_surveys
    )
  ) +
  geom_point(alpha = 0.7) +
  scale_colour_viridis_c(
    name = "N surveys",
    breaks = scales::pretty_breaks()
  ) +
  scale_size_area(
    max_size = 5,
    name = "log(N individuals)"
  ) +
  scale_x_continuous(
    breaks = seq(1950, 2030, by = 4)
  ) +
  labs(
    title = "North East Atlantic (DATRAS)",
    x = "Year",
    y = NULL
  ) +
  guides(
    color = guide_legend(title.position = "top", title.hjust = 0.5),
    size  = guide_legend(title.position = "top", title.hjust = 0.5)
  ) +
  theme(
    axis.text.y.left = element_markdown(),
    legend.position  = "bottom"
  )

ggsave(file.path(home, "summary/species_overview_nea_datras.png"),
  width = 25, height = 30, unit = "cm"
)

# -----------------------------------------------------------------------------
# Data coverage table (printed to console)
# -----------------------------------------------------------------------------
meta <- ca_all |>
  dplyr::summarise(
    n_individuals = n(),
    n_hauls = n_distinct(haul_id),
    n_years = n_distinct(year),
    year_min = min(as.integer(year)),
    year_max = max(as.integer(year)),
    age_min = min(age),
    age_max = max(age),
    lngt_min = min(lngt_cm, na.rm = TRUE),
    lngt_max = max(lngt_cm, na.rm = TRUE),
    .by = c(species, survey)
  ) |>
  dplyr::arrange(species, survey)

options(tibble.print_max = 200)
meta
