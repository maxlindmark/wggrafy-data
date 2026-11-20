# Purpose:   Map of haul locations across all regions.
#
# Input:     outputs/haul_all.rds
#
# Output:    summary/map_cleaned_data.png
#
# Modified:  2026-11-20
# Author:    Max Lindmark

library(dplyr)
library(ggplot2)
theme_set(theme_light())
library(rnaturalearth)
library(sf)
library(here)
home <- here::here()

haul_locs <- readRDS(file.path(home, "outputs/haul_all.rds"))

world <- ne_countries(scale = "large", returnclass = "sf")

# Crop the map to the extent of the data, with a small buffer
pad <- 0.03
xlim <- range(haul_locs$longitude, na.rm = TRUE)
ylim <- range(haul_locs$latitude, na.rm = TRUE)
xlim <- xlim + c(-1, 1) * diff(xlim) * pad
ylim <- ylim + c(-1, 1) * diff(ylim) * pad

ggplot() +
  geom_point(
    data = haul_locs, aes(longitude, latitude, color = survey),
    alpha = 0.1, size = 0.02
  ) +
  geom_sf(data = world, fill = "grey85", color = "grey50", linewidth = 0.05) +
  coord_sf(xlim = xlim, ylim = ylim, expand = FALSE) +
  scale_color_viridis_d() +
  theme(
    legend.position = "bottom",
    legend.title = element_blank(),
    legend.text = element_text(size = 6),
    legend.key.size = unit(0.3, "cm"),
    legend.key.spacing = unit(0.05, "cm"),
    legend.spacing.x = unit(0.05, "cm"),
    legend.margin = margin(0, 0, 0, 0),
    legend.box.margin = margin(0, 0, 0, 0)
  ) +
  guides(color = guide_legend(
    ncol = 8,
    override.aes = list(size = 2, alpha = 1)
  )) +
  labs(x = "Longitude", y = "Latitude", color = "Region")

ggsave(file.path(home, "summary/map_cleaned_data.png"),
  width = 18, height = 11, units = "cm", dpi = 300
)
