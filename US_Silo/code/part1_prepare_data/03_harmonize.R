# =============================================================================
# 03_harmonize.R: Harmonize the BRFSS variables with the CCHS (between-silo)
#
# WHAT IT DOES
#   Recodes the BRFSS variables whose categories differ from the CCHS so that
#   both surveys measure them in the same way. This is between-silo
#   harmonization. The within-silo cleaning (non-response codes, renamed
#   variables across years, income categories) was done in 02_clean_append.R.
#
#   In this harmonization  example, three variables are recoded in the BRFSS silo
#   (see the table in README.md):
#     female    <- sex_reported    (1 = male, 2 = female, recoded to 0 = male,
#                                   1 = female)
#     minority  <- race_binary_wh  (1 = non-Hispanic white, 2 = non-white or Hispanic 
#                                   recoded to 0 = not a minority, 1 = minority)
#     educ      <- education_raw   (EDUCA, 6 levels collapsed to 3: 1 = less than
#                                   secondary, 2 = secondary graduate, 3 = any
#                                   post-secondary)
#
#   The other agreed variables (age, household income, general health) already
#   match the CCHS categories and are only renamed, in Part 2. 
#
# OUTPUT
#   data/clean/brfss_harmonized.rds   the input for Part 2
#
# HOW TO RUN
#   Not run on its own. part1_run_all.R runs it after 02_clean_append.R.
#
# BEFORE RUNNING
#   02_clean_append.R must have run, so that
#   data/clean/brfss_analysis_2016_2022.rds exists. part1_run_all.R also runs
#   00_config.R first, which this script needs.
# =============================================================================


cat("============================================================\n")
cat("STEP 3: HARMONIZE WITH THE CCHS\n")
cat("============================================================\n\n")

# --- Load the cleaned dataset made by 02_clean_append.R ------------------------
brfss <- readRDS(file.path(clean_dir, "brfss_analysis_2016_2022.rds"))
cat("Loaded analysis dataset:", nrow(brfss), "obs\n\n")


# --- Recode to match the CCHS ---------------------------------------------------
# recode a variable only where its categories differ from the CCHSand set anything 
# that can't be recoded to NA.
# In this harmonized case for the BRFSS, female, minority and educ must be harmonized. 
# Respondents with a missing value are not removed in Part 2 not here. 
cat("Applying harmonization recodes...\n")

brfss <- brfss %>%
  mutate(

    # ---- FEMALE ----
    # BRFSS sex_reported: 1 = male, 2 = female. Recode 1 -> 0, 2 -> 1, all
    # other values -> NA.
    female = case_when(
      sex_reported == 1 ~ 0,
      sex_reported == 2 ~ 1,
      TRUE              ~ NA_real_
    ),

    # ---- MINORITY ----
    # BRFSS race_binary_wh (_RACEG21): 1 = non-Hispanic white, 2 = non-white or
    # Hispanic. The CCHS uses a visible minority variable, which is a similar
    # but not identical concept. Recode 1 -> 0, 2 -> 1, all other values -> NA.
    minority = case_when(
      race_binary_wh == 1 ~ 0,
      race_binary_wh == 2 ~ 1,
      TRUE                ~ NA_real_
    ),

    # ---- EDUCATION 
    # BRFSS EDUCA: 1 = never attended/kindergarten only, 2 = grades 1-8,
    # 3 = grades 9-11, 4 = grade 12 or GED, 5 = college 1-3 years, 6 = college 4+ years.
    # recoded to 3 categories to match the CCHS. 
    educ = case_when(
      education_raw %in% 1:3 ~ 1,   # less than secondary
      education_raw == 4     ~ 2,   # secondary graduate
      education_raw %in% 5:6 ~ 3,   # any post-secondary
      TRUE                   ~ NA_real_
    )
  )

cat("Recodes applied.\n\n")


# --- Save -------------------------------------------------------------------------
harmonized_path <- file.path(clean_dir, "brfss_harmonized.rds")
saveRDS(brfss, harmonized_path)

cat("Harmonized dataset:", harmonized_path, "\n")
cat("Dimensions:", nrow(brfss), "obs x", ncol(brfss), "variables\n\n")
