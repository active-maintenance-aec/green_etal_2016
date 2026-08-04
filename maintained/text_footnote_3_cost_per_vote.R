# green_etal_2016/maintained/text_footnote_3_cost_per_vote.R
# Output: output/text_footnote_3_cost_per_vote.csv
# Depends on: original/exp_1.RData through exp_4.RData, output/table_7_pooled.csv, helpers.R
# Description: Footnote 3: total turnout across the four experiments, the campaigns' total
#   outlay on signs, and the resulting cost per additional vote.
source(here::here("maintained", "helpers.R"))

load(here::here("original", "exp_1.RData"))
load(here::here("original", "exp_2.RData"))
load(here::here("original", "exp_3.RData"))
load(here::here("original", "exp_4.RData"))

# Total votes cast ----
# Every precinct in all four experiments, including the untreatable ones excluded from
# the regressions, which is what the archive's in_text_calculations.R sums.
total_turnout <- sum(exp_1$turnout) + sum(exp_2$turnout) +
  sum(exp_3$turnout) + sum(exp_4$turnout)

# What the four campaigns spent on signs ----
# Per-campaign outlays recorded in the archive's in_text_calculations.R; they appear in
# no data file and the article prints only their sum.
total_cost <- 1850 + 345 + 1850 + 4000 + 5000

pooled <- read_csv(here::here("maintained", "output", "table_7_pooled.csv"),
                   show_col_types = FALSE) |>
  filter(experiment == "Pooled")

direct <- pooled$estimate[pooled$arm == "Treated"]
direct_se <- pooled$std.error[pooled$arm == "Treated"]
indirect <- pooled$estimate[pooled$arm == "Adjacent"]

# The footnote's own arithmetic runs on the pooled estimates as Table 7 prints them,
# rounded to three decimals, so the rounding is reproduced here rather than the
# published numbers being retyped.
direct_printed <- round(direct, 3)
indirect_printed <- round(indirect, 3)

cost_per_vote <- function(effect) total_cost / (effect * total_turnout)

# The 95 per cent interval ----
# The archive draws 10,000 effects from the sampling distribution with no seed, so the
# published endpoints are one draw from a distribution rather than a fixed quantity.
# Repeating the draw over many seeds measures how far an endpoint moves.
n_draws <- 10000
n_seeds <- 200
interval_probs <- c(0.025, 0.975)
endpoints <- map_dfr(seq_len(n_seeds), function(s) {
  set.seed(s)
  costs <- cost_per_vote(rnorm(n_draws, mean = direct_printed, sd = round(direct_se, 3)))
  q <- quantile(costs, probs = interval_probs)
  tibble(low = q[[1]], high = q[[2]])
})

results <- tribble(
  ~quantity, ~value,
  "total turnout", total_turnout,
  "total cost", total_cost,
  "pooled direct effect, as Table 7 prints it", direct_printed,
  "pooled direct effect, full precision", direct,
  "cost per vote, direct effect only", cost_per_vote(direct_printed),
  "cost per vote, direct effect at full precision", cost_per_vote(direct),
  "cost per vote, direct and indirect", cost_per_vote(direct_printed + indirect_printed),
  "cost per vote, direct and indirect at full precision", cost_per_vote(direct + indirect),
  "interval lower endpoint, median over seeds", median(endpoints$low),
  "interval lower endpoint, minimum over seeds", min(endpoints$low),
  "interval lower endpoint, maximum over seeds", max(endpoints$low),
  "interval upper endpoint, median over seeds", median(endpoints$high),
  "interval upper endpoint, minimum over seeds", min(endpoints$high),
  "interval upper endpoint, maximum over seeds", max(endpoints$high),
  "interval level, per cent", 100 * diff(interval_probs),
  "seeds drawn", n_seeds
)

write_csv(results, here::here("maintained", "output", "text_footnote_3_cost_per_vote.csv"))
