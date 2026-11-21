# =============================================================================
# part1_main.R: Part 1 controller script for the BRFSS silo (US control states
#               2016-2022)
#
# WHAT IT DOES
#   Runs Part 1 of the pipeline, from the raw BRFSS files to one cleaned BRFSS
#   dataset:
#   00 settings > 01 extract > 02 clean and append
#   Part 1 does not need anything from Central, so it can be run first. Part 2
#   (code/part2_undid_stage_two) then prepares this dataset for undidR once
#   you get Central's empty_diff_df.csv file. 
#   Note: the missingness tables are not part of this pipeline. They are in the
#   appendix/ folder and are run on their own.
#
# BEFORE RUNNING
#   1. Put the raw BRFSS files LLCP2016.XPT ... LLCP2022.XPT in data/raw/
#      (see data/raw/README.md for where to download them).
#               These files can be downloaded here: https://www.cdc.gov/brfss/annual_data/annual_data.htm
#               (Click on the year, then download the SAS Transport file for that year)
#   2. Install the R packages listed under "Required packages" below.
#
# HOW TO RUN **is there an easier way to explain this cuz like yes according to the guide this is true but hard ish, maybe clarify in readme**
#   Nothing needs to be edited by hand. Open a terminal and run:
#     cd <path to this repository>/code/part1_prepare_data
#     R CMD BATCH part1_main.R
#   This also saves a log of the run as part1_main.Rout.
#   Or open this file in RStudio or VS Code and source it. It will run all the
#   component scripts in order for part 1. 
#
# INPUT/OUTPUT
#   Input:  data/raw/LLCP{year}.XPT (one per year)
#   Output: data/clean/brfss_clean_{year}.rds   (one per year)
#           data/clean/brfss_analysis_2016_2022.rds   (all years, cleaned)
# =============================================================================


# --- Required packages ---------------------------------------------------------
# CHECK 1: PACKAGE ERROR: script will stop if a package is missing.
required_packages <- c("here", "haven", "dplyr")
missing_packages  <- setdiff(required_packages,
                             rownames(installed.packages()))

if (length(missing_packages) > 0) {
  stop("Please install these R packages, then run part1_main.R again: ",
       paste(missing_packages, collapse = ", "))
}


# --- Find the project folder ---------------------------------------------------
# root_dir is the top folder of this repository: the folder that contains
# code/, data/ and appendix/. Every other path in the project is built from it.
# here::here() works this out and looks upward from the folder you
# are running in until it finds a .git folder or a file named .here. So the
# repository only needs to keep its original layout (code/, data/, ...).
# Meaning that nothing needs to be edited by hand on your computer! 
root_dir  <- here::here()
part1_dir <- file.path(root_dir, "code", "part1_prepare_data")

# CHECK 2: PROJECT FOLDER ERROR: script will stop if the code folder isn't where
# it's expected. This can happen if you run part1_main.R from the wrong folder
# or move the repo!
if (!file.exists(file.path(part1_dir, "00_config.R"))) {
  stop("Could not find code/part1_prepare_data/00_config.R under ", root_dir,
       ". Run part1_main.R from inside the repository, and keep its original ",
       "folder layout (code/, data/, appendix/).")
}


# --- Run the component scripts in order ---------------------------------------
# echo = TRUE prints each line of code as it runs, so the log shows exactly
# what was done.

# 00: Shared settings (paths, target states, years, variable names)
source(file.path(part1_dir, "00_config.R"), echo = TRUE)

# 01: Read the raw .XPT files, keep the 6 target states, rename variables
source(file.path(part1_dir, "01_extract_harmonize.R"), echo = TRUE)

# 02: Clean non-response codes, create derived variables, stack all years
source(file.path(part1_dir, "02_clean_append.R"), echo = TRUE)


# --- Record the computing environment -----------------------------------------
# Printing the session info puts the R version and package versions in the log.
cat("\n============================================================\n")
cat("SESSION INFO\n")
cat("============================================================\n\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
print(sessionInfo())

cat("\n\nPart 1 complete.\n")