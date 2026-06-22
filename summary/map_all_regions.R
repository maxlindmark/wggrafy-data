# Purpose:   Map of haul locations across all regions.
#
# Input:     outputs/length_all.rds
#
# Output:    summary/map_cleaned_data.png
#
# Modified:  2026-06-22
# Author:    Max Lindmark

library(dplyr)
library(ggplot2)
theme_set(theme_light())
library(rnaturalearth)
library(sf)
library(here)
home <- here::here()

length_all <- readRDS(file.path(home, "outputs/length_all.rds"))

haul_locs <- length_all |>
  distinct(haul_id, lon, lat, region)

world <- ne_countries(scale = "large", returnclass = "sf")

ggplot() +
  geom_point(
    data = haul_locs, aes(lon, lat, color = region),
    alpha = 1, size = 0.05
  ) +
  geom_sf(data = world, fill = "grey85", color = "grey50", linewidth = 0.05) +
  # coord_sf(
  #   xlim = range(haul_locs$lon) + c(-85, 85),
  #   ylim = range(haul_locs$lat) + c(-85, 80)
  # ) +
  coord_sf(expand = 0) +
  scale_color_viridis_d() +
  theme(
    legend.position = "bottom",
    legend.title = element_blank()
  ) +
  guides(color = guide_legend(override.aes = list(size = 2, alpha = 1))) +
  labs(x = "Longitude", y = "Latitude", color = "Region")

ggsave(file.path(home, "summary/map_cleaned_data.png"),
  width = 18, height = 11, units = "cm", dpi = 300
)
