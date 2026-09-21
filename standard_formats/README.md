# standard_formats

This folder defines the common format that all regional cleaning pipelines must conform to before their outputs are passed to `cleaning_codes/merge.R`. Run `00-meta-data-table.R` to regenerate the Excel templates after any format change.

## Files

| File | Description |
|---|---|
| `00-meta-data-table.R` | Generates the three Excel templates below |
| `ind_age_template.xlsx` | Full column spec for the individual aged-fish table |
| `len_freq_template.xlsx` | Full column spec for the length-frequency table |
| `mean_length_at_age_template.xlsx` | Full column spec for the mean length at age table |

---

## `ind_age`: individual aged fish

One row per individual measured and aged fish. Output file: `outputs/<region>/<prefix>_length_clean.rds`, where `<prefix>` is the region's short output prefix (e.g. `nea_datras`) and `outputs/<region>/` has the same name as the region's folder in `cleaning_codes/`.

| Column | Type | Required | Description |
|---|---|---|---|
| haul_id | character | yes | Unique haul identifier |
| species | character | yes | Scientific name (e.g. *Gadus morhua*) |
| valid_aphia | integer | no | WoRMS AphiaID; NA if unavailable |
| survey | character | yes | Survey name (e.g. NS-IBTS) |
| region | character | yes | Broad region label (e.g. North East Atlantic) |
| date | Date | yes | Sample date (YYYY-MM-DD). If day not recorded set day to 01. Year and month are derived from this column. |
| year | integer | no | Sample year (derived from `date`) |
| lon | numeric | yes | Haul midpoint longitude (decimal degrees, WGS84) |
| lat | numeric | yes | Haul midpoint latitude (decimal degrees, WGS84) |
| age | integer | yes | Otolith age in years; 0 = 0-group |
| lngt_cm | numeric | yes | Total length (cm) |
| lngt_clas | numeric | no | Raw length class bin as recorded (cm or mm; see `lngt_code`) |
| lngt_code | character | no | Unit of `lngt_clas`. In DATRAS, inherited from the exchange format: `'.'` = 1 mm and `'0'` = 0.5 cm (`lngt_clas` in mm), `'1'` = 1 cm (`lngt_clas` in cm), and a small amount of `'5'` = 5 cm (`lngt_clas` in cm). Kept to help diagnose unit errors. CA and HL can use different codes within a haul, so they are matched on `lngt_cm`, not on `lngt_clas`/`lngt_code`. |
| ind_wgt | numeric | no | Individual wet weight (g); NA where not measured |
| sex | character | no | Sex of the aged fish: `F`, `M` or `U` (unsexed, including blank and other codes) |
| sampling_type | character | no | How the aged fish were sampled: `unknown`, `random`, `length-stratified` (other types may be added). Determines which records need weighting for length-stratified subsampling. `unknown` where not yet determined. |
| n_entire_bin | numeric | if available | Number of fish in the entire sample (the catch) in this fish's haul, species and 1 cm length bin (floor of `lngt_cm`). Used in the reweighting method. NA where no catch data exist for the bin. In DATRAS: sum of HLNoAtLngt × SubFactor from the HL exchange table. |
| n_entire | numeric | if available | Number of fish in the entire sample (the catch) in this fish's haul and species, summed over all length bins with a known length. NA where no catch data exist. |
| n_aged_bin | integer | yes | Number of aged fish in this fish's haul, species and 1 cm length bin (floor of `lngt_cm`), counted in the cleaned data. |
| n_aged | integer | yes | Number of aged fish in this fish's haul and species, counted in the cleaned data. |

In the reweighting method each aged fish is weighted by `(n_entire_bin / n_entire) / (n_aged_bin / n_aged)`. The weights are not computed in the pipeline.

---

## `len_freq`: length frequencies

One row per haul × length class. Output file: `outputs/<region>/<prefix>_catch_clean.rds`. Must include **all** length classes present in a haul (not just those with aged fish), so that the entire-sample totals (`n_entire`) can be calculated.

| Column | Type | Required | Description |
|---|---|---|---|
| haul_id | character | yes | Unique haul identifier (joins to `ind_age$haul_id`) |
| species | character | yes | Scientific name |
| valid_aphia | integer | no | WoRMS AphiaID; NA if unavailable |
| survey | character | yes | Survey name |
| region | character | yes | Broad region label |
| lngt_clas | numeric | yes | Length class bin as recorded (cm or mm; see `lngt_code`) |
| lngt_code | character | yes | Unit of `lngt_clas` (same coding as `ind_age$lngt_code`) |
| lngt_cm | numeric | yes | Length class in cm (mm and 0.5 cm classes converted; cm classes as is). Used to match to `ind_age` on a common 1 cm bin (floor of `lngt_cm`). NA where the length code is missing. |
| n_entire_bin | numeric | yes | Number of fish in the entire sample (the catch) in this length class in this haul, summed over sex. In DATRAS: sum of HLNoAtLngt × SubFactor from the HL exchange table. |

---

## `mean_length_at_age`: mean length at age

One row per survey × species × year × quarter × age × sex. Output file: `outputs/<region>/<prefix>_mean_length_at_age.rds`. Calculated from `ind_age` and `len_freq` by a script in the region's folder in `cleaning_codes/`; the method is described in the main README. A sample is all hauls in a survey × species × `year_num`. Year and quarter must be available for both input tables (in DATRAS they are parsed from `haul_id`).

| Column | Type | Required | Description |
|---|---|---|---|
| species | character | yes | Scientific name |
| valid_aphia | integer | no | WoRMS AphiaID; NA if unavailable |
| survey | character | yes | Survey name |
| region | character | yes | Broad region label |
| year | integer | yes | Sample year |
| quarter | integer | yes | Sample quarter (1 to 4) |
| year_num | character | yes | Year and quarter, `paste(year, quarter, sep = "_")`. A sample is all hauls in a survey × species × `year_num`. |
| age | integer | yes | Otolith age in years; 0 = 0-group |
| sex | character | yes | `F`, `M`, `U` (unsexed) or `all` (sexes pooled) |
| sampling_type | character | yes | How the aged fish were sampled (from `ind_age$sampling_type`). `random` uses the plain mean; `length-stratified` and `unknown` use the mean weighted by the inverse sampling fraction (fish caught in the length bin / fish aged in the bin). |
| mean_lngt_cm | numeric | yes | Mean length (cm) of the aged fish at this age |
| se_lngt_cm | numeric | no | Standard error of the mean length (cm); NA where there are fewer than two aged fish |
| n_fish | integer | yes | Number of aged fish behind the mean |
