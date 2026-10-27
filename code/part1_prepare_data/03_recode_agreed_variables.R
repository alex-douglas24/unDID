# =============================================================================
# 03_recode_agreed_variables.R: Recode to the variables agreed with Central
#
# WHAT IT DOES
#   Before stage two, each silo agrees with Central on which variables are 
#   used and how they are coded, so that every silo measures the same concepts 
#   in the same way. A silo recodes its own data to match centrals. 
#
#   For this paper,this script recodes the BRFSS data to the six covariates
#   agreed with the CCHS silo and keeps the outcome and a few other columns.
#   Only the simple recodes are done here. Steps that depend on the
#   empty_diff_df.csv from Central (dummy columns, removing missing values, the
#   silo name) happen in the Part 2 folder. 
#
# OUTPUT
#   data/clean/brfss_harmonized.rds   the input for Part 2
#
# HOW TO RUN
#   Not run on its own. part1_main.R runs it after 02_clean_append.R, 00_config.R and 01_extract_harmonize.R. 
#
# BEFORE RUNNING
#   02_clean_append.R must have run, so that
#   data/clean/brfss_analysis_2016_2022.rds exists. part1_main.R also runs
#   00_config.R first, which this script needs.
#
# COVARIATES AGREED WITH THE CCHS SILO *revise me once finished restructure*** also refer to readme file - check if this is the final list, think race, education are different now**
#   female    <- sex_reported    (1 = male, 2 = female, recoded to 0/1)
#   ageg6     <- age_6grp        (_AGE_G, 6 imputed age groups; no recode)
#   educ      <- education_raw   (EDUCA, 6 levels collapsed to 3: less than
#                                 secondary, secondary graduate, any
#                                 post-secondary)
#   hh_inc    <- income_8cat     (already collapsed to 8 categories in
#                                 02_clean_append.R) 
#   health5   <- general_health  (GENHLTH, 1 to 5; "don't know" and "refused"
#                                 already set to NA in 02_clean_append.R)
#   minority  <- race_binary_wh  (_RACEG21: 1 = non-Hispanic white,
#                                 2 = non-white or Hispanic, recoded to 0/1)
#
#   year, state, finalwt (the BRFSS sampling weight) and use30 (the outcome) are 
#   also kept, but not recoded.
# =============================================================================

cat("============================================================\n")
cat("STEP 3: RECODE TO THE AGREED VARIABLES\n")
cat("============================================================\n\n")

# Load the combined dataset made by 02_clean_append.R
brfss <- readRDS(file.path(clean_dir, "brfss_analysis_2016_2022.rds"))
cat("Loaded analysis dataset:", nrow(brfss), "obs\n\n")


# --- Recode to the agreed names and coding -------------------------------------
# In general: the names and coding must match what was agreed with Central.
# In this project: the six covariates are listed above. Each one is made from a
# BRFSS variable cleaned in 02_clean_append.R.
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


# --- Keep the columns Part 2 needs and save ------------------------------------
# Respondents with a missing value are not removed here. That happens in Part 2,
# once the full list of variables is known from Central's file.
agreed_covariates <- c("female", "minority", "ageg6", "educ", "hh_inc", "health5")

brfss_harmonized <- brfss %>%
  select(year, state, finalwt, use30, all_of(agreed_covariates))

harmonized_path <- file.path(clean_dir, "brfss_harmonized.rds")
saveRDS(brfss_harmonized, harmonized_path)

cat("Harmonized dataset:", harmonized_path, "\n")
cat("Dimensions:", nrow(brfss_harmonized), "obs x", ncol(brfss_harmonized),
    "variables\n\n")
