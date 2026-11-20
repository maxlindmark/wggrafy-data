# Purpose:   Figure for cleaning_notes/nea_datras_catch_zeros.md: how the DATRAS catch data are processed, i.e.
#            what follows DATRASextra::clean_datras() and what is added: SpecVal
#            of the catch records and BySpecRecCode of the hauls, which decide
#            whether a haul x species gets a catch, a zero or NA (unknown), and
#            the 1 cm length bins of the catch.
#            Colours: DATRASextra steps, our additions, outcomes.
#
# Output:    cleaning_codes/north_east_atlantic_datras/cleaning_notes/figures/workflow_datras.png
#
# Modified:  2026-11-20
# Author:    Max Lindmark

library(DiagrammeR)
library(DiagrammeRsvg)
library(rsvg)
library(here)
home <- here::here()

out_file <- file.path(home, "cleaning_codes/north_east_atlantic_datras/cleaning_notes/figures/workflow_datras.png")

# mako without its darkest colour, mixed with white (40% colour); black text
lighten <- function(x, a = 0.4) {
  rgb(t(255 - a * (255 - col2rgb(x))), maxColorValue = 255)
}
cols <- c(
  COL_DX = lighten(viridisLite::mako(6)[3]),
  COL_OURS = lighten("#E8A33D"),
  COL_OUT = lighten(viridisLite::mako(6)[5])
)

workflow <- "
digraph workflow {
  graph [rankdir = TB, fontname = Helvetica, nodesep = 0.5, ranksep = 0.45]
  node  [shape = box, style = 'rounded,filled', fontname = Helvetica, fontsize = 13, fillcolor = 'COL_OURS', fontcolor = black, margin = '0.25,0.1']
  edge  [color = grey40, fontname = Helvetica, fontsize = 12]

  dx [fillcolor = 'COL_DX', label = <<B>DATRASextra</B><BR/>hauls with all standard species recorded<BR/>(StdSpecRecCode 1)>]

  q_rec [label = <<B>For each haul x species</B><BR/>is there a catch record (HL)?>]

  q_specval [label = <<B>SpecVal of the record</B><BR/>(not used in clean_datras())>]
  catch     [label = <<B>valid catch records</B><BR/>SpecVal 1, 2, 4-8, 10<BR/>(2, valid only for commercial or assessed<BR/>species, is taken as valid for all):<BR/>any with lengths?>]
  na_sv     [fillcolor = 'COL_OUT', label = <<B>NA</B><BR/>caught, catch unknown:<BR/>only SpecVal 0, 3 or 9 (not to be used)>]
  na_len    [fillcolor = 'COL_OUT', label = <<B>NA</B><BR/>caught, catch by length unknown:<BR/>no lengths (e.g. SpecVal 4, total number only)>]
  bins      [fillcolor = 'COL_OUT', label = <<B>catch: numbers at length in 1 cm bins</B><BR/>(DATRASextra default: the coarsest length class<BR/>of the survey x species, e.g. 5 cm)<BR/>2 and 5 cm classes spread over their 1 cm bins:<BR/>first at the cm of the aged fish of the haul,<BR/>the rest as whole fish at random cm>]

  q_by    [label = <<B>BySpecRecCode of the haul</B><BR/>(not used in clean_datras())>]
  zero_by [fillcolor = 'COL_OUT', label = <<B>0</B><BR/>1, 2 or 6: all species recorded>]
  q_std   [label = <<B>0, 3, 4 or 5: was the species recorded?</B><BR/>yes if any of:<BR/>standard species of the survey (list on the DATRAS download form)<BR/>the survey has no standard species on that list<BR/>code 3 and a gadoid (Gadiformes)<BR/>code 4 and a flatfish (Pleuronectiformes)<BR/>caught in hauls with code 0, 3, 4 or 5 of the same survey x year x country>]
  zero_std [fillcolor = 'COL_OUT', label = <<B>0</B>>]
  na_std   [fillcolor = 'COL_OUT', label = <<B>NA</B><BR/>not recorded>]

  dx -> q_rec
  q_rec -> q_specval [label = '  yes']
  q_rec -> q_by [label = '  no']
  q_specval -> catch
  catch -> bins [label = '  yes']
  catch -> na_len [label = '  no']
  q_specval -> na_sv
  q_by -> zero_by
  q_by -> q_std
  q_std -> zero_std [label = '  yes']
  q_std -> na_std [label = '  no']
}
"

for (k in names(cols)) workflow <- gsub(k, cols[[k]], workflow, fixed = TRUE)

svg <- export_svg(grViz(workflow))
rsvg_png(charToRaw(svg), out_file, width = 1800)
