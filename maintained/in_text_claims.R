# green_etal_2016/maintained/in_text_claims.R
# Output: printed CLAIM lines, one per published quantity
# Depends on: maintained/output/ (run run_all.R first), ground_truth/published_claims.csv
# Description: The second instrument. Every quantity the article or its online appendix
#   prints is recomputed here from the pipeline's own output files, by a path that does
#   not run through the ground truth, and printed as
#   CLAIM <claim_id> = <value> || <label>. ground_truth/claims_gate.R runs this file,
#   counts the printed claims against the extraction, and compares each value against
#   the ground truth's value_rewrite. Nothing here refits a model or reads the article.

source(here::here("maintained", "helpers.R"))

options(width = 200)

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

# published_claims.csv is the extraction, not the comparison. It is read for two things
# only: the set of claim ids, and the number of decimals the page prints each one at,
# which both instruments must agree on or a correct value fails on its formatting.
claims_meta <- read_csv(
  here::here("ground_truth", "published_claims.csv"),
  col_types = cols(.default = col_character(), value_paper = col_character(),
                   needs_block = col_logical(), digits = col_integer())
)

claim <- function(claim_id, value, label) {
  meta <- claims_meta[claims_meta$claim_id == claim_id, ]
  stopifnot(nrow(meta) == 1, !is.na(meta$digits))
  shown <- if (is.na(value)) "NA" else sprintf(paste0("%.", meta$digits, "f"), value)
  cat(sprintf("CLAIM %s = %s || %s\n", claim_id, shown, label))
}

# One cell out of a tidied regression output. The assertion is what stops a widened
# output file turning a scalar into a vector and a claim into a silent list.
cell <- function(d, ...) {
  hit <- filter(d, ...)
  stopifnot(nrow(hit) == 1)
  hit
}

term_of <- c(treated = "condition_factorTreated",
             adjacent = "condition_factorAdjacent",
             constant = "(Intercept)")

ns <- out("table_2_ns.csv")
share <- list("3" = out("table_3_exp1_share.csv"), "4" = out("table_4_exp2_share.csv"),
              "5" = out("table_5_exp3_share.csv"), "6" = out("table_6_exp4_share.csv"))
pooled <- out("table_7_pooled.csv")
bayes <- out("figure_2_bayesian.csv")
appc <- out("appendix_c_margins_turnout.csv")
het <- out("table_8_het_effects.csv")
ri <- out("ri_all_experiments.csv")
pooled_turnout <- out("text_pooled_turnout.csv")
pooled_int <- out("text_pooled_interactions.csv")
cost <- out("text_footnote_3_cost_per_vote.csv")
clean <- map(1:4, ~ read_rds(here::here("maintained", "output",
                                        sprintf("exp_%d_clean.rds", .x))))

pick <- function(d, pattern) {
  hits <- d$value[str_detect(d$quantity, pattern)]
  stopifnot(length(hits) == 1)
  hits
}

# Experimental design, article section 3 ----

# "Experiment 1 took place across two counties in upstate New York containing a total of
# 97 voting precincts, 88 of which were treatable."
claim("text_design_e1_treatable", ns$Total[ns$study == "Experiment 1"],
      "Experiment 1 precincts in the analysis")

# "In Experiment 2, our initial sample size was 128 precincts in the City of Albany.
# However, because some precincts were regarded by the campaign as 'must-treat'
# locations, our experiment was restricted to 69 precincts."
claim("text_design_e2_initial", nrow(clean[[2]]$data),
      "Experiment 2 precincts before the must-treat exclusions")
claim("text_design_e2_restricted", ns$Total[ns$study == "Experiment 2"],
      "Experiment 2 precincts in the analysis")

# "Experiment 3 took place in 5 of 9 Fairfax County, Virginia districts, comprising a
# total of 131 precincts. Experiment 4 was conducted in 88 of Cumberland County,
# Pennsylvania's 107 voting precincts."
claim("text_design_e3_precincts", ns$Total[ns$study == "Experiment 3"],
      "Experiment 3 precincts in the analysis")
claim("text_design_e4_precincts", ns$Total[ns$study == "Experiment 4"],
      "Experiment 4 precincts in the analysis")

