# =============================================================================
# 02_clean_append.R: Clean the variables and stack the years
#
# WHAT IT DOES
#   Loads the yearly .rds files made by 01_extract_rename.R and stacks them
#   into one dataset. Keeps only the respondents who were asked the cannabis
#   questions, sets "don't know" and "refused" codes to missing, creates the
#   cannabis outcome (days of use in the past 30 days) and makes income
#   consistent across years. This is within-silo cleaning only: the recodes to
#   match the CCHS are done in Part 2. Saves the combined dataset to
#   data/clean/brfss_analysis_2016_2022.rds.
#
# BEFORE RUNNING
#   01_extract_rename.R must have run, so that the yearly .rds files are in
#   data/clean/. part1_run_all.R also runs 00_config.R first, which this script
#   needs.
#
# HOW TO RUN
#   Not run on its own. part1_run_all.R runs it after 00_config.R and
#   01_extract_rename.R.
#
# INPUT/OUTPUT
#   Input:  data/clean/brfss_clean_{year}.rds (one per year)
#   Output: data/clean/brfss_analysis_2016_2022.rds
#
# CLEANING DECISIONS
#   - "Don't know" and "refused" codes (7/9 or 77/99, depending on the variable)
#     are set to NA.
#   - Cannabis module filter: respondents with a missing marijuana_days were
#     never asked the question (their state did not use the module that year),
#     so they are removed.
#   - Outcome marijuana_days_clean: 1 to 30 are days of use, 88 ("none") is
#     recoded to 0, and 77 and 99 become NA.
#   - Income has 8 categories in 2016-2020 and 11 in 2021-2022. Categories 9 to
#     11 are collapsed into 8, so the top category ($75,000 or more) means the
#     same thing in every year (income_8cat).
#   - Education, age, general health and the race variables keep their original
#     categories. Any recoding to match the CCHS happens in Part 2.
# =============================================================================





cat("============================================================\n")
cat("STEP 2: CLEAN AND APPEND\n")
cat("============================================================\n\n")

# --- Load and append all years ------------------------------------------------
# bind_rows() fills any variable that is missing in a year with NA.

df_list <- list()

for (yr in years) {
  file_path <- file.path(clean_dir, paste0("brfss_clean_", yr, ".rds"))
  df_list[[as.character(yr)]] <- readRDS(file_path)
  cat("Loaded", yr, "-", nrow(df_list[[as.character(yr)]]), "obs\n")
}

brfss <- bind_rows(df_list)
cat("\nCombined:", nrow(brfss), "obs across",
    length(unique(brfss$year)), "years\n")

rm(df_list)
gc()


# --- Keep those who were asked the cannabis question ---------------------------
# Missing marijuana_days means the respondent was never asked the question, because 
# their state did not include the marijuana module that year, so these rows are dropped.
# 88 = "none" is recoded to mean 0 days of use.

brfss <- brfss %>%
  filter(!is.na(marijuana_days))
 
cat("After filtering to cannabis module respondents:", nrow(brfss), "obs\n\n")
 


# --- Clean the non-response codes and create new variables  ----------------------
# BRFSS coding:
#   77 or 7   = Don't know / Not sure
#   88        = None (recoded to 0)
#   99 or 9   = Refused
#   BLANK/NA  = Not asked or missing

cat("Cleaning non-response codes...\n")

brfss <- brfss %>%
  mutate(
    
    # ---- CANNABIS (outcome) ----
    # Raw values: 1-30 = days, 88 = none, 77 = DK, 99 = refused
    marijuana_days_clean = case_when(
      marijuana_days == 88                        ~ 0,
      marijuana_days >= 1 & marijuana_days <= 30  ~ marijuana_days,
      TRUE                                        ~ NA_real_
    ),
    
    # ---- SEX ----
    # Coding consistent across years: 1 = Male, 2 = Female
    # 7 = DK, 9 = refused -> NA
    sex_reported = ifelse(sex_reported %in% c(7, 9), NA, sex_reported),
    
    # ---- AGE ----
    # age_6grp (_AGE_G): 6 imputed age groups, so there are no "don't know" or
    # "refused" codes to clean. It is the only age variable kept.
    
    # ---- EDUCATION (raw 6-level) ----
    # 9 = refused -> NA
    education_raw = ifelse(education_raw == 9, NA, education_raw),

    
    # ---- INCOME ----
    # 77 = DK, 99 = refused -> NA
    # INCOME2 (2016-20) top category is 8 = $75,000+. INCOME3 (2021-22) adds
    # categories 9-11 above it, so 8 no longer means the same thing.
    # Collapsing 9-11 back into 8 restores a consistent top category.
    income_raw = ifelse(income_raw %in% c(77, 99), NA, income_raw),
    income_8cat = ifelse(income_raw %in% c(9, 10, 11), 8, income_raw),

    # ---- RACE/ETHNICITY ----
    # _IMPRACE: no missing codes (values are imputed, so no refusals)
    # _MRACE: 77 = DK, 99 = refused -> NA
    race_multi     = ifelse(race_multi %in% c(77, 99), NA, race_multi),
    # _RACEG2: 9 = DK/refused -> NA
    race_binary_wh = ifelse(race_binary_wh == 9, NA, race_binary_wh),
    # _RACEGR3: 9 = DK/refused -> NA
    race_5level    = ifelse(race_5level == 9, NA, race_5level),
    # _PRACE: 77 = DK, 88 = no choice given (2022 only), 99 = refused -> NA
    race_preferred = ifelse(race_preferred %in% c(77, 88, 99), NA, race_preferred),
    # _RACE: 9 = DK/refused -> NA
    race_detailed  = ifelse(race_detailed == 9, NA, race_detailed),

    # ---- GENERAL HEALTH ---- 
    # GENHLTH: 1 = excellent, 2 = very good, 3 = good, 4 = fair, 5 = poor,
    # 7 = DK, 9 = refused -> NA
    general_health = case_when(
      general_health %in% c(7, 9) ~ NA_real_,
      TRUE                        ~ general_health
    )
  )


# --- Add state names -------------------------------------------------------------
brfss$state_name <- state_labels[as.character(brfss$state)]


# --- Save the combined dataset ----------------------------------------------------
analysis_path <- file.path(clean_dir, "brfss_analysis_2016_2022.rds")
saveRDS(brfss, analysis_path)

cat("Clean and append complete.\n")
cat("Analysis dataset:", analysis_path, "\n")
cat("Dimensions:", nrow(brfss), "obs x", ncol(brfss), "variables\n\n")
