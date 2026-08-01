# green_etal_2016/maintained/clean_exp2.R
# Output: output/exp_2_clean.rds
# Depends on: original/Experiment_2_Permutation_Matrix.rdata, Experiment_2_Past_Elections.RData, Experiment_2_Results.RData
# Description: Rebuild the Experiment 2 (Albany, 2013) analysis frame from the raw archive files. See README.md in this folder: the seed draw here selects a different permutation column than the published analysis used, so the analysis scripts read original/exp_2.RData instead.
source(here::here("maintained", "helpers.R"))

# Load original data files ----
load(here::here("original", "Experiment_2_Permutation_Matrix.rdata"))
load(here::here("original", "Experiment_2_Past_Elections.RData"))
load(here::here("original", "Experiment_2_Results.RData"))

# Draw observed randomization (same seed as original) ----
set.seed(12345)
chosen_rand <- sample(1:10000, 1)

# Compute marginal probabilities and observed assignment ----
albany <- albany |>
  mutate(
    restricted.prob.3 = rowMeans(restricted.condition.block == 3, na.rm = TRUE),
    restricted.prob.2 = rowMeans(restricted.condition.block == 2, na.rm = TRUE),
    restricted.prob.1 = rowMeans(restricted.condition.block == 1, na.rm = TRUE),
    prob.Z  = rowMeans(restricted.Z.block == 1),
    Z.obs         = restricted.Z.block[, chosen_rand],
    condition.obs = restricted.condition.block[, chosen_rand]
  )

albany <- left_join(albany, officialresults, by = c("id" = "ed"))

# Compute derived vote variables ----
albany <- albany |>
  mutate(
    share  = kathy13 / (kathy13 + corey13 + write13),
    margin = kathy13 - (corey13 + write13),
    turnout = kathy13 + corey13 + write13,

    share_cov  = jennings09 / (jennings09 + ellis09),
    margin_cov = jennings09 - ellis09,
    turnout_cov = jennings09 + ellis09,

    jenningsvoteshare09  = jennings09 / (jennings09 + ellis09),
    jenningsvotemargin09 = jennings09 - ellis09,
    turnout09 = jennings09 + ellis09,
    jenningsvoteshare05  = jennings05 / (jennings05 + goodbee05),
    jenningsvotemargin05 = jennings05 - goodbee05,
    turnout05 = jennings05 + goodbee05,

    weights = case_when(
      condition.obs == 3 ~ 1 / restricted.prob.3,
      condition.obs == 2 ~ 1 / restricted.prob.2,
      condition.obs == 1 ~ 1 / restricted.prob.1
    ),

    in_direct_exp   = as.integer(condition.obs %in% c(1, 3) &
                        restricted.prob.3 < 1 & restricted.prob.3 > 0 &
                        restricted.prob.1 < 1 & restricted.prob.1 > 0),
    in_indirect_exp = as.integer(condition.obs %in% c(1, 2) &
                        restricted.prob.2 < 1 & restricted.prob.2 > 0 &
                        restricted.prob.1 < 1 & restricted.prob.1 > 0),
    in_whole_exp    = as.integer(restricted.prob.3 < 1 & restricted.prob.3 > 0 &
                        restricted.prob.2 < 1 & restricted.prob.2 > 0 &
                        restricted.prob.1 < 1 & restricted.prob.1 > 0),

    condition_factor = factor(condition.obs, levels = 1:3,
                              labels = c("Control", "Adjacent", "Treated")) |>
                       factor(levels = c("Control", "Treated", "Adjacent")),
    include = in_whole_exp,
    study   = "Experiment 2"
  )

# Save ----
exp_2_clean <- albany
cond_mat_2  <- restricted.condition.block
write_rds(list(data = exp_2_clean, cond_mat = cond_mat_2),
          here::here("maintained", "output", "exp_2_clean.rds"))
