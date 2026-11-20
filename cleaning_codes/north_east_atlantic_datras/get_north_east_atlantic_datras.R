# Purpose:   Download and reformat DATRAS trawl survey data for growth analysis.
#            Reads exchange-format data for all surveys, filters to species with
#            both length and age records, builds length frequencies with numbers and
#            weight at length in 1 cm bins (HL, DATRASextra; 2 and 5 cm classes
#            spread over their 1 cm bins) and individual age data (CA; aged fish
#            without a haul get a pooled haul id), and saves a single RDS list keyed
#            by survey name.
#
# Output:    cleaning_codes/north_east_atlantic_datras/merged_survey_data.rds
#            cleaning_codes/north_east_atlantic_datras/log_survey_data.rds
#            A named list; each element has $haul (one row per haul), $hl
#            (numbers and weight per haul * species * length bin), $ca
#            (aged fish, n = number of fish per record), $hl_invalid
#            (haul * species with only invalid catch records) and $hl_nolength
#            (haul * species with valid catch records but no lengths).
#
# Modified:  2026-11-20
# Author:    Max Lindmark

# remotes::install_github("tokami/DATRASextra")
library(tidyr)
library(dplyr)
library(lubridate)
library(DATRASextra)
library(ggplot2)
theme_set(theme_light())
library(purrr)

home <- here::here()

# -----------------------------------------------------------------------------
# Download DATRAS data for all years and surveys
# -----------------------------------------------------------------------------
# Surveys to skip:
# DWS: Irish deep-water survey (2006-2009), no CA (age) records in DATRAS
# Can-Mar: Canadian Maritimes survey, outside the North East Atlantic region
# Test-DATRAS: ICES test survey, not real data
# BTS-GSA17, IS-IDPS: no aged fish with both length and age
# CODS-Q4: no data files in the download
skip_surveys <- c("DWS", "Can-Mar", "Test-DATRAS", "BTS-GSA17", "IS-IDPS", "CODS-Q4")
surveys <- setdiff(icesDatras::getSurveyList(), skip_surveys)

# This takes a while..
download_datras(
  surveys = surveys, years = NULL, overwrite = FALSE, return_data = FALSE,
  path = file.path(home, "raw_data/north_east_atlantic_datras")
)


# -----------------------------------------------------------------------------
# Load saved DATRAS data
# -----------------------------------------------------------------------------

# Get survey names (folder names we just downloaded)
survey_paths <- list.dirs(file.path(home, "raw_data/north_east_atlantic_datras"), recursive = FALSE)

# Drop skipped surveys in case their folders exist from an older download
survey_names <- basename(survey_paths)
keep <- !(survey_names %in% skip_surveys)
survey_paths <- survey_paths[keep]

# Load aphia_id to species name table
data("species_info", package = "DATRASextra")
aphia_to_species <- setNames(species_info$ScientificName_WoRMS, species_info$WoRMS_AphiaID)

# Spread catch in length classes wider than 1 cm over their 1 cm bins: first at the cm of the aged fish of the haul, the rest at random (see cleaning_codes/north_east_atlantic_datras/cleaning_notes/nea_datras_catch_zeros.md)
spread_classes <- function(hl, ca, width) {
  aged <- ca |>
    filter(!is.na(haul.id), !is.na(LngtCm)) |>
    mutate(haul.id = as.character(haul.id), cm = floor(LngtCm), aged = NoAtALK, .keep = "none") |>
    summarise(aged = sum(aged, na.rm = TRUE), .by = c(haul.id, cm))
  cells <- hl |>
    mutate(haul.id = as.character(haul.id), lo = floor(LngtCm), width = width, count = Count, .keep = "none") |>
    filter(!is.na(count)) |>
    summarise(count = sum(count), .by = c(haul.id, lo, width)) |>
    mutate(class = row_number()) |>
    uncount(width, .remove = FALSE, .id = "k") |>
    mutate(cm = lo + k - 1) |>
    left_join(aged, by = c("haul.id", "cm")) |>
    mutate(aged = coalesce(aged, 0), aged_class = sum(aged), rest = round(count - aged_class, 6), .by = class)
  # Rest of the catch: whole fish at random cm of the class (fixed seed); a part of a fish (count not whole) in one random cm, rounded with its bin by add_numbers_at_length()
  rest <- cells |>
    distinct(class, width, rest) |>
    filter(rest > 0)
  random <- tibble(class = integer(0), k = integer(0), n = numeric(0))
  if (nrow(rest) > 0) {
    random <- withr::with_seed(1, {
      rest |>
        reframe(
          k = c(sample.int(width, floor(rest), replace = TRUE), if (rest %% 1 > 0) sample.int(width, 1)),
          n = c(rep(1, floor(rest)), if (rest %% 1 > 0) rest %% 1),
          .by = class
        )
    })
  }
  cells |>
    left_join(random |> summarise(n = sum(n), .by = c(class, k)), by = c("class", "k")) |>
    # Fewer caught than aged: the catch in proportion to the aged fish
    mutate(n = if_else(rest >= 0, aged + coalesce(n, 0), count * aged / aged_class)) |>
    summarise(n = sum(n), .by = c(haul.id, cm))
}


