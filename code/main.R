# =============================================================================
# main.R Master controller script
# UNDiD BRFSS: US Control States 2016-2022
#
# Use:
#   In RStudio: open this file, then Cmd+Shift+Enter (or click Source)
#   From terminal: cd /path/to/project && R CMD BATCH main.R
#
# BEFORE RUNNING:
#   - Ensure the raw BRFSS LLCP .XPT files (2016-2022) are placed in data/raw/
#   - R packages: haven, dplyr, tidyr, purrr, undidR
#   - To reproduce: set root_dir below, run from top to bottom
# =============================================================================

# --- Set root directory -------------------------------------------------------
# This is the ONLY line that needs to change on a different machine.
# Everything else uses paths relative to this.

#root_dir <- getwd()
root_dir <- "/Users/alexandradouglas/Desktop/workingDiD"


# --- Source component scripts in order ----------------------------------------
# 00: Shared configuration (paths, target states, variable mappings)
source(file.path(root_dir, "code", "00_config.R"), echo = TRUE)

clean_dir <- "/Users/alexandradouglas/Desktop/RA/BRFSS_CLEAN"   # TEMP - revert tonight

# 01: Extract and harmonize (read XPT, filter states, rename variables)
# source(file.path(root_dir, "code", "01_extract_harmonize.R"), echo = TRUE)

# 02: Clean and append (set non-response to NA, create derived vars, stack years)
source(file.path(root_dir, "code", "02_clean_append.R"), echo = TRUE)

# 03: Missingness and coverage diagnostics
source(file.path(root_dir, "code", "03_missingness.R"), echo = TRUE)

# 04: Harmonize covariates to agreed CCHS coding and prep undidR input
source(file.path(root_dir, "code", "04_undid_prep.R"), echo = TRUE)

# --- Session info for reproducibility ----------------------------------------
cat("\n============================================================\n")
cat("SESSION INFO\n")
cat("============================================================\n\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("R version:", R.version.string, "\n")
cat("Platform:", R.version$platform, "\n\n")
sessionInfo()
cat("\n\nPipeline complete.\n")