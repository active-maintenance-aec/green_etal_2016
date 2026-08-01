# green_etal_2016: clean_exp1.R
# Output: output/exp_1_clean.rds
# Depends on: original/Experiment_1_Adjacencies.rdata, Experiment_1_Permutation_Matrix.rdata, Experiment_1_Results.RData
# Description: Rebuild the Experiment 1 (NY-22, 2012) analysis frame from the raw archive files: derived vote quantities, aggregation to merged electoral districts, condition assignment and inverse-probability weights.
source(here::here("maintained", "helpers.R"))

# Load original data files ----
load(here::here("original", "Experiment_1_Adjacencies.rdata"))
load(here::here("original", "Experiment_1_Permutation_Matrix.rdata"))
load(here::here("original", "Experiment_1_Results.RData"))

# Compute derived variables ----
exp_1 <- exp_1 |>
  mutate(
    dvote12 = c12demvotes / (c12demvotes + c12repvotes + c12indvotes),
    dvote10 = c10demvotes / (c10demvotes + c10repvotes + c10indvotes),
    dvote08 = c08demvotes / (c08demvotes + c08repvotes + c08indvotes + c08convotes),
    dvote06 = c06demvotes / (c06demvotes + c06repvotes + c06indvotes + c06convotes),
    pvote08 = (p08demvotes + p08wfpvotes) /
              (p08demvotes + p08repvotes + p08indvotes + p08convotes + p08wfpvotes),
    pvote12 = (p12demvotes + p12wfpvotes) /
              (p12demvotes + p12repvotes + p12convotes + p12wfpvotes + p12greenvotes +
               p12socvotes + p12lbnvotes + p12constvotes + p12othervotes),
    nvote12 = c12demvotes - (c12repvotes + c12indvotes),
    npvote12 = (p12demvotes + p12wfpvotes) - (p12repvotes + p12convotes),
    nvote10 = c10demvotes - (c10repvotes + c10indvotes),
    nvote08 = c08demvotes - (c08repvotes + c08indvotes + c08convotes),
    nvote06 = c06demvotes - (c06repvotes + c06indvotes + c06convotes),
    npvote08 = p08demvotes + p08wfpvotes - (p08repvotes + p08indvotes + p08convotes),
    totalcvotes12 = c12demvotes + c12repvotes + c12indvotes + c12othrvotes + c12voidvotes + c12blankvotes,
    totalcvotes10 = c10demvotes + c10repvotes + c10indvotes + c10othrvotes + c10voidvotes + c10blankvotes,
    totalcvotes08 = c08demvotes + c08repvotes + c08indvotes + c08othrvotes + c08voidvotes + c08blankvotes,
    totalcvotes06 = c06demvotes + c06repvotes + c06indvotes + c06othrvotes + c06voidvotes + c06blankvotes,
    totalpvotes08 = p08demvotes + p08wfpvotes + p08repvotes + p08indvotes + p08convotes,
    share = dvote12,
    margin = nvote12,
    turnout = totalcvotes12,
    share_cov = dvote10,
    margin_cov = nvote10,
    turnout_cov = totalcvotes10
  )

# Aggregate to merged electoral districts ----
lawnresults <- aggregate(exp_1[, c(3, 143:165)], by = list(exp_1$fid), sum)
names(lawnresults)[1] <- "fid"
lawnresults <- lawnresults[order(lawnresults$fid), ]

# Assign treatment conditions and IPW ----
untreatables <- c("11", "79", "80", "82", "85")

z_obs <- lawnresults$selected
z_obs[lawnresults$fid %in% untreatables] <- 0
treatable <- rep(1L, 93)
treatable[lawnresults$fid %in% untreatables] <- 0L

n_spillovers <- as.numeric(A.93 %*% z_obs)
condition <- case_when(
  z_obs == 1 & n_spillovers > 0 ~ 1L,
  z_obs == 1 & n_spillovers == 0 ~ 2L,
  z_obs == 0 & n_spillovers > 0 ~ 3L,
  z_obs == 0 & n_spillovers == 0 ~ 4L
)

ipw <- case_when(
  condition == 1 ~ 1 / probs.1.1,
  condition == 2 ~ 1 / probs.1.0,
  condition == 3 ~ 1 / probs.0.1,
  condition == 4 ~ 1 / probs.0.0
)

lawnresults <- lawnresults |>
  mutate(
    z_obs      = z_obs,
    treatable  = treatable,
    condition  = condition,
    weights    = ipw,
    condition_factor = factor(condition, levels = 2:4,
                              labels = c("Treated", "Adjacent", "Control")) |>
                   relevel(ref = "Control"),
    include    = treatable,
    study      = "Experiment 1"
  )

# Save ----
exp_1_clean <- lawnresults
cond_mat_1  <- condition.block
write_rds(list(data = exp_1_clean, cond_mat = cond_mat_1),
          here::here("maintained", "output", "exp_1_clean.rds"))
