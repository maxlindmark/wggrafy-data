# ICES DATRAS surveys

[DATRAS](https://datras.ices.dk) (Database of Trawl Surveys) is the ICES database of trawl survey data. The data are in the DATRAS exchange format, with three record types: hauls (HH), length frequencies of the catch (HL) and aged fish (CA). We download them with `DATRASextra::download_datras()` and process all surveys in one pipeline, [`cleaning_codes/north_east_atlantic_datras/`](../cleaning_codes/north_east_atlantic_datras/). How we clean the data (corrections, decisions and open issues) is documented in its [`cleaning_notes/`](../cleaning_codes/north_east_atlantic_datras/cleaning_notes/), with the open issues in the To do section of each note.

## Sources

- [DATRAS survey list](https://datras.ices.dk/home/surveycode.aspx): name, survey code, metadata record, coordinating working group and protocol of each survey.
- [ICES Survey Protocols](https://ices-library.figshare.com/collections/ICES_Survey_Protocols/6315609): the survey manuals, in the Series of ICES Survey Protocols (SISP, 2012–2020) and from 2021 in Techniques in Marine Environmental Sciences (TIMES). It has newer versions of some of the manuals linked from the survey list.
- [DATRAS exchange format](https://www.ices.dk/data/data-portals/Pages/DATRAS_format_description.aspx), with the codes in the [ICES vocabulary](https://vocab.ices.dk/).

## Surveys

The 24 surveys we download and use (the others are skipped in `get_north_east_atlantic_datras.R`). Name, coordinating working group and protocol are from the DATRAS survey list (where it gives none, the cell is empty); years (first–last, and the number of years with data), quarters, countries and hauls are from `outputs/north_east_atlantic_datras/nea_datras_haul.rds` (quarter and country as in `haul_id`).

| Survey | Name | Coordinating WG | Protocol | Years (number) | Quarters | Countries | Hauls |
|---|---|---|---|---|---|---|---|
| BITS | Baltic International Trawl Survey | WGBIFS | [SISP 7](https://doi.org/10.17895/ices.pub.2883) | 1991–2025 (35) | 1, 2, 3, 4 | DE, DK, EE, LT, LV, PL, RU, SE | 17,784 |
| BTS | Beam Trawl International Survey; also Western Channel and Celtic Sea (Q1), Eastern Channel and Southern North Sea (Q3), Irish Sea and Bristol Channel (Q3) | WGBEAM | [Offshore beam trawl](https://doi.org/10.17895/ices.pub.21603336) | 1985–2025 (41) | 1, 3 | BE, DE, GB, NL | 19,887 |
| BTS-VIII | Beam Trawl Survey - Bay of Biscay | WGBEAM | [Offshore beam trawl](https://doi.org/10.17895/ices.pub.21603336) | 2007–2024 (18) | 4 | FR | 1,386 |
| DYFS | Demersal Young Fish Survey | WGBEAM | [Inshore beam trawl](https://doi.org/10.17895/ices.pub.25382437) | 1985–2025 (41) | 3, 4 | BE, DE, NL | 17,435 |
| EVHOE | French Southern Atlantic Bottom Trawl Survey | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 1997–2024 (28) | 4 | FR | 3,853 |
| FR-CGFS | French Channel Groundfish Survey | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 2006–2024 (19) | 4 | FR | 1,565 |
| FR-WCGFS | French Channel Groundfish Survey | | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 2018–2024 | 3 (7) | FR | 315 |
| IE-IAMS | Irish Anglerfish and Megrim Survey | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 2016–2024 (9) | 1, 2 | IE | 1,007 |
| IE-IGFS | Irish Groundfish Survey | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 2003–2024 (22) | 4 | IE | 3,501 |
| NIGFS | Northern Ireland Groundfish Survey | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 2008–2024 (17) | 1, 4 | GB-NIR | 1,838 |
| NL-BSAS | Netherlands Industry survey on Turbot and Brill | WGBEAM | [WUR report C037/21](https://edepot.wur.nl/544588) | 2019–2025 (7) | 3, 4 | NL | 408 |
| NS-IBTS | North Sea International Bottom Trawl Survey | IBTSWG | [SISP 10](https://doi.org/10.17895/ices.pub.5713) | 1965–2025 (61) | 1, 2, 3, 4 | DE, DK, FR, GB, GB-SCT, NL, NO, SE, SUHH | 36,242 |
| NS-IDPS | Norwegian Sea International Deep Pelagic Survey | WGIDEEPS | [SISP 11](https://doi.org/10.17895/ices.pub.7584) | 2009–2016 (3) | 3 | NO | 249 |
| NSSS | North Sea Sandeel Survey | | | 2012–2024 | 4 (13) | DK | 3,612 |
| PT-IBTS | Portuguese International Bottom Trawl Survey | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 2002–2023 (17) | 4 | PT | 1,367 |
| ROCKALL | Scottish Rockall Survey (Old) | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 1999–2009 (9) | 3 | GB-SCT | 364 |
| SCOROC | Scottish Rockall Bottom Trawl Survey | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 2011–2025 (15) | 3 | GB-SCT | 636 |
| SCOWCGFS | Scottish Westcoast Groundfish Survey | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 2011–2025 (15) | 1, 4 | GB-SCT | 1,657 |
| SE-SOUND | Swedish Survey in the Sound | | | 2011–2023 | 1, 3, 4 (13) | SE | 146 |
| SNS | Sole Net Survey | WGBEAM | [Inshore beam trawl](https://doi.org/10.17895/ices.pub.25382437) | 1985–2025 (40) | 3, 4 | NL | 2,138 |
| SP-ARSA | Spanish Gulf of Cadiz Bottom Trawl Survey | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 2003–2023 (19) | 1, 4 | ES | 1,381 |
| SP-NORTH | Spanish North Coast Bottom Trawl Survey | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 1991–2023 (33) | 3, 4 | ES | 4,063 |
| SP-PORC | Spanish Porcupine Bottom Trawl Survey | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 2001–2023 (23) | 3, 4 | ES | 1,860 |
| SWC-IBTS | Scottish westcoast groundfish survey (Old) | IBTSWG | [SISP 15](https://doi.org/10.17895/ices.pub.3519) | 1986–2010 (25) | 1, 2, 4 | GB-SCT | 2,639 |

Working groups: [IBTSWG](https://www.ices.dk/community/groups/pages/ibtswg.aspx) (International Bottom Trawl Survey Working Group), [WGBEAM](https://www.ices.dk/community/groups/Pages/WGBEAM.aspx) (Working Group on Beam Trawl Surveys), [WGBIFS](https://www.ices.dk/community/groups/pages/wgbifs.aspx) (Baltic International Fish Survey Working Group), [WGIDEEPS](https://www.ices.dk/community/groups/Pages/WGIDEEPS.aspx) (Working Group on International Deep Pelagic Ecosystem Surveys).

Protocols:

- SISP 7: Manual for the Baltic International Trawl Surveys (BITS)
- SISP 10: Manual for the North Sea International Bottom Trawl Surveys
- SISP 11: Manual for the International Deep Pelagic Ecosystem Survey in the Irminger Sea and Adjacent Waters
- SISP 15: Manual of the IBTS North Eastern Atlantic Surveys
- Offshore and Inshore beam trawl: ICES Survey Protocols – Offshore Beam Trawl Surveys, and – Manual for Inshore Beam Trawl Surveys, coordinated by WGBEAM
- WUR report C037/21: Industry survey turbot and brill in the North Sea (Wageningen University & Research)

## To do

- Add notes per survey, as in [FISHGLOB's metadata_docs](https://github.com/fishglob/FishGlob_data/tree/main/metadata_docs) (e.g. season, gear and vessel changes, time series), with links to the relevant cleaning notes.
