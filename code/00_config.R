# =============================================================================
# 00_config.R: Shared configuration
#
# This script defines all settings shared across the project: directory paths, 
# states of interest, study years, and the year-specific variable names in BRFSS.
#
# Sourced by main.R before any other script.
# =============================================================================
# --- Packages -----------------------------------------------------------------
library(haven)
library(dplyr)
library(tidyr)
library(purrr)
library(undidR)


# --- Directories --------------------------------------------------------------
# root_dir is set in main.R before this file is sourced.
# All paths are built with file.path() for platform independence.

raw_dir   <- file.path(root_dir, "data", "raw")
clean_dir <- file.path(root_dir, "data", "clean")
out_dir   <- file.path(root_dir, "output")

dir.create(clean_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(out_dir,   showWarnings = FALSE, recursive = TRUE)


# --- Target states (FIPS codes) -----------------------------------------------
# These 6 US states serve as untreated controls in the unDiD comparing against Canada 

target_states <- c(
  16,  # Idaho
  27,  # Minnesota
  33,  # New Hampshire
  38,  # North Dakota
  47,  # Tennessee
  56   # Wyoming
)

state_labels <- c(
  "16" = "Idaho",
  "27" = "Minnesota",
  "33" = "New Hampshire",
  "38" = "North Dakota",
  "47" = "Tennessee",
  "56" = "Wyoming"
)


# --- Study years --------------------------------------------------------------
years <- 2016:2022


# --- Within silo harmonization variable names -------------------------------------
# BRFSS renames some variables across survey years. This takes the column names in the .XPT files 
# and renames them to a standardized name. See README files for details. 
#UNDID  CHECK IF THEY NEED TO BE THE SAME *****
#
# How it works:
#   names(config)  = column names as they appear in the .XPT for that year
#   values(config) = standardized column names used in the analysis dataset
#
# Example: setNames("marijuana_days", "MARIJANA") creates the element
#   "MARIJANA" = "marijuana_days"
# meaning it finds the column called MARIJANA and rename it to marijuana_days.
#
# Variables that do not exist in a given year (e.g., BIRTHSEX before 2019)
# are handled after: the "available" check in 01_extract_harmonize.R
# skips them, and bind_rows() in 02_clean_append.R fills them with NA.
#
# Variable name changes across the BRFSS 2016-2022: 
#   Cannabis:       MARIJANA (2016-17) -> MARIJAN1 (2018-22)
#   Binge drinking: _RFBING5 (2016-21) -> _RFBING6 (2022)
#   Sex (primary):  SEX (2016-17) -> SEX1 (2018) -> _SEX (2019-22)
#   Sex (reported): SEX (2016-17) -> SEX1 (2018) -> SEXVAR (2019-22)
#   Birth sex:      not collected (2016-18) -> BIRTHSEX (2019-22)
#   Income:         INCOME2 (2016-20, 8 categories) -> INCOME3 (2021-22, 11 categories)
#   Race preferred: _PRACE1 (2016-21) -> _PRACE2 (2022)
#   Race multi:     _MRACE1 (2016-21) -> _MRACE2 (2022)
#   Race binary:    _RACEG21 (2016-21) -> _RACEG22 (2022)
#   Race 5-level:   _RACEGR3 (2016-21) -> _RACEGR4 (2022)
#   Race detailed:  _RACE (2016-21) -> _RACE1 (2022)

get_year_config <- function(yr) {
  
  # --- Year-varying names ----------------------------------
  # Cannabis (outcome)
  mj_var <- if (yr <= 2017) "MARIJANA" else "MARIJAN1"
  
  # Binge drinking
  binge_var <- if (yr <= 2021) "_RFBING5" else "_RFBING6"
  
  # Income
  income_var <- if (yr <= 2020) "INCOME2" else "INCOME3"
  
  # Sex: BRFSS calculated variable (_SEX available 2019+; for earlier years,
  # the closest equivalent is the raw respondent sex variable)
  if (yr <= 2017)      { sex_primary <- "SEX" }
  else if (yr == 2018) { sex_primary <- "SEX1" }
  else                 { sex_primary <- "_SEX" }
  
  # Sex: respondent-reported (changes name each period)
  if (yr <= 2017)      { sex_reported <- "SEX" }
  else if (yr == 2018) { sex_reported <- "SEX1" }
  else                 { sex_reported <- "SEXVAR" }
  
  # Race/ethnicity variables that change in 2022 due to additional category see README file
  mrace_var   <- if (yr <= 2021) "_MRACE1"  else "_MRACE2"
  raceg2_var  <- if (yr <= 2021) "_RACEG21" else "_RACEG22"
  racegr3_var <- if (yr <= 2021) "_RACEGR3" else "_RACEGR4"
  race_var    <- if (yr <= 2021) "_RACE"    else "_RACE1"
  prace_var   <- if (yr <= 2021) "_PRACE1"  else "_PRACE2"
  
  
  # --- Build mapping: raw_name -> standardized_name 
  
  config <- c(
    
    setNames("state",            "_STATE"),
    setNames("finalwt",          "_LLCPWT"),
    
    # ---- OUTCOME: CANNABIS 
    setNames("marijuana_days",   mj_var),
    
    # ---- AGE
    setNames("age_5yr",          "_AGEG5YR"),    # 14-level 5-year groups
    setNames("age_6grp",         "_AGE_G"),       # 6 imputed age groups
    setNames("age_2grp",         "_AGE65YR"),     # 2-level: 18-64 vs 65+
    setNames("age_imputed",      "_AGE80"),        # imputed age collapsed at 80
    
    # ---- SEX 
    setNames("sex",              sex_primary),    # harmonized across all years
    setNames("sex_reported",     sex_reported),   # respondent-reported
    setNames("birthsex",         "BIRTHSEX"),     # 2019-22 only; NA for earlier
    
    # ---- INCOME 
    # INCOME2 (2016-20): 8 categories, top = "$75,000 or more
    # INCOME3 (2021-22): 11 categories, finer top-end brackets
    setNames("income_raw",       income_var),
    
    # ---- EDUCATION 
    # EDUCA: raw 6-level (1=never attended through 6=college grad)
    # Will be recoded to 4 categories in 02_clean_append.R to match CCHS:
    #   1 = less than secondary (EDUCA 1-3)
    #   2 = secondary graduate (EDUCA 4)
    #   3 = some post-secondary (EDUCA 5)
    #   4 = post-secondary/university diploma (EDUCA 6)
    # _EDUCAG: BRFSS-computed 4-level (kept for reference)
    setNames("education_raw",    "EDUCA"),
    setNames("education_4cat",   "_EDUCAG"),
    
    # ---- MARITAL STATUS
    setNames("marital",          "MARITAL"),
    
    # ---- EMPLOYMENT 
    setNames("employment",       "EMPLOY1"),
    
    # ---- HEALTH 
    setNames("general_health",   "GENHLTH"),      # 5-level self-rated
    setNames("health_status",    "_RFHLTH"),      # binary good vs fair/poor
    setNames("physical_health",  "PHYSHLTH"),     # days physical health not good
    setNames("mental_health_d",  "MENTHLTH"),     # days mental health not good
    setNames("mental_health_3",  "_MENT14D"),     # computed 3-level
    
    # ---- RACE/ETHNICITY 
    setNames("race_imputed",     "_IMPRACE"),     # imputed race/ethnicity
    setNames("race_multi",       mrace_var),      # multiracial classification
    setNames("race_binary_wh",   raceg2_var),     # binary: white NH vs other
    setNames("race_5level",      racegr3_var),    # 5-level race/ethnicity
    setNames("race_detailed",    race_var),       # detailed race/ethnicity
    setNames("race_preferred",   prace_var),      # preferred race
    
    # ---- OTHER VARIABLES 
    setNames("binge_drink",      binge_var)       # binary binge drinking
  )
  
  return(config)
}

cat("Configuration loaded.\n")
cat("  Target states:", paste(state_labels, collapse = ", "), "\n")
cat("  Years:", paste(range(years), collapse = "-"), "\n")
cat("  Raw data:", raw_dir, "\n")
cat("  Clean data:", clean_dir, "\n")
cat("  Output:", out_dir, "\n\n")