# -----------------------------------------------------------------------------
# Iterate through surveys, find species with length AND age data, and
# proceed with data processing using R package DATRASextra
# -----------------------------------------------------------------------------
# Outer loop, per survey (all years): read and clean the data, and make the survey-level tables (hauls with effort, haul x species with unknown catch, aged fish without a haul). Inner loop, per species with aged fish that have both length and age: make the length frequencies (numbers and weight per haul x 1 cm bin) and the table of aged fish.
results <- list()
failed <- list()
log_list <- list()

for (i in seq_along(survey_paths)) {
  tryCatch(
    {
      path <- survey_paths[i]
      survey_name <- tools::file_path_sans_ext(basename(path))
      # Species corrections here, on all records, as clean_datras() makes them only after dropping aged fish without a haul
      surv <- read_datras(path) |> correct_species()
      if (is.null(surv[["CA"]])) stop("CA table is NULL")

      # EVHOE 2018: DataType C (per hour) but numbers per haul; undo the per-hour conversion of HL Count (see cleaning_codes/north_east_atlantic_datras/cleaning_notes/nea_datras_datatype_corrections.md)
      fix <- as.character(surv[["HH"]]$Survey) == "EVHOE" & as.character(surv[["HH"]]$Year) == "2018" & as.character(surv[["HH"]]$DataType) == "C"
      if (any(fix)) {
        dur <- setNames(surv[["HH"]]$HaulDur[fix], as.character(surv[["HH"]]$haul.id[fix]))
        hl_fix <- as.character(surv[["HL"]]$haul.id) %in% names(dur)
        surv[["HL"]]$Count[hl_fix] <- surv[["HL"]]$Count[hl_fix] * 60 / dur[as.character(surv[["HL"]]$haul.id[hl_fix])]
        surv[["HH"]]$DataType <- factor(replace(as.character(surv[["HH"]]$DataType), fix, "R"))
      }

      # Aged fish without a haul (haul.id NA): set aside, as clean_datras() drops them (see cleaning_codes/north_east_atlantic_datras/cleaning_notes/nea_datras_aged_without_haul.md)
      ca_pooled <- surv[["CA"]][is.na(surv[["CA"]]$haul.id), ]

      # Drop survey-year-quarters with hauls but no HL at all (catch not reported, not zero catch)
      surv <- clean_datras(surv, drop_without_hl = TRUE, correct_species = FALSE)

      # Keep aged fish without a haul only where their country and ship still have hauls in that survey x year x quarter
      ship_key <- function(x) paste(x$Survey, x$Year, x$Quarter, x$Country, x$Ship)
      ca_pooled <- ca_pooled[ship_key(ca_pooled) %in% ship_key(surv[["HH"]]), ]

      # Pooled haul id: survey:year:quarter:country:ship:gear:pooled:area code; rectangle codes read as numbers converted back (e.g. 4.1e+08 to 41E7)
      area <- as.character(ca_pooled$AreaCode)
      area_num <- suppressWarnings(as.numeric(area))
      conv <- as.character(ca_pooled$AreaType) %in% "0" & !is.na(area_num) & area_num >= 10
      e <- floor(log10(area_num[conv])) - 1
      area[conv] <- paste0(round(area_num[conv] / 10^e), "E", e)
      ca_pooled$haul.id <- if (nrow(ca_pooled) > 0) {
        paste(ca_pooled$Survey, ca_pooled$Year, ca_pooled$Quarter, ca_pooled$Country, ca_pooled$Ship, ca_pooled$Gear, "pooled", area, sep = ":")
      } else {
        character(0)
      }

      # Valid catch records: SpecVal 1, 2, 4-8, 10 (2 taken as valid for all species; see cleaning_codes/north_east_atlantic_datras/cleaning_notes/nea_datras_catch_zeros.md)
      valid_specval <- c(1, 2, 4, 5, 6, 7, 8, 10)

      # Haul x species with only invalid catch records (catch unknown; NA in len_freq)
      hl_invalid <- surv[["HL"]] |>
        summarise(valid = any(SpecVal %in% valid_specval), .by = c(haul.id, Valid_Aphia)) |>
        filter(!valid) |>
        mutate(haul_id = as.character(haul.id), valid_aphia = Valid_Aphia, .keep = "none")

      surv <- subset(surv, SpecVal %in% valid_specval)

      # Haul x species with valid catch records but no lengths (e.g. SpecVal 4, total number only): caught, but the catch by length is unknown (NA in len_freq)
      hl_nolength <- surv[["HL"]] |>
        summarise(lengths = any(!is.na(LngtCm) & !is.na(Count)), .by = c(haul.id, Valid_Aphia)) |>
        filter(!lengths) |>
        mutate(haul_id = as.character(haul.id), valid_aphia = Valid_Aphia, .keep = "none")

      # Effort: swept area (km2) per haul, calculated once for all hauls of the survey (gaps filled with medians per gear); NA if it cannot be calculated
      effort <- tryCatch(
        {
          surv_sa <- add_swept_area(surv)
          tibble(haul.id = surv_sa[["HH"]]$haul.id, effort = surv_sa[["HH"]]$SweptArea)
        },
        error = function(e) {
          message("survey: ", survey_name, " | effort set to NA: ", e$message)
          tibble(haul.id = surv[["HH"]]$haul.id, effort = NA_real_)
        }
      ) |>
        mutate(effort_type = "swept_area_km2")

      # Haul information, one row per haul
      haul <- surv[["HH"]] |>
        distinct(haul.id, .keep_all = TRUE) |>
        # Position is the shoot position (DATRAS); the haul position where the shoot position is incomplete
        mutate(
          use_haul_pos = (is.na(lon) | is.na(lat)) & !is.na(HaulLong) & !is.na(HaulLat),
          lon = if_else(use_haul_pos, HaulLong, lon),
          lat = if_else(use_haul_pos, HaulLat, lat)
        ) |>
        mutate(
          date = make_date(
            as.integer(as.character(Year)),
            as.integer(as.character(Month)),
            if_else(is.na(Day) | as.integer(as.character(Day)) == 0L,
              1L, as.integer(as.character(Day))
            )
          ),
          Gear = as.character(Gear),
          Country = as.character(Country)
        ) |>
        # BySpecRecCode and Country: used in clean to set zeros or NA (not in the output)
        dplyr::select(haul.id, lon, lat, date, Gear, Depth, BySpecRecCode, Country) |>
        left_join(effort, by = "haul.id") |>
        janitor::clean_names()

      ca <- surv[["CA"]]

      # Species with aged fish that have both length and age
      species <- ca |>
        summarise(has_len_age = any(!is.na(LngtCm) & !is.na(Age)), .by = Valid_Aphia) |>
        filter(has_len_age) |>
        pull(Valid_Aphia)

      # Also species aged only without a haul
      species <- union(species, unique(ca_pooled$Valid_Aphia[!is.na(ca_pooled$LngtCm) & !is.na(ca_pooled$Age)]))

      size_list <- list()
      hl_list <- list()

      for (j in species) {
        tryCatch(
          {
            surv_sp <- subset(surv, Valid_Aphia == j)

            # Remove HL lengths above 2 x maxL (see cleaning_codes/north_east_atlantic_datras/cleaning_notes/nea_datras_hl_length_corrections.md)
            max_l <- species_info$maxL[match(j, species_info$WoRMS_AphiaID)]
            if (!is.na(max_l)) {
              too_long <- !is.na(surv_sp[["HL"]]$LngtCm) & surv_sp[["HL"]]$LngtCm > 2 * max_l
              surv_sp[["HL"]] <- surv_sp[["HL"]][!too_long, ]
              if (any(too_long)) message("survey: ", survey_name, " | species: ", j, " | HL rows removed (length > 2 x maxL): ", sum(too_long))
            }

            # LngtCm (DATRAS::readICES) = LngtClas * 0.1 for LngtCode "." and "0", * 1 for "1", "2", "5"; lower bound of the length class

            # Numbers (HH$N) and weight (HH$Wgt, g) per haul x length bin from DATRASextra; a = 0.01, b = 3 if species_info has no a, b
            lw_species <- species_info[species_info$WoRMS_AphiaID == j, ]
            lw_fallback <- if (nrow(lw_species) == 0 || is.na(lw_species$a[1]) || is.na(lw_species$b[1])) c(a = 0.01, b = 3) else NULL
            hl_list[[as.character(j)]] <- tryCatch(
              {
                # 1 cm bins (DATRASextra default: the coarsest length class of the survey x species); catch in 2 and 5 cm classes is spread over their 1 cm bins
                width <- c("2" = 2, "5" = 5)[as.character(surv_sp[["HL"]]$LngtCode)]
                coarse <- !is.na(width) & !is.na(surv_sp[["HL"]]$LngtCm)
                lo <- floor(surv_sp[["HL"]]$LngtCm)
                cm_breaks <- seq(min(lo, na.rm = TRUE), max(lo + coalesce(width, 1), na.rm = TRUE), by = 1)
                spread <- spread_classes(surv_sp[["HL"]][coarse, ], surv_sp[["CA"]], width[coarse])
                # Spread catch as 1 cm records (copies of a record of the haul), so add_numbers_at_length() rounds it per bin to whole fish as all catch
                new_hl <- surv_sp[["HL"]][coarse, ][match(spread$haul.id, as.character(surv_sp[["HL"]]$haul.id[coarse])), ]
                new_hl$LngtCm <- spread$cm
                new_hl$Count <- spread$n
                surv_sp[["HL"]]$Count[coarse] <- 0
                surv_sp[["HL"]] <- rbind(surv_sp[["HL"]], new_hl)

                surv_wgt <- surv_sp |>
                  add_numbers_at_length(cm_breaks = cm_breaks, by = 1) |>
                  add_total_weight_by_haul(lw_pars = lw_fallback)
                n_mat <- surv_wgt[["HH"]]$N
                wgt_mat <- surv_wgt[["HH"]]$Wgt
                stopifnot(identical(attr(surv_wgt, "cm.breaks"), cm_breaks), ncol(n_mat) == length(cm_breaks) - 1, identical(dim(n_mat), dim(wgt_mat)))

                # Length frequencies, one row per haul x 1 cm bin with fish (lngt = lower bound)
                tibble(
                  haul.id = rep(rownames(n_mat), times = ncol(n_mat)),
                  lngt = rep(cm_breaks[-length(cm_breaks)], each = nrow(n_mat)),
                  num = as.vector(n_mat),
                  wgt = as.vector(wgt_mat) / 1000
                ) |>
                  filter(num > 0) |>
                  mutate(valid_aphia = j, species = aphia_to_species[as.character(j)]) |>
                  janitor::clean_names()
              },
              error = function(e) {
                message("survey: ", survey_name, " | species: ", j, " | no length frequencies: ", e$message)
                NULL
              }
            )

            # Aged fish, n = number of fish in the record (NoAtALK); with a haul, and without a haul (pooled haul id)
            size_list[[as.character(j)]] <- bind_rows(
              surv_sp[["CA"]] |> mutate(haul.id = as.character(haul.id)),
              ca_pooled[ca_pooled$Valid_Aphia %in% j, ]
            ) |>
              mutate(LngtCode = as.character(LngtCode), Sex = as.character(Sex)) |>
              dplyr::select(haul.id, n = NoAtALK, LngtClas, LngtCm, LngtCode, Age, IndWgt, Sex) |>
              mutate(
                valid_aphia = j,
                species = aphia_to_species[as.character(j)]
              ) |>
              janitor::clean_names()

            message(
              "survey: ", survey_name,
              " | species: ", j,
              " (", aphia_to_species[as.character(j)], ") | PASSED"
            )
            log_list[[paste(survey_name, j)]] <- tibble(
              survey      = survey_name,
              valid_aphia = j,
              species     = aphia_to_species[as.character(j)],
              status      = "PASSED",
              reason      = NA_character_
            )
          },
          error = function(e) {
            failed[[paste(survey_name, j, sep = "_")]] <<- conditionMessage(e)
            message(
              "survey: ", survey_name,
              " | species: ", j,
              " (", aphia_to_species[as.character(j)], ") | FAILED: ", e$message
            )
            log_list[[paste(survey_name, j)]] <<- tibble(
              survey      = survey_name,
              valid_aphia = j,
              species     = aphia_to_species[as.character(j)],
              status      = "FAILED",
              reason      = e$message
            )
          }
        )
      }

      results[[survey_name]] <- list(
        haul = haul, # one row per haul
        hl = bind_rows(hl_list), # numbers and weight per haul x species x length bin
        ca = bind_rows(size_list), # aged fish (a subsample of the catch), n = number of fish per record
        hl_invalid = hl_invalid, # haul x species with only invalid catch records (SpecVal 0, 3, 9)
        hl_nolength = hl_nolength # haul x species with valid catch records but no lengths
      )
    },
    error = function(e) {
      failed[[survey_name]] <<- conditionMessage(e)
      message("survey: ", survey_name, " | FAILED: ", e$message)
      log_list[[survey_name]] <<- tibble(
        survey      = survey_name,
        valid_aphia = NA_integer_,
        species     = NA_character_,
        status      = "FAILED",
        reason      = e$message
      )
    }
  )
}


# -----------------------------------------------------------------------------
# Save output for further processing
# -----------------------------------------------------------------------------
run_log <- bind_rows(log_list)

saveRDS(results, file.path(home, "cleaning_codes/north_east_atlantic_datras/merged_survey_data.rds"))
saveRDS(run_log, file.path(home, "cleaning_codes/north_east_atlantic_datras/log_survey_data.rds"))
