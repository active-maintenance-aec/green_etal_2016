# green_etal_2016/maintained/appendix_c_margins_turnout.R
# Output: output/appendix_c_margins_turnout.csv
# Depends on: original/exp_1.RData through exp_4.RData, helpers.R
# Description: Appendix Tables C.1 to C.4: effects on vote margin and turnout for all four experiments.
source(here::here("maintained", "helpers.R"))

load(here::here("original", "exp_1.RData"))
load(here::here("original", "exp_2.RData"))
load(here::here("original", "exp_3.RData"))
load(here::here("original", "exp_4.RData"))

# Experiment 1 ----
d1 <- filter(exp_1, treatable == 1)
e1_margin_m1  <- lm_robust(nvote12 ~ condition_factor, weights = weights, data = d1, se_type = "HC2")
e1_margin_m2  <- lm_robust(nvote12 ~ condition_factor + nvote10 + nvote08 + nvote06 + npvote08,
                            weights = weights, data = d1, se_type = "HC2")
e1_turnout_m1 <- lm_robust(totalcvotes12 ~ condition_factor, weights = weights, data = d1, se_type = "HC2")
e1_turnout_m2 <- lm_robust(totalcvotes12 ~ condition_factor + totalcvotes10 + totalcvotes08 + totalcvotes06 + totalpvotes08,
                            weights = weights, data = d1, se_type = "HC2")

# Experiment 2 ----
d2 <- filter(exp_2, include == 1)
e2_margin_m1  <- lm_robust(margin ~ condition_factor, weights = weights, data = d2, se_type = "HC2")
e2_margin_m2  <- lm_robust(margin ~ condition_factor + registereddems + jenningsvotemargin09 + jenningsvotemargin05,
                            weights = weights, data = d2, se_type = "HC2")
e2_turnout_m1 <- lm_robust(turnout ~ condition_factor, weights = weights, data = d2, se_type = "HC2")
e2_turnout_m2 <- lm_robust(turnout ~ condition_factor + registereddems + turnout09 + turnout05,
                            weights = weights, data = d2, se_type = "HC2")

# Experiment 3 ----
e3_margin_m1  <- lm_robust(margin ~ condition_factor, weights = weights, data = exp_3, se_type = "HC2")
e3_margin_m2  <- lm_robust(margin ~ condition_factor + obama_margin_2012 + shannon_margin_2009,
                            weights = weights, data = exp_3, se_type = "HC2")
e3_turnout_m1 <- lm_robust(turnout ~ condition_factor, weights = weights, data = exp_3, se_type = "HC2")
e3_turnout_m2 <- lm_robust(turnout ~ condition_factor + turnout_2012 + turnout_2009,
                            weights = weights, data = exp_3, se_type = "HC2")

# Experiment 4 ----
e4_margin_m1  <- lm_robust(margin ~ condition_factor, weights = weights, data = exp_4, se_type = "HC2")
e4_margin_m2  <- lm_robust(margin ~ condition_factor + GOVM2010 + USPM2008 + GOVM2006 + USPM2004 + GOVM2002 + USPM2000,
                            weights = weights, data = exp_4, se_type = "HC2")
e4_turnout_m1 <- lm_robust(turnout ~ condition_factor, weights = weights, data = exp_4, se_type = "HC2")
e4_turnout_m2 <- lm_robust(turnout ~ condition_factor + GOVT2010 + USPT2008 + GOVT2006 + USPT2004 + GOVT2002 + USPT2000,
                            weights = weights, data = exp_4, se_type = "HC2")

# Collect results ----
extract_both_arms <- function(mod, experiment, outcome, model) {
  tidy(mod) |>
    filter(str_detect(term, "condition_factor")) |>
    mutate(experiment = experiment, outcome = outcome, model = model,
           n = nobs(mod), r2 = summary(mod)$r.squared)
}

results <- bind_rows(
  extract_both_arms(e1_margin_m1,  "Experiment 1", "margin",  "M1"),
  extract_both_arms(e1_margin_m2,  "Experiment 1", "margin",  "M2"),
  extract_both_arms(e1_turnout_m1, "Experiment 1", "turnout", "M1"),
  extract_both_arms(e1_turnout_m2, "Experiment 1", "turnout", "M2"),
  extract_both_arms(e2_margin_m1,  "Experiment 2", "margin",  "M1"),
  extract_both_arms(e2_margin_m2,  "Experiment 2", "margin",  "M2"),
  extract_both_arms(e2_turnout_m1, "Experiment 2", "turnout", "M1"),
  extract_both_arms(e2_turnout_m2, "Experiment 2", "turnout", "M2"),
  extract_both_arms(e3_margin_m1,  "Experiment 3", "margin",  "M1"),
  extract_both_arms(e3_margin_m2,  "Experiment 3", "margin",  "M2"),
  extract_both_arms(e3_turnout_m1, "Experiment 3", "turnout", "M1"),
  extract_both_arms(e3_turnout_m2, "Experiment 3", "turnout", "M2"),
  extract_both_arms(e4_margin_m1,  "Experiment 4", "margin",  "M1"),
  extract_both_arms(e4_margin_m2,  "Experiment 4", "margin",  "M2"),
  extract_both_arms(e4_turnout_m1, "Experiment 4", "turnout", "M1"),
  extract_both_arms(e4_turnout_m2, "Experiment 4", "turnout", "M2")
)

write_csv(results, here::here("maintained", "output", "appendix_c_margins_turnout.csv"))
