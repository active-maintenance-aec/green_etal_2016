# green_etal_2016/maintained/table_2_ns.R
# Output: output/table_2_ns.csv
# Depends on: original/exp_1.RData through exp_4.RData, helpers.R
# Description: Table 2: number of districts in each condition, by experiment.
source(here::here("maintained", "helpers.R"))

# Use pre-saved canonical exp_N.RData objects ----
load(here::here("original", "exp_1.RData"))
load(here::here("original", "exp_2.RData"))
load(here::here("original", "exp_3.RData"))
load(here::here("original", "exp_4.RData"))

# Common columns ----
keep <- c("margin", "share", "turnout", "margin_cov", "share_cov", "turnout_cov",
          "condition_factor", "weights", "include", "study")

all_data <- bind_rows(
  exp_1 |> filter(include == 1) |> select(all_of(keep)),
  exp_2 |> filter(include == 1) |> select(all_of(keep)),
  exp_3 |> filter(include == 1) |> select(all_of(keep)),
  exp_4 |> filter(include == 1) |> select(all_of(keep))
)

# Table 2: Ns by condition ----
ns_table <- all_data |>
  group_by(study) |>
  summarize(
    Control  = sum(condition_factor == "Control"),
    Adjacent = sum(condition_factor == "Adjacent"),
    Treated  = sum(condition_factor == "Treated"),
    Total    = n(),
    .groups  = "drop"
  )

write_csv(ns_table, here::here("maintained", "output", "table_2_ns.csv"))
