# green_etal_2016/ground_truth/build_ground_truth.R
# Output: ground_truth/green_etal_2016_ground_truth.csv
# Depends on: ground_truth/published_claims.csv, ground_truth/archive_values.csv,
#   maintained/output/ (run the maintained scripts first)
# Description: Assemble the ground truth. value_paper comes from published_claims.csv,
#   the hand-reviewed extraction of every numeric token in the article and the online
#   appendix, and from nowhere else. value_script comes from archive_values.csv, the
#   values the deposited scripts themselves print. value_rewrite is read back out of
#   maintained/output/ here, by a different route from the one maintained/in_text_claims.R
#   takes, and the two are compared at the end: a disagreement between them is a finding.
#   No published number is an input to any computation in maintained/.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

# A column whose entries all look numeric is guessed as double, which silently turns the
# article's 0.020 into 0.02 and destroys the printed precision every comparison here
# depends on. Every reader of this file forces the type, this one included.
claims <- read_csv(
  here::here("ground_truth", "published_claims.csv"),
  col_types = cols(.default = col_character(), value_paper = col_character(),
                   needs_block = col_logical(), digits = col_integer())
)
stopifnot(!any(duplicated(claims$claim_id)))

archive <- read_csv(here::here("ground_truth", "archive_values.csv"),
                    col_types = cols(claim_id = col_character(),
                                     value_script = col_double()))
stopifnot(!any(duplicated(archive$claim_id)))

# Every join below goes through this, which asserts uniqueness on both sides and a
# one-to-one result, because a join that silently finds nothing is the failure this
# whole file exists to prevent.
join_one <- function(x, y, by) {
  stopifnot(!any(duplicated(x[[by]])), !any(duplicated(y[[by]])))
  joined <- left_join(x, y, by = by)
  stopifnot(nrow(joined) == nrow(x))
  joined
}

# The rewrite's own values, keyed by claim_id ----
# Each output file is reshaped into (claim_id, value_rewrite). in_text_claims.R selects
# the same numbers cell by cell instead; the two paths meet at the cross-check below.
row_of_term <- c("condition_factorTreated" = "treated",
                 "condition_factorAdjacent" = "adjacent",
                 "(Intercept)" = "constant")

ns <- out("table_2_ns.csv")
ns_long <- ns |>
  mutate(e = str_extract(study, "\\d")) |>
  pivot_longer(c(Control, Adjacent, Treated, Total), names_to = "cell",
               values_to = "value_rewrite") |>
  transmute(claim_id = str_glue("t2_e{e}_{str_to_lower(cell)}"), value_rewrite)

# The row labels of Tables 3 to 6 and C.1 to C.4 quote the same arm counts.
label_ns <- ns |>
  mutate(e = as.integer(str_extract(study, "\\d"))) |>
  pivot_longer(c(Adjacent, Treated), names_to = "arm", values_to = "value_rewrite") |>
  reframe(claim_id = c(str_glue("t{e + 2}_label_n_{str_to_lower(arm)}"),
                       str_glue("c{e}_label_n_{str_to_lower(arm)}")),
          value_rewrite = rep(value_rewrite, 2))

share_files <- c("3" = "table_3_exp1_share.csv", "4" = "table_4_exp2_share.csv",
                 "5" = "table_5_exp3_share.csv", "6" = "table_6_exp4_share.csv")
share_long <- imap(share_files, function(f, tab) {
  d <- out(f)
  cells <- d |>
    filter(term %in% names(row_of_term)) |>
    mutate(rn = row_of_term[term], m = str_to_lower(model)) |>
    select(rn, m, coef = estimate, se = std.error) |>
    pivot_longer(c(coef, se), names_to = "stat", values_to = "value_rewrite") |>
    transmute(claim_id = str_glue("t{tab}_{m}_{rn}_{stat}"), value_rewrite)
  bind_rows(
    cells,
    tibble(claim_id = c(str_glue("t{tab}_m1_n"), str_glue("t{tab}_m2_n"),
                        str_glue("t{tab}_m1_r2"), str_glue("t{tab}_m2_r2")),
           value_rewrite = c(unique(d$n), unique(d$n), unique(d$r2_m1), unique(d$r2_m2)))
  )
}) |> list_rbind()

pooled <- out("table_7_pooled.csv")
pooled_long <- pooled |>
  mutate(rn = if_else(experiment == "Pooled", "pooled",
                      str_glue("e{str_extract(experiment, '\\\\d')}")),
         a = if_else(arm == "Treated", "direct", "indirect")) |>
  select(rn, a, coef = estimate, se = std.error) |>
  pivot_longer(c(coef, se), names_to = "stat", values_to = "value_rewrite") |>
  transmute(claim_id = str_glue("t7_{a}_{rn}_{stat}"), value_rewrite)

