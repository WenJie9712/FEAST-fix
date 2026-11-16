# FEAST 0.1.1

Released 2026-11-16.

## Bug fixes

* `FEAST_rarefy()` no longer fails with `the condition has length > 1` on R >= 4.2.
  `class()` returns `c("matrix", "array")` for a matrix, so
  `if (!is.element(class(x), c("matrix", "data.frame", "array")))` produced a logical
  vector longer than one element and `if` aborted. The check uses `inherits()`, which
  always returns a single logical.
* `FEAST()` returns the `S1` by `S2` proportion matrix `P` announced in the documentation.
  It used to return `list = c(proportions_mat, FEAST_output)`, a flat list of 10 elements,
  so `rownames()` / `colnames()` of the result were `NULL` and `PlotSourceContribution()`
  could not be applied to it.
* The vignette no longer calls `devtools::install_github("cozygene/FEAST")` while it is
  being knitted (the chunk is now `eval = FALSE`). That call replaced a local build with
  the upstream version, which still contains the `FEAST_rarefy()` bug.

## New features

* New `plot_type` argument for `PlotSourceContribution()` and
  `PlotPerSinkSourceContribution()`: `"bar"` (default, unchanged behaviour) or `"pie"`.
  Pie charts are drawn one per sink sample; with `Same_sources_flag = 1` a single
  facetted figure with one pie per sink is produced.
* New `palette` argument, shared by both plotting functions:
  `NULL` (default) keeps the ggthemes economist palette, a single string such as
  `"Set2"` selects an RColorBrewer palette, and a character vector of colours is used
  as given.
* Pie charts are saved with a `_pie` suffix (`*_pie_FEAST.png`), so bar plots and pie
  charts of the same data no longer overwrite each other.

## Documentation

* Vignette: added a pie chart example and the `palette` / `plot_type` arguments; the
  example data path now points to `Demo/`.
* README: added installation, quick start, plotting reference and output description.

## Housekeeping

* Removed compiled artefacts (`*.o`, `*.so`, `*.dll`) from `src/`; they are rebuilt on
  installation.
