# green_etal_2016/maintained/text_exp1_merged_shares.R
# Output: output/text_exp1_merged_shares.csv
# Depends on: original/exp_1.RData, original/Experiment_1_Results.RData,
#   output/table_7_pooled.csv, output/table_8_het_effects.csv,
#   output/text_pooled_interactions.csv, output/figure_2_bayesian.csv,
#   output/ri_all_experiments.csv, helpers.R
# Description: Everything downstream of Experiment 1's vote shares, recomputed with the
#   four merged precincts' shares taken from their summed vote counts. The deposited
#   analysis computes shares and then sums them across merged precincts, so a merged
#   unit carries the sum of two shares. The published objects stay as they are in the
#   table scripts; this script reports the corrected value beside each one.
source(here::here("maintained", "helpers.R"))

load(here::here("original", "exp_1.RData"))
published <- exp_1
load(here::here("original", "Experiment_1_Results.RData"))
precincts <- exp_1

# Shares from summed counts ----
vote_counts <- str_subset(names(precincts), "^(c12|c10|c08|c06|p08).*votes$")
corrected_shares <- precincts |>
  group_by(fid) |>
  summarise(across(all_of(vote_counts), sum), n_precincts = n(), .groups = "drop") |>
  transmute(
    fid,
    n_precincts,
    fixed_dvote12 = c12demvotes / (c12demvotes + c12repvotes + c12indvotes),
    fixed_dvote10 = c10demvotes / (c10demvotes + c10repvotes + c10indvotes),
    fixed_dvote08 = c08demvotes / (c08demvotes + c08repvotes + c08indvotes + c08convotes),
    fixed_dvote06 = c06demvotes / (c06demvotes + c06repvotes + c06indvotes + c06convotes),
    fixed_pvote08 = (p08demvotes + p08wfpvotes) /
      (p08demvotes + p08repvotes + p08indvotes + p08convotes + p08wfpvotes)
  )

joined <- left_join(published, corrected_shares, by = "fid")

# The same definitions must return the deposit's own value for every unmerged unit, and
# the deposit's share outcome must be dvote12, or the correction is not a correction.
unmerged <- filter(joined, n_precincts == 1)
stopifnot(
  sum(joined$n_precincts == 2) == 4,
  all(filter(joined, n_precincts == 2)$condition_factor == "Adjacent"),
  all.equal(unmerged$fixed_dvote12, unmerged$dvote12),
  all.equal(unmerged$fixed_dvote10, unmerged$dvote10),
  all.equal(unmerged$fixed_dvote08, unmerged$dvote08),
  all.equal(unmerged$fixed_dvote06, unmerged$dvote06),
  all.equal(unmerged$fixed_pvote08, unmerged$pvote08),
  all.equal(published$share, published$dvote12)
)

corrected <- joined |>
  mutate(
    dvote12 = fixed_dvote12,
    dvote10 = fixed_dvote10,
    dvote08 = fixed_dvote08,
    dvote06 = fixed_dvote06,
    pvote08 = fixed_pvote08,
    share = fixed_dvote12
  )
d_published <- filter(joined, treatable == 1)
d_corrected <- filter(corrected, treatable == 1)

# Table 3 ----
fit_table_3 <- function(rhs, data) {
  lm_robust(as.formula(str_c("dvote12 ~ ", rhs)), weights = weights, data = data, se_type = "HC2")
}
rhs_model_2 <- "condition_factor + dvote10 + dvote08 + dvote06 + pvote08"

table_3_rows <- function(rhs, model) {
  before <- fit_table_3(rhs, d_published)
  after <- fit_table_3(rhs, d_corrected)
  tibble(
    term = c("Treated", "Adjacent", "Constant", "Treated SE", "Adjacent SE", "Constant SE", "R2"),
    published = c(coef(before)[c("condition_factorTreated", "condition_factorAdjacent", "(Intercept)")],
                  before$std.error[c("condition_factorTreated", "condition_factorAdjacent", "(Intercept)")],
                  summary(before)$r.squared),
    corrected = c(coef(after)[c("condition_factorTreated", "condition_factorAdjacent", "(Intercept)")],
                  after$std.error[c("condition_factorTreated", "condition_factorAdjacent", "(Intercept)")],
                  summary(after)$r.squared)
  ) |>
    mutate(float = "Table 3", column = model)
}
table_3 <- bind_rows(table_3_rows("condition_factor", "Model 1"), table_3_rows(rhs_model_2, "Model 2"))

