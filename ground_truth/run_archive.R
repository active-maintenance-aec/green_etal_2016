# green_etal_2016/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original/ (run download_original.R first)
# Description: Runs the deposited scripts twice, each time in a scratch copy of original/
#   and never in original/ itself: once as shipped, and once from a copy stripped of the
#   intermediates the deposit ships. Records each script's exit status per pass, and every
#   deposited file a pass withheld, rebuilt, overwrote, or added.
#
#   The deposit's write calls are all commented out: every save(), every sink() and the
#   one print.xtable(file = ) carry a leading #. A measured zero in the as-shipped pass is
#   therefore the deposit writing nothing, not scripts failing before their writes. The
#   stripped pass withholds the ten files those commented saves would write (the
#   permutation matrices, the two data-with-assignment objects, exp_1 to exp_4, and
#   meta_results.tex), and since no deposited code writes them, each is withheld and none
#   is rebuilt.
#
#   The four *_RA_Function.R scripts are not run in either pass. They regenerate the
#   permutation matrices by redrawing up to 100,000 randomizations, their saves are
#   commented out, so a run would write nothing, and Experiment_4_RA_Function.R calls
#   beepr, which is not part of this environment. Lawn_Signs_Source.R is only ever
#   sourced by the other scripts and gets no row.
#
#   Pooled_analysis.R and in_text_calculations.R load exp_N.rdata where the deposit ships
#   exp_N.RData, so they find their inputs only on a case-insensitive file system. This
#   script is not part of run_all.R; it was run on macOS.
#
#   The ground truth's archive column, ground_truth/archive_values.csv, is not written
#   here.

library(here)
library(tidyverse)

here::i_am("ground_truth/run_archive.R")

stopifnot(dir.exists(here::here("original")))

analysis_scripts <- c("Experiment_1_Analysis.R", "Experiment_2_Analysis.R",
                      "Experiment_3_Analysis.R", "Experiment_4_Analysis.R",
                      "Pooled_analysis.R", "in_text_calculations.R")
ra_scripts <- str_glue("Experiment_{1:4}_RA_Function.R")
intermediates <- c("Experiment_1_Permutation_Matrix.rdata",
                   "Experiment_2_Permutation_Matrix.rdata",
                   "Experiment_3_Data_with_Random_Assignment.RData",
                   "Experiment_4_Permutation_Matrix.rdata",
                   "Experiment_4_Data_with_Random_Assignment.RData",
                   "exp_1.RData", "exp_2.RData", "exp_3.RData", "exp_4.RData",
                   "meta_results.tex")
stopifnot(all(file.exists(here::here("original", c(analysis_scripts, ra_scripts,
                                                   intermediates)))))

# Twice the longest as-shipped script, which takes a few minutes.
timeout_seconds <- 1800

# One pass ----
# Copies original/ to a fresh scratch directory, withholds the given files, runs each
# analysis script in its own clean R session, and compares the copy afterward with the
# deposit file by file.
run_pass <- function(withhold) {
  scratch <- tempfile("green_etal_2016_archive_")
  dir.create(scratch)
  file.copy(list.files(here::here("original"), full.names = TRUE), scratch)
  file.remove(file.path(scratch, withhold))
  before <- tools::md5sum(list.files(scratch, full.names = TRUE))
  names(before) <- basename(names(before))

  status <- map(analysis_scripts, function(script) {
    log_file <- file.path(scratch, str_c(script, ".log"))
    exit_status <- withr::with_dir(scratch, system2(
      file.path(R.home("bin"), "Rscript"), c("--vanilla", script),
      stdout = log_file, stderr = log_file, timeout = timeout_seconds
    ))
    log <- read_lines(log_file)
    file.remove(log_file)
    # A failed load() reports only the connection; the warning before it names the file.
    missing_file <- str_match(log, "cannot open compressed file '([^']+)'")[, 2]
    missing_file <- missing_file[!is.na(missing_file)]
    error_line <- str_subset(log, "^Error")
    if (length(error_line) > 0 && length(missing_file) > 0) {
      error_line <- str_glue("{error_line[1]} (cannot open {missing_file[1]})")
    }
    tibble(
      script, exit_status,
      outcome = case_when(exit_status == 124 ~ "timeout",
                          exit_status == 0 ~ "clean",
                          .default = "error"),
      stopped_at = case_when(
        exit_status == 124 ~ str_glue("killed at the {timeout_seconds}-second limit"),
        exit_status == 0 ~ NA_character_,
        length(error_line) > 0 ~ str_squish(error_line[1]),
        .default = str_squish(last(log))
      )
    )
  }) |> list_rbind()

  after <- tools::md5sum(list.files(scratch, full.names = TRUE))
  names(after) <- basename(names(after))
  deposit <- tools::md5sum(list.files(here::here("original"), full.names = TRUE))
  names(deposit) <- basename(names(deposit))

  files <- tibble(file = union(names(deposit), names(after))) |>
    mutate(
      md5_deposit = unname(deposit[file]),
      md5_before = unname(before[file]),
      md5_after = unname(after[file]),
      effect = case_when(
        is.na(md5_deposit) & !is.na(md5_after) ~ "added",
        file %in% withhold & is.na(md5_after) ~ "withheld",
        file %in% withhold ~ "rebuilt",
        !is.na(md5_before) & is.na(md5_after) ~ "deleted",
        !is.na(md5_before) & md5_before != md5_after ~ "overwritten",
        .default = NA_character_
      ),
      matches_deposit = if_else(effect %in% c("rebuilt", "overwritten"),
                                md5_after == md5_deposit, NA)
    ) |>
    filter(!is.na(effect)) |>
    select(file, effect, matches_deposit)

  unlink(scratch, recursive = TRUE)
  list(status = status, files = files)
}

# Both passes ----
as_shipped <- run_pass(withhold = character())
stripped <- run_pass(withhold = intermediates)

# The RA scripts' rows say why they were not run, in both passes.
ra_rows <- tibble(
  script = ra_scripts, exit_status = NA_integer_, outcome = "not_run",
  stopped_at = "not run: regenerates a deposited permutation matrix by redrawing randomizations, and its save() is commented out, so a run writes nothing"
)

run_status <- bind_rows(
  as_shipped = bind_rows(as_shipped$status, ra_rows),
  stripped = bind_rows(stripped$status, ra_rows),
  .id = "pass"
) |>
  mutate(role = if_else(script %in% analysis_scripts, "analysis", "other"),
         exit_status = as.integer(exit_status)) |>
  select(pass, script, role, exit_status, outcome, stopped_at)

overwrites <- bind_rows(as_shipped = as_shipped$files, stripped = stripped$files,
                        .id = "pass") |>
  select(pass, file, effect, matches_deposit)

stopifnot(
  nrow(run_status) == 2 * (length(analysis_scripts) + length(ra_scripts)),
  all(run_status$outcome %in% c("clean", "error", "timeout", "not_run")),
  all(overwrites$effect %in% c("added", "overwritten", "rebuilt", "withheld", "deleted")),
  setequal(overwrites$file[overwrites$pass == "stripped" &
                             overwrites$effect %in% c("withheld", "rebuilt")],
           intermediates)
)

write_csv(run_status, here::here("ground_truth", "archive_run_status.csv"))
write_csv(overwrites, here::here("ground_truth", "archive_overwrites.csv"))
print(run_status, n = nrow(run_status), width = 200)
print(overwrites, n = nrow(overwrites))