# Footnote 1: "the intent-to-treat effect understates the average treatment effect only
# by a factor of 22/23 = 0.96 in Experiment 1 and 17/20 = 0.85 in Experiment 4."
# The deposit records assignment, not receipt, so only the denominators are checkable.
claim("text_fn1_e1_treated_assigned", ns$Treated[ns$study == "Experiment 1"],
      "Experiment 1 precincts assigned to signs")
claim("text_fn1_e4_treated_assigned", ns$Treated[ns$study == "Experiment 4"],
      "Experiment 4 precincts assigned to signs")

# "We then simulate the distribution of this F-statistic under the sharp null hypothesis
# of no effect by recomputing the F-statistic under 10,000 possible (restricted) random
# assignments."
claim("text_ri_permutations", ncol(clean[[1]]$cond_mat),
      "permutations shipped in the Experiment 1 object")

# Table 2: treatment assignments ----
for (e in 1:4) {
  study <- paste("Experiment", e)
  row <- cell(ns, study == !!study)
  claim(str_glue("t2_e{e}_control"), row$Control, str_glue("Table 2, {study}, control"))
  claim(str_glue("t2_e{e}_adjacent"), row$Adjacent, str_glue("Table 2, {study}, adjacent"))
  claim(str_glue("t2_e{e}_treated"), row$Treated, str_glue("Table 2, {study}, treated"))
  claim(str_glue("t2_e{e}_total"), row$Total, str_glue("Table 2, {study}, total"))
}

# Tables 3 to 6: vote share ----
for (tab in names(share)) {
  d <- share[[tab]]
  e <- as.integer(tab) - 2
  for (m in c("m1", "m2")) {
    for (rn in names(term_of)) {
      k <- cell(d, model == toupper(m), term == term_of[[rn]])
      claim(str_glue("t{tab}_{m}_{rn}_coef"), k$estimate,
            str_glue("Table {tab}, {toupper(m)}, {rn}, coefficient"))
      claim(str_glue("t{tab}_{m}_{rn}_se"), k$std.error,
            str_glue("Table {tab}, {toupper(m)}, {rn}, standard error"))
    }
    claim(str_glue("t{tab}_{m}_n"), unique(d$n), str_glue("Table {tab}, {toupper(m)}, N"))
  }
  claim(str_glue("t{tab}_m1_r2"), unique(d$r2_m1), str_glue("Table {tab}, M1, R2"))
  claim(str_glue("t{tab}_m2_r2"), unique(d$r2_m2), str_glue("Table {tab}, M2, R2"))
  claim(str_glue("t{tab}_label_n_treated"), ns$Treated[ns$study == paste("Experiment", e)],
        str_glue("Table {tab}, treated row label"))
  claim(str_glue("t{tab}_label_n_adjacent"), ns$Adjacent[ns$study == paste("Experiment", e)],
        str_glue("Table {tab}, adjacent row label"))
}

# Results, article sections 5.1 to 5.4 ----
# The tables print proportions and the prose percentage points, so each of these is the
# table's cell times 100, at the one decimal the sentence uses.
t3 <- share[["3"]]
t4 <- share[["4"]]
t5 <- share[["5"]]
t6 <- share[["6"]]

# "Without covariates, the estimated effect of direct treatment on vote share is 2.5
# percentage points (robust SE = 2.7), and the estimated spillover effect is 3.7
# percentage points (robust SE = 2.7)."
claim("text_r1_direct_m1", 100 * cell(t3, model == "M1", term == term_of[["treated"]])$estimate,
      "Experiment 1 unadjusted direct effect, percentage points")
claim("text_r1_direct_m1_se", 100 * cell(t3, model == "M1", term == term_of[["treated"]])$std.error,
      "Experiment 1 unadjusted direct effect standard error, percentage points")
claim("text_r1_spillover_m1", 100 * cell(t3, model == "M1", term == term_of[["adjacent"]])$estimate,
      "Experiment 1 unadjusted spillover effect, percentage points")
claim("text_r1_spillover_m1_se", 100 * cell(t3, model == "M1", term == term_of[["adjacent"]])$std.error,
      "Experiment 1 unadjusted spillover standard error, percentage points")