bayes <- out("figure_2_bayesian.csv")
scen_key <- c("Agnostic" = "agnostic", "Optimist" = "optimist", "Skeptic" = "skeptic")
time_key <- c("Prior" = "prior", "Update 1" = "u1", "Update 2" = "u2",
              "Update 3" = "u3", "Update 4" = "u4")
bayes_long <- bayes |>
  transmute(s = scen_key[as.character(scenario)], tm = time_key[as.character(time)],
            mean, sd = se, pr = pr_pos) |>
  pivot_longer(c(mean, sd, pr), names_to = "stat", values_to = "value_rewrite") |>
  transmute(claim_id = str_glue("f2_{s}_{tm}_{stat}"), value_rewrite)

appc <- out("appendix_c_margins_turnout.csv")
appc_cells <- appc |>
  filter(term %in% names(row_of_term)) |>
  mutate(e = str_extract(experiment, "\\d"), rn = row_of_term[term],
         m = str_to_lower(model)) |>
  select(e, outcome, m, rn, coef = estimate, se = std.error) |>
  pivot_longer(c(coef, se), names_to = "stat", values_to = "value_rewrite") |>
  transmute(claim_id = str_glue("c{e}_{outcome}_{m}_{rn}_{stat}"), value_rewrite)
appc_foot <- appc |>
  summarize(n = unique(n), r2 = unique(r2), .by = c(experiment, outcome, model)) |>
  mutate(e = str_extract(experiment, "\\d"), m = str_to_lower(model)) |>
  pivot_longer(c(n, r2), names_to = "stat", values_to = "value_rewrite") |>
  transmute(claim_id = str_glue("c{e}_{outcome}_{m}_{stat}"), value_rewrite)

het <- out("table_8_het_effects.csv")
het_row <- c("condition_factorTreated" = "treated",
             "condition_factorAdjacent" = "adjacent",
             "party_share" = "support",
             "condition_factorTreated:party_share" = "treated_x",
             "condition_factorAdjacent:party_share" = "adjacent_x",
             "(Intercept)" = "constant")
het_cells <- het |>
  mutate(e = str_extract(experiment, "\\d"), rn = het_row[term]) |>
  select(e, rn, coef = estimate, se = std.error) |>
  pivot_longer(c(coef, se), names_to = "stat", values_to = "value_rewrite") |>
  transmute(claim_id = str_glue("d5_e{e}_{rn}_{stat}"), value_rewrite)
het_foot <- het |>
  summarize(n = unique(n), r2 = unique(r2), .by = experiment) |>
  mutate(e = str_extract(experiment, "\\d")) |>
  pivot_longer(c(n, r2), names_to = "stat", values_to = "value_rewrite") |>
  transmute(claim_id = str_glue("d5_e{e}_{stat}"), value_rewrite)

# Prose ----
ri <- out("ri_all_experiments.csv") |> filter(outcome == "share")
ri_long <- ri |>
  transmute(claim_id = str_glue("text_r{str_extract(experiment, '\\\\d')}_ri_p"),
            value_rewrite = p_value)

cost <- out("text_footnote_3_cost_per_vote.csv")
pick <- function(pattern) {
  hits <- cost$value[str_detect(cost$quantity, pattern)]
  stopifnot(length(hits) == 1)
  hits
}

pooled_turnout <- out("text_pooled_turnout.csv")
pooled_int <- out("text_pooled_interactions.csv")
clean <- map(1:4, ~ read_rds(here::here("maintained", "output",
                                        sprintf("exp_%d_clean.rds", .x))))

share_cell <- function(tab, model_label, rn, stat) {
  d <- out(share_files[[as.character(tab)]])
  hit <- filter(d, model == model_label, row_of_term[term] == rn)
  stopifnot(nrow(hit) == 1)
  if (stat == "coef") hit$estimate else hit$std.error
}

turnout_cells <- appc |>
  filter(outcome == "turnout", model == "M2", term %in% names(row_of_term),
         row_of_term[term] != "constant")
interactions <- het |>
  filter(str_detect(term, ":party_share")) |>
  mutate(t_stat = estimate / std.error)
by_experiment <- interactions |>
  summarize(all_positive = all(estimate > 0), all_negative = all(estimate < 0),
            .by = experiment)

