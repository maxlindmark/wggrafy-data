# Purpose:   Download and structure DATRAS trawl survey data for growth analysis.
#            Reads exchange-format data for all surveys, filters to species with
#            both length and age records, builds first-phase length frequencies
#            (HL, n_k) and second-phase individual age data (CA), and saves a
#            single RDS list keyed by survey name.
#
# Output:    data/clean/clean_survey_data.rds
#            A named list; each element has $ca (one row per aged fish) and
#            $hl (one row per haul * length class).
#
# Modified:  2026-06-22
# Author:    Max Lindmark

#remotes::install_github("tokami/DATRASextra")
library(tidyr)
library(dplyr)
library(lubridate)
library(DATRASextra)
library(ggplot2)
library(purrr)

home <- here::here()

# -----------------------------------------------------------------------------
# Download DATRAS data for all years and surveys
# -----------------------------------------------------------------------------
# This takes a while..
# download_datras(surveys = NULL, years = NULL, dir = paste0(home, "/data/survey-data/"))


# -----------------------------------------------------------------------------
# Load saved DATRAS data
# -----------------------------------------------------------------------------

# Get survey names (folder names we just downloaded)
survey_paths <- list.dirs(file.path(home, "data", "survey-data"), recursive = FALSE)

# Load aphia_id to species name table
data("species_info", package = "DATRASextra")
aphia_to_species <- setNames(species_info$ScientificName_WoRMS, species_info$WoRMS_AphiaID)


# -----------------------------------------------------------------------------
# Iterate through surveys, find species with length AND age data, and 
# proceed with data processing using R package DATRASextra
# -----------------------------------------------------------------------------
results  <- list()
failed   <- list()
log_list <- list()

for (i in seq_along(survey_paths)) {
  tryCatch({
    path <- survey_paths[i]
    survey_name <- tools::file_path_sans_ext(basename(path))
    surv <- read_datras(path) |> clean_datras()
    
    if (is.null(surv[["CA"]])) stop("CA table is NULL")
    
    ca <- surv[["CA"]]
    
    species_check <- ca |>
      summarise(
        has_len_age = any(!is.na(LngtCm) & !is.na(Age)),
        valid = has_len_age,
        .by = Valid_Aphia
      )
    
    species <- species_check |> filter(valid) |> pull(Valid_Aphia)
    
    size_list <- list()
    hl_list   <- list()
    
    for (j in species) {
      tryCatch({
        surv_sp <- subset(surv, Valid_Aphia == j)
        
        # N_k: first-phase raised count per haul x length stratum.
        # Count = HLNoAtLngt * SubFactor, computed by the DATRAS package.
        # Sum across sex in case HL has separate rows per sex per length class.
        # Keep ALL length strata (including those with no aged fish) — needed
        # for the EP likelihood denominator (empty-stratum Q_k terms).
        n_k <- surv_sp[["HL"]] |>
          mutate(LngtCode = as.character(LngtCode)) |>
          summarise(n_k = sum(Count, na.rm = TRUE), .by = c(haul.id, LngtClas, LngtCode))
        
        hl_list[[as.character(j)]] <- n_k |>
          mutate(
            valid_aphia = j,
            species     = aphia_to_species[as.character(j)]
          ) |>
          janitor::clean_names()
        
        size_list[[as.character(j)]] <- surv_sp[["CA"]] |>
          mutate(LngtCode = as.character(LngtCode)) |>
          left_join(
            distinct(surv_sp[["HH"]], haul.id, .keep_all = TRUE) |>
              dplyr::select(haul.id, lon, lat, Month, Day),
            by = "haul.id"
          ) |>
          left_join(n_k, by = c("haul.id", "LngtClas", "LngtCode")) |>
          dplyr::select(
            haul.id, NoAtALK, LngtClas, LngtCm, LngtCode, Age, IndWgt,
            n_k, lon, lat, Year, Month, Day
          ) |>
          # expand: one row per individual fish (NoAtALK > 1 means multiple
          # fish of the same length bin and age were grouped in DATRAS)
          tidyr::uncount(NoAtALK) |>
          mutate(
            date        = make_date(
              as.integer(as.character(Year)),
              as.integer(as.character(Month)),
              if_else(is.na(Day) | as.integer(as.character(Day)) == 0L,
                      1L, as.integer(as.character(Day)))
            ),
            valid_aphia = j,
            species     = aphia_to_species[as.character(j)]
          ) |>
          dplyr::select(-Year, -Month, -Day) |>
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
        
      }, error = function(e) {
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
      })
    }
    
    results[[survey_name]] <- list(
      hl = bind_rows(hl_list),    # first-phase: N_k for all length strata per haul
      ca = bind_rows(size_list)   # second-phase: one row per individual aged fish
    )
    
  }, error = function(e) {
    failed[[survey_name]] <<- conditionMessage(e)
    message("survey: ", survey_name, " | FAILED: ", e$message)
    log_list[[survey_name]] <<- tibble(
      survey      = survey_name,
      valid_aphia = NA_integer_,
      species     = NA_character_,
      status      = "FAILED",
      reason      = e$message
    )
  })
}


# -----------------------------------------------------------------------------
# Save output for further processing
# -----------------------------------------------------------------------------
run_log <- bind_rows(log_list)

saveRDS(results, file.path(home, "R/01-prepare-survey-data/north-east-atlantic/output/merged_survey_data.rds"))
saveRDS(run_log, file.path(home, "R/01-prepare-survey-data/north-east-atlantic/output/log_survey_data.rds"))
