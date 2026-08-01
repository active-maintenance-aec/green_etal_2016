# green_etal_2016: clean_exp3.R
# Output: output/exp_3_clean.rds
# Depends on: original/Experiment_3_Data_with_Random_Assignment.RData, Experiment_3_Results.RData
# Description: Rebuild the Experiment 3 (Virginia, 2013) analysis frame from the raw archive files.
source(here::here("maintained", "helpers.R"))

# Load original data files ----
load(here::here("original", "Experiment_3_Data_with_Random_Assignment.RData"))
load(here::here("original", "Experiment_3_Results.RData"))

# Merge and compute derived variables ----
results <- left_join(results, results2013,
                     by = c("precinct_id_2012" = "precinct_id"))

results <- results |>
  mutate(
    writein = replace_na(writein, 0),

    share  = Cuccinelli / (Cuccinelli + McAuliffe + Sarvis + writein),
    margin = Cuccinelli - (McAuliffe + Sarvis + writein),
    turnout = Cuccinelli + McAuliffe + Sarvis + writein,

    obama_share_2012  = Barack.Obama..D..2012.Vote.Totals /
                        (Barack.Obama..D..2012.Vote.Totals + OTHER.2012.Vote.Totals +
                         Mitt.Romney..R..2012.Vote.Totals),
    obama_margin_2012 = Barack.Obama..D..2012.Vote.Totals -
                        (Mitt.Romney..R..2012.Vote.Totals + OTHER.2012.Vote.Totals),
    obama_2share_2012 = Barack.Obama..D..2012.Vote.Totals /
                        (Barack.Obama..D..2012.Vote.Totals + Mitt.Romney..R..2012.Vote.Totals),
    turnout_2012 = Barack.Obama..D..2012.Vote.Totals + OTHER.2012.Vote.Totals +
                   Mitt.Romney..R..2012.Vote.Totals,

    shannon_share_2009  = Stephen.C..Shannon..D..Vote.Totals /
                          (Stephen.C..Shannon..D..Vote.Totals +
                           Other.2009.Vote.Totals +
                           Ken.T..Cuccinelli.II..R..Vote.Totals),
    shannon_margin_2009 = Stephen.C..Shannon..D..Vote.Totals -
                          (Ken.T..Cuccinelli.II..R..Vote.Totals + Other.2009.Vote.Totals),
    turnout_2009 = Stephen.C..Shannon..D..Vote.Totals + Other.2009.Vote.Totals +
                   Ken.T..Cuccinelli.II..R..Vote.Totals,

    share_cov  = obama_share_2012,
    margin_cov = obama_margin_2012,
    turnout_cov = turnout_2012,

    probs.Z = rowMeans(restricted.Z.block),

    condition_factor = factor(condition.obs, levels = 1:3,
                              labels = c("Control", "Adjacent", "Treated")) |>
                       factor(levels = c("Control", "Treated", "Adjacent")),
    include = 1L,
    study   = "Experiment 3"
  )

# Save ----
exp_3_clean <- results
cond_mat_3  <- restricted.condition.block
write_rds(list(data = exp_3_clean, cond_mat = cond_mat_3),
          here::here("maintained", "output", "exp_3_clean.rds"))
