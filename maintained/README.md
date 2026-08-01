# green_etal_2016: maintained rewrite

Maintained rewrite of Green, Krasno, Coppock, Farrer, Lenoir, and Zingher (2016,
*Electoral Studies*), "The Effects of Lawn Signs on Vote Outcomes: Results from Four
Randomized Field Experiments."

One script per published table or figure. Every script sources `helpers.R` first and
resolves paths with `here::here()`, so any of them can be run on its own from the
repository root; `run_all.R` runs them in order.

---

## Scripts

| Script | Output |
|---|---|
| `helpers.R` | Packages, and `f_treat()` for the randomization inference F-statistic |
| `clean_exp1.R` to `clean_exp4.R` | Data prep for each experiment, writing `output/*.rds` |
| `table_2_ns.R` | Table 2 (treatment assignment Ns) |
| `table_3_exp1_share.R` | Table 3 (Experiment 1 vote share) |
| `table_4_exp2_share.R` | Table 4 (Experiment 2 vote share) |
| `table_5_exp3_share.R` | Table 5 (Experiment 3 vote share) |
| `table_6_exp4_share.R` | Table 6 (Experiment 4 vote share) |
| `table_7_pooled.R` | Table 7 (pooled meta-analysis) |
| `table_8_het_effects.R` | Table 8 (heterogeneous effects by party support) |
| `appendix_c_margins_turnout.R` | Tables C.1 to C.4 (margin and turnout) |
| `ri_all_experiments.R` | Randomization inference p-values, all four experiments |
| `figure_2_bayesian.R` | Figure 2 (Bayesian learning) |

Every analysis script loads the archive's pre-saved `exp_N.RData` objects directly
from `original/` rather than reading what `clean_expN.R` writes. The `clean_expN.R`
scripts document the data preparation in tidy form and are worth reading, but they are
not the source of any published number, for the reason set out immediately below.

---

## Experiment 2 (Albany): correct assignment and R 3.6 warning

### The short version

If you are trying to reproduce Table 4 and are getting **M1 Treated ≈ 0.130** and
**M2 Treated ≈ 0.019** instead of the published **0.009** and **-0.014**, you have
hit the R 3.6.0 `sample()` change. See below. The published analysis is correct.

### Background

Experiment 2 (Albany, NY, 2013) used constrained randomization. A matrix of 10,000
pre-screened permutations of treatment assignment (`restricted.condition.block`,
stored in `original/Experiment_2_Permutation_Matrix.rdata`) was constructed, and one
column was selected as the observed assignment. The published archive selects this
column with:

```r
set.seed(12345)
chosen.rand <- sample(1:10000, 1)
```

### The R 3.6.0 problem

R 3.6.0 (released April 2019) changed the default algorithm used by `sample()` when
converting uniform random variates to integers. The old method was "Rounding"; the new
default is "Rejection". These two methods produce different sequences from the same seed.

Consequence: `set.seed(12345); sample(1:10000, 1)` returns **7210** under R < 3.6 and
**8243** under R 3.6 or later. Columns 7210 and 8243 of `restricted.condition.block` are
different treatment assignments and produce substantially different estimates.

| Column | Source | M1 Treated | M2 Treated |
|---|---|---|---|
| **7210** | R < 3.6, `set.seed(12345)`: **correct** | 0.009 | -0.014 |
| 8243 | R >= 3.6, `set.seed(12345)`: wrong | 0.130 | 0.019 |

### How the correct assignment was verified

Three independent checks all confirm that column 7210 is the correct assignment:

1. **Column search**: `exp_2$condition.obs` (from the pre-saved `original/exp_2.RData`)
   was matched against all 10,000 columns of `restricted.condition.block`. Exact match
   at column 7210 only.

2. **Treatment districts file**: an author's working file from the project folder,
   `albanytreatmentdistricts.csv`, which is not part of the deposit, records the 34
   districts that actually received lawn signs. The Z vector from column 7210 of
   `restricted.Z.block` matches that list exactly.

3. **Pre-3.6 seed**: `set.seed(12345, sample.kind="Rounding"); sample(1:10000, 1)`
   returns 7210 on any R version, confirming that the original analysis environment
   (R < 3.6) selected this column.

### The backup file

`exp2_correct_assignment.csv` (this directory) contains the 128 Albany electoral
districts with their correct assignment:

| Column | Description |
|---|---|
| `id` | Electoral district ID (e.g., `001-02`) |
| `Z_obs` | Binary treatment indicator (1 = received lawn signs) |
| `condition_obs` | Condition code: 1 = control, 2 = adjacent, 3 = treated |
| `condition_label` | Human-readable label |

This file can be used to bypass the seed entirely:

```r
assignment <- read_csv(here::here("maintained", "exp2_correct_assignment.csv"))
# merge assignment$condition_obs onto your Albany data by id
```

### Why the maintained rewrite is unaffected

The maintained rewrite loads `original/exp_2.RData` directly for all analyses
(Tables 4, 7, 8, and Appendix C). This object was saved from the original analysis
environment (R < 3.6) and encodes column 7210. It reproduces the published results
on any R version because it never calls `sample()`.

The only affected path is `Experiment_2_Analysis.R` in the original archive when run
on R 3.6 or later. If you need to run that script on current R and match the published
results, add `sample.kind = "Rounding"` to the seed call:

```r
set.seed(12345, sample.kind = "Rounding")
chosen.rand <- sample(1:10000, 1)   # 7210, correct
```

### The randomization inference p-values

The same column choice governs the observed F-statistic that the randomization
inference test permutes, and getting it wrong changes the answer. Experiment 2's
published p-value for vote share is 0.90 (article, section 5.2). Column 7210 reproduces
it (0.897); column 8243 gives 0.79. Until August 2026 `ri_all_experiments.R` took its
observed assignment from `clean_exp2.R` and therefore reported 0.79. It now reads
`original/exp_2.RData` like every other script, so all four published p-values
reproduce: 0.22, 0.90, 0.02 and 0.77.

### Summary of investigation

Conducted 2026-03-19, extended to the randomization inference p-values 2026-08-01.
The reproducibility report at the repository root carries the full account.
