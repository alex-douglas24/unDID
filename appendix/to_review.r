
# Appendix Extra 
# to go at the end of main.R when doing the graphs 
# =============================================================================
# Fig 1: Did cannabis use change? (use30, treatment vs control)
# =============================================================================
trends_use <- brfss %>%
  filter(!is.na(use30)) %>%
  group_by(group, year) %>%
  summarise(pct = round(mean(use30) * 100, 1), .groups = "drop")

p1 <- ggplot(trends_use, aes(x = year, y = pct, color = group)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -1, size = 3.5, show.legend = FALSE) +
  geom_vline(xintercept = 2018, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2018.15, y = max(trends_use$pct) + 1,
           label = "Canada legalization", hjust = 0, size = 3.2, color = "grey40") +
  scale_color_manual(values = group_colors) +
  scale_x_continuous(breaks = 2016:2022) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
  labs(title = "Share of Population Using Cannabis in Past 30 Days",
       y = "% Who Used", x = NULL, color = NULL) +
  theme_trends

ggsave("output/fig1_prevalence_treat_control.png", p1,
       width = 10, height = 6, dpi = 300)


# =============================================================================
# Fig 2: How much did use change? (mean days among users, treatment vs control)
# =============================================================================
trends_days <- brfss %>%
  filter(!is.na(marijuana_days_clean), use30 == 1) %>%
  group_by(group, year) %>%
  summarise(mean_days = round(mean(marijuana_days_clean), 1), .groups = "drop")