# "The estimated effect of direct treatment remains 2.5 percentage points, but the
# standard error falls sharply (robust SE = 1.7). The estimated spillover effect
# decreases to 1.8 percentage points, and its standard error falls to 1.6 percentage
# points. Using randomization inference, we fail to reject the joint null hypothesis of
# no direct or indirect effects (p=0.22)."
claim("text_r1_direct_m2", 100 * cell(t3, model == "M2", term == term_of[["treated"]])$estimate,
      "Experiment 1 adjusted direct effect, percentage points")
claim("text_r1_direct_m2_se", 100 * cell(t3, model == "M2", term == term_of[["treated"]])$std.error,
      "Experiment 1 adjusted direct effect standard error, percentage points")
claim("text_r1_spillover_m2", 100 * cell(t3, model == "M2", term == term_of[["adjacent"]])$estimate,
      "Experiment 1 adjusted spillover effect, percentage points")
claim("text_r1_spillover_m2_se", 100 * cell(t3, model == "M2", term == term_of[["adjacent"]])$std.error,
      "Experiment 1 adjusted spillover standard error, percentage points")
claim("text_r1_ri_p", cell(ri, experiment == "Experiment 1", outcome == "share")$p_value,
      "Experiment 1 randomization inference p-value, vote share")

# "Without adjustment, the signs appeared to increase vote share for Sheehan by 0.9
# percentage points, but with adjustment, appeared to decrease her vote share by 1.4
# points. ... The randomization inference test of the joint hypothesis of no direct or
# indirect effect yields a p-value of 0.90."
claim("text_r2_direct_m1", 100 * cell(t4, model == "M1", term == term_of[["treated"]])$estimate,
      "Experiment 2 unadjusted direct effect, percentage points")
claim("text_r2_direct_m2", abs(100 * cell(t4, model == "M2", term == term_of[["treated"]])$estimate),
      "Experiment 2 adjusted direct effect, percentage points, size of the decrease")
claim("text_r2_ri_p", cell(ri, experiment == "Experiment 2", outcome == "share")$p_value,
      "Experiment 2 randomization inference p-value, vote share")

# "Cuccinelli's vote share increased by 1.8 percentage points in treated precincts and
# 1.8 percentage points in adjacent precincts. A randomization inference test of the
# joint null hypothesis that neither direct nor adjacent signs affected outcomes
# generates a p-value of 0.02."
claim("text_r3_direct_m2", 100 * cell(t5, model == "M2", term == term_of[["treated"]])$estimate,
      "Experiment 3 adjusted direct effect, percentage points")
claim("text_r3_spillover_m2", 100 * cell(t5, model == "M2", term == term_of[["adjacent"]])$estimate,
      "Experiment 3 adjusted spillover effect, percentage points")
claim("text_r3_ri_p", cell(ri, experiment == "Experiment 3", outcome == "share")$p_value,
      "Experiment 3 randomization inference p-value, vote share")

# "directly treated precincts saw 1.2 percentage points lower vote share for Eichelberger
# and Schin; indirect treatment decreased vote share by 2.0 points. ... The randomization
# inference test shows that we cannot reject the null hypothesis no direct or indirect
# effects (p = 0.77)."
claim("text_r4_direct_m2", abs(100 * cell(t6, model == "M2", term == term_of[["treated"]])$estimate),
      "Experiment 4 adjusted direct effect, percentage points, size of the decrease")
claim("text_r4_spillover_m2", abs(100 * cell(t6, model == "M2", term == term_of[["adjacent"]])$estimate),
      "Experiment 4 adjusted spillover effect, percentage points, size of the decrease")
claim("text_r4_ri_p", cell(ri, experiment == "Experiment 4", outcome == "share")$p_value,
      "Experiment 4 randomization inference p-value, vote share")

# Effects on turnout, article section 5.5 ----

# "We find that lawn signs had essentially no effect on turnout. Pooling the
# covariate-adjusted estimates according to Equation (3) below, we find that direct
# effect of lawn signs on total votes cast in a precinct was 7.2 votes, with a standard
# error of 9.5 votes."
turnout_direct <- cell(pooled_turnout, arm == "Treated")
claim("text_turnout_pooled_direct", turnout_direct$estimate,
      "pooled direct effect on votes cast")
claim("text_turnout_pooled_direct_se", turnout_direct$std.error,
      "pooled direct effect on votes cast, standard error")
