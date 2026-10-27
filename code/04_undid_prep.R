# =============================================================================
# 04_undid_prep.R: Prepare the BRFSS data for undidR and run stages one and two
#
# WHAT IT DOES
#   Loads the BRFSS analysis dataset produced by 02_clean_append.R, recodes the variables 
#   to the coding agreed with the CCHS silo, removes respondents if they have a missing outcome 
#   or covariate, turns the categorical covariates into 0/1 dummy columns, and saves the undidR input dataset.
#  
#   Then it runs stage one (initialize) and stage two (fill in the empty_diff_df.csv received from the CCHS silo) for both common and staggered adoption. 
#
# This script does cross-silo coordination only. BRFSS cleaning
# (dropping reserved codes, collapsing categories, etc.) already happens
# in 02_clean_append.R and is not repeated here. If the agreed covariate
# coding changes, this is the only file that needs to change.
#
# Input:  data/clean/brfss_analysis_2016_2022.rds
# Output: data/clean/brfss_undid_input.rds
#
# Agreed covariate names and BRFSS sources:
#   female    <- sex_reported    (1 = male, 2 = female, recoded to 0/1)
#   ageg6     <- age_6grp        (_AGE_G, 6 imputed age groups; no recode)
#   educ      <- education_raw   (EDUCA, 6 levels; no recode — undidR has a
#                                 separate coefficient per silo, so categories
#                                 don't need to match across silos)
#   hh_inc    <- income_8cat     (already collapsed to 8 categories in clean_append.R)
#   health5   <- general_health  (GENHLTH, 1-5; reserved codes already
#                                 dropped in clean_append.R)
#   minority  <- race_binary_wh  (_RACEG21: 1 = non-Hispanic white,
#                                 2 = non-white or Hispanic, recoded to 0/1)
#
# Also retained: year (time column), use30 (outcome), state (row filtering,
# not a covariate), finalwt (BRFSS sampling weight).
#
# Requires: 00_config.R sourced first, and the analysis dataset built by
# 02_clean_append.R.
# =============================================================================


# =============================================================================
# 00_config.R: Shared settings 
#
# What this script does:
#  
#
# Before runnning:   
#  
#  
# How to run it:
#   
# 
# Output:
#  
# =============================================================================





cat("============================================================\n")
cat("STEP 4: UNDID PREP\n")
cat("============================================================\n\n")
 
brfss <- readRDS(file.path(clean_dir, "brfss_analysis_2016_2022.rds"))
cat("Loaded analysis dataset:", nrow(brfss), "obs\n\n")
 
 
# --- Apply cross-silo harmonization recodes -----------------------------------
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
 
 
# --- Step 1: Convert the time column to character ---------------------------------------
# undid_stage_two() requires the time column to contain date STRINGS, not
# numerics and not Date objects. 
brfss <- brfss %>%
  mutate(year = as.character(year))
 
cat("year class after conversion:", class(brfss$year), "\n")
cat("year values present:", paste(sort(unique(brfss$year)), collapse = ", "), "\n\n")
 
 
# --- Step 2: Drop incomplete rows -----------------------------------------------------
# Dropping here ensures that diff_estimate and diff_estimate_covariates are
# computed on the SAME sample in stage two, making the two columns comparable.
 
undid_covariates <- c("female", "minority", "ageg6", "educ", "hh_inc", "health5")
 
n_before <- nrow(brfss)
 
for (v in c("use30", undid_covariates)) {
  n_missing <- sum(is.na(brfss[[v]]))
  cat(sprintf("  missing %-10s %7d\n", paste0(v, ":"), n_missing))
}

brfss <- brfss[stats::complete.cases(brfss[, c("use30", undid_covariates)]), ]

cat("\nDropped", n_before - nrow(brfss), "rows with missing outcome/covariates\n")
cat("Analysis sample:", nrow(brfss), "obs\n\n")


# --- Create dummy columns for the categorical covariates ----------------------
# Each category of ageg6, educ, hh_inc and health5 becomes its own 0/1 column.
# The lowest category of each is left out as the reference group.
brfss <- brfss %>%
  mutate(
    ageg6   = factor(ageg6),
    educ    = factor(educ),
    hh_inc  = factor(hh_inc),
    health5 = factor(health5)
  )

X <- model.matrix(~ ageg6 + educ + hh_inc + health5, data = brfss)
cat_dummies <- X[, -1, drop = FALSE]   # drops the intercept column

brfss <- cbind(brfss, cat_dummies)

# The covariate list is now the 21 dummy names, in the same order as the CSV
undid_covariates <- c("female", colnames(cat_dummies), "minority")

cat("Covariates now used:\n")
cat(paste(undid_covariates, collapse = ";"), "\n\n")

# --- Verify every agreed covariate is present and usable ----------------------
missing_covariates <- setdiff(undid_covariates, names(brfss))
 
if (length(missing_covariates) > 0) {
  stop("Missing covariate(s): ", paste(missing_covariates, collapse = ", "))
} else {
  cat("All", length(undid_covariates), "agreed covariates present.\n")
}

