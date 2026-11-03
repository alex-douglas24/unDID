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
#   
#   In line with the manuscript this file goes through the following steps: 
#     a. variables names to match teh empty_diff_df.csv exactly received from Central 
#     b. time column that has string/text only 
#     c. silo name column that matches the silo name is empty_diff_df.csv received from Central, stored as text 
#     d. no missing values in any varaible used in th analysis
#     e. a 0/1 dummy column for eahc category of every categorical variable with more than two categories, leaving out the reference category. 
#     For example if a variable has 4 categories, three dummy columns are created, one for each of the non-reference categories.
#     f. outcome column. Central and the silos must have agreed on what it measures. For example, cannabis use in the opast 30 
# days in one silo cant be matched to use in past 12 months in another silo. 
# 
#
# INPUT/OUTPUT
#   Input:  data/clean/brfss_analysis_2016_2022.rds           from Part 1
#           data/undid/common_adoption/empty_diff_df.csv      from Central
#           data/undid/staggered_adoption/empty_diff_df.csv   from Central
#   Output: data/clean/brfss_undid_input.rds                  the undidR input data
#           data/undid/common_adoption/                       filled_diff_df_USA.csv and
#                                                             trends_data_USA.csv
#           data/undid/staggered_adoption/                    filled_diff_df_USA.csv and
#                                                             trends_data_USA.csv
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
#   - Part 1 must have run, so that data/clean/brfss_analysis_2016_2022.rds exists.
#   - The empty_diff_df.csv files from the CCHS silo must be saved in
#     data/undid/common_adoption/ (common adoption) and
#     data/undid/staggered_adoption/ (staggered adoption).
#   - Install the R packages checked below.
# =============================================================================


# --- Required packages ---------------------------------------------------------
# Stops if a package is missing. Tested with R 4.4.1 and undidR 3.0.2.
required_packages <- c("here", "dplyr", "undidR")
missing_packages  <- setdiff(required_packages, rownames(installed.packages()))

if (length(missing_packages) > 0) {
  stop("Please install these R packages, then run part2_main.R again: ", paste(missing_packages, collapse = ", "))
}

library(dplyr)
library(undidR)


# --- Find the project folder ---------------------------------------------------
# root_dir is the top folder of this repository: the folder that contains
# code/, data/ and appendix/. Every other path in the project is built from it.
root_dir  <- here::here()

# CHECK 2: PROJECT FOLDER ERROR: script will stop if the code folder isn't where its supposed to be. 
if (!file.exists(file.path(root_dir, "code", "part2_undid_stage_two", "part2_main.R"))) {
  stop("Could not find code/part2_undid_stage_two/part2_main.R under ",
       root_dir, ". Run part2_main.R from inside the repository, and keep its ",
       "original folder layout.")
}


# --- Settings and files received from the CCHS silo ----------------------------
# In general: stage two starts from the empty_diff_df.csv file sent by Central
# The silo name must be spelled exactly as it is in that file.
# In this project: the US silo is called "USA". The two received files are kept
# in separate folders so that the filled files are saved next to them.
clean_dir  <- file.path(root_dir, "data", "clean")
common_dir <- file.path(root_dir, "data", "undid", "common_adoption")
stag_dir   <- file.path(root_dir, "data", "undid", "staggered_adoption")

silo_name   <- "USA"
common_file <- file.path(common_dir, "empty_diff_df.csv")
stag_file   <- file.path(stag_dir,   "empty_diff_df.csv")

# CHECK 3: INPUT FILE ERROR: script will stop if the input file is not in place.
if (!file.exists(file.path(clean_dir, "brfss_harmonized.rds"))) {
  stop("Missing data/clean/brfss_harmonized.rds. Run Part 1 first.")
}

for (f in c(common_file, stag_file)) {
  if (!file.exists(f)) {
    stop("Missing ", f, ". Save the empty_diff_df.csv file received from the ", "CCHS silo there.")
  }
}

# --- Load the analysis dataset -------------------------------------------------
# Made in Part 1 (02_clean_append.R).
brfss <- readRDS(file.path(clean_dir, "brfss_analysis_2016_2022.rds"))
cat("Loaded analysis dataset:", nrow(brfss), "obs\n\n")



