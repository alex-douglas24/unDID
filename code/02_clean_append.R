# =============================================================================
# 02_clean_append.R — Clean variables, create derived measures, append years
#
# Loads the yearly .rds files from 01_extract_harmonize.R, stacks them,
# filters to respondents with cannabis module data, cleans non-response
# codes, creates variables, and saves the analysis dataset.
#
# Input:  data/clean/brfss_clean_{year}.rds (one per year)
# Output: data/clean/brfss_analysis_2016_2022.rds
#
# Cleaning decisions documented:
#   - BRFSS non-response codes (77/88/99 and 7/9) are set to NA.
#   - marijuana_days 88 ("none") is recoded to 0, not NA.
#   - PHYSHLTH and MENTHLTH 88 ("none") recoded to 0.
#   - Education (EDUCA) is recoded from 6 categories to 4 for
#     harmonization with the CCHS.
#   - Income is recoded into 8 categories instead of 11 categories. 
#
# Requires: 00_config.R sourced first
# =============================================================================

cat("============================================================\n")
cat("STEP 2: CLEAN AND APPEND\n")
cat("============================================================\n\n")

# --- Load and append all years ------------------------------------------------

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


# --- Filter to cannabis module respondents ------------------------------------
# Respondents with marijuana_days == NA were never asked the question (their
# state did not ask the marijuana module that year). 
# 88 = "none" is recoded to mean 0 days of use.

brfss <- brfss %>%
  filter(!is.na(marijuana_days) | marijuana_days == 88)

cat("After filtering to cannabis module respondents:", nrow(brfss), "obs\n\n")


# --- Clean non-response codes ------------------------------------------------
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
    # Core coding consistent across years: 1 = Male, 2 = Female
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
    
    # ---- EDUCATION (recoded to 4 categories for CCHS harmonization) ----
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
    
    # ---- EDUCATION (BRFSS computed 4-level, maybe delete? ----
    # 9 = DK/refused -> NA
    education_4cat = ifelse(education_4cat == 9, NA, education_4cat),
    
    # ---- INCOME ----
    # 77 = DK, 99 = refused -> NA
    # Raw categories preserved; harmonization deferred 
    income_raw = ifelse(income_raw %in% c(77, 99), NA, income_raw),
    
    # ---- INCOME ----
    # 77 = DK, 99 = refused -> NA
    # Categories 9-11 only exist in INCOME3 (2021-22) and represent higher
    # brackets above $100k. These are recoded to NA so that categories 1-8
    # are consistent across all years.
    income_raw = ifelse(income_raw %in% c(9, 10, 11, 77, 99), NA, income_raw),
    
    # ---- MARITAL STATUS ----
    # 9 = refused -> NA
    marital = ifelse(marital == 9, NA, marital),
    
    # ---- EMPLOYMENT ----
    # 9 = refused -> NA
    employment = ifelse(employment == 9, NA, employment),
    
    # ---- GENERAL HEALTH ----
    # 7 = DK, 9 = refused -> NA
    general_health = ifelse(general_health %in% c(7, 9), NA, general_health),
    
    # ---- HEALTH STATUS (binary) ----
    # 1 = good or better, 2 = fair or poor, 9 = DK/refused -> NA
    health_status = ifelse(health_status == 9, NA, health_status),
    
    # ---- PHYSICAL HEALTH (days not good, past 30) ----
    # 88 = none (recode to 0), 1-30 = days, 77 = DK, 99 = refused -> NA
    physical_health = case_when(
      physical_health == 88                        ~ 0,
      physical_health >= 1 & physical_health <= 30 ~ physical_health,
      TRUE                                         ~ NA_real_
    ),
    
    # ---- MENTAL HEALTH DAYS (continuous, past 30) ----
    # 88 = none (recode to 0), 1-30 = days, 77 = DK, 99 = refused -> NA
    mental_health_d = case_when(
      mental_health_d == 88                        ~ 0,
      mental_health_d >= 1 & mental_health_d <= 30 ~ mental_health_d,
      TRUE                                         ~ NA_real_
    ),
    
    # ---- MENTAL HEALTH 3-LEVEL (BRFSS computed) ----
    # 1 = 0 bad days, 2 = 1-13 days, 3 = 14-30 days, 9 = DK/refused -> NA
    mental_health_3 = ifelse(mental_health_3 == 9, NA, mental_health_3),
    
    # ---- BINGE DRINKING (binary) ----
    # 1 = No, 2 = Yes, 9 = DK/refused -> NA
    binge_drink = ifelse(binge_drink == 9, NA, binge_drink),
    
    # ---- RACE/ETHNICITY ----
    # _IMPRACE: no missing codes (values are imputed, so no refusals)
    # _MRACE: 77 = DK, 99 = refused -> NA
    race_multi     = ifelse(race_multi %in% c(77, 99), NA, race_multi),
    # _RACEG2: 9 = DK/refused -> NA
    race_binary_wh = ifelse(race_binary_wh == 9, NA, race_binary_wh),
    # _RACEGR3: 9 = DK/refused -> NA
    race_5level    = ifelse(race_5level == 9, NA, race_5level),
    # _PRACE: 77 = DK, 88 = no choice given (2022 only), 99 = refused -> NA
    race_preferred = ifelse(race_preferred %in% c(77, 88, 99), NA, race_preferred)
  )


# --- State labels -------------------------------------------------------------
brfss$state_name <- state_labels[as.character(brfss$state)]


# --- Save analysis dataset ----------------------------------------------------
analysis_path <- file.path(clean_dir, "brfss_analysis_2016_2022.rds")
saveRDS(brfss, analysis_path)

cat("Clean and append complete.\n")
cat("Analysis dataset:", analysis_path, "\n")
cat("Dimensions:", nrow(brfss), "obs x", ncol(brfss), "variables\n\n")
