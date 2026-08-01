# green_etal_2016: table_5_exp3_share.R
# Output: output/table_5_exp3_share.csv
# Depends on: original/exp_3.RData, helpers.R
# Description: Table 5: effect of lawn signs on vote share, Experiment 3.
source(here::here("maintained", "helpers.R"))

load(here::here("original", "exp_3.RData"))

# Models ----
m1 <- lm_robust(share ~ condition_factor, weights = weights,
                data = exp_3, se_type = "HC2")
m2 <- lm_robust(share ~ condition_factor + obama_share_2012 + shannon_share_2009,
                weights = weights, data = exp_3, se_type = "HC2")

# Extract results ----
results <- bind_rows(
  tidy(m1) |> mutate(model = "M1"),
  tidy(m2) |> mutate(model = "M2")
) |>
  filter(str_detect(term, "condition_factor|Intercept")) |>
  mutate(n = nobs(m1), r2_m1 = summary(m1)$r.squared, r2_m2 = summary(m2)$r.squared)

write_csv(results, here::here("maintained", "output", "table_5_exp3_share.csv"))
