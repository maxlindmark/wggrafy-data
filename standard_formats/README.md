# standard_formats

This folder defines the common format that all regional cleaning pipelines must conform to before their outputs are passed to `cleaning_codes/merge.R`. Run `00-meta-data-table.R` to regenerate the Excel templates after any format change.

Output files are `outputs/<region>/<prefix>_<table>.rds`, where `<prefix>` is the region's short output prefix (e.g. `nea_datras`) and `outputs/<region>/` has the same name as the region's folder in `cleaning_codes/`.

## Files

| File | Description |
|---|---|
| `00-meta-data-table.R` | Generates the Excel templates below |
| `haul_template.xlsx` | Full column spec for the haul table |
| `len_freq_template.xlsx` | Full column spec for the length-frequency table |
| `ind_age_template.xlsx` | Full column spec for the individual aged-fish table |
| `mean_length_at_age_template.xlsx` | Full column spec for the mean length at age table |

## Joining the tables

| Table | One row per | Join to `haul` by |
|---|---|---|
| `haul` | haul | |
| `len_freq` | haul × species × length bin | `haul_id` |
| `ind_age` | unique aged fish record (`n` = number of fish) | `haul_id` |
| `mean_length_at_age` | survey × species × year × quarter × age × sex | |

The scientific name (`species`) is stored only in `ind_age`, which holds every species used; other tables get it by `aphia_id`, e.g. `left_join(distinct(ind_age, aphia_id, species), by = "aphia_id")`.

---

## `haul`: hauls

One row per haul, all hauls of the surveys, including hauls without catch of the species (needed to create zeros). Output file: `outputs/<region>/<prefix>_haul.rds`.

| Column | Type | Required | Description |
|---|---|---|---|
| haul_id | character | yes | Unique haul identifier |
| survey | character | yes | Survey name (e.g. NS-IBTS) |
| region | character | yes | Broad region label (e.g. North East Atlantic) |
| date | Date | yes | Sample date (YYYY-MM-DD). If day not recorded set day to 01. |
| latitude | numeric | yes | Haul latitude (decimal degrees, WGS84); in DATRAS the shooting position (the hauling position where it is missing) |
| longitude | numeric | yes | Haul longitude (decimal degrees, WGS84); as `latitude` |
| gear | character | if available | Gear code |
| depth | numeric | if available | Bottom depth (m) |
| effort | numeric | if available | Fishing effort of the haul, in the unit given by `effort_type` |
| effort_type | character | if available | Type and unit of effort, e.g. `swept_area_km2` |

---

## `len_freq`: length frequencies

One row per haul × species × length bin where the species was caught. Output file: `outputs/<region>/<prefix>_len_freq.rds`. Must include **all** length bins present in a haul (not just those with aged fish). Catch per haul and species is the sum over length bins; zeros (hauls where the species was not caught) are not stored but created by a join with `haul` (see the main README).

| Column | Type | Required | Description |
|---|---|---|---|
| haul_id | character | yes | Unique haul identifier (joins to `haul`) |
| aphia_id | integer | yes | WoRMS AphiaID |
| lngt | numeric | yes | Length bin in cm, lower bound of the 1 cm bin (fish of `lngt` to `lngt` + 1 cm). All regions use 1 cm bins; aged fish in `ind_age` are matched to the bin their length falls in. In DATRAS: `DATRASextra::add_numbers_at_length()` with 1 cm breaks (its default would be the coarsest length class of the survey × species, 0.1 to 5 cm); lengths in mm are summed into 1 cm bins, and catch in 2 and 5 cm classes is spread over their 1 cm bins (see `cleaning_codes/north_east_atlantic_datras/cleaning_notes/nea_datras_catch_zeros.md`). |
| length_type | character | yes | Type of length measurement (same coding as `ind_age$length_type`). In DATRAS, `total` is assumed for all records. |
| num | numeric | yes | Number of fish in the entire sample (the catch) in this length bin in this haul. NA (with `lngt` and `wgt` NA) where the catch of the species in the haul is unknown (not recorded, invalid catch records, or catch recorded without lengths): one such row per haul × species, kept as NA when creating zeros. In DATRAS: numbers at length from `DATRASextra::add_numbers_at_length()` (HLNoAtLngt × SubFactor, × HaulDur / 60 for `DataType` C, summed per 1 cm bin and rounded to whole fish). Catch in 5 cm classes (NS-IBTS 1966–2001) is spread over 1 cm bins before the rounding: first at the cm of the aged fish of the haul, the rest as whole fish at random cm. Same name and unit as FISHGLOB's `num`, which is per haul × species (the sum over the length bins). |
| wgt | numeric | if available | Weight (kg) of the fish in this length bin in this haul; summed over bins it gives the catch weight. In DATRAS: from `DATRASextra::add_total_weight_by_haul()`, a × (bin midpoint)^b × `num`, with a and b from DATRASextra's `species_info` (a = 0.01, b = 3 where missing). Same name and unit as FISHGLOB's `wgt`, which is per haul × species (the sum over the length bins). |

