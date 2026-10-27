# =============================================================================
# part2_main.R: Part 2 controller script. Prepare the silo data and run undidR
#               stage two 
#
# WHAT IT DOES
#   This is the script for part 2 of the undidR analysis. This can only occur once 
#   central sets up the design and sends each silo the empty_diff_df.csv. 
#   Stage two happens inside each silo. The silo prepares its data to match that file, 
#   points undidR to the file, and send back two filled to central: 
#     filled_diff_df_<silo>.csv    the ATT estimates (with and without
#                                  covariates) and their variances
#     trends_data_<silo>.csv       the mean outcome for every year
#
#   In this project: this is stage two for the US silo, which is the six BRFSS
#   control states pooled into one silo named "USA". It runs stage two twice, 
#   once for common adoption and once for staggered adoption. Stage one is not
#   run here, because the CCHS silo does it. 
#     01 prepares the silo data and 02 runs stage two
#
# INPUT/OUTPUT
#   data/clean/brfss_undid_input.rds         the undidR input data from part1
#   data/undid/common_adoption/              filled_diff_df_USA.csv and
#                                            trends_data_USA.csv
#   data/undid/staggered_adoption/           filled_diff_df_USA.csv and
#                                            trends_data_USA.csv
#   The filled_diff_df_USA.csv and trends_data_USA.csv files in the two undid
#   folders are the files to send back to the CCHS silo. In this case we are demonstrating 
#   both staggered and common adoption, but in a real project only one would be used.
#
# HOW TO RUN **revise look at the guide to make sure this is correct**
#   Open a terminal and run:
#     cd <path to this repository>/code/part2_undid_stage_two
#     R CMD BATCH part2_main.R
#   Or open this file in RStudio or VS Code and source it.
#
# BEFORE RUNNING
#   - Part 1 must have run, so that data/clean/brfss_harmonized.rds exists.
#   - The empty_diff_df.csv files from the CCHS silo must be saved in
#     data/undid/common_adoption/ (common adoption) and
#     data/undid/staggered_adoption/ (staggered adoption).
#   - Install the R packages checked below.
# =============================================================================


# --- Required packages ---------------------------------------------------------
# Stops if a package is missing. Tested with R 4.4.1 and undidR 3.0.2.
required_packages <- c("here", "dplyr", "undidR")
missing_packages  <- setdiff(required_packages,
                             rownames(installed.packages()))

if (length(missing_packages) > 0) {
  stop("Please install these R packages, then run part2_main.R again: ",
       paste(missing_packages, collapse = ", "))
}

library(dplyr)
library(undidR)


# --- Find the project folder ---------------------------------------------------
# root_dir is the top folder of this repository: the folder that contains
# code/, data/ and appendix/. Every other path in the project is built from it.
#
# here::here() works it out automatically. It looks upward from the folder you
# are running in until it finds a .git folder or a file named .here. So the
# repository only needs to keep its original layout (code/, data/, ...).
root_dir  <- here::here()
part2_dir <- file.path(root_dir, "code", "part2_undid_stage_two")

# Safety check: stop with a clear message if the Part 2 folder isn't where we
# expect it, instead of failing later with a confusing error.
if (!file.exists(file.path(part2_dir, "01_prepare_silo_data.R"))) {
  stop("Could not find code/part2_undid_stage_two/01_prepare_silo_data.R under ",
       root_dir, ". Run part2_main.R from inside the repository, and keep its ",
       "original folder layout.")
}


# --- Settings and files received from the CCHS silo ----------------------------
# In general: stage two starts from the empty_diff_df.csv file sent by the
# coordinator. The silo name must be spelled exactly as it is in that file.
# In this project: the US silo is called "USA". The two received files are kept
# in separate folders so that the filled files are saved next to them.
clean_dir  <- file.path(root_dir, "data", "clean")
common_dir <- file.path(root_dir, "data", "undid", "common_adoption")
stag_dir   <- file.path(root_dir, "data", "undid", "staggered_adoption")

silo_name   <- "USA"
common_file <- file.path(common_dir, "empty_diff_df.csv")
stag_file   <- file.path(stag_dir,   "empty_diff_df.csv")

# Stop with a clear message if an input file is not in place
if (!file.exists(file.path(clean_dir, "brfss_harmonized.rds"))) {
  stop("Missing data/clean/brfss_harmonized.rds. Run Part 1 first.")
}

for (f in c(common_file, stag_file)) {
  if (!file.exists(f)) {
    stop("Missing ", f, ". Save the empty_diff_df.csv file received from the ",
         "CCHS silo there.")
  }
}


# --- Run the Part 2 scripts in order ------------------------------------------
# echo = TRUE prints each line of code as it runs, so the log shows exactly
# what was done.

# 01: Prepare the data to match the received files, then check it
source(file.path(part2_dir, "01_prepare_silo_data.R"), echo = TRUE)

# 02: Run undidR stage two for common adoption and for staggered adoption
source(file.path(part2_dir, "02_run_stage_two.R"), echo = TRUE)


# --- Record the computing environment -----------------------------------------
# Printing the session info puts the R and package versions in the log.
cat("\n============================================================\n")
cat("SESSION INFO\n")
cat("============================================================\n\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
print(sessionInfo())

cat("\n\nPart 2 complete.\n")