# The descriptive half of the sentence: no turnout estimate, pooled or per experiment,
# reaches conventional significance.
turnout_cells <- filter(appc, outcome == "turnout", model == "M2",
                        str_detect(term, "condition_factor"))
claim("text_turnout_no_effect",
      as.numeric(all(abs(turnout_cells$estimate / turnout_cells$std.error) < 1.96) &
                 abs(turnout_direct$estimate / turnout_direct$std.error) < 1.96),
      "1 if no turnout estimate, per experiment or pooled, reaches |t| = 1.96")

# Table 7: pooled vote share ----
exp_label <- c(e1 = "Experiment 1", e2 = "Experiment 2", e3 = "Experiment 3",
               e4 = "Experiment 4", pooled = "Pooled")
arm_label <- c(direct = "Treated", indirect = "Adjacent")
for (a in names(arm_label)) {
  for (rn in names(exp_label)) {
    k <- cell(pooled, experiment == exp_label[[rn]], arm == arm_label[[a]])
    claim(str_glue("t7_{a}_{rn}_coef"), k$estimate,
          str_glue("Table 7, {exp_label[[rn]]}, {a} effect"))
    claim(str_glue("t7_{a}_{rn}_se"), k$std.error,
          str_glue("Table 7, {exp_label[[rn]]}, {a} effect standard error"))
  }
}

# Bayesian integration, article section 6 ----

# "As shown in Table 7, the pooled estimate of average effect of lawn signs in directly
# treated precincts is 1.7 percentage points, with a standard error of 0.7 percentage
# points. The corresponding pooled estimate for the average effect of adjacency is 1.5
# percentage points, with a standard error of 0.6 percentage points. It appears that
# signs on average raise vote shares by just over one percentage point."
pooled_direct <- cell(pooled, experiment == "Pooled", arm == "Treated")
pooled_indirect <- cell(pooled, experiment == "Pooled", arm == "Adjacent")
claim("text_pooled_direct", 100 * pooled_direct$estimate, "pooled direct effect, percentage points")
claim("text_pooled_direct_se", 100 * pooled_direct$std.error,
      "pooled direct effect standard error, percentage points")
claim("text_pooled_indirect", 100 * pooled_indirect$estimate,
      "pooled spillover effect, percentage points")
claim("text_pooled_indirect_se", 100 * pooled_indirect$std.error,
      "pooled spillover effect standard error, percentage points")
claim("text_pooled_just_over_one",
      as.numeric(100 * pooled_direct$estimate > 1 & 100 * pooled_direct$estimate < 2),
      "1 if the pooled direct effect is between one and two percentage points")

# "The agnostic and the optimist are assumed to have diffuse priors whose standard
# deviations are 5 percentage points, whereas the skeptic's prior has a standard
# deviation of 1 percentage point."
claim("text_prior_diffuse_sd",
      100 * cell(bayes, scenario == "Agnostic", time == "Prior")$se,
      "diffuse prior standard deviation, percentage points")
claim("text_prior_skeptic_sd",
      100 * cell(bayes, scenario == "Skeptic", time == "Prior")$se,
      "skeptical prior standard deviation, percentage points")

# "The agnostic observer (row 1), concludes that there is a 98.8 percent chance that lawn
# signs increase the vote share of the advertising candidate. The optimistic observer
# (row 2) puts this probability at 0.991, and even the initial skeptic (row 3) concludes
# that this probability is 0.966."
claim("text_agnostic_pr",
      100 * cell(bayes, scenario == "Agnostic", time == "Update 4")$pr_pos,
      "agnostic posterior probability the effect is positive, per cent")
claim("text_optimist_pr",
      cell(bayes, scenario == "Optimist", time == "Update 4")$pr_pos,
      "optimistic posterior probability the effect is positive")
claim("text_skeptic_pr",
      cell(bayes, scenario == "Skeptic", time == "Update 4")$pr_pos,
      "skeptical posterior probability the effect is positive")

# Figure 2: the panel labels ----
scen_label <- c(agnostic = "Agnostic", optimist = "Optimist", skeptic = "Skeptic")
time_label <- c(prior = "Prior", u1 = "Update 1", u2 = "Update 2", u3 = "Update 3",
                u4 = "Update 4")
