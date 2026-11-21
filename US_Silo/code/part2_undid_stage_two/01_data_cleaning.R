# =============================================================================
# 01_data_cleaning.R: Prepare the silo data to match Central's files
#
# WHAT IT DOES
#   In line with the manuscript this file goes through the following steps: 
#     a. recodes variables names to match the empty_diff_df.csv exactly received from Central 
#     b. converts time column to text only 
#     c. adds silo name column that matches the silo name is empty_diff_df.csv received from Central, stored as text 
#     d. removes missing values in any varaible used in the analysis
#     e. creates a a 0/1 dummy column for each category of every categorical variable with more than two categories, leaving out the reference category. 
#     For example if a variable has 4 categories, three dummy columns are created, one for each of the non-reference categories.
#     f. checks the data against the received files from Central and saves the undidR input data.
#
# OUTPUT
#   data/clean/brfss_undid_input.rds
#
# HOW TO RUN
#   Not run on its own. part2_run_all.R runs it first.
#
# BEFORE RUNNING
#   Part 1 must have run, and part2_run_all.R must have set silo_name, clean_dir,
#   common_file and stag_file.
# =============================================================================


# --- Load the analysis dataset -------------------------------------------------
# Made in Part 1 
brfss <- readRDS(file.path(clean_dir, "brfss_analysis_2016_2022.rds"))
cat("Loaded analysis dataset:", nrow(brfss), "obs\n\n")


# --- (a) Recode to the variable names and coding agreed with Central  ------------
# names and coding must match what was agreed with Central. In this example the six 
# agreed covariates are female, minority, ageg6, educ, hh_inc and health5. **revise**
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
# do you even need this check? its not above 

# --- Check the data against the received files ---------------------------------
# Before running stage two, check that the data matches what central sent.
# The checks below are run on both received files.

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