# --- (a) Recode to the variable names and coding agreed with Central  ------------
# In general: the names and coding must match what was agreed with Central
# In this project: the six agreed covariates are female, minority, ageg6, educ, hh_inc and health5. 
# Each one is made from a BRFSS variables cleaned in Part 1. 
#   female    <- sex_reported    (1 = male, 2 = female, recoded to 0/1)
#   ageg6     <- age_6grp        (_AGE_G, 6 imputed age groups; no recode)
#   educ      <- education_raw   (EDUCA, 6 levels collapsed to 3: less than
#                                 secondary, secondary graduate, any
#                                 post-secondary) ### *REVISE* DOUBLE CHECK THIS PLEASE!!! 
#   hh_inc    <- income_8cat     (already collapsed to 8 categories in
#                                 02_clean_append.R)
#   health5   <- general_health  (GENHLTH, 1 to 5; "don't know" and "refused"
#                                 already set to NA in 02_clean_append.R)
#   minority  <- race_binary_wh  (_RACEG21: 1 = non-Hispanic white,
#                                 2 = non-white or Hispanic, recoded to 0/1)*REVISE* old one i think? 
cat("Applying harmonization recodes...\n")


brfss <- brfss %>%
  mutate(
 
    # ---- FEMALE (harmonized to CCHS coding) ----
    # BRFSS sex_reported: 1 = male, 2 = female. CCHS uses a 0/1 female binary.
    # Recode 1 -> 0, 2 -> 1, all other values -> NA.
    female = case_when(
      sex_reported == 1 ~ 0,
      sex_reported == 2 ~ 1,
      TRUE              ~ NA_real_
    ),
 
    # ---- MINORITY (harmonized to CCHS coding) ----
    # BRFSS race_binary_wh (_RACEG21): 1 = non-Hispanic white, 2 = non-white
    # or Hispanic. CCHS uses a binary variable for visible minorities.
    # Recode 1 -> 0, 2 -> 1, all other values -> NA.
    minority = case_when(
      race_binary_wh == 1 ~ 0,
      race_binary_wh == 2 ~ 1,
      TRUE                ~ NA_real_
    ),
 
    # ---- AGE GROUP (agreed name, no recode) ----
    # age_6grp (_AGE_G): 6 imputed age groups, increasing. Cut points already
    # match the CCHS agreed scheme.
    ageg6 = age_6grp,
 
    # ---- EDUCATION (collapsed to the agreed 3 categories, increasing) ----
    # EDUCA: 1 = never attended / kindergarten only, 2 = grades 1-8,
    # 3 = grades 9-11, 4 = grade 12 or GED, 5 = college 1-3 years,
    # 6 = college 4+ years.
    educ = case_when(
      education_raw %in% 1:3 ~ 1,   # less than secondary
      education_raw == 4     ~ 2,   # graduated secondary
      education_raw %in% 5:6 ~ 3,   # any post-secondary
      TRUE                   ~ NA_real_
    ),
 
    # ---- HOUSEHOLD INCOME (agreed name, no recode) ----
    # income_8cat: already collapsed to 8 increasing categories in
    # 02_clean_append.R, top category 75k+. Matches the CCHS scheme as-is.
    hh_inc = income_8cat,
 
    # ---- GENERAL HEALTH (agreed name, no recode) ----
    # general_health (GENHLTH): 1 = excellent to 5 = poor. Reserved codes
    # (7, 9) already dropped in 02_clean_append.R.
    health5 = general_health
  )
 
cat("Recodes applied.\n\n")
 
 
# --- (b) Make the time column text ---------------------------------------------
# undid_stage_two() needs the time column to hold text so "2016", not numbers and not Date objects.
# In this project: the time column is year.
brfss <- brfss %>%
  mutate(year = as.character(year))

cat("year class after conversion:", class(brfss$year), "\n")
cat("year values present:", paste(sort(unique(brfss$year)), collapse = ", "), "\n\n")
 
 
# --- (c) Add the silo name column ----------------------------------------------
# the data needs a silo name column that matches the silo name in the filled_diff file exactly, stored as text.
# In this project: every respondent belongs to the pooled US silo, "USA".
brfss$silo_name <- as.character(silo_name)
 
 
# --- (d) Remove respondents with missing values --------------------------------
# No variable used in the analysis can have a missing value so removing the rows here also 
# means diff_estimate (without covariates) and diff_estimate_covariates (with covariates) are calculated on the same
# respondents in stage two, so the two columns can be compared.In this project: the outcome and the six agreed 
# covariates, before they are split into dummy columns.
undid_covariates <- c("female", "minority", "ageg6", "educ", "hh_inc", "health5")

n_before <- nrow(brfss)
 
for (v in c("use30", undid_covariates)) {
  n_missing <- sum(is.na(brfss[[v]]))
  cat(sprintf("  missing %-10s %7d\n", paste0(v, ":"), n_missing))
}
 
brfss <- brfss[stats::complete.cases(brfss[, c("use30", undid_covariates)]), ]
 
