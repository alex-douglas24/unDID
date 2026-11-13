# =============================================================================
# 02_undid_stage2.R: Run undidR stage two
#
# WHAT IT DOES
#   Runs stage two for the US silo, once with the common adoption file and once
#   with the staggered adoption file, and saves the filled and trends files for both cases. 
#
# OUTPUT
#   data/undid/common_adoption/
#   filled_diff_df_USA.csv
#   trends_data_USA.csv
#   data/undid/staggered_adoption/
#   filled_diff_df_USA.csv
#   trends_data_USA.csv
#
# HOW TO RUN
#   Not run on its own. part2_run_all.R runs it after 01_data_cleaning.R.
#
# BEFORE RUNNING
#   01_data_cleaning.R must have run, so that data/clean/brfss_undid_input.rds
#   exists.
# =============================================================================
undid_input <- readRDS(file.path(clean_dir, "brfss_undid_input.rds"))

# --- Stage two: common adoption ------------------------------------------------
# stage two points undidR to the empty_diff_df.csv received from Central. 
# undidR uses that file together with the silo's data to calculate
# the before-and-after differences, and saves the filled file and the trends
# file in the folder given by filepath.
# In this project: reads data/undid/common_adoption/empty_diff_df.csv and saves
# the two output files in that same folder.
 
cat("============================================================\n")
cat("STAGE TWO: COMMON ADOPTION\n")
cat("============================================================\n\n")
 
stage2 <- undid_stage_two(
  empty_diff_filepath = common_file,
  silo_name           = silo_name,
  silo_df             = undid_input,
  time_column         = "year",
  outcome_column      = "use30",
  silo_date_format    = "yyyy",
  filepath            = common_dir
)
 
print(stage2$diff_df[, c("silo_name", "treat", "start_time", "end_time",
                         "diff_estimate", "diff_estimate_covariates", "n")])
 
cat("\nSend back: filled_diff_df_", silo_name, ".csv and trends_data_",
    silo_name, ".csv (from ", common_dir, ")\n\n", sep = "")
 
 
# --- Stage two: staggered adoption ---------------------------------------------
# Same as above, with the staggered adoption file. Its rows list every
# comparison between a treatment start year (gvar) and a later year, so the
# filled file has several rows for this silo.
# In this project: reads data/undid/staggered_adoption/empty_diff_df.csv and
# saves the two output files in that same folder. If you were to use undid you would 
# only run one of the two adoption types, not both.
 
cat("============================================================\n")
cat("STAGE TWO: STAGGERED ADOPTION\n")
cat("============================================================\n\n")
 
stage2_stag <- undid_stage_two(
  empty_diff_filepath = stag_file,
  silo_name           = silo_name,
  silo_df             = undid_input,
  time_column         = "year",
  outcome_column      = "use30",
  silo_date_format    = "yyyy",
  filepath            = stag_dir
)
 
print(stage2_stag$diff_df[, c("silo_name", "gvar", "treat", "gt",
                              "diff_estimate", "diff_estimate_covariates", "n")])
 
cat("\nSend back: filled_diff_df_", silo_name, ".csv and trends_data_",
    silo_name, ".csv (from ", stag_dir, ")\n\n", sep = "")

# --- Record the computing environment -----------------------------------------
# Printing the session info puts the R and package versions in the log.
cat("\n============================================================\n")
cat("SESSION INFO\n")
cat("============================================================\n\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
print(sessionInfo())

cat("\n\nPart 2 complete.\n")