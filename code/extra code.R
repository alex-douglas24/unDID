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