for (s in names(scen_label)) {
  for (tm in names(time_label)) {
    k <- cell(bayes, scenario == scen_label[[s]], time == time_label[[tm]])
    lab <- str_glue("Figure 2, {scen_label[[s]]}, {time_label[[tm]]}")
    claim(str_glue("f2_{s}_{tm}_mean"), k$mean, str_glue("{lab}, posterior mean"))
    claim(str_glue("f2_{s}_{tm}_sd"), k$se, str_glue("{lab}, posterior standard deviation"))
    claim(str_glue("f2_{s}_{tm}_pr"), k$pr_pos, str_glue("{lab}, pr(ATE > 0)"))
  }
}

# Footnote 3: cost per vote ----

# "Considering only the direct effect, we estimate the cost per vote across all four
# experiments to be $3.18, with a 95% confidence interval extending from $1.70 to
# $13.71. This figure is calculated from total turnout (241,613), the direct effect (1.7
# points), and the total cost ($13,045): $13,045/(241,613 * 0.017) = $3.18. If we include
# indirect effects in this calculation, the cost per vote drops to $1.69."
claim("text_fn3_total_turnout", pick(cost, "^total turnout$"),
      "votes cast across the four experiments")
claim("text_fn3_total_cost", pick(cost, "^total cost$"), "total spent on signs, dollars")
claim("text_fn3_direct_points", 100 * pooled_direct$estimate,
      "pooled direct effect, percentage points, as quoted in the footnote")
claim("text_fn3_cost_direct", pick(cost, "^cost per vote, direct effect only$"),
      "cost per vote at the direct effect, dollars")
claim("text_fn3_cost_total", pick(cost, "^cost per vote, direct and indirect$"),
      "cost per vote including spillovers, dollars")
claim("text_fn3_ci_level", pick(cost, "^interval level"), "interval level, per cent")
# The archive draws the interval unseeded, so what is checkable is the endpoint's
# central value over repeated draws rather than any single one.
claim("text_fn3_ci_low", pick(cost, "^interval lower endpoint, median"),
      "lower interval endpoint, median over 200 seeds, dollars")
claim("text_fn3_ci_high", pick(cost, "^interval upper endpoint, median"),
      "upper interval endpoint, median over 200 seeds, dollars")

# Appendix B: randomization protocols ----

# "Five precincts were deemed untreatable because they had no public land."
claim("appb_e1_untreatable", sum(clean[[1]]$data$treatable == 0),
      "Experiment 1 precincts excluded as untreatable")

# "We repeated this procedure until we had 10,000 possible randomizations from which we
# selected (at random) the actual randomization to be deployed in the experiment."
claim("appb_e2_permutations", ncol(clean[[2]]$cond_mat),
      "Experiment 2 permutations shipped in the deposit")

# "30 of 131 precincts were assigned to treatment such that no adjacent precincts were
# also assigned to treatment. 100,000 such randomizations were generated; this full set
# was restricted to 10,000 randomizations."
claim("appb_e3_treated", ns$Treated[ns$study == "Experiment 3"],
      "Experiment 3 precincts assigned to signs")
claim("appb_e3_precincts", ns$Total[ns$study == "Experiment 3"],
      "Experiment 3 precincts")
claim("appb_e3_permutations", ncol(clean[[3]]$cond_mat),
      "Experiment 3 permutations shipped in the deposit")

# "In Pennsylvania, we first conducted 100,000 complete random assignments in which 20 of
# our 88 precincts were assigned to receive signs. ... We collected 10,000 random
# assignments meeting this criterion."
claim("appb_e4_treated", ns$Treated[ns$study == "Experiment 4"],
      "Experiment 4 precincts assigned to signs")
claim("appb_e4_precincts", ns$Total[ns$study == "Experiment 4"],
      "Experiment 4 precincts")
claim("appb_e4_permutations", ncol(clean[[4]]$cond_mat),
      "Experiment 4 permutations shipped in the deposit")

