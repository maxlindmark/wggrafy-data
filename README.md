# wggrafy-data

Data collation pipeline for [ICES WGGRAFY](https://www.ices.dk/community/groups/Pages/Wggrafy.aspx) (Working Group on Impacts of Warming on Growth Rates and Fisheries Yields). The goal is a standardised, multi-region dataset of size-at-age observations from scientific bottom trawl surveys, for use in growth analyses.

The structure is inspired by [FishGlob](https://github.com/fishglob/FishGlob_data), but each region has its own cleaning pipeline that handles all surveys within it and standardises them to a common format. A final script merges all regions.

Scientific surveys are conducted with different sampling protocols. Unless the samples are truly random (which is rare if it ever occurs), statistics need to be corrected using information from the survey catches. Hence, this repository is built around each region having two data products:

- **Individual length-at-age records** (`ind_age`): one row per measured and aged fish.
- **Length-frequency distributions** (`len_freq`): catch by length class (one row per haul × length class), covering all length classes regardless of whether fish were aged.

The total catch from the trawl from which the aged fish where subsampled is needed to avoid biased estimates of growth parameters caused by the is length-stratified subsampling. While there are many methods for dealing with this bias, a relatively simple and promising method that lets the analsyst work with individual-level size-at-age data from the aged sample is the "reweighting" method [Chih 2009](https://doi.org/10.1577/M09-018.1). This method fits growth models to the aged subsample only, but includes the ratio between two proportions as a weight for an individual observation: 1) the proportion of fish in the entire sample that belonged to the fish’s length-bin and 2) the proportion of fish in the aged subsample that belonged to the sh’s length-bin (see [Chih 2009](https://doi.org/10.1577/M09-018.1); [Perreault et al. (2020)](https://doi.org/10.1139/cjfas-2019-0129); [Hilling et al. 2020](https://doi.org/10.1002/nafm.10429); [Lusk et al. (2021)](https://academic.oup.com/najfm/article/41/3/570/7817432); and references therein).

## Regions & Surveys

This table is populated automatically by `cleaning_codes/merge.R` from the merged data. Do not edit it by hand.

| Region | Data source | Output prefix | Surveys | Script folder |
|---|---|---|---|---|
| North East Atlantic (DATRAS) | DATRAS | `nea_datras` | BITS, BTS, BTS-GSA17, BTS-VIII, Can-Mar, CODS-Q4, DYFS, EVHOE, FR-CGFS, FR-WCGFS, IE-IAMS, IE-IGFS, NIGFS, NL-BSAS, NS-IBTS, NSSS, PT-IBTS, ROCKALL, SCOROC, SCOWCGFS, SE-SOUND, SNS, SP-ARSA, SP-NORTH, SP-PORC, SWC-IBTS | `cleaning_codes/north-east-atlantic-datras/` |

## Using the data

To use the compiled data, either:

- Use the merged outputs in **[outputs/](outputs/)** (`length_all.rds`, `catch_all.rds`); or

- Use the region-specific cleaned files (e.g. `outputs/north-east-atlantic-datras/nea_datras_length_clean.rds` and `nea_datras_catch_clean.rds`).

The output format is defined in **[standard_formats/](standard_formats/)**.

## Repository structure

- **[cleaning_codes](cleaning_codes)** contains one subfolder per region. For example, `north-east-atlantic-datras` contains a `get_` script (download and collate) and a `clean_` script (filter, standardise, QC) and a `mean_length_at_age_` script (mean length at age from the cleaned tables). This folder also contains a `merge.R` script, to combine all regions and update the README overview of surveys. 
- **[standard_formats](standard_formats)** defines the common output format (column names, types, units) that every regional pipeline must conform to.
- **[outputs](outputs)** contains the cleaned and merged `.rds` files: one subfolder per region (named as the folder in `cleaning_codes/`) with that region's cleaned files, and the merged files at the top level.
- **[raw_data](raw_data)** holds the raw downloaded survey files, organised into one subfolder per region (gitignored due to size).
- **[summary](summary)** contains overview figures of data coverage by species, survey, and year.
- **[metadata_docs](metadata_docs)** documents survey-specific data quirks, manual corrections, and known issues (one file per region).

Code formatting is done with [styler](https://styler.r-lib.org/) (`styler::tidyverse_style()`)

## Data processing steps

Processing is done at the region level. The steps below describe the current DATRAS pipeline and serve as a template; other regions may differ depending on data format and available metadata.

1. Download and merge raw survey files for all sub-surveys in the region (`get_<region>.R`)
2. Filter to species with both length and age records
3. Clean and homogenise columns following the format in [`standard_formats/`](standard_formats/)
4. Identify and fix errors (e.g. lengths recorded in mm) using per-species length-at-age plots saved in `cleaning_codes/<region>/check_species_laa/`; corrections are documented in [`metadata_docs/`](metadata_docs/)
5. Add a `region` label and save cleaned `ind_age` and `len_freq` tables to `outputs/<region>/`
6. Calculate mean length at age from the cleaned tables (`mean_length_at_age_<region>.R`)

Once all regions are processed, run `cleaning_codes/merge.R` to bind them into `outputs/length_all.rds` and `outputs/catch_all.rds`.

## Output format

Full column specifications (types, required fields, descriptions) are in [standard_formats/](standard_formats/), with downloadable Excel templates ([`ind_age_template.xlsx`](standard_formats/ind_age_template.xlsx), [`len_freq_template.xlsx`](standard_formats/len_freq_template.xlsx), [`mean_length_at_age_template.xlsx`](standard_formats/mean_length_at_age_template.xlsx)).

**`ind_age`** (`outputs/<region>/<prefix>_length_clean.rds`, `outputs/length_all.rds`): one row per individual aged fish

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
| lngt_code | Unit of lngt_clas. In DATRAS: `'.'` = 1 mm and `'0'` = 0.5 cm (lngt_clas in mm), `'1'` = 1 cm (lngt_clas in cm), rarely `'5'` = 5 cm |
| ind_wgt | Individual wet weight (g) |
| sex | Sex of the aged fish: `F`, `M` or `U` (unsexed) |
| sampling_type | How the aged fish were sampled: `unknown`, `random`, `length-stratified` (other types may be added) |
| n_entire_bin | Number of fish in the entire sample (the catch) in this fish's haul, species and 1 cm length bin (floor of lngt_cm). NA where no catch data exist for the bin |
| n_entire | Number of fish in the entire sample (the catch) in this fish's haul and species |
| n_aged_bin | Number of aged fish in this fish's haul, species and 1 cm length bin |
| n_aged | Number of aged fish in this fish's haul and species |

**`len_freq`** (`outputs/<region>/<prefix>_catch_clean.rds`, `outputs/catch_all.rds`): one row per haul × length class

| Column | Description |
|---|---|
| haul_id | Unique haul identifier (joins to `ind_age`) |
| species | Scientific name |
| valid_aphia | WoRMS AphiaID |
| survey | Survey name |
| region | Broad region label |
| lngt_clas | Length class bin as recorded |
| lngt_code | Unit of lngt_clas |
| lngt_cm | Length class in cm (used to match to `ind_age` on a 1 cm bin) |
| n_entire_bin | Raised count (total catch) of fish in this length class in this haul |

**`mean_length_at_age`** (`outputs/<region>/<prefix>_mean_length_at_age.rds`): one row per survey × species × year × quarter × age × sex

Calculated from `ind_age`, and `len_freq` in case of length-stratified subsampling. The `north-east-atlantic-datras` case for example uses the approach in [Bettoli & Miranda (2001)](https://doi.org/10.1577/1548-8675(2001)021%3C0425:CNAEML%3E2.0.CO;2), where aged fish (from length-stratified subsample) are extrapolated to the catch, i.e., each fish is weighted by the inverse sampling fraction of its 1 cm length bin. Sex-specific rows use the sex ratio of the aged fish in each length bin. See the region's `mean_length_at_age_` script for details. Other regions may have other pipelines for reaching the same final result; a mean length-at-age by survey, year, quarter, and sex.

| Column | Description |
|---|---|
| species | Scientific name |
| valid_aphia | WoRMS AphiaID |
| survey | Survey name |
| region | Broad region label |
| year | Sample year |
| quarter | Sample quarter (1 to 4) |
| year_num | Year and quarter, `paste(year, quarter, sep = "_")`. A sample is all hauls in a survey × species × `year_num` |
| age | Otolith age (years); 0 = 0-group |
| sex | `F`, `M`, `U` (unsexed) or `all` (sexes pooled) |
| sampling_type | How the aged fish were sampled (from `ind_age`) |
| mean_lngt_cm | Mean length (cm) of the aged fish at this age |
| se_lngt_cm | Standard error of the mean length (cm); NA where there are fewer than two aged fish |
| n_fish | Number of aged fish behind the mean |

## Dependencies

`DATRASextra` must be installed from GitHub: `remotes::install_github("tokami/DATRASextra")`. All other packages are on CRAN: `tidyverse`, `lubridate`, `here`, `ggtext`, `writexl`, `tidylog`

## TODO

* `sampling_type` is `unknown` for all records in `north-east-atlantic-datras`. In the final preparation, join a table of survey, year and sampling strategy (e.g. a csv) to fill it. It decides which records need weighting for length-stratified subsampling; the mean length at age uses the plain mean for `random` and the weighted mean for `length-stratified` and `unknown`.

* Sex-specific mean length at age: the sex ratio comes from the pooled sample of survey*species*`year_num`, within each 1 cm length bin. Note this isn't calculated at the haul level (because in a haul, we may have to few samples to calulcate reliable sex-ratios by length bin (1 cm), whereas at the survey*species*`year_num` level, about 91% of the aged fish sit in bins with more than 10 aged fish). Anchor if this is valid!

* Include or not include raw data? It's only 150 MB for DATRAS across all surveys!

* Shape files for each region? Or survey? (messy in DATRAS)

* That Canadian survey on DATRAS (Can-Mar) & the Mediterranian one

* In the DATRAS case, there are a lot of surveys overlappin in space. Do we aggregate length at age by survey or domain? Currently done by survey, but will need to merge this somehow. Sub-divisions?
