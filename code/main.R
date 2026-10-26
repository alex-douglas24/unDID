# =============================================================================
# main.R Master controller script
# UNDiD BRFSS: US Control States 2016-2022
#
# What this script does:
#   This is the main controller script that runs the cleaning, harmonization and UNDiD preperation for the US Silo.
#   This script should run top to bottom and produce a clean, harmonized dataset. 
#
# Before runnning:   
#   1. Put the raw BRFSS files LLCP2016.XPT ... LLCP2022.XPT in data/raw/
#      (see data/raw/README.md for where to download them).
#               These files can be downloaded here: https://www.cdc.gov/brfss/annual_data/annual_data.htm
#               (Click on the year, then download the SAS Transport  file for that year)
#   2. Put the two empty_diff_df.csv files received from the Central Silo (in this case the CCHS silo) in:
#        data/clean/received_common/empty_diff_df.csv   (common adoption)
#        data/clean/received_stag/empty_diff_df.csv     (staggered adoption)
#   3. Install the R packages listed under "Required packages" below.
#  
# How to run it:
#   1. Set the root_dir variable below to the path of the working directory on your machine.
#   2. Open RStudio or VS Code and source this script. It will run all the component scripts in order. 
# 
# Output:
#   1. A clean, harmonized dataset in data/clean/undid_input
# =============================================================================





# --- Required packages ---------------------------------------------------------
# CHECK 1: PACKAGE ERROR: script will stop if a package is missing. 
required_packages <- c("here", "haven", "dplyr", "tidyr", "purrr", "undidR")
missing_packages  <- setdiff(required_packages,
                             rownames(installed.packages()))
 
if (length(missing_packages) > 0) {
  stop("Please install these R packages, then run main.R again: ",
       paste(missing_packages, collapse = ", "))





# --- Find the project folder ---------------------------------------------------
# root_dir is the top folder of this repository: the folder that contains
# code/, data/ and output/. Every other path in the project is built from it.
# here::here() works this out and looks upward from the folder you
# are running in until it finds a .git folder or a file named .here. So the
# repository only needs to keep its original layout (code/, data/, ...).
# Meaning that nothing needs to be edited by hand on a different computer.
root_dir <- here::here()
 
# CHECK 2: PROJECT FOLDER ERROR: script will stop if the code folder isn't where its expected. 
#This can happen if you run main.R from the wrong folder or move the repo!
if (!file.exists(file.path(root_dir, "code", "00_config.R"))) {
  stop("Could not find code/00_config.R under ", root_dir, ". ",
       "Run main.R from inside the repository, and keep its original ",
       "folder layout (code/, data/, output/).")
}





# --- Run the component scripts in order ---------------------------------------
# echo = TRUE prints each line of code as it runs, so the log shows exactly
# what was done.
 
# 00: Shared settings (paths, target states, years, variable names)
source(file.path(root_dir, "code", "00_config.R"), echo = TRUE)
 
# 01: Read the raw .XPT files, keep the 6 target states, rename variables
source(file.path(root_dir, "code", "01_extract_harmonize.R"), echo = TRUE)
 
# 02: Clean non-response codes, creates derived variables, stack all years
source(file.path(root_dir, "code", "02_clean_append.R"), echo = TRUE)
 
# 03: Missingness and coverage tables (written to output/) MAYBE NOT NEEDED, BUT KEEPING FOR NOW *REVIEW*
source(file.path(root_dir, "code", "03_missingness.R"), echo = TRUE)
 
# 04: Wait for stage one file from Central (empty-diff-df.csv) then match the covariate names (and coding?) *REVIEW*
source(file.path(root_dir, "code", "04_undid_prep.R"), echo = TRUE)
 




# --- Record the computing environment -----------------------------------------
# Saves the R version and package versions used for this run.
cat("\n============================================================\n")
cat("SESSION INFO\n")
cat("============================================================\n\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
 
session_path <- file.path(out_dir, "session_info.txt")
writeLines(capture.output(sessionInfo()), session_path)
cat("Session info saved to:", session_path, "\n\n")
print(sessionInfo())
 
cat("\n\nPipeline complete.\n")