# Appendix Tables C.1 to C.4: margin and turnout ----
out_label <- c(margin = "margin", turnout = "turnout")
for (e in 1:4) {
  study <- paste("Experiment", e)
  for (o in names(out_label)) {
    for (m in c("m1", "m2")) {
      for (rn in names(term_of)) {
        k <- cell(appc, experiment == !!study, outcome == out_label[[o]],
                  model == toupper(m), term == term_of[[rn]])
        lab <- str_glue("Table C.{e}, {o}, {toupper(m)}, {rn}")
        claim(str_glue("c{e}_{o}_{m}_{rn}_coef"), k$estimate, str_glue("{lab}, coefficient"))
        claim(str_glue("c{e}_{o}_{m}_{rn}_se"), k$std.error, str_glue("{lab}, standard error"))
      }
      block <- filter(appc, experiment == !!study, outcome == out_label[[o]],
                      model == toupper(m))
      claim(str_glue("c{e}_{o}_{m}_n"), unique(block$n), str_glue("Table C.{e}, {o}, {toupper(m)}, N"))
      claim(str_glue("c{e}_{o}_{m}_r2"), unique(block$r2), str_glue("Table C.{e}, {o}, {toupper(m)}, R2"))
    }
  }
  claim(str_glue("c{e}_label_n_treated"), ns$Treated[ns$study == study],
        str_glue("Table C.{e}, treated row label"))
  claim(str_glue("c{e}_label_n_adjacent"), ns$Adjacent[ns$study == study],
        str_glue("Table C.{e}, adjacent row label"))
}

# Appendix Table D.5: heterogeneous effects ----
het_term <- c(treated = "condition_factorTreated", adjacent = "condition_factorAdjacent",
              support = "party_share", treated_x = "condition_factorTreated:party_share",
              adjacent_x = "condition_factorAdjacent:party_share", constant = "(Intercept)")
for (e in 1:4) {
  study <- paste("Experiment", e)
  for (rn in names(het_term)) {
    k <- cell(het, experiment == !!study, term == het_term[[rn]])
    lab <- str_glue("Table D.5, {study}, {rn}")
    claim(str_glue("d5_e{e}_{rn}_coef"), k$estimate, str_glue("{lab}, coefficient"))
    claim(str_glue("d5_e{e}_{rn}_se"), k$std.error, str_glue("{lab}, standard error"))
  }
  block <- filter(het, experiment == !!study)
  claim(str_glue("d5_e{e}_n"), unique(block$n), str_glue("Table D.5, {study}, N"))
  claim(str_glue("d5_e{e}_r2"), unique(block$r2), str_glue("Table D.5, {study}, R2"))
}

# Appendix D text ----

# "When we pool the interaction terms by taking a precision-weighted average across
# experiments, we estimate that the average interaction effect for the direct treatment
# is 0.009 with a standard error of 0.007. The estimated average interaction effect for
# the indirect treatment is 0.007, with a standard error of 0.007."
int_direct <- cell(pooled_int, arm == "Treated")
int_indirect <- cell(pooled_int, arm == "Adjacent")
claim("appd_pooled_direct_interaction", int_direct$estimate,
      "pooled direct-treatment interaction with party support")
claim("appd_pooled_direct_interaction_se", int_direct$std.error,
      "pooled direct-treatment interaction, standard error")
claim("appd_pooled_indirect_interaction", int_indirect$estimate,
      "pooled spillover interaction with party support")
claim("appd_pooled_indirect_interaction_se", int_indirect$std.error,
      "pooled spillover interaction, standard error")

# "None of the coefficients on the interaction terms are estimated with sufficient
# precision to make confident claims about treatment effect heterogeneity. ... Three of
# the four experiments show interactions in line with this hypothesis. In experiments 1,
# 2, and 3, we observe positive interactions. The signs of the interaction coefficients
# for experiment 4 do not match this theory: the signs of the interactions are negative."
interactions <- het |>
  filter(str_detect(term, ":party_share")) |>
  mutate(t_stat = estimate / std.error)
claim("appd_no_precise_interactions", as.numeric(all(abs(interactions$t_stat) < 1.96)),
      "1 if no interaction coefficient reaches |t| = 1.96")
by_experiment <- interactions |>
  summarize(all_positive = all(estimate > 0), all_negative = all(estimate < 0),
            .by = experiment)
claim("appd_three_of_four_positive", sum(by_experiment$all_positive),
      "experiments whose two interaction coefficients are both positive")
claim("appd_e4_negative_interactions",
      as.numeric(by_experiment$all_negative[by_experiment$experiment == "Experiment 4"]),
      "1 if both of Experiment 4's interaction coefficients are negative")
