# =============================================================================
# 01_extract_harmonize.R — Extract and harmonize BRFSS data
#
# For each survey year: reads the raw LLCP .XPT file, filters to the 6 target
# states, selects and renames variables to standardized names (using the
# year specific names from 00_config.R), and saves a clean .rds file.
#
# Input:  data/raw/LLCP{year}.XPT (one per year)
# Output: data/clean/brfss_clean_{year}.rds (one per year)
#
# Notes:
#   - Only the main LLCP (combined landline + cellphone) files are needed.
#     Our 6 target states always included the marijuana module on all
#     questionnaire versions, meaning version-specific files (V1/V2/V3) are
#     not needed
#   - Variables that do not exist in a given year (e.g., BIRTHSEX before
#     2019) are skipped during selection. bind_rows() in 02_clean_append.R
#     fills those columns with NA.
#   - Not all 6 states fielded the marijuana module every year. This is
#     expected and documented in the console output below.
# =============================================================================

cat("============================================================\n")
cat("STEP 1: EXTRACT AND HARMONIZE\n")
cat("============================================================\n\n")

for (yr in years) {
  
  cat("Processing", yr, "...\n")
  
  # --- Read raw XPT 
  file_path <- file.path(raw_dir, paste0("LLCP", yr, ".XPT"))
  df <- read_xpt(file_path)
  cat("  Raw file:", ncol(df), "variables,", nrow(df), "observations\n")
  
  # --- Get variable mapping for this year
  config       <- get_year_config(yr)
  raw_names    <- names(config)
  common_names <- unname(config)
  
  # --- Check which variables exist 
  available <- raw_names %in% names(df)
  
  if (!all(available)) {
    missing_vars <- raw_names[!available]
    cat("  Note: Not in", yr, "data (expected for some years):",
        paste(missing_vars, collapse = ", "), "\n")
  }
  
  # --- Filter to target states
  df <- df %>%
    filter(`_STATE` %in% target_states)
  
  cat("  After filtering to target states:", nrow(df), "observations\n")
  
  if (nrow(df) == 0) {
    cat("  No observations — skipping.\n\n")
    next
  }
  
  # --- Select and rename 
  rename_vec <- setNames(raw_names[available], common_names[available])
  
  df_clean <- df %>%
    select(all_of(raw_names[available])) %>%
    rename(all_of(rename_vec))
  
  # --- Add year ---
  df_clean$year <- yr
  
  # --- Summary ---
  cat("  States present:",
      paste(state_labels[as.character(unique(df_clean$state))], collapse = ", "), "\n")
  cat("  Cannabis data non-missing:",
      sum(!is.na(df_clean$marijuana_days)), "of", nrow(df_clean), "\n")
  
  # --- Save ---
  out_path <- file.path(clean_dir, paste0("brfss_clean_", yr, ".rds"))
  saveRDS(df_clean, out_path)
  cat("  Saved:", out_path, "\n\n")
  
  rm(df, df_clean)
  gc()
}

cat("Extract and harmonize complete.\n\n")
