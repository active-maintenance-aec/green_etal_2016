# green_etal_2016: table_7_pooled.R
# Output: output/table_7_pooled.csv
# Depends on: original/exp_1.RData through exp_4.RData, helpers.R
# Description: Table 7: per-experiment direct and indirect effects on vote share, pooled by fixed-effects meta-analysis.
source(here::here("maintained", "helpers.R"))

# Use the pre-saved canonical exp_N.RData objects, as Pooled_analysis.R does in the
# original archive. exp_2 was saved with a different chosen.rand than set.seed(12345)
# produces when Experiment_2_Analysis.R is run fresh on R 3.6 or later, so reading the
# pre-saved object is what makes the pooled estimates match the published paper.
load(here::here("original", "exp_1.RData"))
load(here::here("original", "exp_2.RData"))
load(here::here("original", "exp_3.RData"))
load(here::here("original", "exp_4.RData"))

# Per-experiment covariate-adjusted vote-share models ----
d1 <- filter(exp_1, treatable == 1)
d2 <- filter(exp_2, include == 1)

m1 <- lm_robust(dvote12 ~ condition_factor + dvote10 + dvote08 + dvote06 + pvote08,
                weights = weights, data = d1, se_type = "HC2")
m2 <- lm_robust(share ~ condition_factor + registereddems + jenningsvoteshare09 + jenningsvoteshare05,
                weights = weights, data = d2, se_type = "HC2")
m3 <- lm_robust(share ~ condition_factor + obama_share_2012 + shannon_share_2009,
                weights = weights, data = exp_3, se_type = "HC2")
m4 <- lm_robust(share ~ condition_factor + GOVP2010 + USPP2008 + GOVP2006 + USPP2004 + GOVP2002 + USPP2000,
                weights = weights, data = exp_4, se_type = "HC2")

# Extract treated and adjacent coefficients + SEs ----
extract_arm <- function(mod, arm_label, exp_label) {
  term <- paste0("condition_factor", arm_label)
  tibble(experiment = exp_label, arm = arm_label,
         estimate   = coef(mod)[term],
         std.error  = summary(mod)$coefficients[term, "Std. Error"])
}

direct   <- map2_dfr(list(m1, m2, m3, m4), paste0("Experiment ", 1:4),
                     ~ extract_arm(.x, "Treated",  .y))
indirect <- map2_dfr(list(m1, m2, m3, m4), paste0("Experiment ", 1:4),
                     ~ extract_arm(.x, "Adjacent", .y))

# Fixed-effects meta-analysis ----
# The paper pools by inverse-variance weighting with rmeta::meta.summaries(method = "fixed");
# metafor::rma(method = "FE") is the maintained equivalent.
direct_fe <- rma(yi = direct$estimate, sei = direct$std.error, method = "FE")
indirect_fe <- rma(yi = indirect$estimate, sei = indirect$std.error, method = "FE")

pooled <- tribble(
  ~experiment, ~arm, ~estimate, ~std.error,
  "Pooled", "Treated", as.numeric(direct_fe$beta), direct_fe$se,
  "Pooled", "Adjacent", as.numeric(indirect_fe$beta), indirect_fe$se
)

results <- bind_rows(direct, indirect, pooled) |> arrange(arm, experiment)
write_csv(results, here::here("maintained", "output", "table_7_pooled.csv"))