# A covariate with no variation would be collinear with the intercept in the
# stage-two residualizing regression.
no_variation <- undid_covariates[
  sapply(brfss[undid_covariates], function(x) length(unique(x)) < 2)
]
 
if (length(no_variation) > 0) {
  cat("WARNING: covariate(s) with no variation:",
      paste(no_variation, collapse = ", "), "\n")
  cat("These will be collinear in stage two. Resolve before sending.\n")
}

# Print the observed range of each covariate so the codings can be checked
# against the CCHS side at a glance.
cat("\nObserved covariate codings:\n")
for (v in undid_covariates) {
  cat(sprintf("  %-10s %s\n", paste0(v, ":"),
              paste(sort(unique(brfss[[v]])), collapse = ", ")))
}
cat("\n")

# --- Select and save undidR input dataset -------------------------------------
undid_input <- brfss %>%
  select(year, use30, state, finalwt, all_of(undid_covariates))

undid_path <- file.path(clean_dir, "brfss_undid_input.rds")
saveRDS(undid_input, undid_path)

cat("Undid input dataset:", undid_path, "\n")
cat("Dimensions:", nrow(undid_input), "obs x", ncol(undid_input), "variables\n\n")

cat("------------------------------------------------------------\n")
cat("COVARIATE NAMES TO CONFIRM WITH THE CCHS SILO:\n")
cat(paste(undid_covariates, collapse = ", "), "\n")
cat("------------------------------------------------------------\n\n")
 
cat("Undid prep complete.\n\n")
 
 
# =============================================================================
# Stage One: Initialize — common treatment time
#
# Isn't this step normally run once by the server or in this case the CCHS silo 
# which then sends empty_diff_df.csv out to the US silo? redone here 
# so the US silo can build its own copy and check it against the one received.
#
# Design: two silos. "US" (six states pooled, control) and "CAN" (treated).
# Treatment time 2018 — legalization was 17 October 2018
#
# Weights "diff": weights each silo's difference by the number of observations
# behind it. With one treated and one control silo the weighting choice has no
# effect on the point estimate — every option should return the same number.
# Running all four to check that the setup is right as they should be the same. 
# =============================================================================

cat("============================================================\n")
cat("STAGE ONE: INITIALIZE (verification copy)\n")
cat("============================================================\n\n")

undid_dir <- file.path(clean_dir, "undid", "common")
dir.create(undid_dir, recursive = TRUE, showWarnings = FALSE)

init <- create_init_csv(
  silo_names      = c("USA", "CAN"),
  start_times     = "2016",
  end_times       = "2022",
  treatment_times = c("control", "2018"),
  covariates      = undid_covariates,
  filepath        = undid_dir
)

print(init)

empty_diff_df <- create_diff_df(
  init_filepath = file.path(undid_dir, "init.csv"),
  date_format   = "yyyy",
  freq          = "yearly",
  weights       = "diff",
  filepath      = undid_dir
)
 
print(empty_diff_df)
 
cat("\nStage one files written to:", undid_dir, "\n")
cat("Compare empty_diff_df.csv against the copy received from the CCHS silo\n")
cat("before running stage two.\n\n")
 
 
# =============================================================================
# Stage Two: fill in the empty_diff_df.csv received from the CCHS silo.
# The received file lives in data/clean/received_common. The filled file and
# the trends file are saved in that same folder. Send both back.
# =============================================================================

cat("============================================================\n")
cat("STAGE TWO: FILL IN RECEIVED FILE (common adoption)\n")
cat("============================================================\n\n")

received_dir <- file.path(clean_dir, "received_common")

stage2 <- undid_stage_two(
  empty_diff_filepath = file.path(received_dir, "empty_diff_df.csv"),
  silo_name           = "USA",
  silo_df             = undid_input,
  time_column         = "year",
  outcome_column      = "use30",
  silo_date_format    = "yyyy",
  filepath            = received_dir
)

print(stage2$diff_df[, c("silo_name", "treat", "start_time", "end_time",
                         "diff_estimate", "diff_estimate_covariates", "n")])

cat("\nSend back: filled_diff_df_USA.csv and trends_data_USA.csv\n\n")

# =============================================================================
# Stage Two (staggered adoption): fill in the staggered empty_diff_df.csv
# received from the CCHS silo. The received file lives in
# data/clean/received_stag. The filled file and the trends file are saved in
# that same folder. Send both back.
# =============================================================================

cat("============================================================\n")
cat("STAGE TWO: FILL IN RECEIVED FILE (staggered adoption)\n")
cat("============================================================\n\n")

received_stag_dir <- file.path(clean_dir, "received_stag")

stage2_stag <- undid_stage_two(
  empty_diff_filepath = file.path(received_stag_dir, "empty_diff_df.csv"),
  silo_name           = "USA",
  silo_df             = undid_input,
  time_column         = "year",
  outcome_column      = "use30",
  silo_date_format    = "yyyy",
  filepath            = received_stag_dir
)

print(stage2_stag$diff_df[, c("silo_name", "gvar", "treat", "gt",
                              "diff_estimate", "diff_estimate_covariates", "n")])

cat("\nSend back: filled_diff_df_USA.csv and trends_data_USA.csv\n\n")
# =============================================================================