prose <- tribble(
  ~claim_id, ~value_rewrite,
  "text_design_e1_treatable", ns$Total[ns$study == "Experiment 1"],
  "text_design_e2_initial", nrow(clean[[2]]$data),
  "text_design_e2_restricted", ns$Total[ns$study == "Experiment 2"],
  "text_design_e3_precincts", ns$Total[ns$study == "Experiment 3"],
  "text_design_e4_precincts", ns$Total[ns$study == "Experiment 4"],
  "text_fn1_e1_treated_assigned", ns$Treated[ns$study == "Experiment 1"],
  "text_fn1_e4_treated_assigned", ns$Treated[ns$study == "Experiment 4"],
  "text_ri_permutations", ncol(clean[[1]]$cond_mat),
  "text_r1_direct_m1", 100 * share_cell(3, "M1", "treated", "coef"),
  "text_r1_direct_m1_se", 100 * share_cell(3, "M1", "treated", "se"),
  "text_r1_spillover_m1", 100 * share_cell(3, "M1", "adjacent", "coef"),
  "text_r1_spillover_m1_se", 100 * share_cell(3, "M1", "adjacent", "se"),
  "text_r1_direct_m2", 100 * share_cell(3, "M2", "treated", "coef"),
  "text_r1_direct_m2_se", 100 * share_cell(3, "M2", "treated", "se"),
  "text_r1_spillover_m2", 100 * share_cell(3, "M2", "adjacent", "coef"),
  "text_r1_spillover_m2_se", 100 * share_cell(3, "M2", "adjacent", "se"),
  "text_r2_direct_m1", 100 * share_cell(4, "M1", "treated", "coef"),
  "text_r2_direct_m2", abs(100 * share_cell(4, "M2", "treated", "coef")),
  "text_r3_direct_m2", 100 * share_cell(5, "M2", "treated", "coef"),
  "text_r3_spillover_m2", 100 * share_cell(5, "M2", "adjacent", "coef"),
  "text_r4_direct_m2", abs(100 * share_cell(6, "M2", "treated", "coef")),
  "text_r4_spillover_m2", abs(100 * share_cell(6, "M2", "adjacent", "coef")),
  "text_turnout_pooled_direct", pooled_turnout$estimate[pooled_turnout$arm == "Treated"],
  "text_turnout_pooled_direct_se", pooled_turnout$std.error[pooled_turnout$arm == "Treated"],
  "text_turnout_no_effect",
    as.numeric(all(abs(turnout_cells$estimate / turnout_cells$std.error) < 1.96) &
               abs(pooled_turnout$estimate[pooled_turnout$arm == "Treated"] /
                   pooled_turnout$std.error[pooled_turnout$arm == "Treated"]) < 1.96),
  "text_pooled_direct", 100 * pooled$estimate[pooled$experiment == "Pooled" & pooled$arm == "Treated"],
  "text_pooled_direct_se", 100 * pooled$std.error[pooled$experiment == "Pooled" & pooled$arm == "Treated"],
  "text_pooled_indirect", 100 * pooled$estimate[pooled$experiment == "Pooled" & pooled$arm == "Adjacent"],
  "text_pooled_indirect_se", 100 * pooled$std.error[pooled$experiment == "Pooled" & pooled$arm == "Adjacent"],
  "text_pooled_just_over_one",
    as.numeric(100 * pooled$estimate[pooled$experiment == "Pooled" & pooled$arm == "Treated"] > 1 &
               100 * pooled$estimate[pooled$experiment == "Pooled" & pooled$arm == "Treated"] < 2),
  "text_prior_diffuse_sd", 100 * bayes$se[bayes$scenario == "Agnostic" & bayes$time == "Prior"],
  "text_prior_skeptic_sd", 100 * bayes$se[bayes$scenario == "Skeptic" & bayes$time == "Prior"],
  "text_agnostic_pr", 100 * bayes$pr_pos[bayes$scenario == "Agnostic" & bayes$time == "Update 4"],
  "text_optimist_pr", bayes$pr_pos[bayes$scenario == "Optimist" & bayes$time == "Update 4"],
  "text_skeptic_pr", bayes$pr_pos[bayes$scenario == "Skeptic" & bayes$time == "Update 4"],
  "text_fn3_total_turnout", pick("^total turnout$"),
  "text_fn3_total_cost", pick("^total cost$"),
  "text_fn3_direct_points", 100 * pooled$estimate[pooled$experiment == "Pooled" & pooled$arm == "Treated"],
  "text_fn3_cost_direct", pick("^cost per vote, direct effect only$"),
  "text_fn3_cost_total", pick("^cost per vote, direct and indirect$"),
  "text_fn3_ci_level", pick("^interval level"),
  "text_fn3_ci_low", pick("^interval lower endpoint, median"),
  "text_fn3_ci_high", pick("^interval upper endpoint, median"),
  "appb_e1_untreatable", sum(clean[[1]]$data$treatable == 0),
  "appb_e2_permutations", ncol(clean[[2]]$cond_mat),
  "appb_e3_treated", ns$Treated[ns$study == "Experiment 3"],
  "appb_e3_precincts", ns$Total[ns$study == "Experiment 3"],
  "appb_e3_permutations", ncol(clean[[3]]$cond_mat),
  "appb_e4_treated", ns$Treated[ns$study == "Experiment 4"],
  "appb_e4_precincts", ns$Total[ns$study == "Experiment 4"],
  "appb_e4_permutations", ncol(clean[[4]]$cond_mat),
  "appd_pooled_direct_interaction", pooled_int$estimate[pooled_int$arm == "Treated"],
  "appd_pooled_direct_interaction_se", pooled_int$std.error[pooled_int$arm == "Treated"],
  "appd_pooled_indirect_interaction", pooled_int$estimate[pooled_int$arm == "Adjacent"],
  "appd_pooled_indirect_interaction_se", pooled_int$std.error[pooled_int$arm == "Adjacent"],
  "appd_no_precise_interactions", as.numeric(all(abs(interactions$t_stat) < 1.96)),
  "appd_three_of_four_positive", sum(by_experiment$all_positive),
  "appd_e4_negative_interactions",
    as.numeric(by_experiment$all_negative[by_experiment$experiment == "Experiment 4"])
)

