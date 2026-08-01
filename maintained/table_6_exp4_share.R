# green_etal_2016/maintained/table_6_exp4_share.R
# Output: output/table_6_exp4_share.csv
# Depends on: original/exp_4.RData, helpers.R
# Description: Table 6: effect of lawn signs on vote share, Experiment 4.
source(here::here("maintained", "helpers.R"))

load(here::here("original", "exp_4.RData"))

# Models ----
m1 <- lm_robust(share ~ condition_factor, weights = weights,
                data = exp_4, se_type = "HC2")
m2 <- lm_robust(share ~ condition_factor + GOVP2010 + USPP2008 + GOVP2006 + USPP2004 + GOVP2002 + USPP2000,
                weights = weights, data = exp_4, se_type = "HC2")

# Extract results ----
results <- bind_rows(
  tidy(m1) |> mutate(model = "M1"),
  tidy(m2) |> mutate(model = "M2")
) |>
  filter(str_detect(term, "condition_factor|Intercept")) |>
  mutate(n = nobs(m1), r2_m1 = summary(m1)$r.squared, r2_m2 = summary(m2)$r.squared)

write_csv(results, here::here("maintained", "output", "table_6_exp4_share.csv"))
