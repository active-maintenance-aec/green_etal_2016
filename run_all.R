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

# In-text quantities ----
# text_footnote_3_cost_per_vote.R reads the Table 7 estimates, so it runs after
# table_7_pooled.R.
source(here::here("maintained", "text_footnote_3_cost_per_vote.R"))

# Randomization inference ----
# Four experiments by three outcomes, 10,000 permutations each; the slow step, around
# two minutes in total.
source(here::here("maintained", "ri_all_experiments.R"))

# Ground truth ----
# Assembles the ground truth from the published extraction, the deposited scripts' own
# values and maintained/output/, then runs the coverage gate, which sources
# in_text_claims.R and halts if any published quantity has lost its claim block or if
# the two instruments disagree.
source(here::here("ground_truth", "build_ground_truth.R"))

# In-text claims, printed for a reader ----
# The gate above already ran this file under capture.output. This second pass is the
# human-readable log: one line per published quantity, recomputed from output/. It goes
# into its own environment for the same reason the gate does: the file names its objects
# for what they hold, and so does every other script this one sources.
source(here::here("maintained", "in_text_claims.R"), local = new.env())

# Deposited archive, again ----
# The check at the top of this file is a precondition: it says original/ was intact
# before anything ran. Nothing above writes to original/, and this second pass is what
# demonstrates it rather than assuming it. Nothing is downloaded; the files are already
# present and are re-checked against the manifest on checksum, byte size and membership.
source(here::here("download_original.R"))
