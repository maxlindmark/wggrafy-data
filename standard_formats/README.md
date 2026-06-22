# standard_formats

This folder defines the common format that all regional cleaning pipelines must conform to before their outputs are passed to `cleaning_codes/merge.R`. Run `00-meta-data-table.R` to regenerate the Excel templates after any format change.

## Files

| File | Description |
|---|---|
| `00-meta-data-table.R` | Generates the two Excel templates below |
| `ind_age_template.xlsx` | Full column spec for the individual aged-fish table |
| `len_freq_template.xlsx` | Full column spec for the length-frequency table |

---

## `ind_age`: individual aged fish

One row per individual measured and aged fish. Output file: `outputs/<region>_length_clean.rds`.

| Column | Type | Required | Description |
|---|---|---|---|
| haul_id | character | yes | Unique haul identifier |
| species | character | yes | Scientific name (e.g. *Gadus morhua*) |
| valid_aphia | integer | no | WoRMS AphiaID; NA if unavailable |
| survey | character | yes | Survey name (e.g. NS-IBTS) |
| region | character | yes | Broad region label (e.g. North East Atlantic) |
| date | Date | yes | Sample date (YYYY-MM-DD). If day not recorded set day to 01. Year and month are derived from this column. |
| lon | numeric | yes | Haul midpoint longitude (decimal degrees, WGS84) |
| lat | numeric | yes | Haul midpoint latitude (decimal degrees, WGS84) |
| age | integer | yes | Otolith age in years; 0 = 0-group |
| lngt_cm | numeric | yes | Total length (cm) |
| lngt_clas | numeric | no | Raw length class bin as recorded (cm or mm; see `lngt_code`) |
| lngt_code | character | no | Unit of `lngt_clas`: `'cm'` or `'mm'`. In DATRAS: `'1'` = 1 cm bins; `'0'`/`'.'`/`'2'`/`'5'` = mm bins (inherited from exchange format to help diagnose unit errors). |
| ind_wgt | numeric | no | Individual wet weight (g); NA where not measured |
| n_k | numeric | if available | Total number of fish in this length class in this haul (N_k in Perreault et al. 2020), joined from the length-frequency data. Used as the sampling weight in the EP likelihood. NA where no haul-level catch data exist. In DATRAS: sum of HLNoAtLngt × SubFactor from the HL exchange table. |

---

## `len_freq`: length frequencies

One row per haul × length class. Output file: `outputs/<region>_catch_clean.rds`. Must include **all** length classes present in a haul (not just those with aged fish), as empty-stratum terms in the EP likelihood require complete coverage.

| Column | Type | Required | Description |
|---|---|---|---|
| haul_id | character | yes | Unique haul identifier (joins to `ind_age$haul_id`) |
| species | character | yes | Scientific name |
| valid_aphia | integer | no | WoRMS AphiaID; NA if unavailable |
| survey | character | yes | Survey name |
| region | character | yes | Broad region label |
| lngt_clas | numeric | yes | Length class bin as recorded (cm or mm; see `lngt_code`) |
| lngt_code | character | yes | Unit of `lngt_clas` (same coding as `ind_age$lngt_code`) |
| n_k | numeric | yes | Total number of fish in this length class in this haul (N_k in Perreault et al. 2020). In DATRAS: sum of HLNoAtLngt × SubFactor from the HL exchange table. |
