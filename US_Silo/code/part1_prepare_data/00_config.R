# =============================================================================
# 00_config.R: Shared settings 
#
# WHAT IT DOES
#   This script defines the setting that the pther scrips use like the folder paths, 
#   find_xpt(), which finds the raw BRFSS file for each year, the 6 US states used as 
#   the control group, study years, get_year_config(), a lookup of BRFSS variable names, 
#   as some of them change between years. This script also loads the needed packages.
#
# BEFORE RUNNING
#   main.R must have set root_dir (the top folder of the repository).
#  
# HOW TO RUN
#   This script is not run on its own. main.R runs it first to set up the environment for 
#   the other scripts to pull the correct folders and use the correct variable names.
# 
# INPUT/OUTPUT *revise*
#   This script does not create any data files. It will create the data/raw, data/clean and 
#   output folders if they are missing. 
# =============================================================================



# --- Packages -----------------------------------------------------------------
# main.R checks that these are installed before running this file.
library(haven)
library(dplyr)



# --- Folders ------------------------------------------------------------------
# root_dir (the top folder of the repository) is set in main.R.
#   raw_dir    raw BRFSS .XPT files, downloaded by the user (not in the repo)
#   clean_dir  cleaned data and undidR files created by the scripts
 
raw_dir   <- file.path(root_dir, "data", "raw")
clean_dir <- file.path(root_dir, "data", "clean")
 
# Create any folder that is missing. data/raw and data/clean is not stored in the repository,
# so it will not exist after a you download the repo, instead they are created by the scripts. 
dir.create(raw_dir,   showWarnings = FALSE, recursive = TRUE)
dir.create(clean_dir, showWarnings = FALSE, recursive = TRUE)


# --- Find the raw file for one year -------------------------------------------
# Once you download the LLCP{year}.XPT files from the BRFSS, put them in data/raw/ and this function will find them.
# This function is needed as some years the BRFSS files have a trailing space in the filename (e.g., "LLCP2016.XPT "), 
# so it matches on the year and ignores whitespace instead of requiring you to rename certain year files. 
# CHECK 3: RAW DATA FILE ERROR: Script will stop if no file, or more than one file, matches.
find_xpt <- function(yr, dir = raw_dir) {
  files <- list.files(dir, pattern = "\\.XPT\\s*$", ignore.case = TRUE)
  files <- files[!startsWith(files, "._")]
  hit   <- files[grepl(as.character(yr), files, fixed = TRUE)]
 
  if (length(hit) == 0) {
    stop("No .XPT file found for ", yr, " in ", dir)
  }
  if (length(hit) > 1) {
    stop("Multiple .XPT files match ", yr, ": ", paste(hit, collapse = ", "))
  }
 
  file.path(dir, hit)
}





# --- Target states (FIPS codes) -----------------------------------------------
# These 6 US states will act as the control group They are pooled into one silo in 
# 04_undid_prep.R. Note: not every state asked the cannabis questions in every year. 
# The tables in output/module_coverage.csv show which years each state is in. *REVIEW*
 
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


#** this is what you need to write about in the guide

# --- Within Silo variable names harmonization by year--------------------------
# BRFSS renames some variables across survey years. This takes the column names in the .XPT files 
# and renames them to a standardized name. See README files for more details on within silo variable name changes. 
# How it works:
#   names(config)  = column names as they appear in the .XPT for that year
#   values(config) = standardized column names used in the analysis dataset
##*REVISE does this actually make sense** 
# find a way to make it clear that this is like within silo variable name changes, not across silo variable name changes! 
# Example: setNames("marijuana_days", "MARIJANA") will find the column called MARIJANA  and rename it to marijuana_days.
#   "MARIJANA" = "marijuana_days"
# Variables that do not exist in a given year (e.g., BIRTHSEX before 2019)
# are handled after: the "available" check in 01_extract_harmonize.R
# skips them, and bind_rows() in 02_clean_append.R fills them with NA.
#*create a table for within silo variable name changes across years?*
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