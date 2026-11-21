# =============================================================================
# 02_clean_append.R — Clean variables, append years *add smth revise me*
# 
# WHAT IT DOES
#   Loads the yearly .rds files from 01_extract_harmonize.R, stacks them and 
#   keeps only the respondents who were asked the cannabis module question, sets 
#   "dont know" and "refused" codes to NA , creates cannibis use variables and 
#   recodes some variables to match the CCHS. Saves the combined datset to 
#   data/clean/brfss_analysis_2016_2022.rds.
#
# BEFORE RUNNING
#   01_extract_harmonize.R must have run, to create the yearly .rds files which 
#   must be in data/clean/. main.R also runs 00_config.R first, which this script needs.
#
# HOW TO RUN
#   Not run on its own. main.R runs it after 01_extract_harmonize and 00_config.R scripts.
#
# INPUT/OUTPUT
#   Input:  data/clean/brfss_clean_{year}.rds (one per year)
#   Output: data/clean/brfss_analysis_2016_2022.rds
#
# Cleaning decisions documented: 
#   - BRFSS codes for "dont know" and "refused" as NA.
#   - marijuana_days 88 ("none") is recoded to 0, not NA.
#   - PHYSHLTH and MENTHLTH 88 ("none") recoded to 0.
#   - Education (EDUCA) is recoded from 6 categories to 4 for
#     harmonization with the CCHS.  *revise* should this be in line with unDID unfilled step 1??
#   - Income has 8 categories in 2016-2020 and 11 in 2021-2022. Categories 9 to
#     11 are collapsed into 8, so the top category means the same thing in
#     every year (income_8cat). *revise* 
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
    # Binary: any use in past 30 days (1 = yes, 0 = no)
    use30 = case_when(
      marijuana_days_clean >= 1              ~ 1,
      marijuana_days_clean == 0              ~ 0,
      TRUE                                   ~ NA_real_
    ),
    # High use: 25+ days in past 30 (1 = yes, 0 = no)
    mj_high = case_when(
      marijuana_days_clean >= 25             ~ 1,
      !is.na(marijuana_days_clean)           ~ 0,
      TRUE                                   ~ NA_real_
    ),
    # Moderate use: 1-24 days in past 30 (1 = yes, 0 = no)
    mj_mod = case_when(
      marijuana_days_clean >= 1 & marijuana_days_clean < 25 ~ 1,
      !is.na(marijuana_days_clean)                          ~ 0,
      TRUE                                                  ~ NA_real_
    ),
    
    # ---- SEX ----
    # Coding consistent across years: 1 = Male, 2 = Female
    # 7 = DK, 9 = refused -> NA
    sex          = ifelse(sex %in% c(7, 9), NA, sex),
    sex_reported = ifelse(sex_reported %in% c(7, 9), NA, sex_reported),
    birthsex     = ifelse(birthsex %in% c(7, 9), NA, birthsex),
    
    # ---- AGE ----
    # _AGEG5YR: 14 = DK/Refused -> NA
    age_5yr  = ifelse(age_5yr == 14, NA, age_5yr),
    # _AGE65YR: 3 = DK/Refused -> NA
    age_2grp = ifelse(age_2grp == 3, NA, age_2grp),
    # _AGE_G and _AGE80: no special missing codes
    
    # ---- EDUCATION (raw 6-level) ----
    # 9 = refused -> NA
    education_raw = ifelse(education_raw == 9, NA, education_raw),
    
    # ---- EDUCATION (recoded to 4 categories for CCHS harmonization) ---- *revise* should this be in line with unDID unfilled step 1??
    # Not used in the undidR analysis: 04_undid_prep.R builds its own
    # 3-category education variable directly from education_raw.
    # Collapses raw EDUCA to match the 4 CCHS education categories:
    #   1 = Less than secondary (EDUCA 1-3: never attended, elementary, some HS)
    #   2 = Secondary graduate (EDUCA 4: HS graduate or GED)
    #   3 = Some post-secondary (EDUCA 5: college 1-3 years)
    #   4 = Post-secondary/university diploma (EDUCA 6: college 4+ years)
    education_harmonized = case_when(
      education_raw %in% c(1, 2, 3) ~ 1,
      education_raw == 4             ~ 2,
      education_raw == 5             ~ 3,
      education_raw == 6             ~ 4,
      TRUE                           ~ NA_real_
    ),
    
    # ---- EDUCATION (BRFSS computed 4-level, maybe delete? *revise*----
    # 9 = DK/refused -> NA
    # Not used in the analysis. Kept for the missingness tables in
    # 03_missingness.R.
    # 9 = DK/refused -> NA
    education_4cat = ifelse(education_4cat == 9, NA, education_4cat),
    
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

    # ---- GENERAL HEALTH ---- *revise* not needed???
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