# Table 7 ----
model_2_corrected <- fit_table_3(rhs_model_2, d_corrected)
table_7_published <- read_csv(here::here("maintained", "output", "table_7_pooled.csv"),
                              show_col_types = FALSE)

table_7_corrected <- table_7_published |>
  filter(experiment != "Pooled") |>
  mutate(
    term = str_c("condition_factor", arm),
    estimate = if_else(experiment == "Experiment 1", coef(model_2_corrected)[term], estimate),
    std.error = if_else(experiment == "Experiment 1", model_2_corrected$std.error[term], std.error)
  )

pooled <- function(arm_label) {
  rows <- filter(table_7_corrected, arm == arm_label)
  fit <- rma(yi = rows$estimate, sei = rows$std.error, method = "FE")
  c(as.numeric(fit$beta), fit$se)
}

table_7 <- tribble(
  ~experiment, ~arm, ~stat, ~corrected,
  "Experiment 1", "Treated", "estimate", coef(model_2_corrected)["condition_factorTreated"],
  "Experiment 1", "Treated", "std.error", model_2_corrected$std.error["condition_factorTreated"],
  "Experiment 1", "Adjacent", "estimate", coef(model_2_corrected)["condition_factorAdjacent"],
  "Experiment 1", "Adjacent", "std.error", model_2_corrected$std.error["condition_factorAdjacent"],
  "Pooled", "Treated", "estimate", pooled("Treated")[1],
  "Pooled", "Treated", "std.error", pooled("Treated")[2],
  "Pooled", "Adjacent", "estimate", pooled("Adjacent")[1],
  "Pooled", "Adjacent", "std.error", pooled("Adjacent")[2]
) |>
  left_join(pivot_longer(table_7_published, c(estimate, std.error), names_to = "stat", values_to = "published"),
            by = c("experiment", "arm", "stat")) |>
  transmute(float = "Table 7", column = experiment, term = str_c(arm, " ", stat), published, corrected)

# Table D.5, Experiment 1 column, and the appendix's pooled interactions ----
fit_d5 <- function(data_full, data_sample) {
  sample_scaled <- data_full |>
    mutate(party_share = as.numeric(scale(pvote08))) |>
    filter(fid %in% data_sample$fid)
  lm_robust(share ~ condition_factor * party_share + dvote10 + dvote08 + dvote06,
            weights = weights, data = sample_scaled, se_type = "HC2")
}
d5_before <- fit_d5(joined, d_published)
d5_after <- fit_d5(corrected, d_corrected)

d5_published <- read_csv(here::here("maintained", "output", "table_8_het_effects.csv"),
                         show_col_types = FALSE)
stopifnot(all.equal(
  unname(coef(d5_before)[filter(d5_published, experiment == "Experiment 1")$term]),
  filter(d5_published, experiment == "Experiment 1")$estimate
))

d5_terms <- filter(d5_published, experiment == "Experiment 1")$term
table_d5 <- bind_rows(
  tibble(term = d5_terms, published = coef(d5_before)[d5_terms], corrected = coef(d5_after)[d5_terms]),
  tibble(term = str_c(d5_terms, " SE"), published = d5_before$std.error[d5_terms], corrected = d5_after$std.error[d5_terms]),
  tibble(term = "R2", published = summary(d5_before)$r.squared, corrected = summary(d5_after)$r.squared)
) |>
  mutate(float = "Table D.5", column = "Experiment 1")

pool_interaction <- function(arm_label) {
  term_name <- str_c("condition_factor", arm_label, ":party_share")
  rows <- filter(d5_published, term == term_name) |>
    arrange(experiment) |>
    mutate(
      estimate = if_else(experiment == "Experiment 1", coef(d5_after)[term_name], estimate),
      std.error = if_else(experiment == "Experiment 1", d5_after$std.error[term_name], std.error)
    )
  fit <- rma(yi = rows$estimate, sei = rows$std.error, method = "FE")
  c(as.numeric(fit$beta), fit$se)
}
interactions_published <- read_csv(here::here("maintained", "output", "text_pooled_interactions.csv"),
                                   show_col_types = FALSE)
pooled_interactions <- interactions_published |>
  mutate(
    corrected_estimate = map_dbl(arm, \(x) pool_interaction(x)[1]),
    corrected_se = map_dbl(arm, \(x) pool_interaction(x)[2])
  )
