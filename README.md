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
