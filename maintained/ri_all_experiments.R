# green_etal_2016/maintained/ri_all_experiments.R
# Output: output/ri_all_experiments.csv
# Depends on: original/exp_1.RData through exp_4.RData, helpers.R
# Description: Randomization inference p-values for the joint null of no direct and no
#   indirect effect, for all four experiments and all three outcomes. Each experiment's
#   observed F-statistic is compared against the 10,000 pre-computed permutations that
#   ship inside its exp_N.RData object.

source(here::here("maintained", "helpers.R"))

# Every experiment reads its data and its permutation matrix from the same canonical
# object the table scripts use, so the observed assignment behind the p-value is the
# one behind the published coefficients. Reading the permutation matrix from anywhere
# else is what broke Experiment 2 in the March 2026 pass: clean_exp2.R redraws the
# observed column with set.seed(12345), which selects column 8243 on R 3.6 and later
# rather than the column 7210 the published analysis used.

# Experiment 1 ----
load(here::here("original", "exp_1.RData"))

formulas_1 <- list(
  share   = "dvote12 ~ condition_factor + dvote10 + dvote08 + dvote06 + pvote08",
  margin  = "nvote12 ~ condition_factor + nvote10 + nvote08 + nvote06 + npvote08",
  turnout = "totalcvotes12 ~ condition_factor + totalcvotes10 + totalcvotes08 + totalcvotes06 + totalpvotes08"
)

keep_1 <- exp_1$treatable == 1
d1 <- exp_1[keep_1, ]
f_obs_1 <- map_dbl(formulas_1, f_treat, treat_var = "condition_factor", wt_name = "weights", data = d1)

f_sims_1 <- matrix(NA_real_, nrow = ncol(cond_mat_1), ncol = 3,
                   dimnames = list(NULL, names(formulas_1)))
for (i in seq_len(ncol(cond_mat_1))) {
  cond_sim <- cond_mat_1[, i]
  wts_sim <- case_when(
    cond_sim == 1 ~ 1 / exp_1$probs.1.1,
    cond_sim == 2 ~ 1 / exp_1$probs.1.0,
    cond_sim == 3 ~ 1 / exp_1$probs.0.1,
    cond_sim == 4 ~ 1 / exp_1$probs.0.0
  )
  cond_fac <- relevel(
    factor(cond_sim, levels = 2:4, labels = c("Treated", "Adjacent", "Control")),
    ref = "Control"
  )
  d_sim <- d1
  d_sim$condition_factor <- cond_fac[keep_1]
  d_sim$weights <- wts_sim[keep_1]
  f_sims_1[i, ] <- map_dbl(formulas_1, f_treat, "condition_factor", "weights", data = d_sim)
}

ri_1 <- tibble(
  experiment = "Experiment 1",
  outcome = names(formulas_1),
  p_value = map_dbl(names(formulas_1), \(x) mean(f_sims_1[, x] >= f_obs_1[x]))
)

# Experiment 2 ----
load(here::here("original", "exp_2.RData"))

formulas_2 <- list(
  share   = "share ~ condition_factor + registereddems + jenningsvoteshare09 + jenningsvoteshare05",
  margin  = "margin ~ condition_factor + registereddems + jenningsvotemargin09 + jenningsvotemargin05",
  turnout = "turnout ~ condition_factor + registereddems + turnout09 + turnout05"
)

keep_2 <- exp_2$in_whole_exp == 1
d2 <- exp_2[keep_2, ]
f_obs_2 <- map_dbl(formulas_2, f_treat, "condition_factor", "weights", data = d2)

f_sims_2 <- matrix(NA_real_, nrow = ncol(cond_mat_2), ncol = 3,
                   dimnames = list(NULL, names(formulas_2)))
for (i in seq_len(ncol(cond_mat_2))) {
  cond_sim <- cond_mat_2[, i]
  wts_sim <- case_when(
    cond_sim == 3 ~ 1 / exp_2$restricted.prob.3,
    cond_sim == 2 ~ 1 / exp_2$restricted.prob.2,
    cond_sim == 1 ~ 1 / exp_2$restricted.prob.1
  )
  cond_fac <- factor(cond_sim, levels = 1:3, labels = c("Control", "Adjacent", "Treated")) |>
    factor(levels = c("Control", "Treated", "Adjacent"))
  d_sim <- d2
  d_sim$condition_factor <- cond_fac[keep_2]
  d_sim$weights <- wts_sim[keep_2]
  f_sims_2[i, ] <- map_dbl(formulas_2, f_treat, "condition_factor", "weights", data = d_sim)
}

ri_2 <- tibble(
  experiment = "Experiment 2",
  outcome = names(formulas_2),
  p_value = map_dbl(names(formulas_2), \(x) mean(f_sims_2[, x] >= f_obs_2[x]))
)