interactions <- bind_rows(
  transmute(pooled_interactions, float = "Appendix D text", column = "Pooled interaction",
            term = str_c(arm, " estimate"), published = estimate, corrected = corrected_estimate),
  transmute(pooled_interactions, float = "Appendix D text", column = "Pooled interaction",
            term = str_c(arm, " SE"), published = std.error, corrected = corrected_se)
)

# Figure 2 ----
# Every panel's posterior, updated on the corrected Experiment 1 estimate. The closed form
# gives the same state as updating one experiment at a time.
direct_corrected <- filter(table_7_corrected, arm == "Treated") |> arrange(experiment)
figure_2_published <- read_csv(here::here("maintained", "output", "figure_2_bayesian.csv"),
                               show_col_types = FALSE)
priors <- tribble(
  ~scenario, ~prior_mean, ~prior_se,
  "Agnostic", 0, 0.05,
  "Optimist", 0.05, 0.05,
  "Skeptic", 0, 0.01
)
figure_2 <- figure_2_published |>
  filter(time != "Prior") |>
  left_join(priors, by = "scenario") |>
  mutate(
    k = as.numeric(str_extract(time, "\\d")),
    precision = map2_dbl(k, prior_se, \(n, s) 1 / s^2 + sum(1 / direct_corrected$std.error[seq_len(n)]^2)),
    weighted = pmap_dbl(list(k, prior_mean, prior_se), \(n, m, s) {
      m / s^2 + sum(direct_corrected$estimate[seq_len(n)] / direct_corrected$std.error[seq_len(n)]^2)
    }),
    corrected_mean = weighted / precision,
    corrected_se = sqrt(1 / precision),
    corrected_pr = pnorm(0, mean = corrected_mean, sd = corrected_se, lower.tail = FALSE)
  )
figure_2_rows <- bind_rows(
  transmute(figure_2, float = "Figure 2", column = str_c(scenario, ", ", time), term = "posterior mean", published = mean, corrected = corrected_mean),
  transmute(figure_2, float = "Figure 2", column = str_c(scenario, ", ", time), term = "posterior SE", published = se, corrected = corrected_se),
  transmute(figure_2, float = "Figure 2", column = str_c(scenario, ", ", time), term = "pr(ATE>0)", published = pr_pos, corrected = corrected_pr)
)

# Randomization inference, vote share ----
ri_share <- "dvote12 ~ condition_factor + dvote10 + dvote08 + dvote06 + pvote08"
keep <- corrected$treatable == 1
f_obs <- f_treat(ri_share, "condition_factor", "weights", d_corrected)

f_sims <- map_dbl(seq_len(ncol(cond_mat_1)), function(i) {
  cond_sim <- cond_mat_1[, i]
  wts_sim <- case_when(
    cond_sim == 1 ~ 1 / corrected$probs.1.1,
    cond_sim == 2 ~ 1 / corrected$probs.1.0,
    cond_sim == 3 ~ 1 / corrected$probs.0.1,
    cond_sim == 4 ~ 1 / corrected$probs.0.0
  )
  cond_fac <- relevel(factor(cond_sim, levels = 2:4, labels = c("Treated", "Adjacent", "Control")),
                      ref = "Control")
  d_sim <- d_corrected
  d_sim$condition_factor <- cond_fac[keep]
  d_sim$weights <- wts_sim[keep]
  f_treat(ri_share, "condition_factor", "weights", d_sim)
})

ri_published <- read_csv(here::here("maintained", "output", "ri_all_experiments.csv"),
                         show_col_types = FALSE) |>
  filter(experiment == "Experiment 1", outcome == "share") |>
  pull(p_value)
ri <- tibble(float = "Section 5.1 text", column = "Experiment 1", term = "RI p-value",
             published = ri_published, corrected = mean(f_sims >= f_obs))

# Collect ----
results <- bind_rows(table_3, table_7, table_d5, interactions, figure_2_rows, ri) |>
  select(float, column, term, published, corrected)
write_csv(results, here::here("maintained", "output", "text_exp1_merged_shares.csv"))

print(filter(results, float != "Figure 2") |> mutate(across(c(published, corrected), \(x) round(x, 4))), n = Inf)
print(filter(results, float == "Figure 2", round(published, 3) != round(corrected, 3)) |> mutate(across(c(published, corrected), \(x) round(x, 3))), n = Inf)
