# green_etal_2016/maintained/table_3_exp1_share.R
# Output: output/table_3_exp1_share.csv
# Depends on: original/exp_1.RData, helpers.R
# Description: Table 3: effect of lawn signs on vote share, Experiment 1.
source(here::here("maintained", "helpers.R"))

load(here::here("original", "exp_1.RData"))
d <- filter(exp_1, treatable == 1)

# Models ----
m1 <- lm_robust(dvote12 ~ condition_factor, weights = weights,
                data = d, se_type = "HC2")
m2 <- lm_robust(dvote12 ~ condition_factor + dvote10 + dvote08 + dvote06 + pvote08,
                weights = weights, data = d, se_type = "HC2")

# Extract results ----
results <- bind_rows(
  tidy(m1) |> mutate(model = "M1"),
  tidy(m2) |> mutate(model = "M2")
) |>
  filter(str_detect(term, "condition_factor|Intercept")) |>
  mutate(n = nobs(m1), r2_m1 = summary(m1)$r.squared, r2_m2 = summary(m2)$r.squared)

write_csv(results, here::here("maintained", "output", "table_3_exp1_share.csv"))
