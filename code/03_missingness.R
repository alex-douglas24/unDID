# =============================================================================
# 03_missingness.R — Item nonresponse and module coverage diagnostics
# probably can delete later? just of the appendix with missingness from the BRFSS data
# Produces three tables written to output/:
#   missingness_by_year.csv   percent missing per variable, per year
#   module_coverage.csv       observations per state per year
#   covariate_cost.csv        sample retained under different covariate sets
#
# Requires: 00_config.R sourced first, and the analysis dataset built by
# 02_clean_append.R.
# =============================================================================

cat("============================================================\n")
cat("STEP 3: MISSINGNESS DIAGNOSTICS\n")
cat("============================================================\n\n")

brfss <- readRDS(file.path(clean_dir, "brfss_analysis_2016_2022.rds"))


# --- Table 1: percent missing by variable and year ----------------------------
# All candidate codings are included, not just the chosen ones, so the
# selection between alternatives (e.g. age_5yr vs age_imputed) is documented.

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
# The cannabis module is optional; states choose annually whether to field it.
# NA indicates the state did not ask the question that year.

module_coverage <- brfss %>%
  count(state_name, year) %>%
  pivot_wider(names_from = year, values_from = n)

write.csv(module_coverage,
          file.path(out_dir, "module_coverage.csv"), row.names = FALSE)

cat("\n\nObservations by state and year:\n")
print(as.data.frame(module_coverage))


# --- Table 3: sample retained under each covariate set ------------------------
# Covariate missingness reduces the effective sample in every silo-period
# cell, which inflates diff_var and the resulting ATT standard error.

cov_sets <- list(
  "none"                  = character(0),
  "age + sex"             = c("age_5yr", "sex_reported"),
  "+ education"           = c("age_5yr", "sex_reported", "education_4cat"),
  "+ marital"             = c("age_5yr", "sex_reported", "education_4cat", "marital"),
  "+ income"              = c("age_5yr", "sex_reported", "education_4cat", "marital", "income_8cat")
)

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

cat("\n\nMissingness diagnostics complete.\n")
cat("Tables written to:", out_dir, "\n\n")