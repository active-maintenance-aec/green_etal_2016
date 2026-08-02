# green_etal_2016/run_all.R
# Runs the whole reproduction in order: fetch and verify the deposited archive, rebuild
# each experiment's analysis frame, then every published table and figure.
# Every script is self-contained and can also be run on its own.

library(here)
here::i_am("run_all.R")

# Deposited archive ----
# Downloads from Dataverse on a fresh clone; verifies checksums either way.
source(here::here("download_original.R"))

# Cleaning ----
# These rebuild each experiment's analysis frame from the raw archive files. They
# document the data preparation; the table scripts read the archive's canonical
# exp_N.RData objects, for the reason given in maintained/README.md.
source(here::here("maintained", "clean_exp1.R"))
source(here::here("maintained", "clean_exp2.R"))
source(here::here("maintained", "clean_exp3.R"))
source(here::here("maintained", "clean_exp4.R"))

# Tables ----
source(here::here("maintained", "table_2_ns.R"))
source(here::here("maintained", "table_3_exp1_share.R"))
source(here::here("maintained", "table_4_exp2_share.R"))
source(here::here("maintained", "table_5_exp3_share.R"))
source(here::here("maintained", "table_6_exp4_share.R"))
source(here::here("maintained", "table_7_pooled.R"))
source(here::here("maintained", "table_8_het_effects.R"))
source(here::here("maintained", "appendix_c_margins_turnout.R"))

# Figures ----
# figure_2_bayesian.R reads the Table 7 estimates, so it runs after table_7_pooled.R.
source(here::here("maintained", "figure_2_bayesian.R"))

# Randomization inference ----
# Four experiments by three outcomes, 10,000 permutations each; the slow step, around
# two minutes in total.
source(here::here("maintained", "ri_all_experiments.R"))

# Deposited archive, again ----
# The check at the top of this file is a precondition: it says original/ was intact
# before anything ran. Nothing above writes to original/, and this second pass is what
# demonstrates it rather than assuming it. Nothing is downloaded; the files are already
# present and are re-checked against the manifest on checksum, byte size and membership.
source(here::here("download_original.R"))
