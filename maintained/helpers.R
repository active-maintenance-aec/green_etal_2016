# green_etal_2016: helpers.R
# Shared packages and helper functions sourced by every script in maintained/.

library(here)
library(tidyverse)
library(estimatr)
library(metafor)
library(gridExtra)

here::i_am("maintained/helpers.R")

# Observed F-statistic for the treatment terms ----
# Fits the full model and the same model with the treatment terms dropped, both
# with inverse-probability weights, and returns the F-statistic comparing them.
# This is the statistic the paper's randomization inference permutes; it
# reimplements get_f() from the archive's Lawn_Signs_Source.R.
f_treat <- function(formula_str, treat_var, wt_name, data) {
  data$w_ <- data[[wt_name]]
  full <- lm(as.formula(formula_str), weights = w_, data = data)
  restricted_str <- sub(paste0(treat_var, " \\+\\s*"), "", formula_str)
  rest <- lm(as.formula(restricted_str), weights = w_, data = data)
  anova(rest, full)$F[2]
}
