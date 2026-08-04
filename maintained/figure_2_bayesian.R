# green_etal_2016/maintained/figure_2_bayesian.R
# Output: output/figure_2_bayesian.pdf, output/figure_2_bayesian.png,
#   output/figure_2_bayesian.csv
# Depends on: output/table_7_pooled.csv, helpers.R
# Description: Figure 2: how an agnostic, an optimistic and a skeptical observer update
#   their prior about the direct effect of lawn signs as the four experiments arrive.

source(here::here("maintained", "helpers.R"))

# Direct effect estimates ----
# Read at full precision from the Table 7 output rather than retyping the rounded
# values the table prints. The original Pooled_analysis.R updates on the fitted
# coefficients, so rounding first would not reproduce it.
direct <- read_csv(here::here("maintained", "output", "table_7_pooled.csv"),
                   show_col_types = FALSE) |>
  filter(arm == "Treated", experiment != "Pooled") |>
  arrange(experiment)

direct_fx <- direct$estimate
direct_fx_se <- direct$std.error

# Bayesian update: inverse-variance weighting ----
bayes_update <- function(prior_mean, prior_se, est, se) {
  post_prec <- 1 / prior_se^2 + 1 / se^2
  post_mean <- (prior_mean / prior_se^2 + est / se^2) / post_prec
  post_se <- sqrt(1 / post_prec)
  c(post_mean, post_se)
}

lawn_learning <- function(prior_mean, prior_se) {
  states <- matrix(NA, nrow = 5, ncol = 2)
  states[1, ] <- c(prior_mean, prior_se)
  for (i in seq_along(direct_fx)) {
    states[i + 1, ] <- bayes_update(states[i, 1], states[i, 2],
                                    direct_fx[i], direct_fx_se[i])
  }
  as_tibble(states, .name_repair = ~ c("mean", "se")) |>
    mutate(time = c("Prior", paste0("Update ", 1:4)))
}

scenarios <- bind_rows(
  lawn_learning(0, 0.05) |> mutate(scenario = "Agnostic"),
  lawn_learning(0.05, 0.05) |> mutate(scenario = "Optimist"),
  lawn_learning(0, 0.01) |> mutate(scenario = "Skeptic")
) |>
  mutate(
    time = factor(time, levels = c("Prior", paste0("Update ", 1:4))),
    scenario = factor(scenario, levels = c("Agnostic", "Optimist", "Skeptic")),
    pr_pos = pnorm(0, mean = mean, sd = se, lower.tail = FALSE),
    facet = sprintf("N(%.3f, %.3f)\npr(ATE>0)=%.3f", mean, se, pr_pos)
  )

write_csv(scenarios, here::here("maintained", "output", "figure_2_bayesian.csv"))

# Density curves for the ribbon plot ----
x_grid <- seq(-0.15, 0.15, by = 0.0001)

gg_df <- scenarios |>
  rowwise() |>
  reframe(
    x = x_grid,
    y = dnorm(x_grid, mean = mean, sd = se),
    scenario = scenario,
    time = time,
    facet = facet
  )

make_panel <- function(scen) {
  panel_df <- filter(gg_df, scenario == scen)
  ggplot(panel_df, aes(x = x, y = y)) +
    geom_line() +
    geom_vline(xintercept = 0, linetype = "dashed") +
    geom_ribbon(data = filter(panel_df, x > 0), aes(ymax = y), ymin = 0,
                fill = "lightgray", alpha = 0.5) +
    facet_grid(scenario ~ facet) +
    coord_cartesian(xlim = c(-0.11, 0.11)) +
    theme_bw() +
    theme(
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      axis.title = element_blank(),
      legend.position = "none",
      strip.background = element_blank()
    )
}

# arrangeGrob draws nothing but still opens a device, which under Rscript means a stray
# Rplots.pdf in the working directory. A null device absorbs it.
pdf(NULL)
g_all <- arrangeGrob(
  make_panel("Agnostic"),
  make_panel("Optimist"),
  make_panel("Skeptic"),
  ncol = 1
)
dev.off()

ggsave(here::here("maintained", "output", "figure_2_bayesian.pdf"),
       plot = g_all, width = 15, height = 9)
ggsave(here::here("maintained", "output", "figure_2_bayesian.png"),
       plot = g_all, width = 15, height = 9, dpi = 150)
