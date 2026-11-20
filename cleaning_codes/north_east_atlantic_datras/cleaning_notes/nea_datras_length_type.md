# NEA DATRAS: length type (`length_type`)

`length_type` is `total` for all records in `north_east_atlantic_datras` (set in `cleaning_codes/north_east_atlantic_datras/clean_north_east_atlantic_datras.R`).

In DATRAS, the length measurement type (`LenMeasType`) exists only in the HL (catch) table, not in CA (aged fish). We already know that CA and HL can use different length units (`lngt_code`) within a haul, so we cannot assume that the HL type applies to the aged fish. Since there is no such column in CA, we assume total length for now.

While most records are blank or total length, some are not, and some of those seem mislabeled.

`LenMeasType` is not carried through `get_north_east_atlantic_datras.R`, so it is not in `merged_survey_data.rds`. The numbers below were counted directly from the raw DATRAS downloads in `raw_data/north_east_atlantic_datras/` (all HL rows, all years).

## ICES codes

From the ICES vocabulary `TS_LenMeasType`. There is no fork length code.

| Code | Meaning |
|---|---|
| -9 | Not known |
| 1 | Total length, linear |
| 2 | Standard length |
| 3 | Pre supra-caudal fin length |
| 4 | Pre anal-fin length |
| 5 | Mantle length |
| 6 | Carapace length |
| 7 | Carapace width |
| 8 | Second dorsal fin length |
| 9 | Shell height |
| 10 | Shell width |
| 11 | Wing width |
| 12 | Total length, curved |
| 13 | Pinched tail length |

## Codes for the species in the cleaned data

HL rows for the 59 species (284 survey × species combinations) in the cleaned length-at-age data:

| Code | HL rows |
|---|---|
| blank | 6,204,532 |
| 1 (total length) | 1,481,177 |
| 8 (second dorsal fin length) | 3,536 |
| 6 (carapace length) | 566 |
| 5 (mantle length) | 66 |
| 4 (pre anal-fin length) | 26 |
| 10 (shell width) | 3 |

Several surveys never report the code (all rows blank): IE-IGFS, IE-IAMS, NIGFS, ROCKALL, SCOROC, SCOWCGFS, SP-ARSA, SP-NORTH, SP-PORC and SWC-IBTS.

## Records that are neither blank nor total length

| Survey | Species | Code | HL rows |
|---|---|---|---|
| NS-IBTS | *Scomber scombrus* | 8 (second dorsal fin length) | 2,962 |
| NS-IBTS | *Trachurus trachurus* | 8 (second dorsal fin length) | 574 |
| FR-CGFS | *Trachurus trachurus* | 4 (pre anal-fin length) | 26 |
| NS-IBTS | *Eutrigla gurnardus* | 5 (mantle length) | 25 |
| EVHOE | *Chelidonichthys lucerna* | 10 (shell width) | 3 |
| BITS | *Pleuronectes platessa* | 6 (carapace length) | 225 |
| BITS | *Limanda limanda* | 6 (carapace length) | 89 |
| BITS | *Gadus morhua* | 6 (carapace length) | 87 |
| BITS | *Clupea harengus* | 6 (carapace length) | 60 |
| BITS | *Merlangius merlangus* | 6 (carapace length) | 38 |
| BITS | *Platichthys flesus* | 6 (carapace length) | 23 |
| BITS | *Sprattus sprattus* | 6 (carapace length) | 16 |
| BITS | *Solea solea* | 6 (carapace length) | 11 |
| BITS | *Scophthalmus rhombus* | 6 (carapace length) | 7 |
| BITS | *Trachurus trachurus* | 6 (carapace length) | 6 |
| BITS | *Scophthalmus maximus* | 6 (carapace length) | 2 |
| BITS | *Zoarces viviparus* | 6 (carapace length) | 2 |
| BITS | *Sprattus sprattus* | 5 (mantle length) | 22 |
| BITS | *Merlangius merlangus* | 5 (mantle length) | 19 |

Carapace length, mantle length and shell width are measurements for crustaceans, cephalopods and shellfish, not fish, so these seem mislabeled.

The largest group, second dorsal fin length (8) on *S. scombrus* and *T. trachurus* in NS-IBTS, comes entirely from Norway, 2018 to 2022 (Q1 and Q3). Because it is a consistent block from one country, it may be a real measurement type rather than a mislabel. This has not been checked.

## To do

* Check the code 8 records (Norway, NS-IBTS, 2018 to 2022) with the data submitters, and whether the aged fish (CA) from the same hauls were measured the same way.
* Decide how to handle the apparently mislabeled codes (5, 6, 10 on fish) and the pre anal-fin length (4) records in FR-CGFS.
* If a length type is to be taken from HL, keep `LenMeasType` in `get_north_east_atlantic_datras.R`, and decide how to assign it to the aged fish given that CA has no such column.
