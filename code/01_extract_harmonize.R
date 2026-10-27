# =============================================================================
# 01_extract_harmonize.R: Extract and harmonize BRFSS data
#
# WHAT IT DOES
#   For each survey year: reads the LLCP .XPT file, filters to the 6 target states
#   selects and renames variables to standardized names (using the year specific 
#   names from 00_config.R), adds a year column and saves a clean .rds file.
#
# BEFORE RUNNING
#   The raw BRFSS files (LLCP2016.XPT to LLCP2022.XPT) must be in data/raw/.
#   Download links are in README.md.
#
# HOW TO RUN
#   Not run on its own. main.R runs it after 00_config.R.
#
# INPUT/OUTPUT
#   Input:  data/raw/LLCP{year}.XPT (one per year)
#   Output: data/clean/brfss_clean_{year}.rds (one per year)
#
# Notes: *revise! is this actually true? or even is this needed?*
#   - Only the main LLCP (combined landline + cellphone) files are needed.
#     Our 6 target states always included the marijuana module on all
#     questionnaire versions  *revise! is this actually true?*
#   - Variables that do not exist in a given year (e.g., BIRTHSEX before
#     2019) are skipped during selection. bind_rows() in 02_clean_append.R
#     fills those columns with NA. *
#   - Not all 6 states fielded the marijuana module every year. (explain why this is fine?)
# =============================================================================



cat("============================================================\n")
cat("STEP 1: EXTRACT AND HARMONIZE\n")
cat("============================================================\n\n")

for (yr in years) {
  
  cat("Processing", yr, "...\n")
  
  # --- Read the raw XPT for this year 
  file_path <- find_xpt(yr)
  df <- read_xpt(file_path)
  cat("  Raw file:", ncol(df), "variables,", nrow(df), "observations\n")
  
  # --- Get variable names used in this years file and standardize them 
  config       <- get_year_config(yr)
  raw_names    <- names(config)
  common_names <- unname(config)
  
  # --- Check which of the variables exist in this years file 
  available <- raw_names %in% names(df)
  
  if (!all(available)) {
    missing_vars <- raw_names[!available]
    cat("  Note: Not in", yr, "data (expected for some years):",
        paste(missing_vars, collapse = ", "), "\n")
  }
  
  # --- Keep the 6 control states
  df <- df %>%
    filter(`_STATE` %in% target_states)
  
  cat("  After filtering to target states:", nrow(df), "observations\n")
  
  if (nrow(df) == 0) {
    cat("  No observations — skipping.\n\n")
    next
  }
  
  # --- Select and rename the variables to standardized names
  rename_vec <- setNames(raw_names[available], common_names[available])
  
  df_clean <- df %>%
    select(all_of(raw_names[available])) %>%
    rename(all_of(rename_vec))
  
  # --- Add year as raw file does not have it ---
  df_clean$year <- yr
  
  # --- Print summary ---
  cat("  States present:",
      paste(state_labels[as.character(unique(df_clean$state))], collapse = ", "), "\n")
  cat("  Cannabis data non-missing:",
      sum(!is.na(df_clean$marijuana_days)), "of", nrow(df_clean), "\n")
  
  # --- Save one cleaned file for each year ---
  out_path <- file.path(clean_dir, paste0("brfss_clean_", yr, ".rds"))
  saveRDS(df_clean, out_path)
  cat("  Saved:", out_path, "\n\n")
  
  rm(df, df_clean)
  gc()
}

cat("Extract and harmonize complete.\n\n")