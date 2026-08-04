#! /usr/bin/env Rscript

# ===== Argument Parsing ===== #
# USAGE: alluvial.R one_id_column [an arbitrary number of cluster files]
# Cluster files should have a ClusterNumber column that will be renamed to the filename
# [one_id_column]    ClusterNumber
# ============================ #

args <- commandArgs(trailingOnly = TRUE)
id_col <- args[1]
files  <- args[-1]

# == Testing
# id_col <- "SequenceName"
# files <- c("blast_results.tsv", "wgs_clusters.tsv", "orf2_clusters.tsv")

# ====== Libraries
library(tidyverse)
library(magrittr)
library(ggalluvial)
library(purrr)

# ====== Load arbitrary number of cluster files
tables <- lapply(
  files,
  function(f) {
    x <- read.delim(f, check.names = FALSE)
    method <- tools::file_path_sans_ext(basename(f))
    names(x)[names(x) == "ClusterNumber"] <- method
    x[[method]] <- as.character(x[[method]])
    x
  }
)

# ====== Merge into one data frame
df <- reduce(
  tables,
  inner_join,
  by = id_col
)

cluster_cols <- setdiff(names(df), id_col)
method_levels <- tools::file_path_sans_ext(basename(files))

plot_df <-
  df %>%
  pivot_longer(
    cols = all_of(cluster_cols),
    names_to = "method",
    values_to = "cluster"
  ) %>%
  mutate(
    method = factor(method, levels = method_levels)
  )

# ====== Plot alluvial
ggplot(
  plot_df,
  aes(
    x = method,
    stratum = cluster,
    alluvium = .data[[id_col]],
    y = 1,
    fill = cluster
  )
) +
  geom_flow(alpha = 0.8) +
  geom_stratum() +
  geom_text(
    stat = "stratum",
    aes(label = after_stat(stratum))
  ) +
  theme_classic() +
  theme(
    legend.position = "none",
    axis.title.y = element_blank(),
    #axis.text.y = element_blank(), # TBD: decide if I want to drop y axis labels later
    axis.ticks.y = element_blank(),
    axis.title.x = element_blank(),
  )

# ==== Save plot
ggsave("alluvial.png", width=6, height=4)


