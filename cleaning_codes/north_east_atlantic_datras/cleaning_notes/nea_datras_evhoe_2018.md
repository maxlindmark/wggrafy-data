# DATRAS: EVHOE 2018, numbers per hour or per haul?
2026-11-17

The EVHOE hauls of 2018 have `DataType` C (catch numbers per hour); the other years have R (numbers per haul). We think the 2018 numbers are per haul, i.e. that `DataType` should be R.

``` r
library(dplyr)

# Folder to download the DATRAS files into
data_dir <- "datras_data"
DATRASextra::download_datras(surveys = "EVHOE", years = 2017:2019, path = data_dir, overwrite = FALSE, return_data = FALSE)
DATRASextra::download_datras(surveys = "FR-CGFS", years = 2018, path = data_dir, overwrite = FALSE, return_data = FALSE)
```

``` r
# Read one record type (HH, HL or CA) from an exchange file
read_records <- function(zip, type) {
  tmp <- tempfile()
  unzip(zip, exdir = tmp)
  lines <- readLines(file.path(tmp, "DATRAS.csv"))
  rows <- which(startsWith(lines, paste0(type, ",")))
  read.csv(text = lines[c(rows[1] - 1, rows)], colClasses = "character")
}
```

## How we found it: more fish aged than caught

Whiting in haul W0579 (30 minutes) of EVHOE 2018. Per length: fish caught (`HLNoAtLngt`), as reported and if they were numbers per hour (× 30 / 60, rounded as in `DATRAS::addSpectrum()`), and fish aged (`CANoAtLngt`). Read as numbers per hour, more fish were aged than caught.

``` r
zip <- file.path(data_dir, "EVHOE", "EVHOE_2018.zip")

caught <- read_records(zip, "HL") |>
  filter(StNo == "W0579", HaulNo == "46", SpecCode == "126438") |>
  mutate(length_cm = as.numeric(LngtClass) / 10, caught = as.numeric(HLNoAtLngt), caught_if_per_hour = round(caught * 30 / 60), .keep = "none")

aged <- read_records(zip, "CA") |>
  filter(StNo == "W0579", HaulNo == "46", SpecCode == "126438", !AgeRings %in% c("", "-9")) |>
  mutate(length_cm = floor(as.numeric(LngtClass) / 10)) |>
  count(length_cm, wt = as.numeric(CANoAtLngt), name = "aged")

full_join(caught, aged, by = "length_cm") |>
  arrange(length_cm) |>
  knitr::kable()
```

| length_cm | caught | caught_if_per_hour | aged |
|----------:|-------:|-------------------:|-----:|
|        10 |      2 |                  1 |    2 |
|        11 |      5 |                  2 |    2 |
|        12 |      3 |                  2 |    3 |
|        13 |      2 |                  1 |    2 |
|        14 |      2 |                  1 |    2 |
|        15 |      2 |                  1 |    2 |
|        16 |      2 |                  1 |    2 |
|        17 |      1 |                  0 |    1 |
|        18 |      2 |                  1 |    2 |
|        19 |      1 |                  0 |    1 |
|        22 |      1 |                  0 |    1 |
|        23 |      1 |                  0 |    1 |

## Why we think the numbers are per haul

In numbers per hour from a 30-minute haul, every fish counts as 2, so `HLNoAtLngt` is never 1. In FR-CGFS 2018 (numbers per hour) no length class has 1; in EVHOE 2018 many do, as in the EVHOE years with numbers per haul.

``` r
files <- c(
  file.path(data_dir, "EVHOE", paste0("EVHOE_", 2017:2019, ".zip")),
  file.path(data_dir, "FR-CGFS", "FR-CGFS_2018.zip")
)

bind_rows(lapply(files, function(zip) {
  hh <- read_records(zip, "HH")
  hl <- read_records(zip, "HL")
  tibble(
    file = basename(zip),
    DataType = paste(unique(hh$DataType[hh$DataType != ""]), collapse = ", "),
    median_HaulDur = median(as.numeric(hh$HaulDur)),
    pct_length_classes_with_1 = round(100 * mean(as.numeric(hl$HLNoAtLngt) == 1, na.rm = TRUE), 1)
  )
})) |>
  knitr::kable()
```

| file             | DataType | median_HaulDur | pct_length_classes_with_1 |
|:-----------------|:---------|---------------:|--------------------------:|
| EVHOE_2017.zip   | R        |             31 |                      43.5 |
| EVHOE_2018.zip   | C        |             30 |                      42.1 |
| EVHOE_2019.zip   | R        |             30 |                      42.6 |
| FR-CGFS_2018.zip | C        |             30 |                       0.0 |
