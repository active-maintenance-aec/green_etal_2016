# green_etal_2016/maintained/table_4_exp2_share.R
# Output: output/table_4_exp2_share.csv
# Depends on: original/exp_2.RData, helpers.R
# Description: Table 4: effect of lawn signs on vote share, Experiment 2.
source(here::here("maintained", "helpers.R"))

load(here::here("original", "exp_2.RData"))
d <- filter(exp_2, include == 1)

# Models ----
m1 <- lm_robust(share ~ condition_factor, weights = weights,
                data = d, se_type = "HC2")
m2 <- lm_robust(share ~ condition_factor + registereddems + jenningsvoteshare09 + jenningsvoteshare05,
                weights = weights, data = d, se_type = "HC2")

# Extract results ----
results <- bind_rows(
  tidy(m1) |> mutate(model = "M1"),
  tidy(m2) |> mutate(model = "M2")
) |>
  filter(str_detect(term, "condition_factor|Intercept")) |>
  mutate(n = nobs(m1), r2_m1 = summary(m1)$r.squared, r2_m2 = summary(m2)$r.squared)

write_csv(results, here::here("maintained", "output", "table_4_exp2_share.csv"))