rewrite <- bind_rows(ns_long, label_ns, share_long, pooled_long, bayes_long,
                     appc_cells, appc_foot, het_cells, het_foot, ri_long, prose) |>
  mutate(claim_id = as.character(claim_id))
stopifnot(!any(duplicated(rewrite$claim_id)))

# A published value with no rewrite counterpart must be a claim the pipeline genuinely
# cannot reach, never a mistyped label, so every id the rewrite offers has to be one the
# article makes.
stopifnot(length(setdiff(rewrite$claim_id, claims$claim_id)) == 0)

# Verdicts ----
# A value agrees when the rewrite's number, printed to the page's own precision, gives
# the digits the page gives. A numeric tolerance cannot be read off value_paper, because
# a double does not record how many decimals the article printed.
printed <- function(value, digits) {
  if_else(is.na(value), NA_character_, sprintf(paste0("%.", digits, "f"), value))
}

gt <- claims |>
  join_one(archive, "claim_id") |>
  join_one(rewrite, "claim_id") |>
  mutate(
    paper_id = "green_etal_2016",
    script_printed = printed(value_script, digits),
    rewrite_printed = printed(value_rewrite, digits),
    match = if_else(is.na(script_printed), NA_real_,
                    as.numeric(script_printed == value_paper)),
    match_rewrite = if_else(is.na(rewrite_printed), NA_real_,
                            as.numeric(rewrite_printed == value_paper))
  )

# Two classes of row carry their verdict in holds rather than in match_rewrite: a
# descriptive claim, which has no printed number to compare, and the two endpoints of
# footnote 3's interval, which the deposit draws unseeded so that no single value is the
# published one.
unseeded <- c(text_fn3_ci_low = "^interval lower endpoint",
              text_fn3_ci_high = "^interval upper endpoint")
within_seeds <- map_dbl(names(unseeded), function(id) {
  stem <- unseeded[[id]]
  target <- parse_double(claims$value_paper[claims$claim_id == id])
  as.numeric(target >= pick(paste0(stem, ", minimum")) &
             target <= pick(paste0(stem, ", maximum")))
})
names(within_seeds) <- names(unseeded)

gt <- gt |>
  mutate(
    holds = case_when(
      claim_type == "descriptive" ~ as.numeric(value_rewrite == parse_double(value_paper)),
      claim_id %in% names(unseeded) ~ unname(within_seeds[claim_id]),
      .default = NA_real_
    ),
    match_rewrite = if_else(claim_type == "descriptive" | claim_id %in% names(unseeded),
                            NA_real_, match_rewrite),
    match = if_else(claim_type == "descriptive" | claim_id %in% names(unseeded),
                    NA_real_, match)
  )

# defect_locus ----
# Experiment 2's published analysis was deployed on permutation column 7210, which is
# what exp_2.RData stores. Running the deposited Experiment_2_Analysis.R on R 3.6 or
# later redraws set.seed(12345); sample(1:10000, 1) and gets column 8243 instead, so
# every Experiment 2 cell the deposited script prints today differs from the published
# one while the rewrite, reading the deployed assignment, reproduces it. That is the
# signature of environment drift: the archive fails and the rewrite succeeds.
sampler_rows <- gt$claim_id[str_detect(gt$claim_id, "^(t4_|c2_|text_r2_)")]

