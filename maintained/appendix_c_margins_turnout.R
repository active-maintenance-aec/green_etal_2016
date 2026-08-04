# green_etal_2016/maintained/appendix_c_margins_turnout.R
# Output: output/appendix_c_margins_turnout.csv, output/text_pooled_turnout.csv
# Depends on: original/exp_1.RData through exp_4.RData, helpers.R
# Description: Appendix Tables C.1 to C.4: effects on vote margin and turnout for all four
#   experiments, plus the pooled turnout effects the main text reports in section 5.5.
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
# tidy() on an lm_robust object already returns a column called outcome, holding the
# dependent variable's name. A mutate() whose right-hand side is also called outcome
# reads that column rather than the argument, so the label passed in is silently
# discarded and Experiment 1's rows come back labelled nvote12 and totalcvotes12
# while the other three, whose variables happen to be named margin and turnout, look
# correct. The published tables are indexed by outcome, so the argument is named
# apart from the column it fills.
extract_terms <- function(mod, experiment, outcome_label, model) {
  tidy(mod) |>
    filter(term == "(Intercept)" | str_detect(term, "condition_factor")) |>
    mutate(experiment = experiment, outcome = outcome_label, model = model,
           n = nobs(mod), r2 = summary(mod)$r.squared)
}

fits <- list(
  list(e1_margin_m1,  "Experiment 1", "margin",  "M1"),
  list(e1_margin_m2,  "Experiment 1", "margin",  "M2"),
  list(e1_turnout_m1, "Experiment 1", "turnout", "M1"),
  list(e1_turnout_m2, "Experiment 1", "turnout", "M2"),
  list(e2_margin_m1,  "Experiment 2", "margin",  "M1"),
  list(e2_margin_m2,  "Experiment 2", "margin",  "M2"),
  list(e2_turnout_m1, "Experiment 2", "turnout", "M1"),
  list(e2_turnout_m2, "Experiment 2", "turnout", "M2"),
  list(e3_margin_m1,  "Experiment 3", "margin",  "M1"),
  list(e3_margin_m2,  "Experiment 3", "margin",  "M2"),
  list(e3_turnout_m1, "Experiment 3", "turnout", "M1"),
  list(e3_turnout_m2, "Experiment 3", "turnout", "M2"),
  list(e4_margin_m1,  "Experiment 4", "margin",  "M1"),
  list(e4_margin_m2,  "Experiment 4", "margin",  "M2"),
  list(e4_turnout_m1, "Experiment 4", "turnout", "M1"),
  list(e4_turnout_m2, "Experiment 4", "turnout", "M2")
)

results <- map_dfr(fits, ~ extract_terms(.x[[1]], .x[[2]], .x[[3]], .x[[4]]))
write_csv(results, here::here("maintained", "output", "appendix_c_margins_turnout.csv"))

# Pooled turnout effects, main text section 5.5 ----
# The paper pools the covariate-adjusted turnout estimates by the same fixed-effects
# meta-analysis it uses for vote share in Table 7.
turnout_m2 <- filter(results, outcome == "turnout", model == "M2")
direct <- filter(turnout_m2, term == "condition_factorTreated") |> arrange(experiment)
indirect <- filter(turnout_m2, term == "condition_factorAdjacent") |> arrange(experiment)

direct_fe <- rma(yi = direct$estimate, sei = direct$std.error, method = "FE")
indirect_fe <- rma(yi = indirect$estimate, sei = indirect$std.error, method = "FE")

pooled_turnout <- tribble(
  ~arm, ~estimate, ~std.error, ~n_studies,
  "Treated", as.numeric(direct_fe$beta), direct_fe$se, nrow(direct),
  "Adjacent", as.numeric(indirect_fe$beta), indirect_fe$se, nrow(indirect)
)
write_csv(pooled_turnout, here::here("maintained", "output", "text_pooled_turnout.csv"))
