# wggrafy-data

Data collation pipeline for [ICES WGGRAFY](https://www.ices.dk/community/groups/Pages/Wggrafy.aspx) (Working Group on Impacts of Warming on Growth Rates and Fisheries Yields). The goal is a standardised, multi-region dataset of size-at-age observations from scientific bottom trawl surveys, for use in growth and fisheries yield analyses.

The structure is inspired by [FishGlob](https://github.com/fishglob/FishGlob_data), but each region has its own cleaning pipeline that handles all surveys within it and standardises them to a common format. A final script merges all regions.

We envision size-at-age data will be available at different levels in different places. In the ideal scenario, each region contributes two data products:

- **Individual length-at-age records** (`ind_age`): one row per measured and aged fish.
- **Length-frequency distributions** (`len_freq`): catch by length class (one row per haul × length class), covering all length classes regardless of whether fish were aged.

The total catch from the trawl or gillnet from which the aged fish where subsampled is needed to avoid biased estimates of growth parameters caused by the is length-stratified subsampling. While there are many methods for dealing with this bias, a relatively simple and promising method that lets the analsyst work with individual-level size-at-age data from the aged sample is the "empirical proportion" method. This method fits growth models to the aged subsample only, but includes the ratio between two proportions as a weight for an individual observation: 1) the proportion of fish in the entire sample that belonged to the fish’s length-bin and 2) the proportion of fish in the aged subsample that belonged to the sh’s length-bin (see [Chih 2009](https://doi.org/10.1577/M09-018.1); [Perreault et al. (2020)](https://doi.org/10.1139/cjfas-2019-0129); [Hilling et al. 2020](https://doi.org/10.1002/nafm.10429); [Lusk et al. (2021)](https://academic.oup.com/najfm/article/41/3/570/7817432); and references therein).

Currently the repo contains code that works with surveys hosted on the [DATRAS](https://datras.ices.dk/) database, where this is available. However there may be data sets where the total catches, from which the aged fish were subsampled, are not now, or data sets where only summaries, not individual-level data, are not available.

## Regions & Surveys
An overview of data currently available (species, survey, and year) can be found in **[summary](summary)**.

| Region | Data source | Output prefix | Surveys | Script folder |
|---|---|---|---|---|
| North East Atlantic (DATRAS) | DATRAS | `nea_datras` | BITS, BTS, BTS-GSA17, BTS-VIII, Can-Mar, CODS-Q4, DYFS, EVHOE, FR-CGFS, FR-WCGFS, IE-IAMS, IE-IGFS, NIGFS, NL-BSAS, NS-IBTS, NSSS, PT-IBTS, ROCKALL, SCOROC, SCOWCGFS, SE-SOUND, SNS, SP-ARSA, SP-NORTH, SP-PORC, SWC-IBTS | `cleaning_codes/north-east-atlantic-datras/` |

## Using the data

To use the compiled data, either:

- Use the merged outputs in **[outputs/](outputs/)** (`length_all.rds`, `catch_all.rds`); or

- Use the region-specific cleaned files (e.g. `nea_datras_length_clean.rds`, `nea_datras_catch_clean.rds`) and run **[cleaning_codes/merge.R](cleaning_codes/merge.R)** to recompile.

The output format is defined in **[standard_formats/](standard_formats/)**.

## Repository structure

- **[cleaning_codes](cleaning_codes)** contains one subfolder per region, each with a `get_` script (download and collate) and a `clean_` script (filter, standardise, QC), plus `merge.R` to combine all regions.
- **[standard_formats](standard_formats)** defines the common output format (column names, types, units) that every regional pipeline must conform to.
- **[outputs](outputs)** contains the cleaned and merged `.rds` files.
- **[raw_data](raw_data)** holds the raw downloaded survey files, organised into one subfolder per region (gitignored due to size).
- **[summary](summary)** contains overview figures of data coverage by species, survey, and year.
- **[metadata_docs](metadata_docs)** documents survey-specific data quirks, manual corrections, and known issues (one file per region).

## Data processing steps

Processing is done at the region level. The steps below describe the current DATRAS pipeline and serve as a template; other regions may differ depending on data format and available metadata.

1. Download and merge raw survey files for all sub-surveys in the region (`get_<region>.R`)
2. Filter to species with both length and age records
3. Clean and homogenise columns following the format in [`standard_formats/`](standard_formats/)
4. Identify and fix errors (e.g. lengths recorded in mm) using per-species length-at-age plots saved in `cleaning_codes/<region>/check_species_laa/`; corrections are documented in [`metadata_docs/`](metadata_docs/)
5. Add a `region` label and save cleaned `ind_age` and `len_freq` tables to `outputs/`

Once all regions are processed, run `cleaning_codes/merge.R` to bind them into `outputs/length_all.rds` and `outputs/catch_all.rds`.

## Output format

Full column specifications (types, required fields, descriptions) are in [standard_formats/](standard_formats/), with downloadable Excel templates ([`ind_age_template.xlsx`](standard_formats/ind_age_template.xlsx), [`len_freq_template.xlsx`](standard_formats/len_freq_template.xlsx)).

**`ind_age`** (`<region>_length_clean.rds`, `length_all.rds`): one row per individual aged fish

| Column | Description |
|---|---|
| haul_id | Unique haul identifier |
| species | Scientific name |
| valid_aphia | WoRMS AphiaID |
| survey | Survey name |
| region | Broad region label |
| date | Sample date (YYYY-MM-DD) |
| lon | Haul midpoint longitude (decimal degrees, WGS84) |
| lat | Haul midpoint latitude (decimal degrees, WGS84) |
| age | Otolith age (years); 0 = 0-group |
| lngt_cm | Total length (cm) |
| lngt_clas | Raw length class bin as recorded |
| lngt_code | Unit of lngt_clas: `'cm'` or `'mm'` |
| ind_wgt | Individual wet weight (g) |
| n_k | Total number of fish in this length class in this haul (N_k in Perreault et al. 2020), joined from the length-frequency data. Used as the sampling weight in the EP likelihood. NA where no haul-level catch data exist. |

**`len_freq`** (`<region>_catch_clean.rds`, `catch_all.rds`): one row per haul × length class

| Column | Description |
|---|---|
| haul_id | Unique haul identifier (joins to `ind_age`) |
| species | Scientific name |
| valid_aphia | WoRMS AphiaID |
| survey | Survey name |
| region | Broad region label |
| lngt_clas | Length class bin as recorded |
| lngt_code | Unit of lngt_clas |
| n_k | Raised count (total catch) of fish in this length class in this haul |

## Dependencies

`DATRASextra` must be installed from GitHub: `remotes::install_github("tokami/DATRASextra")`. All other packages are on CRAN: `tidyverse`, `lubridate`, `here`, `ggtext`, `writexl`.

## TODO

* We envision size-at-age data will be available at different levels in different places. In the ideal scenario, each region contributes two data products:

* Include or not include raw data? It's only 150 MB for DATRAS across all surveys!

* Shape files for each region?

* How do we make room for regions/surveys that don't have "tier 1" level data? I.e., length-at-age and length-frequency? (Related: what are the tiers? only length-at-age, without haul-level catch? only summarised length-at-age?

* More detailed proof checking of DATRAS collation logs + final data

* Should we scan DATRAS for CA species with no n_k data? See data "tiers"

* That Canadian survey on DATRAS (Can-Mar) & the Mediterranian one
