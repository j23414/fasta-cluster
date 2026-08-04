# fasta-cluster

A modular workflow for taking a set of sequences and clustering them into representative sequences

## Usage

```
nextflow run fasta-cluster \
  --fasta sequences.fasta \
  --samplesheet [samplesheet.csv] \
  --min_similarity '80.0' \
  --outdir "cluster-results" \
  --segments "WGS" \
  -profile stjude
```

## Optional: Alluvial plots to compare various clustering methods

```bash
# General format of the script (remember to drop the comments, or command does not work)
Rscript bin/alluvial.R \
  SequenceName \   #<= One ID to combine cluster files
  mmseq_cluster.tsv fastani_cluster.tsv mash_cluster.tsv # <= An abitrary number of cluster files, must have a ClusterNumber column

# Generates an alluvial plot in the order that the cluster files are passed in
open alluvial.png
```