p2 <- ggplot(trends_days, aes(x = year, y = mean_days, color = group)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_text(aes(label = paste0(mean_days, " days")), 
            vjust = -1, size = 3.5, show.legend = FALSE) +
  geom_vline(xintercept = 2018, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2018.15, y = max(trends_days$mean_days) + 0.5,
           label = "Canada legalization", hjust = 0, size = 3.2, color = "grey40") +
  scale_color_manual(values = group_colors) +
  scale_x_continuous(breaks = 2016:2022) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
  labs(title = "Average Days of Cannabis Use Among Users",
       subtitle = "Among respondents who used at least once in the past 30 days",
       y = "Mean Days (Past 30)", x = NULL, color = NULL) +
  theme_trends

ggsave("output/fig2_mean_days_treat_control.png", p2,
       width = 10, height = 6, dpi = 300)


# =============================================================================
# Fig 3: Individual states — mean days among users
# =============================================================================
trends_state <- brfss %>%
  filter(!is.na(marijuana_days_clean), use30 == 1) %>%
  group_by(state_name, year) %>%
  summarise(mean_days = round(mean(marijuana_days_clean), 1), .groups = "drop")

p3 <- ggplot(trends_state, aes(x = year, y = mean_days, color = state_name)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.5) +
  geom_text(aes(label = mean_days), vjust = -1, size = 2.8, show.legend = FALSE) +
  geom_vline(xintercept = 2018, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2018.15, y = max(trends_state$mean_days) + 0.5,
           label = "Canada legalization", hjust = 0, size = 3.2, color = "grey40") +
  scale_x_continuous(breaks = 2016:2022) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
  labs(title = "Average Days of Cannabis Use by State — Among Users",
       y = "Mean Days (Past 30)", x = NULL, color = "State") +
  theme_trends

ggsave("output/fig3_mean_days_by_state.png", p3,
       width = 10, height = 6, dpi = 300)

# =============================================================================
# Fig 4: Did heavy use change? (mj_high, treatment vs control)
# =============================================================================
trends_heavy <- brfss %>%
  filter(!is.na(mj_high)) %>%
  group_by(group, year) %>%
  summarise(pct = round(mean(mj_high) * 100, 1), .groups = "drop")

p4 <- ggplot(trends_heavy, aes(x = year, y = pct, color = group)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -1, size = 3.5, show.legend = FALSE) +
  geom_vline(xintercept = 2018, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2018.15, y = max(trends_heavy$pct) + 0.3,
           label = "Canada legalization", hjust = 0, size = 3.2, color = "grey40") +
  scale_color_manual(values = group_colors) +
  scale_x_continuous(breaks = 2016:2022) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
  labs(title = "Share of Population Using Cannabis 25+ Days per Month",
       subtitle = "Near-daily or daily use",
       y = "% Heavy Users", x = NULL, color = NULL) +
  theme_trends

ggsave("output/fig4_heavy_use_treat_control.png", p4,
       width = 10, height = 6, dpi = 300)


# =============================================================================
# Fig 5: Heavy use by individual state
# =============================================================================
trends_heavy_state <- brfss %>%
  filter(!is.na(mj_high)) %>%
  group_by(state_name, year) %>%
  summarise(pct = round(mean(mj_high) * 100, 1), .groups = "drop")

p5 <- ggplot(trends_heavy_state, aes(x = year, y = pct, color = state_name)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.5) +
  geom_text(aes(label = paste0(pct, "%")), vjust = -1, size = 2.8, show.legend = FALSE) +
  geom_vline(xintercept = 2018, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2018.15, y = max(trends_heavy_state$pct) + 0.3,
           label = "Canada legalization", hjust = 0, size = 3.2, color = "grey40") +
  scale_x_continuous(breaks = 2016:2022) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
  labs(title = "Heavy Cannabis Use by State — 25+ Days per Month",
       y = "% Heavy Users", x = NULL, color = "State") +
  theme_trends

ggsave("output/fig5_heavy_use_by_state.png", p5,
       width = 10, height = 6, dpi = 300)

cat("Figures 4 and 5 saved to output/\n")




cat("All figures saved to output/\n")
library(dplyr)
library(ggplot2)

# =============================================================================
# All 6 states combined as one control group (no treatment/control split)
# =============================================================================

# --- Fig A: Share of population using cannabis (all 6 states combined) ---
trends_all_use <- brfss %>%
  filter(!is.na(use30)) %>%
  group_by(year) %>%
  summarise(pct = round(mean(use30) * 100, 1), .groups = "drop")

pA <- ggplot(trends_all_use, aes(x = year, y = pct)) +
  geom_line(linewidth = 1.2, color = "#2c7bb6") +
  geom_point(size = 3, color = "#2c7bb6") +
  geom_text(aes(label = paste0(pct, "%")), vjust = -1, size = 3.5) +
  geom_vline(xintercept = 2018, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2018.15, y = max(trends_all_use$pct) + 0.5,
           label = "Canada legalization", hjust = 0, size = 3.2, color = "grey40") +
  scale_x_continuous(breaks = 2016:2022) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
  labs(title = "Share of Population Using Cannabis in Past 30 Days",
       subtitle = "6 US control states combined (ID, MN, NH, ND, TN, WY)",
       y = "% Who Used", x = NULL) +
  theme_trends

ggsave("output/figA_prevalence_combined.png", pA,
       width = 10, height = 6, dpi = 300)


# --- Fig B: Average days of use among users (all 6 states combined) ---
trends_all_days <- brfss %>%
  filter(!is.na(marijuana_days_clean), use30 == 1) %>%
  group_by(year) %>%
  summarise(mean_days = round(mean(marijuana_days_clean), 1), .groups = "drop")

pB <- ggplot(trends_all_days, aes(x = year, y = mean_days)) +
  geom_line(linewidth = 1.2, color = "#2c7bb6") +
  geom_point(size = 3, color = "#2c7bb6") +
  geom_text(aes(label = paste0(mean_days, " days")), vjust = -1, size = 3.5) +
  geom_vline(xintercept = 2018, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2018.15, y = max(trends_all_days$mean_days) + 0.3,
           label = "Canada legalization", hjust = 0, size = 3.2, color = "grey40") +
  scale_x_continuous(breaks = 2016:2022) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
  labs(title = "Average Days of Cannabis Use Among Users",
       subtitle = "6 US control states combined (ID, MN, NH, ND, TN, WY)",
       y = "Mean Days (Past 30)", x = NULL) +
  theme_trends

ggsave("output/figB_mean_days_combined.png", pB,
       width = 10, height = 6, dpi = 300)


# --- Fig C: Heavy cannabis use (all 6 states combined) ---
trends_all_heavy <- brfss %>%
  filter(!is.na(mj_high)) %>%
  group_by(year) %>%
  summarise(pct = round(mean(mj_high) * 100, 1), .groups = "drop")

pC <- ggplot(trends_all_heavy, aes(x = year, y = pct)) +
  geom_line(linewidth = 1.2, color = "#2c7bb6") +
  geom_point(size = 3, color = "#2c7bb6") +
  geom_text(aes(label = paste0(pct, "%")), vjust = -1, size = 3.5) +
  geom_vline(xintercept = 2018, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2018.15, y = max(trends_all_heavy$pct) + 0.2,
           label = "Canada legalization", hjust = 0, size = 3.2, color = "grey40") +
  scale_x_continuous(breaks = 2016:2022) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
  labs(title = "Share of Population Using Cannabis 25+ Days per Month",
       subtitle = "6 US control states combined (ID, MN, NH, ND, TN, WY)",
       y = "% Heavy Users", x = NULL) +
  theme_trends

ggsave("output/figC_heavy_use_combined.png", pC,
       width = 10, height = 6, dpi = 300)

cat("Figures A, B, C saved to output/\n")







#test file from before below 
# LOAD PACKAGES
library(dplyr)
library(haven)
library(tidyr)


# LOAD DATASET
clean_df <- read_dta("brfss_clean.dta")


# Keep only observations with nonmissing variables for outcome
clean_df <- clean_df |>
  filter(!is.na(days30d))

# Drop observations with missing values for control variables
clean_df <- clean_df |>
  drop_na(ageg6, educ, hh_inc, health5, ethnicity)

# Creating factor variables out of categorical variables
clean_df <- clean_df |>
  mutate(
    ageg6 = factor(ageg6),
    educ = factor(educ),
    hh_inc = factor(hh_inc),
    health5 = factor(health5),
  )

# CREATING DUMMY VARIABLES FOR CATEGORIES
X <- model.matrix(~ ageg6 + educ + hh_inc + health5,
                  data = clean_df, na.action = na.pass)

cat_dummies <- X[, -1, drop = FALSE] # this line excludes the intercept column

# Merge new dummy variables with existing data
clean_df <- cbind(clean_df, cat_dummies)




 # to do reproducibility 
 # re run the whole pipeline on a different machine, and check that the output is identical without manual intervention 
 # fix the .XPT files paths as right now it is hard coded to my machine, and the output paths are also hard coded to my machine.
 #  Move the undid paths into 00_config.R so they aren't redefined per script:  undid_common_dir    <- file.path(clean_dir, "undid", "common")
 #    undid_staggered_dir <- file.path(clean_dir, "undid", "staggered")
 # Keep the common and staggered specs in separate folders. Stage three reads every file in a directory beginning filled_diff_df_, so mixing them would  combine two different specifications.
 # Appendix stuff: final wt is carried but undid stage 2 is unweighted mean no survey weight 
 # 2018 is partial treated year cuz oct 2018 was the legalization date, so the estimate is attenuated.
# to do manuscript
# education variable harmonization question - we can not harmonize it just gotta change the code - wait on decision 
# fix the race variable cuz maybe it shouldnt be binary?? also ask about manuscript decision re the harmonization part 
# should it refer to the harmonization names for the undid or for the BRFSS? i assume undid so in that case the other 
# part goes into the appendix and readmefiles 