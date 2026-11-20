# NEA DATRAS: erroneous lengths in the catch data (HL)

Applied in `cleaning_codes/north_east_atlantic_datras/get_north_east_atlantic_datras.R`, before the weight (`wgt`) is calculated from the lengths. The corrections of the aged fish (CA) are separate and documented in `nea_datras_species_corrections.md`.

## Rule

HL rows with a length above 2 × the species' maximum length (`maxL` in DATRASextra's `species_info`) are considered erroneous and removed. Species without `maxL` are not checked (*Alosa*, *Phrynorhombus norvegicus*, Ammodytidae, *Ammodytes*, *Sebastes*).

The threshold is 2 × `maxL` because `maxL` is too low for some species: e.g. many Baltic sprat in BITS are above the sprat `maxL` of 16 cm. Lengths between 1 × and 2 × `maxL` are kept.

## Records removed

93 HL rows of the species in the cleaned data, holding 1,449 fish (0.0003% of the 564 million fish in `len_freq`); 3 more rows are of three-spined stickleback in BITS, which is not in the cleaned data. No aged fish are above 2 × `maxL` (after the CA corrections), so no length-at-age data are affected.

| Species | Survey | Rows | Fish | Length range (cm) | `maxL` (cm) | % of survey × species catch |
|---|---|---|---|---|---|---|
| *Osmerus eperlanus* | BITS | 27 | 55 | 110–220 | 45 | 0.074 |
| *Limanda limanda* | BTS | 18 | 758 | 407–426 | 40 | 0.015 |
| *Myoxocephalus scorpius* | BITS | 1 | 1 | 254 | 60 | 0.001 |
| *Buglossidium luteum* | NS-IBTS | 1 | 1 | 34 | 16.4 | 0.0009 |
| *Sprattus sprattus* | BITS | 24 | 594 | 37.5–140 | 16 | 0.0005 |
| *Buglossidium luteum* | BTS | 2 | 4 | 38–50 | 16.4 | 0.0005 |
| *Merlangius merlangus* | EVHOE | 1 | 1 | 246 | 91.5 | 0.0005 |
| *Platichthys flesus* | BITS | 2 | 10 | 338–420 | 60 | 0.0004 |
| *Engraulis encrasicolus* | NS-IBTS | 1 | 1 | 170 | 20 | 0.0003 |
| *Clupea harengus* | BITS | 12 | 16 | 125–205 | 45 | < 0.0001 |
| *Clupea harengus* | NS-IBTS | 3 | 4 | 160–235 | 45 | < 0.0001 |
| *Limanda limanda* | NS-IBTS | 1 | 4 | 100 | 40 | < 0.0001 |

The *Limanda limanda* rows in BTS are all 758 dab in one haul (`BTS:1992:3:DE:06S1:BT7:32:32`), which before this check gave a catch weight of 785 t.

## Length cuts as in the aged fish

In `clean_north_east_atlantic_datras.R`, the catch gets the same length cuts as the aged fish where the catch has the same errors: sprat in BITS and anchovy in NS-IBTS above 20 cm are removed (16,493 sprat and 82 anchovy).