---

## `ind_age`: individual aged fish

One row per unique aged fish record; `n` is the number of fish with exactly these values. Output file: `outputs/<region>/<prefix>_ind_age.rds`.

| Column | Type | Required | Description |
|---|---|---|---|
| haul_id | character | yes | Unique haul identifier (joins to `haul`); contains `pooled` for aged fish whose haul is unknown (not in `haul`; survey, year and quarter are in the id) |
| aphia_id | integer | yes | WoRMS AphiaID |
| species | character | yes | Scientific name (e.g. *Gadus morhua*). Only stored here; other tables get it by `aphia_id` |
| lngt | numeric | yes | Length (cm); the type of length is given in `length_type` |
| age | integer | yes | Otolith age in years; 0 = 0-group |
| sex | character | no | Sex of the aged fish: `F`, `M` or `U` (unsexed, including blank and other codes) |
| ind_wgt | numeric | no | Individual wet weight (g); NA where not measured |
| sampling_type | character | no | How the aged fish were sampled: `unknown`, `random`, `length-stratified` (other types may be added). Determines which records need weighting for length-stratified subsampling. `unknown` where not yet determined. |
| length_type | character | yes | Type of length measurement: `total`, `fork`, `standard` (other types may be added). In DATRAS, `LenMeasType` exists only in the HL table, not in CA, so `total` is assumed for all records. |
| n | integer | yes | Number of aged fish with exactly these values (haul, species, length, age, sex, weight, ...) |

In the reweighting method each aged fish is weighted by (fish caught in its length bin / fish caught in the haul) / (fish aged in its length bin / fish aged in the haul), per haul × species, with the bin being the 1 cm `len_freq` bin (`lngt` to `lngt` + 1) its length falls in. Fish caught is the sum of `num` in `len_freq` (in the bin or the haul), and fish aged is the sum of `n` in `ind_age`. The weights are not computed in the pipeline.

---

## `mean_length_at_age`: mean length at age

One row per survey × species × year × quarter × age × sex. Output file: `outputs/<region>/<prefix>_mean_length_at_age.rds`. Calculated from `ind_age` and `len_freq` by a script in the region's folder in `cleaning_codes/`; the method is described in the main README. A sample is all hauls in a survey × species × year × quarter. Survey, year and quarter must be available for both input tables (in DATRAS they are parsed from `haul_id`). The quarter is set by the region's mean length script, not stored in `haul`: in DATRAS it is the survey quarter from `haul_id`; otherwise e.g. the calendar quarter of `date`.

| Column | Type | Required | Description |
|---|---|---|---|
| aphia_id | integer | yes | WoRMS AphiaID |
| survey | character | yes | Survey name |
| region | character | yes | Broad region label |
| year | integer | yes | Year of the survey |
| quarter | integer | yes | Survey quarter (in DATRAS the survey's quarter label, which can differ from the calendar quarter of the date). A sample is all hauls in a survey × species × year × quarter. |
| age | integer | yes | Otolith age in years; 0 = 0-group |
| sex | character | yes | `F`, `M`, `U` (unsexed) or `all` (sexes pooled) |
| sampling_type | character | yes | How the aged fish were sampled (from `ind_age$sampling_type`). `random` uses the plain mean; `length-stratified` and `unknown` use the mean weighted by the inverse sampling fraction (fish caught in the length bin / fish aged in the bin). |
| length_type | character | yes | Type of length measurement (from `ind_age$length_type`) |
| mean_lngt | numeric | yes | Mean length (cm) at this age (see the main README for how the aged fish are weighted) |
| se_lngt | numeric | no | Standard error of the mean length (cm); NA where there are fewer than two aged fish, or (in DATRAS) where more fish were aged than caught in their length bins, so that they stand for one fish or less in the catch |
| n_fish | integer | yes | Number of aged fish behind the mean |