# Experiment 3 ----
load(here::here("original", "exp_3.RData"))

formulas_3 <- list(
  share   = "share ~ condition_factor + obama_share_2012 + shannon_share_2009",
  margin  = "margin ~ condition_factor + obama_margin_2012 + shannon_margin_2009",
  turnout = "turnout ~ condition_factor + turnout_2012 + turnout_2009"
)

f_obs_3 <- map_dbl(formulas_3, f_treat, "condition_factor", "weights", data = exp_3)

f_sims_3 <- matrix(NA_real_, nrow = ncol(cond_mat_3), ncol = 3,
                   dimnames = list(NULL, names(formulas_3)))
for (i in seq_len(ncol(cond_mat_3))) {
  cond_sim <- cond_mat_3[, i]
  wts_sim <- case_when(
    cond_sim == 3 ~ 1 / exp_3$restricted.prob.3,
    cond_sim == 2 ~ 1 / exp_3$restricted.prob.2,
    cond_sim == 1 ~ 1 / exp_3$restricted.prob.1
  )
  cond_fac <- factor(cond_sim, levels = 1:3, labels = c("Control", "Adjacent", "Treated")) |>
    factor(levels = c("Control", "Treated", "Adjacent"))
  d_sim <- exp_3
  d_sim$condition_factor <- cond_fac
  d_sim$weights <- wts_sim
  f_sims_3[i, ] <- map_dbl(formulas_3, f_treat, "condition_factor", "weights", data = d_sim)
}

ri_3 <- tibble(
  experiment = "Experiment 3",
  outcome = names(formulas_3),
  p_value = map_dbl(names(formulas_3), \(x) mean(f_sims_3[, x] >= f_obs_3[x]))
)

# Experiment 4 ----
# cond_mat_4 stores condition labels as text rather than as the codes 1 to 3.
load(here::here("original", "exp_4.RData"))

formulas_4 <- list(
  share   = "share ~ condition_factor + GOVP2010 + USPP2008 + GOVP2006 + USPP2004 + GOVP2002 + USPP2000",
  margin  = "margin ~ condition_factor + GOVM2010 + USPM2008 + GOVM2006 + USPM2004 + GOVM2002 + USPM2000",
  turnout = "turnout ~ condition_factor + GOVT2010 + USPT2008 + GOVT2006 + USPT2004 + GOVT2002 + USPT2000"
)

f_obs_4 <- map_dbl(formulas_4, f_treat, "condition_factor", "weights", data = exp_4)

f_sims_4 <- matrix(NA_real_, nrow = ncol(cond_mat_4), ncol = 3,
                   dimnames = list(NULL, names(formulas_4)))
for (i in seq_len(ncol(cond_mat_4))) {
  cond_sim <- as.character(cond_mat_4[, i])
  wts_sim <- case_when(
    cond_sim == "treated" ~ 1 / exp_4$res_prob_treated,
    cond_sim == "adjacent" ~ 1 / exp_4$res_prob_adj,
    cond_sim == "control" ~ 1 / exp_4$res_prob_control
  )
  cond_fac <- factor(cond_sim,
                     levels = c("control", "adjacent", "treated"),
                     labels = c("Control", "Adjacent", "Treated")) |>
    factor(levels = c("Control", "Treated", "Adjacent"))
  d_sim <- exp_4
  d_sim$condition_factor <- cond_fac
  d_sim$weights <- wts_sim
  f_sims_4[i, ] <- map_dbl(formulas_4, f_treat, "condition_factor", "weights", data = d_sim)
}

ri_4 <- tibble(
  experiment = "Experiment 4",
  outcome = names(formulas_4),
  p_value = map_dbl(names(formulas_4), \(x) mean(f_sims_4[, x] >= f_obs_4[x]))
)

# Collect ----
ri_all <- bind_rows(ri_1, ri_2, ri_3, ri_4)
write_csv(ri_all, here::here("maintained", "output", "ri_all_experiments.csv"))

# The article reports a randomization inference p-value for vote share only, one per
# experiment, in sections 5.1 to 5.4. Margin and turnout are computed here but are not
# stated anywhere in the article or its appendix.
published_share <- c("Experiment 1" = 0.22, "Experiment 2" = 0.90,
                     "Experiment 3" = 0.02, "Experiment 4" = 0.77)
print(
  ri_all |>
    mutate(
      check = "RI p-value, joint null of no direct and no indirect effect",
      published = if_else(outcome == "share", published_share[experiment], NA_real_)
    ) |>
    select(check, experiment, outcome, p_value, published),
  n = Inf, width = 200
)