cat("\nDropped", n_before - nrow(brfss), "rows with missing outcome/covariates\n")
cat("Analysis sample:", nrow(brfss), "obs\n\n")
 
 
# --- (e) Create dummy columns for the categorical covariates -------------------
# A categorical variable with more than two categories becomes one 0/1 column per category, so each category gets its own coefficient in stage
# two. The reference category is left out. In this project: ageg6, educ, hh_inc and health5 need to be changed. For example, ageg6 gives the
# columns ageg62 to ageg66. female and minority are already 0/1.
 
brfss <- brfss %>%
  mutate(
    ageg6   = factor(ageg6),
    educ    = factor(educ),
    hh_inc  = factor(hh_inc),
    health5 = factor(health5)
  )
 
# model.matrix() builds the dummy columns. Its first column is an intercept of
# all 1s, which is dropped.
X <- model.matrix(~ ageg6 + educ + hh_inc + health5, data = brfss)
cat_dummies <- X[, -1, drop = FALSE]
 
brfss <- cbind(brfss, cat_dummies)
 
# From here on, the covariates are female, the 18 dummy columns and minority:
# 20 in total.  **revise** make sure this is true??
undid_covariates <- c("female", colnames(cat_dummies), "minority")
 
cat("Covariates now used:\n")
cat(paste(undid_covariates, collapse = ";"), "\n\n")
 
 
# --- (f) The outcome -----------------------------------------------------------
# In this project: the outcome is use30, made in 02_clean_append.R. It is 1 if
# the respondent used cannabis on at least one of the past 30 days, and 0 if on
# none. **revise** ensure this is also correct didn't think it was a binary variable but a count of days used?
 
 
# --- Check the data against the received files ---------------------------------
# Before running stage two, check that the data matches what central sent. 
# In this project: the checks below are run on both received files. 
 
# CHECK 4: COVARIATE ERROR: every covariate must be present and must take at
# least two different values. A covariate that is the same for every respondent
# cannot be estimated in stage two (it would duplicate the intercept).
missing_covariates <- setdiff(undid_covariates, names(brfss))
 
if (length(missing_covariates) > 0) {
  stop("Missing covariate(s): ", paste(missing_covariates, collapse = ", "))
} else {
  cat("All", length(undid_covariates), "covariates present.\n")
}
 
no_variation <- undid_covariates[
  sapply(brfss[undid_covariates], function(x) length(unique(x)) < 2)
]
 
if (length(no_variation) > 0) {
  stop("Covariate(s) with no variation: ",
       paste(no_variation, collapse = ", "),
       ". These cannot be estimated in stage two.")
}
 
# Print the values each covariate takes. Every dummy should show 0, 1.
cat("\nObserved covariate codings:\n")
for (v in undid_covariates) {
  cat(sprintf("  %-10s %s\n", paste0(v, ":"),
              paste(sort(unique(brfss[[v]])), collapse = ", ")))
}
cat("\n")
 
# CHECK 5: DATA TYPE ERROR: the time column and the silo name column must be
# text, and no variable used in the analysis can have a missing value.
stopifnot(is.character(brfss$year), is.character(brfss$silo_name))
 
if (anyNA(brfss[, c("year", "silo_name", "use30", undid_covariates)])) {
  stop("Missing values remain in a variable used in the analysis.")
}
 
# CHECK 6: RECEIVED FILE ERROR: for each received file, the silo name and every
# covariate it lists must match the data exactly.
check_received_file <- function(path) {
  received <- read.csv(path, stringsAsFactors = FALSE)
 
  if (!silo_name %in% received$silo_name) {
    stop("Silo name \"", silo_name, "\" is not in ", path, ". Silos in that ",
         "file: ", paste(unique(received$silo_name), collapse = ", "))
  }
 
  listed <- trimws(unlist(strsplit(received$covariates, ";")))
  listed <- unique(listed[!is.na(listed) & listed != ""])
 
  not_in_data <- setdiff(listed, names(brfss))
  if (length(not_in_data) > 0) {
    stop("Covariate(s) listed in ", path, " but not in the data: ",
         paste(not_in_data, collapse = ", "))
  }
 
  cat("Checked", path, "\n")
}
 
check_received_file(common_file)
check_received_file(stag_file)
cat("\n")
 
 
# --- Keep the columns undidR needs and save ------------------------------------
# state and finalwt (the BRFSS sampling weight) are kept, but undid_stage_two()
# doesn't use sampling weights, so they are not used in stage two. **explain the diff thing here?? vs other weight??**
undid_input <- brfss %>%
  select(year, silo_name, use30, state, finalwt, all_of(undid_covariates))
 
undid_path <- file.path(clean_dir, "brfss_undid_input.rds")
saveRDS(undid_input, undid_path)
 
cat("Undid input dataset:", undid_path, "\n")
cat("Dimensions:", nrow(undid_input), "obs x", ncol(undid_input), "variables\n\n")
 
 
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