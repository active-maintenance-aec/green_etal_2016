# Active Maintenance Report: green_etal_2016

2026-08-01

- [Summary](#summary)
  - [Does the deposited archive run?](#does-the-deposited-archive-run)
  - [Does the maintained rewrite reproduce the
    paper?](#does-the-maintained-rewrite-reproduce-the-paper)
- [Paper overview](#paper-overview)
- [Original archive reproducibility](#original-archive-reproducibility)
  - [The Experiment 2 seed](#the-experiment-2-seed)
- [The extraction and the two
  instruments](#the-extraction-and-the-two-instruments)
- [Coverage](#coverage)
- [Number-by-number comparison](#number-by-number-comparison)
- [Maintained rewrite](#maintained-rewrite)
  - [Architecture](#architecture)
  - [Deprecated patterns replaced](#deprecated-patterns-replaced)
- [Randomization inference](#randomization-inference)
- [Figure 2 verification](#figure-2-verification)
- [Maintained rewrite verification](#maintained-rewrite-verification)
- [Errata](#errata)
- [R environment](#r-environment)

*Drafted by Claude Opus 5 under the supervision of Alex Coppock.*

This repository holds the actively maintained replication code for
Green, Krasno, Coppock, Farrer, Lenoir and Zingher (2016), together with
the reproducibility report that documents what the original archive did
and did not do. It is part of a program applying the maintenance
proposal in Peer, Orr and Coppock (2021, *PS: Political Science &
Politics*, doi
[10.1017/S1049096521000366](https://doi.org/10.1017/S1049096521000366))
to a set of published archives.

|  |  |
|----|----|
| Article | [10.1016/j.electstud.2015.12.002](https://doi.org/10.1016/j.electstud.2015.12.002) |
| Replication archive | [10.7910/DVN/K2TLDB](https://doi.org/10.7910/DVN/K2TLDB) |
| Pre-analysis plan (Experiment 3) | [osf.io/umysq](https://osf.io/umysq) |
| Pre-analysis plan (Experiment 4) | [osf.io/ejfgk](https://osf.io/ejfgk) |

**The data are not redistributed here.** The deposit is 12 MB across 33
files and lives at Harvard Dataverse, which is the only copy this
repository points at. `download_original.R` fetches it and verifies
every file; `original_manifest.csv` pins the file identifiers, sizes and
checksums, so the exact bytes this code was written against are recorded
in version control even though the bytes themselves are not.

**Repository layout.** `maintained/` is the maintained rewrite: one
script per published table or figure, writing to `output/`, which is
committed so a reader can compare a fresh run against it without
downloading anything. It also holds `in_text_claims.R`, which recomputes
every quantity the article states and prints it beside the sentence that
states it. `ground_truth/` ties every published number to the code that
produces it: `published_claims.csv` is the extraction of every number
the article and appendix print, `archive_values.csv` is what the
deposited scripts themselves print, `build_ground_truth.R` assembles the
comparison, and `claims_gate.R` enforces the coverage. `original/` is
created by the download script and is deliberately absent from the
repository. This file is the reproducibility report, also available as a
PDF in `report/`.

**License.** CC0 1.0 Universal, matching the terms of the deposit this
repository maintains. See `LICENSE`.

**To reproduce.** Clone or download the repository, open
`green_etal_2016.Rproj`, and run:

``` r
source("run_all.R")
```

That fetches the deposit, verifies its 33 files, and produces every
table and figure into `maintained/output/`. Required packages:
tidyverse, estimatr, metafor, gridExtra, knitr, kableExtra, here. Paths
resolve through `here`, so nothing depends on the working directory. The
full run takes about two minutes, almost all of it in the randomization
inference, which refits 120,000 pairs of weighted models across 40,000
permutations. A successful run overwrites `maintained/output/`, which is
committed: **`git diff` on that folder is the reproduction check.**

# Summary

Two questions, answered before the detail.

## Does the deposited archive run?

Yes. All six analysis scripts execute without error on a current R
installation, with no hardcoded paths, no functions called before they
are defined, and no deprecated calls that have since been removed. Every
package they name still installs from CRAN, including `beepr` 2.0, which
only one of the random-assignment scripts calls, to play a sound on
completion.

Running is not the same as reproducing, and one line changes a great
many numbers. `Experiment_2_Analysis.R` picks the observed treatment
assignment out of a matrix of 10,000 admissible randomizations with
`set.seed(12345); sample(1:10000, 1)`. R 3.6.0 changed how `sample()`
converts uniform draws to integers, so that line returned column 7210
when the paper was written and returns column 8243 today. Column 7210 is
the assignment that was actually deployed, and it is the one the
archive’s own pre-saved `exp_2.RData` encodes, so the archive contains
the right answer and the live script path no longer finds it. 43 of the
378 published values a deposited script can be checked against therefore
fail to reproduce, and all 43 come from that one line: every cell of
Table 4, every cell of appendix Table C.2, and the Experiment 2
randomization inference p-value. The deposit’s other scripts read
`exp_2.RData` directly and are unaffected, which is why Table 7, Table
D.5 and the pooled quantities reproduce exactly.

## Does the maintained rewrite reproduce the paper?

Yes, without exception. All 400 published values that can be compared
against the rewrite match to the precision the page prints, including
every panel label of Figure 2 and all 345 cells of the 12 published
floats. A further 7 claims have no printed number to compare, either
because the sentence states a shape rather than a value or because the
deposit draws the quantity without a seed; 7 of 7 hold against the
pipeline’s own estimates. The remaining 74 published numbers are design
facts the deposit does not record, such as how many signs were planted
and how far in advance, and are verified against the article’s own
methods section rather than against code.

Nothing in the article contradicts its own tables, its own data or its
own code, so this repository carries no errata document.

The rewrite reaches Experiment 2 through the pre-saved `exp_2.RData`
object rather than through the seed, which is what makes it immune to
the R version change. Reaching it any other way is a live hazard rather
than a hypothetical one: until August 2026 the rewrite’s randomization
inference script took Experiment 2’s observed assignment from its own
cleaning script, which redraws the seed, and consequently reported 0.79
where the article reports 0.90. That script now reads the same canonical
object as everything else.

# Paper overview

**Citation**: Green, D. P., Krasno, J. S., Coppock, A., Farrer, B. D.,
Lenoir, B. and Zingher, J. N. (2016). “The effects of lawn signs on vote
outcomes: Results from four randomized field experiments.” *Electoral
Studies*, 41, 143-150. DOI: 10.1016/j.electstud.2015.12.002

**Summary**: Four randomized field experiments test whether lawn signs
change vote outcomes. In each, geographic units (electoral districts or
precincts) were assigned to receive signs, to be adjacent to a unit that
received signs, or to neither, so that each experiment estimates a
direct effect and a spillover effect at once. Because adjacency makes
the assignment probabilities unequal across units, every estimate is
inverse-probability weighted, and inference is randomization based: an
observed F-statistic for the joint null of no direct and no indirect
effect is compared against 10,000 pre-computed admissible
randomizations. The four experiments are a 2012 congressional general
election in New York, a 2013 mayoral primary in Albany, a 2013
gubernatorial general election in Virginia, and a 2015 county
commissioner primary in Cumberland County, Pennsylvania. Pooling the
four by fixed-effects meta-analysis gives a direct effect of 1.7
percentage points of vote share (SE 0.7) and a spillover effect of 1.5
points (SE 0.6).

# Original archive reproducibility

| Script | Status on current R | Resolution |
|:---|:---|:---|
| Lawn_Signs_Source.R | Clean (sourced by all scripts) | No changes required |
| Experiment_1_Analysis.R | Clean | No changes required |
| Experiment_2_Analysis.R | Runs clean, but Table 4 and the Experiment 2 p-value no longer reproduce | set.seed(12345, sample.kind = ‘Rounding’), or read the deposited exp_2.RData |
| Experiment_3_Analysis.R | Clean | No changes required |
| Experiment_4_Analysis.R | Clean | No changes required |
| Pooled_analysis.R | Clean | No changes required |
| in_text_calculations.R | Clean | No changes required |
| Experiment_1_RA_Function.R | Parses; regenerates a deposited matrix, not re-run | None needed: its output is deposited |
| Experiment_2_RA_Function.R | Parses; regenerates a deposited matrix, not re-run | None needed: its output is deposited |
| Experiment_3_RA_Function.R | Parses; regenerates a deposited matrix, not re-run | None needed: its output is deposited |
| Experiment_4_RA_Function.R | Parses; needs beepr, which installs from CRAN | install.packages(‘beepr’) |

Original archive reproducibility, checked against R 4.6.0 on 1 August
2026.

Every package the archive names still installs from CRAN: `stargazer`,
`xtable`, `sandwich`, `lmtest`, `ggplot2`, `dplyr`, `randomizr`, `beepr`
and `rmeta`. The last of these is the fragile one. `rmeta` 3.0 has not
been updated since March 2018 and survives on CRAN by its archiving
policy rather than by maintenance, and `Pooled_analysis.R` depends on it
for a single call to `meta.summaries()`. The maintained rewrite pools
with `metafor::rma(method = "FE")` instead, so it does not inherit the
exposure.

The four `*_RA_Function.R` scripts regenerate the permutation matrices
from scratch. They parse cleanly and their packages install, but they
were not re-run to completion: they are stochastic, they take a long
time, and the matrices they build are themselves deposited, so
re-running them would replace a deposited object with a different one
rather than check anything.

## The Experiment 2 seed

The one substantive failure has nothing to do with packages.
`Experiment_2_Analysis.R` opens by drawing the observed treatment
assignment out of the deposited permutation matrix:

``` r
set.seed(12345)
chosen.rand <- sample(1:10000, 1)
```

R 3.6.0, released in April 2019, replaced the “Rounding” method that
`sample()` used to convert uniform variates to integers with a
“Rejection” method. The same seed therefore selects a different column
than it did when the analysis was run: 7210 under the old method, 8243
under the new one. The two columns are different treatment assignments
and give different answers.

Column 7210 is the assignment the experiment actually used. Three
independent checks agree on that: it is the column the archive’s own
pre-saved `exp_2.RData` encodes, it is the column whose treated set
matches the authors’ record of which districts received signs, and it is
what `set.seed(12345, sample.kind = "Rounding")` returns on any R
version. Column 7210 also reproduces the published Table 4 and the
published Experiment 2 p-value; column 8243 reproduces neither.

| Quantity | Published | Column 7210 (R \< 3.6) | Column 8243 (R 3.6+) |
|:---|:---|:---|:---|
| Table 4 M1 treated | 0.009 | 0.009 | 0.130 |
| Table 4 M2 treated | -0.014 | -0.014 | 0.019 |
| Table C.2 margin M1 treated | 24.673 | 24.673 | 21.495 |
| Table C.2 turnout M2 treated | 9.029 | 9.029 | 5.985 |
| Section 5.2 p-value | 0.90 | 0.90 | 0.79 |

What the Experiment 2 permutation column decides. The published column
is the article’s own string; the other two are computed.

The archive is not wrong. It contains both the script and the object the
script was meant to produce, and the object is correct. What it lacks is
any signal that the two have come apart, which is the failure this
maintenance program exists to catch: a reader running the deposited
script today gets numbers that differ from the paper, with no error and
no warning.

# The extraction and the two instruments

Everything below rests on one hand-reviewed file.
`ground_truth/published_claims.csv` is the **extraction**: every numeric
token in the article and the online appendix, read off the published
pages, classified by hand, and committed. It carries 481 rows. Table
cells, figure labels, prose quantities, design facts and the numbers in
appendix A that come from election returns rather than from the deposit
are all in it, each with the string the page prints and the number of
decimals the page prints it at.

| Class        | Rows | Needing a claim block |
|:-------------|-----:|----------------------:|
| pipeline     |  388 |                   388 |
| definitional |   49 |                    14 |
| structural   |   22 |                     0 |
| transcribed  |   17 |                     0 |
| descriptive  |    5 |                     5 |

The extraction by class. A pipeline claim is one the code should
produce; a descriptive claim states a shape or a count rather than a
value; definitional, structural and transcribed claims are design facts,
page structure, and numbers taken from outside the deposit.

Two instruments then read the pipeline’s output independently.
`ground_truth/build_ground_truth.R` reshapes each output file into a
long table keyed by claim identifier and joins it to the extraction.
`maintained/in_text_claims.R` selects the same numbers cell by cell,
quoting the article’s own sentence beside each prose claim, and prints
one line per quantity. `ground_truth/claims_gate.R` runs the second file
as a program, not as text, and halts the run unless three things hold:
the number of printed claims equals the 407 extraction rows requiring
one, the two identifier sets are equal in both directions, and every
printed value agrees with the ground truth at the precision the page
uses. A claim block that errored, printed nothing, or silently read the
wrong file would fail that gate.

The independence is the point. The gate found two defects in this
repository that no number-against-number check could:
`appendix_c_margins_turnout.R` was labelling Experiment 1’s rows with
the dependent variable’s name rather than the outcome it was passed, so
a filter on turnout silently dropped one of four experiments, and the
appendix D pooled interaction effects, the section 5.5 pooled turnout
effect and footnote 3’s cost per vote had no counterpart in `output/` at
all.

# Coverage

The article and its appendix print 481 numbers. 400 of them are produced
by the pipeline and compared cell by cell; 7 are judged as claims rather
than as values; the other 74 are facts about how the experiments were
run that no deposited file records.

| Float | Published cells | Archive comparable | Archive matching | Rewrite comparable | Rewrite matching |
|:---|---:|---:|---:|---:|---:|
| Table 2 | 16 | 16 | 16 | 16 | 16 |
| Table 3 | 18 | 18 | 18 | 18 | 18 |
| Table 4 | 18 | 18 | 4 | 18 | 18 |
| Table 5 | 18 | 18 | 18 | 18 | 18 |
| Table 6 | 18 | 18 | 18 | 18 | 18 |
| Table 7 | 20 | 20 | 20 | 20 | 20 |
| Figure 2 | 45 | 45 | 45 | 45 | 45 |
| Table C.1 | 34 | 34 | 34 | 34 | 34 |
| Table C.2 | 34 | 34 | 6 | 34 | 34 |
| Table C.3 | 34 | 34 | 34 | 34 | 34 |
| Table C.4 | 34 | 34 | 34 | 34 | 34 |
| Table D.5 | 56 | 56 | 56 | 56 | 56 |

Every published float, with the number of cells it prints and how many
reproduce. Coverage is complete: no float has a cell without a row.

# Number-by-number comparison

Of the 481 published values, 378 can be compared against what a
deposited script prints. 335 of those match and 43 do not. Every failure
is listed in full below, and every one is the Experiment 2 seed.

| Location | Claim | Paper | Archive | Rewrite | Locus |
|:---|:---|:---|:---|:---|:---|
| Section 5.2, p. 147 | text_r2_ri_p | 0.90 | 0.79 | 0.90 | environment |
| Table 4 | t4_m1_adjacent_coef | 0.012 | 0.137 | 0.012 | environment |
| Table 4 | t4_m1_adjacent_se | 0.046 | 0.072 | 0.046 | environment |
| Table 4 | t4_m1_constant_coef | 0.659 | 0.543 | 0.659 | environment |
| Table 4 | t4_m1_constant_se | 0.039 | 0.068 | 0.039 | environment |
| Table 4 | t4_m1_r2 | 0.001 | 0.130 | 0.001 | environment |
| Table 4 | t4_m1_treated_coef | 0.009 | 0.130 | 0.009 | environment |
| Table 4 | t4_m1_treated_se | 0.054 | 0.080 | 0.054 | environment |
| Table 4 | t4_m2_adjacent_coef | 0.004 | 0.028 | 0.004 | environment |
| Table 4 | t4_m2_adjacent_se | 0.045 | 0.035 | 0.045 | environment |
| Table 4 | t4_m2_constant_coef | 0.287 | 0.146 | 0.287 | environment |
| Table 4 | t4_m2_constant_se | 0.131 | 0.101 | 0.131 | environment |
| Table 4 | t4_m2_r2 | 0.253 | 0.588 | 0.253 | environment |
| Table 4 | t4_m2_treated_coef | -0.014 | 0.019 | -0.014 | environment |
| Table 4 | t4_m2_treated_se | 0.057 | 0.053 | 0.057 | environment |
| Table C.2 | c2_margin_m1_adjacent_coef | 21.436 | 34.970 | 21.436 | environment |
| Table C.2 | c2_margin_m1_adjacent_se | 12.565 | 14.896 | 12.565 | environment |
| Table C.2 | c2_margin_m1_constant_coef | 32.415 | 22.642 | 32.415 | environment |
| Table C.2 | c2_margin_m1_constant_se | 9.733 | 12.294 | 9.733 | environment |
| Table C.2 | c2_margin_m1_r2 | 0.048 | 0.087 | 0.048 | environment |
| Table C.2 | c2_margin_m1_treated_coef | 24.673 | 21.495 | 24.673 | environment |
| Table C.2 | c2_margin_m1_treated_se | 17.196 | 19.694 | 17.196 | environment |
| Table C.2 | c2_margin_m2_adjacent_coef | 5.563 | 14.440 | 5.563 | environment |
| Table C.2 | c2_margin_m2_adjacent_se | 12.363 | 9.834 | 12.363 | environment |
| Table C.2 | c2_margin_m2_constant_coef | -30.993 | -20.217 | -30.993 | environment |
| Table C.2 | c2_margin_m2_constant_se | 15.629 | 16.556 | 15.629 | environment |
| Table C.2 | c2_margin_m2_r2 | 0.501 | 0.556 | 0.501 | environment |
| Table C.2 | c2_margin_m2_treated_coef | 4.427 | -2.839 | 4.427 | environment |
| Table C.2 | c2_margin_m2_treated_se | 14.470 | 14.972 | 14.470 | environment |
| Table C.2 | c2_turnout_m1_adjacent_coef | 33.191 | 44.038 | 33.191 | environment |
| Table C.2 | c2_turnout_m1_adjacent_se | 15.131 | 19.682 | 15.131 | environment |
| Table C.2 | c2_turnout_m1_constant_coef | 92.776 | 83.329 | 92.776 | environment |
| Table C.2 | c2_turnout_m1_constant_se | 11.927 | 16.506 | 11.927 | environment |
| Table C.2 | c2_turnout_m1_r2 | 0.067 | 0.095 | 0.067 | environment |
| Table C.2 | c2_turnout_m1_treated_coef | 38.407 | 37.614 | 38.407 | environment |
| Table C.2 | c2_turnout_m1_treated_se | 23.037 | 26.008 | 23.037 | environment |
| Table C.2 | c2_turnout_m2_adjacent_coef | 8.012 | 14.943 | 8.012 | environment |
| Table C.2 | c2_turnout_m2_adjacent_se | 11.276 | 14.808 | 11.276 | environment |
| Table C.2 | c2_turnout_m2_constant_coef | -43.402 | -42.177 | -43.402 | environment |
| Table C.2 | c2_turnout_m2_constant_se | 15.695 | 16.529 | 15.695 | environment |
| Table C.2 | c2_turnout_m2_r2 | 0.695 | 0.702 | 0.695 | environment |
| Table C.2 | c2_turnout_m2_treated_coef | 9.029 | 5.985 | 9.029 | environment |
| Table C.2 | c2_turnout_m2_treated_se | 13.372 | 15.442 | 13.372 | environment |

Every published value a deposited script fails to reproduce on current
R. The rewrite reproduces all of them, which is the signature of
environment drift rather than of an error in the deposit.

The complete row-by-row table, all 481 of them, is
`ground_truth/green_etal_2016_ground_truth.csv`.

# Maintained rewrite

The rewrite lives in `maintained/`: seventeen scripts covering four
cleaning steps, the six published tables, the appendix margin and
turnout tables, appendix Table D.5, Figure 2, footnote 3’s cost
calculation, the randomization inference, and the in-text claims. It is
a translation, not a reanalysis: every estimator, specification and
sample restriction is the one the paper used.

## Architecture

Each experiment’s analysis reads the archive’s canonical `exp_N.RData`
object, which carries both the analysis frame and that experiment’s
10,000-column permutation matrix. The `clean_expN.R` scripts rebuild the
same frames from the raw deposited files in tidy form and are the
readable account of how each variable is constructed, but no published
number is taken from them. That separation is deliberate and
load-bearing: `clean_exp2.R` redraws the observed assignment with the
same seed the archive uses, and therefore selects the wrong column on
any current R.

Weighted models use `estimatr::lm_robust(se_type = "HC2")` in place of
`lm()` followed by a `coeftest(fit, vcovHC(fit, type = "HC2"))` wrapper,
which is the same estimator with the same standard errors. Pooling uses
`metafor::rma(method = "FE")` in place of `rmeta::meta.summaries()`. The
randomization inference reimplements the archive’s `get_f()` as
`f_treat()` in `helpers.R` and loops over the deposited permutation
matrices, computing all four experiments rather than carrying any
p-value forward as a constant.

## Deprecated patterns replaced

| Original pattern | Replacement |
|:---|:---|
| `rm(list = ls())` | (omitted) |
| `setwd("")` | `here::here()` |
| `lm()` + `coeftest(vcovHC, 'HC2')` | `estimatr::lm_robust(se_type = "HC2")` |
| `rmeta::meta.summaries(method = 'fixed')` | `metafor::rma(method = "FE")` |
| `stargazer` + `sink()` | `write_csv()` to `output/` |
| `xtable` + `print.xtable` | `write_csv()` to `output/` |
| `within()` blocks over base indexing | `mutate()` paragraphs |
| `merge()` | `left_join()` |
| `multiplot()` (grid-based) | `gridExtra::arrangeGrob()` |
| `pdf()` / `png()` devices | `ggsave()` |
| `library(beepr)` + `beep()` | (omitted) |
| magrittr pipe | native pipe |

Deprecated patterns and their replacements in the maintained rewrite.

# Randomization inference

The article reports one randomization inference p-value per experiment,
for vote share, in sections 5.1 through 5.4. All four reproduce.

| Experiment   | Outcome | Rewrite | Published |
|:-------------|:--------|:--------|:----------|
| Experiment 1 | share   | 0.2225  | 0.22      |
| Experiment 1 | margin  | 0.1573  |           |
| Experiment 1 | turnout | 0.5261  |           |
| Experiment 2 | share   | 0.8974  | 0.90      |
| Experiment 2 | margin  | 0.8928  |           |
| Experiment 2 | turnout | 0.6967  |           |
| Experiment 3 | share   | 0.0208  | 0.02      |
| Experiment 3 | margin  | 0.2633  |           |
| Experiment 3 | turnout | 0.3322  |           |
| Experiment 4 | share   | 0.7714  | 0.77      |
| Experiment 4 | margin  | 0.8770  |           |
| Experiment 4 | turnout | 0.8509  |           |

Randomization inference p-values for the joint null of no direct and no
indirect effect, 10,000 permutations each. The article states the vote
share p-values only.

The margin and turnout p-values are computed here for completeness and
appear nowhere in the article or its appendix, so they have no
ground-truth row: the ground truth records what the paper claims, and a
quantity the paper never states is not a claim. Producing them is cheap:
all twelve p-values together, 40,000 permutations and 120,000 pairs of
weighted models, take under two minutes.

Every p-value here is computed rather than carried. The permutation
matrices are already inside the `exp_3.RData` and `exp_4.RData` objects
the table scripts load, so no additional file is read, and the two loops
together run in under a minute. A number typed into a script is not a
number the script produces.

# Figure 2 verification

Figure 2 traces how an agnostic, an optimistic and a skeptical observer
update a prior about the direct effect as the four experiments arrive,
and each of its fifteen panels is labelled with the posterior mean, the
posterior standard deviation and the posterior probability that the
effect is positive. Those forty-five numbers are the figure’s content,
and all forty-five reproduce.

| Observer | Panel    | Quantity     | Paper | Rewrite | Match |
|:---------|:---------|:-------------|:------|:--------|------:|
| Agnostic | Prior    | mean         | 0.000 | 0.000   |     1 |
| Agnostic | Prior    | pr(ATE \> 0) | 0.500 | 0.500   |     1 |
| Agnostic | Prior    | sd           | 0.050 | 0.050   |     1 |
| Agnostic | Update 1 | mean         | 0.022 | 0.022   |     1 |
| Agnostic | Update 1 | pr(ATE \> 0) | 0.915 | 0.915   |     1 |
| Agnostic | Update 1 | sd           | 0.016 | 0.016   |     1 |
| Agnostic | Update 2 | mean         | 0.019 | 0.019   |     1 |
| Agnostic | Update 2 | pr(ATE \> 0) | 0.895 | 0.895   |     1 |
| Agnostic | Update 2 | sd           | 0.016 | 0.016   |     1 |
| Agnostic | Update 3 | mean         | 0.019 | 0.019   |     1 |
| Agnostic | Update 3 | pr(ATE \> 0) | 0.993 | 0.993   |     1 |
| Agnostic | Update 3 | sd           | 0.008 | 0.008   |     1 |
| Agnostic | Update 4 | mean         | 0.016 | 0.016   |     1 |
| Agnostic | Update 4 | pr(ATE \> 0) | 0.988 | 0.988   |     1 |
| Agnostic | Update 4 | sd           | 0.007 | 0.007   |     1 |
| Optimist | Prior    | mean         | 0.050 | 0.050   |     1 |
| Optimist | Prior    | pr(ATE \> 0) | 0.841 | 0.841   |     1 |
| Optimist | Prior    | sd           | 0.050 | 0.050   |     1 |
| Optimist | Update 1 | mean         | 0.027 | 0.027   |     1 |
| Optimist | Update 1 | pr(ATE \> 0) | 0.955 | 0.955   |     1 |
| Optimist | Update 1 | sd           | 0.016 | 0.016   |     1 |
| Optimist | Update 2 | mean         | 0.024 | 0.024   |     1 |
| Optimist | Update 2 | pr(ATE \> 0) | 0.941 | 0.941   |     1 |
| Optimist | Update 2 | sd           | 0.016 | 0.016   |     1 |
| Optimist | Update 3 | mean         | 0.020 | 0.020   |     1 |
| Optimist | Update 3 | pr(ATE \> 0) | 0.996 | 0.996   |     1 |
| Optimist | Update 3 | sd           | 0.008 | 0.008   |     1 |
| Optimist | Update 4 | mean         | 0.017 | 0.017   |     1 |
| Optimist | Update 4 | pr(ATE \> 0) | 0.991 | 0.991   |     1 |
| Optimist | Update 4 | sd           | 0.007 | 0.007   |     1 |
| Skeptic  | Prior    | mean         | 0.000 | 0.000   |     1 |
| Skeptic  | Prior    | pr(ATE \> 0) | 0.500 | 0.500   |     1 |
| Skeptic  | Prior    | sd           | 0.010 | 0.010   |     1 |
| Skeptic  | Update 1 | mean         | 0.006 | 0.006   |     1 |
| Skeptic  | Update 1 | pr(ATE \> 0) | 0.768 | 0.768   |     1 |
| Skeptic  | Update 1 | sd           | 0.009 | 0.009   |     1 |
| Skeptic  | Update 2 | mean         | 0.006 | 0.006   |     1 |
| Skeptic  | Update 2 | pr(ATE \> 0) | 0.754 | 0.754   |     1 |
| Skeptic  | Update 2 | sd           | 0.009 | 0.009   |     1 |
| Skeptic  | Update 3 | mean         | 0.012 | 0.012   |     1 |
| Skeptic  | Update 3 | pr(ATE \> 0) | 0.977 | 0.977   |     1 |
| Skeptic  | Update 3 | sd           | 0.006 | 0.006   |     1 |
| Skeptic  | Update 4 | mean         | 0.011 | 0.011   |     1 |
| Skeptic  | Update 4 | pr(ATE \> 0) | 0.966 | 0.966   |     1 |
| Skeptic  | Update 4 | sd           | 0.006 | 0.006   |     1 |

Figure 2 panel labels, transcribed from page 149 of the article, against
the maintained rewrite.

The rewrite updates on the fitted coefficients at full precision,
reading them from `maintained/output/table_7_pooled.csv`, which is what
the original does. Retyping the four direct effects at the three decimal
places Table 7 prints would carry a rounding into a calculation rather
than into a display.

<img src="maintained/output/figure_2_bayesian.png" style="width:100.0%"
alt="Figure 2 as reproduced by the maintained rewrite." />

# Maintained rewrite verification

Every published value with a counterpart in the pipeline carries
`match_rewrite = 1`: **400** of 400, with 0 differing. The prose is
where the coverage was thinnest and is now complete, so it is worth
setting out separately.

| Location | Claim | Paper | Rewrite | Verdict |
|:---|:---|:---|:---|:---|
| Appendix B | appb_e1_untreatable | 5 | 5 | matches |
| Appendix B | appb_e2_permutations | 10000 | 10000 | matches |
| Appendix B | appb_e3_permutations | 10000 | 10000 | matches |
| Appendix B | appb_e3_precincts | 131 | 131 | matches |
| Appendix B | appb_e3_treated | 30 | 30 | matches |
| Appendix B | appb_e4_permutations | 10000 | 10000 | matches |
| Appendix B | appb_e4_precincts | 88 | 88 | matches |
| Appendix B | appb_e4_treated | 20 | 20 | matches |
| Appendix D | appd_e4_negative_interactions | 1 | 1 | holds |
| Appendix D | appd_no_precise_interactions | 1 | 1 | holds |
| Appendix D | appd_pooled_direct_interaction | 0.009 | 0.009 | matches |
| Appendix D | appd_pooled_direct_interaction_se | 0.007 | 0.007 | matches |
| Appendix D | appd_pooled_indirect_interaction | 0.007 | 0.007 | matches |
| Appendix D | appd_pooled_indirect_interaction_se | 0.007 | 0.007 | matches |
| Appendix D | appd_three_of_four_positive | 3 | 3 | holds |
| Footnote 1, p. 144 | text_fn1_e1_treated_assigned | 23 | 23 | matches |
| Footnote 1, p. 144 | text_fn1_e4_treated_assigned | 20 | 20 | matches |
| Footnote 3, p. 149 | text_fn3_ci_high | 13.71 | 13.17 | holds |
| Footnote 3, p. 149 | text_fn3_ci_level | 95 | 95 | matches |
| Footnote 3, p. 149 | text_fn3_ci_low | 1.70 | 1.70 | holds |
| Footnote 3, p. 149 | text_fn3_cost_direct | 3.18 | 3.18 | matches |
| Footnote 3, p. 149 | text_fn3_cost_total | 1.69 | 1.69 | matches |
| Footnote 3, p. 149 | text_fn3_direct_points | 1.7 | 1.7 | matches |
| Footnote 3, p. 149 | text_fn3_total_cost | 13045 | 13045 | matches |
| Footnote 3, p. 149 | text_fn3_total_turnout | 241613 | 241613 | matches |
| Section 3, p. 144 | text_design_e1_treatable | 88 | 88 | matches |
| Section 3, p. 144 | text_design_e2_initial | 128 | 128 | matches |
| Section 3, p. 144 | text_design_e2_restricted | 69 | 69 | matches |
| Section 3, p. 144 | text_design_e3_precincts | 131 | 131 | matches |
| Section 3, p. 144 | text_design_e4_precincts | 88 | 88 | matches |
| Section 4, p. 147 | text_ri_permutations | 10000 | 10000 | matches |
| Section 5.1, p. 147 | text_r1_direct_m1 | 2.5 | 2.5 | matches |
| Section 5.1, p. 147 | text_r1_direct_m1_se | 2.7 | 2.7 | matches |
| Section 5.1, p. 147 | text_r1_direct_m2 | 2.5 | 2.5 | matches |
| Section 5.1, p. 147 | text_r1_direct_m2_se | 1.7 | 1.7 | matches |
| Section 5.1, p. 147 | text_r1_ri_p | 0.22 | 0.22 | matches |
| Section 5.1, p. 147 | text_r1_spillover_m1 | 3.7 | 3.7 | matches |
| Section 5.1, p. 147 | text_r1_spillover_m1_se | 2.7 | 2.7 | matches |
| Section 5.1, p. 147 | text_r1_spillover_m2 | 1.8 | 1.8 | matches |
| Section 5.1, p. 147 | text_r1_spillover_m2_se | 1.6 | 1.6 | matches |
| Section 5.2, p. 147 | text_r2_direct_m1 | 0.9 | 0.9 | matches |
| Section 5.2, p. 147 | text_r2_direct_m2 | 1.4 | 1.4 | matches |
| Section 5.2, p. 147 | text_r2_ri_p | 0.90 | 0.90 | matches |
| Section 5.3, p. 148 | text_r3_direct_m2 | 1.8 | 1.8 | matches |
| Section 5.3, p. 148 | text_r3_ri_p | 0.02 | 0.02 | matches |
| Section 5.3, p. 148 | text_r3_spillover_m2 | 1.8 | 1.8 | matches |
| Section 5.4, p. 148 | text_r4_direct_m2 | 1.2 | 1.2 | matches |
| Section 5.4, p. 148 | text_r4_ri_p | 0.77 | 0.77 | matches |
| Section 5.4, p. 148 | text_r4_spillover_m2 | 2.0 | 2.0 | matches |
| Section 5.5, p. 148 | text_turnout_no_effect | 1 | 1 | holds |
| Section 5.5, p. 148 | text_turnout_pooled_direct | 7.2 | 7.2 | matches |
| Section 5.5, p. 148 | text_turnout_pooled_direct_se | 9.5 | 9.5 | matches |
| Section 6, p. 148 | text_agnostic_pr | 98.8 | 98.8 | matches |
| Section 6, p. 148 | text_optimist_pr | 0.991 | 0.991 | matches |
| Section 6, p. 148 | text_pooled_direct | 1.7 | 1.7 | matches |
| Section 6, p. 148 | text_pooled_direct_se | 0.7 | 0.7 | matches |
| Section 6, p. 148 | text_pooled_indirect | 1.5 | 1.5 | matches |
| Section 6, p. 148 | text_pooled_indirect_se | 0.6 | 0.6 | matches |
| Section 6, p. 148 | text_pooled_just_over_one | 1 | 1 | holds |
| Section 6, p. 148 | text_prior_diffuse_sd | 5 | 5 | matches |
| Section 6, p. 148 | text_prior_skeptic_sd | 1 | 1 | matches |
| Section 6, p. 148 | text_skeptic_pr | 0.966 | 0.966 | matches |

Every quantity the article states in prose, in a footnote, or in the
appendix text, against the maintained rewrite.

Two of these need a word. Footnote 3’s cost per vote is computed by the
article from the pooled direct effect as Table 7 prints it, at three
decimals, so $13,045 / (241{,}613 \times 0.017) = \$3.18$ is the
article’s own arithmetic and reproduces exactly; at the pooled
estimate’s full precision the same calculation gives \$3.26. And the
footnote’s 95 per cent interval is drawn in the deposit from 10,000
normal variates with no seed, so no single number is the published one.
Over 200 seeds the lower endpoint runs from \$1.66 to \$1.73 and the
upper from \$11.79 to \$15.19, and the published \$1.70 and \$13.71 both
sit inside those ranges.

# Errata

None. The extraction covers all 481 numbers the article and its appendix
print, and no row carries `defect_locus = paper_internal`: nothing in
the article contradicts its own tables, its own data, or the code the
authors deposited. The 43 values a deposited script no longer reproduces
are a property of R rather than of the paper, and the paper’s numbers
are the correct ones.

Two things about the published record are worth recording without rising
to errata. Table 5 prints its second goodness-of-fit row without the
`R2` label its three sibling tables carry, so the values 0.094 and 0.825
sit under a blank stub. And the appendix numbers its tables C.1 through
C.4 and then D.5, so there is no Table D.1 through D.4. Neither
misstates a quantity.

# R environment

| Item      | Value                  |
|:----------|:-----------------------|
| R version | 4.6.0                  |
| Platform  | aarch64-apple-darwin23 |
| Date run  | 2026-08-03             |

| Package   | Version |
|:----------|:--------|
| estimatr  | 1.0.6   |
| metafor   | 5.0.1   |
| dplyr     | 1.2.1   |
| ggplot2   | 4.0.3   |
| tidyr     | 1.3.2   |
| purrr     | 1.2.2   |
| here      | 1.0.2   |
| gridExtra | 2.3     |

Package versions used for the run behind this report.
