# =============================================================================
# 03_missingness.R: Missing data and cannabis module coverage tables for appendix! 
#   These tables are for the missing data appendix. No later script reads them,
#   so the undidR results do not depend on this step.
#
# WHAT IT DOES
#   Builds three descriptive tables about the BRFSS data:
#   1. how much of each variable is missing, by year
#   2. how many respondents each state has, by year
#   3. how much of the sample is kept under different sets of covariates
#
# OUTPUT
#   output/missingness_by_year.csv   percent missing per variable, per year
#   output/module_coverage.csv       number of respondents per state, per year
#   output/covariate_cost.csv        sample kept under each set of covariates
#
# HOW TO RUN
#   Not run on its own. main.R runs it after 02_clean_append.R, 01_extract_harmonize.R and 00_config.R scripts.
#
# BEFORE RUNNING
#   02_clean_append.R must have run, so that
#   data/clean/brfss_analysis_2016_2022.rds exists. main.R also runs
#   00_config.R first, which this script needs.
# =============================================================================





cat("============================================================\n")
cat("STEP 3: MISSINGNESS\n")
cat("============================================================\n\n")

# Load the combined dataset made by 02_clean_append.R
brfss <- readRDS(file.path(clean_dir, "brfss_analysis_2016_2022.rds"))

# --- Table 1: percent missing by variable and year ----------------------------
# All candidate codings are included, not just the chosen ones, so the
# selection between alternatives (e.g. age_5yr vs age_imputed) is documented.
# *possibly revise for appendix: maybe only include the variables used in the undidR analysis?*

miss_vars <- c("marijuana_days_clean", "use30",
               "age_5yr", "age_6grp", "age_2grp", "age_imputed",
               "sex", "sex_reported", "birthsex",
               "education_raw", "education_4cat", "education_3cat",
               "income_raw", "income_8cat",
               "general_health", "race_binary_wh",
               "marital", "employment", "binge_drink")
miss_vars <- intersect(miss_vars, names(brfss))

missingness_by_year <- brfss %>%
  group_by(year) %>%
  summarise(across(all_of(miss_vars), ~ round(100 * mean(is.na(.x)), 1)),
            .groups = "drop") %>%
  pivot_longer(-year, names_to = "variable", values_to = "pct_na") %>%
  pivot_wider(names_from = year, values_from = pct_na)

write.csv(missingness_by_year,
          file.path(out_dir, "missingness_by_year.csv"), row.names = FALSE)

cat("Percent missing by year:\n")
print(as.data.frame(missingness_by_year))


# --- Table 2: cannabis module coverage ----------------------------------------
# The cannabis module is optional and states choose annually whether to use it.
# NA means the state has no respondents with cannabis answers that year, because it didn't 
# include the module. 

module_coverage <- brfss %>%
  count(state_name, year) %>%
  pivot_wider(names_from = year, values_from = n)

write.csv(module_coverage,
          file.path(out_dir, "module_coverage.csv"), row.names = FALSE)

cat("\n\nObservations by state and year:\n")
print(as.data.frame(module_coverage))


# --- Table 3: sample kept under each covariate set ------------------------
# Every covariate with missing values removes respondents from the sample. Meaning 
# a smaller sample gives a larger variance (diff_var) and a larger standard error
# for the ATT.
# Below are possible sets of covariates, from none to all 5. The table shows how many 
#respondents are kept under each set which is useful when choosing variables. The undidR analysis 
# uses the "age + sex + education + marital + income" set. *revise* maybe only include the variables used in the undidR analysis?

cov_sets <- list(
  "none"                  = character(0),
  "age + sex"             = c("age_5yr", "sex_reported"),
  "+ education"           = c("age_5yr", "sex_reported", "education_4cat"),
  "+ marital"             = c("age_5yr", "sex_reported", "education_4cat", "marital"),
  "+ income"              = c("age_5yr", "sex_reported", "education_4cat", "marital", "income_8cat")
)

# For each covariate set and each year, this reports how many respondents would
# be kept if we required an answer on the outcome (use30) AND on every covariate
# in that set. It makes three columns:
#   n         all respondents in that year
#   kept      respondents with no missing answer on use30 or on any covariate
#             in the set
#   pct_kept  kept as a percent of n
# Example: for the "age + sex" set, a respondent counts as kept only if use30,
# age_5yr and sex_reported are all filled in.
covariate_cost <- purrr::imap_dfr(cov_sets, function(vars, label) {
  brfss %>%
    group_by(year) %>%
    summarise(n = n(),
              kept = sum(complete.cases(pick(all_of(c(vars, "use30"))))),
              .groups = "drop") %>%
    mutate(covariate_set = label,
           pct_kept = round(100 * kept / n, 1))
}) %>%
  select(covariate_set, year, n, kept, pct_kept) %>%
  pivot_wider(names_from = year, values_from = c(n, kept, pct_kept))

write.csv(covariate_cost,
          file.path(out_dir, "covariate_cost.csv"), row.names = FALSE)

cat("\n\nSample retained by covariate set:\n")
print(as.data.frame(
  covariate_cost %>% select(covariate_set, starts_with("pct_kept"))))

cat("\n\nMissingness complete.\n")
cat("Tables written to:", out_dir, "\n\n")