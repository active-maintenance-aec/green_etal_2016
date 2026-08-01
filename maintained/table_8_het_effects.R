# green_etal_2016/maintained/table_8_het_effects.R
# Output: output/table_8_het_effects.csv
# Depends on: original/exp_1.RData through exp_4.RData, helpers.R
# Description: Table 8 (appendix D): treatment effects interacted with standardized past party support.
source(here::here("maintained", "helpers.R"))

load(here::here("original", "exp_1.RData"))
load(here::here("original", "exp_2.RData"))
load(here::here("original", "exp_3.RData"))
load(here::here("original", "exp_4.RData"))

# Scale party support variable per experiment ----
exp_1 <- exp_1 |> mutate(party_share = as.numeric(scale(pvote08)))
exp_2 <- exp_2 |> mutate(party_share = as.numeric(scale(jenningsvoteshare09)))
exp_3 <- exp_3 |> mutate(party_share = as.numeric(scale(1 - obama_2share_2012)))
exp_4 <- exp_4 |> mutate(party_share = as.numeric(scale(1 - USPP2008)))

# Heterogeneous effects models ----
d1 <- filter(exp_1, treatable == 1)
d2 <- filter(exp_2, include == 1)

m1 <- lm_robust(share ~ condition_factor * party_share + dvote10 + dvote08 + dvote06,
                weights = weights, data = d1, se_type = "HC2")
m2 <- lm_robust(share ~ condition_factor * party_share + registereddems + jenningsvoteshare05,
                weights = weights, data = d2, se_type = "HC2")
m3 <- lm_robust(share ~ condition_factor * party_share + shannon_share_2009,
                weights = weights, data = exp_3, se_type = "HC2")
m4 <- lm_robust(share ~ condition_factor * party_share + GOVP2010 + GOVP2006 + USPP2004 + GOVP2002 + USPP2000,
                weights = weights, data = exp_4, se_type = "HC2")

# Extract results ----
extract_het <- function(mod, exp_label) {
  tidy(mod) |>
    filter(str_detect(term, "condition_factor|party_share")) |>
    mutate(experiment = exp_label, n = nobs(mod), r2 = summary(mod)$r.squared)
}

results <- map2_dfr(list(m1, m2, m3, m4), paste0("Experiment ", 1:4), extract_het)
write_csv(results, here::here("maintained", "output", "table_8_het_effects.csv"))
