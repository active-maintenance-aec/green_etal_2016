# green_etal_2016: clean_exp4.R
# Output: output/exp_4_clean.rds
# Depends on: original/Experiment_4_Data_with_Random_Assignment.RData, Experiment_4_Permutation_Matrix.rdata, Experiment_4_Results.RData
# Description: Rebuild the Experiment 4 (Pennsylvania 41st, 2014) analysis frame from the raw archive files.
source(here::here("maintained", "helpers.R"))

# Load original data files ----
load(here::here("original", "Experiment_4_Data_with_Random_Assignment.RData"))
load(here::here("original", "Experiment_4_Permutation_Matrix.rdata"))
load(here::here("original", "Experiment_4_Results.RData"))

# condition_obs is a factor with levels "control" (1), "adjacent" (2), "treated" (3)

# Merge results and filter to study units ----
PA_41_df <- PA_41_df |>
  left_join(results) |>
  mutate(
    turnout  = Cross + Difilippo + Eichelberger + Schin + Other,
    share    = (Eichelberger + Schin) / turnout,
    in_study = res_prob_treated < 1 & res_prob_treated > 0 &
               res_prob_adj     < 1 & res_prob_adj     > 0 &
               res_prob_control < 1 & res_prob_control > 0
  ) |>
  filter(in_study)

# Compute IPW: match on factor labels ----
cond_chr <- as.character(PA_41_df$condition_obs)  # "control"/"adjacent"/"treated"

PA_41_df <- PA_41_df |>
  mutate(
    weights = case_when(
      cond_chr == "treated"  ~ 1 / res_prob_treated,
      cond_chr == "adjacent" ~ 1 / res_prob_adj,
      cond_chr == "control"  ~ 1 / res_prob_control
    ),
    margin      = Eichelberger - (Cross + Difilippo + Schin + Other),
    GOVT2010    = GOVRV2010 + GOVDV2010,
    USPT2008    = USPRV2008 + USPDV2008,
    GOVT2006    = GOVRV2006 + GOVDV2006,
    USPT2004    = USPRV2004 + USPDV2004,
    GOVT2002    = GOVRV2002 + GOVDV2002,
    USPT2000    = USPRV2000 + USPDV2000,
    GOVM2010    = GOVRV2010 - GOVDV2010,
    USPM2008    = USPRV2008 - USPDV2008,
    GOVM2006    = GOVRV2006 - GOVDV2006,
    USPM2004    = USPRV2004 - USPDV2004,
    GOVM2002    = GOVRV2002 - GOVDV2002,
    USPM2000    = USPRV2000 - USPDV2000,
    margin_cov  = GOVM2010,
    share_cov   = GOVP2010,
    turnout_cov = GOVT2010,
    condition_factor = factor(condition_obs,
                              levels = c("control", "adjacent", "treated"),
                              labels = c("Control", "Adjacent", "Treated")) |>
                       factor(levels = c("Control", "Treated", "Adjacent")),
    include = 1L,
    study   = "Experiment 4"
  )

# Save ----
exp_4_clean <- PA_41_df
cond_mat_4  <- restricted_condition_mat
write_rds(list(data = exp_4_clean, cond_mat = cond_mat_4),
          here::here("maintained", "output", "exp_4_clean.rds"))
