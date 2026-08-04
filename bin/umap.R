#! /usr/bin/env Rscript

# === Argument parsing === #
# USAGE: umap.R distance_tsv metadata_tsv id_column color_by_column
# OUTPUT: umap.png
# ======================== # 

args <- commandArgs(trailingOnly = TRUE)

dist_file     <- args[1]
metadata_file <- args[2]
id_col        <- args[3] # accession_version
colour_by     <- args[4]

# == Testing
# dist_file = "data/mash_distance.tsv"
# metadata_file = "data/major_clusters.tsv"
# id_col = "accession"
# colour_by = "cluster"

# === Libraries
library(tidyverse)
library(magrittr)
library(uwot)

# === Read in distance and metadata files
dist <- read.delim(dist_file)
meta <- read.delim(metadata_file)

# === Build square matrix
nodes <- sort(unique(c(dist$node1, dist$node2)))

D <- matrix(
  0,
  nrow = length(nodes),
  ncol = length(nodes),
  dimnames = list(nodes, nodes)
)

D[cbind(match(dist$node1,nodes),
        match(dist$node2,nodes))] <- dist$dist

D[cbind(match(dist$node2,nodes),
        match(dist$node1,nodes))] <- dist$dist

# === Umap
embedding <- umap(D)

# === Prepare dataframe for plotting
plot_df <-
  data.frame(
    node = rownames(D),
    UMAP1 = embedding[,1],
    UMAP2 = embedding[,2]
  )

plot_df <-
  left_join(
    plot_df,
    meta,
    by = c("node" = id_col)
  )

# === Plot UMAP
p <- ggplot(
  plot_df,
  aes(
    UMAP1,
    UMAP2,
    colour = .data[[colour_by]]
  )
) +
  geom_point(size = 2, alpha = 0.8) +
  theme_classic()

if (is.numeric(plot_df[[colour_by]])) {
  p <- p + scale_colour_viridis_c()
} else {
  p <- p + scale_colour_viridis_d()
}
p 

ggsave("umap_legend.png", p, width = 8, height = 4)

p + theme(legend.position="none")

ggsave("umap.png", width = 4, height = 4)
