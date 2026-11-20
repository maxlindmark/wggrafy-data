# Purpose:   Workflow figure for the README: from the survey database to the
#            stored tables, the data products made by joins, and the merge.
#            Colours (viridis mako without its darkest colour, lightened):
#            raw data, scripts, stored tables, data products made with joins
#            (not stored), merged tables. Black dots: joins (where the arrows
#            of the joined tables meet).
#
# Output:    summary/workflow.png
#
# Modified:  2026-11-18
# Author:    Max Lindmark

library(DiagrammeR)
library(DiagrammeRsvg)
library(rsvg)
library(here)
home <- here::here()

# mako without its darkest colour, mixed with white (40% colour); black text
lighten <- function(x, a = 0.4) {
  rgb(t(255 - a * (255 - col2rgb(x))), maxColorValue = 255)
}
cols <- setNames(
  lighten(viridisLite::mako(6)[2:6]),
  c("COL_RAW", "COL_SCRIPT", "COL_TABLE", "COL_PRODUCT", "COL_MERGED")
)

workflow <- "
digraph workflow {
  graph [rankdir = TB, fontname = Helvetica, nodesep = 0.3, ranksep = 0.6]
  node  [shape = box, style = 'rounded,filled', fontname = Helvetica, fontsize = 14, fillcolor = 'COL_TABLE', fontcolor = black]
  edge  [color = grey40, fontname = Helvetica, fontsize = 11]

  source [label = 'Survey database\\n(e.g. DATRAS)', fillcolor = 'COL_RAW']
  get    [label = 'get_<region>.R\\ndownloads and collates the raw survey data', fillcolor = 'COL_SCRIPT']
  clean  [label = 'clean_<region>.R\\nclean, correct, reformat', fillcolor = 'COL_SCRIPT']

  haul     [label = <<B>haul</B><BR/>one row per haul, all hauls of the surveys<BR/><BR/>haul_id, survey, region, date,<BR/>latitude, longitude, gear, depth,<BR/>effort, effort_type>]
  len_freq [label = <<B>len_freq</B><BR/>one row per haul x species x length bin,<BR/>only where caught (NA where catch unknown)<BR/><BR/>haul_id, aphia_id, lngt,<BR/>length_type, num, wgt>]
  ind_age  [label = <<B>ind_age</B><BR/>one row per unique aged fish record<BR/>(n = number of fish)<BR/><BR/>haul_id, aphia_id, species, lngt, age,<BR/>sex, ind_wgt, sampling_type, length_type, n>]

  density [label = 'Density including zeros\\ncatch (kg or numbers) / effort, all hauls', fillcolor = 'COL_PRODUCT']
  spatial [label = 'Spatially explicit length at age\\none row per fish, with position and date', fillcolor = 'COL_PRODUCT']
  mlaa    [label = <<B>mean_length_at_age</B><BR/>one row per survey x species x year x quarter x age x sex<BR/>(mean_length_at_age_&lt;region&gt;.R)<BR/><BR/>aphia_id, survey, region, year, quarter, age,<BR/>sex, sampling_type, length_type, mean_lngt, se_lngt, n_fish>]

  merge [label = 'merge.R\\nbind_rows() per table across regions: haul, len_freq, ind_age\\nand mean_length_at_age (one file per table),\\nand updates the surveys table in the README', fillcolor = 'COL_SCRIPT']
  all   [label = 'outputs/<table>_all.rds', fillcolor = 'COL_MERGED']

  {rank = same; haul -> len_freq -> ind_age [style = invis]}
  {rank = same; density -> spatial -> mlaa [style = invis]}

  source -> get -> clean
  clean -> haul; clean -> len_freq; clean -> ind_age

  node [shape = point, width = 0.12, fillcolor = black, label = '']
  j_density; j_spatial; j_mlaa

  edge [arrowhead = none]
  haul -> j_density; len_freq -> j_density
  haul -> j_spatial; len_freq -> j_spatial; ind_age -> j_spatial
  len_freq -> j_mlaa; ind_age -> j_mlaa

  edge [arrowhead = normal]
  j_density -> density [label = '  catch = len_freq summed per haul x species\\l  left: all hauls x species of each survey (from haul)\\l  left_join(catch, by = c(\\\"haul_id\\\", \\\"aphia_id\\\"))\\l  0 where the species is not in len_freq; NA (catch unknown) stays NA\\l']
  j_spatial -> spatial [label = '  left_join(ind_age, haul, by = \\\"haul_id\\\")\\l  fish caught and aged per haul x species x length bin,\\l  left_join() to aged fish: reweighting\\l  tidyr::uncount(n): one row per fish\\l']
  j_mlaa -> mlaa [label = '  survey, year, quarter from haul_id\\l  fish caught and aged per survey x species x year\\l  x quarter x length bin, left_join() to aged fish\\l']

  mlaa -> merge
  merge -> all
}
"

for (k in names(cols)) workflow <- gsub(k, cols[[k]], workflow, fixed = TRUE)

svg <- export_svg(grViz(workflow))
rsvg_png(charToRaw(svg), file.path(home, "summary/workflow.png"), width = 2000)