gt <- gt |>
  mutate(
    defect_locus = case_when(
      claim_id %in% sampler_rows & !is.na(match) & match == 0 ~ "environment",
      !is.na(match) & match == 0 ~ "unresolved",
      !is.na(match_rewrite) & match_rewrite == 0 ~ "unresolved",
      !is.na(holds) & holds == 0 ~ "unresolved",
      .default = NA_character_
    )
  )

# THE LOCUS RULE, three states. An adverse row, meaning either verdict is 0 or holds is
# 0, must carry a locus. A clean match must not. A row with no verdict may.
adverse <- (!is.na(gt$match) & gt$match == 0) |
  (!is.na(gt$match_rewrite) & gt$match_rewrite == 0) |
  (!is.na(gt$holds) & gt$holds == 0)
clean <- (!is.na(gt$match_rewrite) & gt$match_rewrite == 1) &
  (is.na(gt$match) | gt$match == 1) & is.na(gt$holds)
stopifnot(all(!is.na(gt$defect_locus[adverse])), all(is.na(gt$defect_locus[clean])))

# Notes, computed from the same comparison that set the verdict ----
gt <- gt |>
  mutate(
    verdict_clause = case_when(
      !is.na(match_rewrite) & match_rewrite == 1 & !is.na(match) & match == 0 ~
        str_glue("The deposited scripts print {script_printed} where the article prints {value_paper}; the rewrite reproduces the article."),
      !is.na(match_rewrite) & match_rewrite == 1 ~
        str_glue("Reproduced at the precision the page prints: {rewrite_printed}."),
      !is.na(match_rewrite) & match_rewrite == 0 ~
        str_glue("The rewrite gives {rewrite_printed} where the article prints {value_paper}."),
      !is.na(holds) & holds == 1 ~ "The claim holds against the pipeline's own estimates.",
      !is.na(holds) & holds == 0 ~ "The claim does not hold against the pipeline's own estimates.",
      is.na(value_rewrite) ~ "No counterpart in the pipeline; verified at the point of use.",
      .default = "No verdict."
    ),
    coverage_clause = case_when(
      claim_type == "transcribed" ~
        " The value comes from outside the deposit and cannot be checked against it.",
      claim_type %in% c("structural", "definitional") & is.na(value_rewrite) ~
        " A design fact the deposit does not record.",
      is.na(value_script) & !is.na(value_rewrite) ~
        " The deposited scripts print no counterpart to this value.",
      .default = ""
    ),
    notes = str_c(verdict_clause, coverage_clause)
  )

# claim_id is the claim: it names the float, the row, the column and the statistic, and
# it is the key maintained/in_text_claims.R prints and the gate matches on. A separate
# prose restatement of it would be a second description free to drift from the first.
gt_out <- gt |>
  transmute(paper_id, claim_id, table_figure = location, claim_type,
            value_script, value_paper, match, value_rewrite, match_rewrite, holds,
            defect_locus, notes) |>
  arrange(table_figure, claim_id, .locale = "en")

write_csv(gt_out, here::here("ground_truth", "green_etal_2016_ground_truth.csv"))

# Coverage, checked against the extraction and against the second instrument ----
required <- claims$claim_id[claims$claim_type %in% c("pipeline", "descriptive")]
stopifnot(length(setdiff(required, gt_out$claim_id)) == 0,
          length(setdiff(gt_out$claim_id, claims$claim_id)) == 0)

source(here::here("ground_truth", "claims_gate.R"))

print(tibble(
  quantity = c("extraction rows", "ground-truth rows", "locations covered",
               "archive comparable", "archive matching",
               "rewrite comparable", "rewrite matching", "rewrite differing",
               "descriptive and unseeded claims judged", "of which hold",
               "rows with a defect locus"),
  value = c(nrow(claims), nrow(gt_out), n_distinct(gt_out$table_figure),
            sum(!is.na(gt_out$match)), sum(gt_out$match == 1, na.rm = TRUE),
            sum(!is.na(gt_out$match_rewrite)), sum(gt_out$match_rewrite == 1, na.rm = TRUE),
            sum(gt_out$match_rewrite == 0, na.rm = TRUE),
            sum(!is.na(gt_out$holds)), sum(gt_out$holds == 1, na.rm = TRUE),
            sum(!is.na(gt_out$defect_locus)))
))
print(count(gt_out, table_figure, name = "rows"), n = Inf)
