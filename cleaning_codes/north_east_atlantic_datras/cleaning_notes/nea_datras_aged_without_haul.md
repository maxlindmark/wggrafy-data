# NEA DATRAS: aged fish without a haul

Some aged fish records (CA) cannot be linked to a haul by `read_datras()`: their station or haul number is missing after reading (e.g. an empty station number in a file where the column is read as numbers). DATRAS (`fixMissingHaulIds()`) then links them by ship × ICES rectangle (`AreaCode`) × year × quarter:

- `strict = TRUE` (default, used here): assigned only if exactly one haul matches; otherwise left without a haul (`haul.id` NA).
- `strict = FALSE`: assigned to a random haul among the matching ones; if none in the rectangle, to a random haul of the ship in the same roundfish area. Not used, as these fish would then look like fish of that haul.

`clean_datras()` drops the records without a haul (in DATRAS `subset()`, at its first haul-level filter). This is not expected to change in DATRAS or DATRASextra.

## What we do: pooled haul id

In `get_north_east_atlantic_datras.R`, the aged fish without a haul are set aside before `clean_datras()` and added to `ind_age` with a pooled `haul_id`:

- `survey:year:quarter:country:ship:gear:pooled:area code`, e.g. `EVHOE:2001:4:FR:35HT:GOV:pooled:EV`. The area code is an ICES rectangle or a larger area (roundfish area, survey stratum, ICES division); rectangle codes that `read_datras()` reads as numbers (e.g. `41E7` as `4.1e+08`) are converted back.
- The pooled `haul_id` is not in `haul`: these fish have no position, date or catch. The mean length at age reads survey, year and quarter from the `haul_id`, so they are used there.
- Species corrections (`correct_species()`) are made on all records before they are set aside, so these fish get the same species names as the others.
- They are kept only where their country and ship still have hauls in that survey × year × quarter after `clean_datras()`, so that their catch is in the catch of the sample.

| Survey | Aged fish with a pooled `haul_id` | Pooled `haul_id`s |
|---|---|---|
| NS-IBTS | 418,561 | 1,480 |
| SWC-IBTS | 43,931 | 395 |
| EVHOE | 37,022 | 51 |
| BTS | 2,956 | 6 |
| SCOWCGFS | 536 | 6 |
| SCOROC | 6 | 1 |
| **All** | **503,012** | **1,939** |

Effects on the outputs: `haul` and the other `ind_age` records unchanged; `len_freq` gains hake and both anglerfish species in EVHOE (aged only in 1997–2013); the mean length at age has 5,580 new rows (e.g. EVHOE 1997–2013, 108 samples) and 9,899 changed, none lost.

Left out, as their ship has no hauls left in that survey × year × quarter:

- NS-IBTS, country `DUM` (ships DCA, HOL), 1985–1987 Q1: 12,202 fish; this country has no hauls in DATRAS.
- NSSS, Scottish ship 74NM, 2012–2021 Q4: 9,494 fish; its hauls have `StdSpecRecCode` 0 and are removed by `clean_datras()`.
- NSSS 2008–2011 Q4: 4,671 fish; no catch data in these years.

138 kept fish (NS-IBTS 130, SWC-IBTS 8) come from a ship whose hauls have no catch of that species in that survey × year × quarter.

## To do

- Dutch SNS and DYFS up to 2001: aged fish that seem to be registered by subarea under one haul could get a pooled `haul_id` too, once the Dutch survey contacts confirm (see [`nea_datras_n_k_issue.md`](nea_datras_n_k_issue.md)).
