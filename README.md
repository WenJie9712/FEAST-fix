FEAST - a scalable algorithm for quantifying the origins of complex microbial communities
=======================

A major challenge of analyzing the compositional structure of microbiome data is identifying its potential origins. Here, we introduce Fast Expectation-mAximization microbial Source Tracking (*FEAST*), a ready-to-use scalable framework that can simultaneously estimate the contribution of thousands of potential source environments in a timely manner, thereby helping unravel the origins of complex microbial communities. The information gained from *FEAST* may provide insight into quantifying contamination, tracking the formation of developing microbial communities, as well as distinguishing and characterizing bacteria-related health conditions.

For more details see Shenhav et al., Nature Methods 2019 (https://www.nature.com/articles/s41592-019-0431-x).

What's new in 0.1.1
-----------------------

* `FEAST_rarefy()` no longer crashes with `the condition has length > 1` on R >= 4.2 (the matrix type check used `class()`, which returns two values for matrices).
* `FEAST()` returns the documented `S1` by `S2` proportion matrix `P` instead of a flat list, so `rownames(P)` / `colnames(P)` and the plotting functions work as advertised.
* New `plot_type = "pie"` option and new `palette` option for the plotting functions.
* Compilation artefacts were removed from `src/`.

See [NEWS.md](NEWS.md) for the complete change list.

Support
-----------------------

For support using FEAST, please email: liashenhav@gmail.com. This is our new beta version - your comments/insights would be greatly appreciated.

Software requirements and installation
-----------------------

*FEAST* is implemented in R (>= 3.4.4) and requires **Rcpp**, **RcppArmadillo**, **vegan**, **dplyr**, **reshape2**, **gridExtra**, **ggplot2** and **ggthemes**. Install and load them before installing *FEAST*. On macOS, if you have installation issues with **Rcpp** or **RcppArmadillo**, install homebrew or the Xcode command line tools and reinstall them.

```r
Packages <- c("Rcpp", "RcppArmadillo", "vegan", "dplyr", "reshape2",
              "gridExtra", "ggplot2", "ggthemes")
install.packages(Packages)
lapply(Packages, library, character.only = TRUE)
```

Install *FEAST* from a local clone of this repository (recommended when you work on the package itself):

```r
devtools::install_local("path/to/FEAST")
```

or from GitHub:

```r
devtools::install_github("cozygene/FEAST", ref = "FEAST")
```

The GitHub branch is the older upstream version; it does not contain the 0.1.1 fixes.

Quick start
-----------------------

The `Demo/` directory contains `otu_example_multi.txt` and `metadata_example_multi.txt` (many sinks,
each with its own sources), which are used in the quick start below. `otu_example.txt` and
`metadata_example.txt` are the smaller files from the earlier single-sink release; they have no `id`
column, so add one (for example `1` for the sink and all its sources) before calling `FEAST()`.

```r
library(FEAST)

# FEAST() and the plotting functions call setwd(dir_path), so keep the paths absolute
data_dir <- normalizePath("Demo")
out_dir  <- file.path(tempdir(), "FEAST_results")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

metadata <- Load_metadata(metadata_path = file.path(data_dir, "metadata_example_multi.txt"))
otus <- Load_CountMatrix(CountMatrix_path = file.path(data_dir, "otu_example_multi.txt"))

FEAST_output <- FEAST(C = otus, metadata = metadata,
                      different_sources_flag = 1,
                      dir_path = out_dir, outfile = "demo")
```

`FEAST()` prints its progress, writes `demo_source_contributions_matrix.txt` into `dir_path` and returns the same matrix as a data frame.

Plotting the results
-----------------------

`PlotSourceContribution()` saves stacked bar plots or pie charts of the estimated proportions:

| argument | description |
| ------------- | ------------- |
| `SinkNames` | vector with the sink names to plot |
| `SourceNames` | vector with all source names (i.e. `colnames(FEAST_output)`) |
| `Same_sources_flag` | `1` if all sinks share the same group of sources, `0` if each sink has its own sources |
| `mixing_proportions` | the matrix returned by `FEAST()` |
| `dir_path` | directory the `.png` file is written to |
| `Plot_title` | title of the plot and prefix of the `.png` file |
| `N` | number of plots per `.png` file |
| `plot_type` | `"bar"` (default) or `"pie"` |
| `palette` | `NULL` (economist palette), a single RColorBrewer palette name, or a vector of colours |

```r
K <- 2

# stacked bar plots
PlotSourceContribution(SinkNames = rownames(FEAST_output)[1:K],
                       SourceNames = colnames(FEAST_output),
                       Same_sources_flag = 0, mixing_proportions = FEAST_output,
                       dir_path = out_dir, Plot_title = "bar_", N = 2)

# the same data as pie charts, with a different colour palette
PlotSourceContribution(SinkNames = rownames(FEAST_output)[1:K],
                       SourceNames = colnames(FEAST_output),
                       Same_sources_flag = 0, mixing_proportions = FEAST_output,
                       dir_path = out_dir, Plot_title = "pie_", N = 2,
                       plot_type = "pie", palette = "Set2")
```

Output files are named `<Plot_title><k>_FEAST.png` for bar plots and
`<Plot_title>_pie<k>_FEAST.png` for pie charts, so the two types never overwrite each other.
With `Same_sources_flag = 1`, a single figure containing every requested sink is written
(`<Plot_title>_FEAST.png` or `<Plot_title>_pie_FEAST.png`).

A single sink can also be drawn directly, which returns the `ggplot` object:

```r
p <- PlotPerSinkSourceContribution(SourceNames = colnames(FEAST_output)[!is.na(FEAST_output[1, ])],
                                   source_contribution = FEAST_output[1, ][!is.na(FEAST_output[1, ])],
                                   sink_name = rownames(FEAST_output)[1],
                                   dir_path = out_dir, save_plot = 0,
                                   plot_type = "pie", palette = "Dark2")
p
```

Input format
-----------------------

The input to *FEAST* is composed of two tab-delimited ASCII text files.

(1) count table - An m by n count matrix, where m is the number of samples and n is the number of taxa. Row names are the sample ids ('SampleID'). Column names are the taxa ids. Every consecutive column contains read counts for each sample. Note that this order must be respected.

count matrix (first 4 rows and columns):

| | ERR525698 |ERR525693 | ERR525688| ERR525699|
| ------------- | ------------- |------------- |------------- |------------- |
| taxa_1  |  0 | 5 | 0|20 |
| taxa_2  |  15 | 5 | 0|0 |
| taxa_3  |  0 | 13 | 200|0 |
| taxa_4  |  4 | 5 | 0|0 |

(2) metadata - An m by 3 table, where m is the number of samples. The metadata table has three columns (i.e., 'Env', 'SourceSink', 'id'). The first column is a description of the sampled environment (e.g., human gut), the second column indicates if this sample is a source or a sink (can take the value 'Source' or 'Sink'). The third column is the Sink-Source id. When using multiple sinks, each tested with the same group of sources, only the rows with 'SourceSink' = Sink will get an id (between 1 - number of sinks in the data). In this scenario, the sources' ids are blank. When using multiple sinks, each tested with a distinct group of sources, each combination of sink and its corresponding sources should get the same id (between 1 - number of sinks in the data). Note that these names must be respected.

*using multiple sinks, each tested with the same group of sources:*

| SampleID | Env |SourceSink | id |
| ------------- | ------------- |------------- |-------------|
| ERR525698  |  infant gut 1 | Sink | 1
| ERR525693  |  infant gut 2 | Sink | 2 |
| ERR525688   |  Adult gut 1 | Source| NA |
| ERR525699  |  Adult gut 2 | Source | NA |
| ERR525697  |  Adult gut 3 | Source | NA |

*using multiple sinks, each tested with a different group of sources:*

| SampleID | Env |SourceSink | id |
| ------------- | ------------- |------------- |-------------|
| ERR525698  |  infant gut 1 | Sink | 1
| ERR525688   |  Adult gut 1 | Source| 1 |
| ERR525691   |  Adult gut 2 | Source | 1 |
| ERR525699  |  infant gut 2 | Sink | 2 |
| ERR525697   |  Adult gut 3 | Source | 2 |
| ERR525696   |  Adult gut 4 | Source | 2 |

Output
-----------------------

*FEAST* returns an S1 by S2 matrix P, where S1 is the number of sinks and S2 is the number of sources (including an unknown source). Each row in matrix P sums to 1. Pij is the contribution of source j to sink i. If Pij == NA it indicates that source j was not used in the analysis of sink i. The same matrix is written to `<outfile>_source_contributions_matrix.txt`.

| infant gut 2  |Adult gut 1 | Adult gut 2| Adult gut 3| Adult skin 1 |  Adult skin 2|  Adult skin 3| Soil 1 | Soil 2 | unknown|
| ------------- | ------------- |------------- |------------- |------------- |------------- |------------- |------------- |------------- |------------- |
|  5.108461e-01  |  9.584116e-23 | 4.980321e-12 | 2.623358e-02|5.043635e-13 | 8.213667e-59| 1.773058e-10 |  2.704118e-14 |  3.460067e-02 |  4.283196e-01 |
