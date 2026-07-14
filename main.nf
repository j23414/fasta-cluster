include { MASH_SKETCH } from './modules/nf-core/mash/sketch/main'
include { MASH_DIST } from './modules/nf-core/mash/dist/main'
include { MASH_TRIANGLE } from './modules/local/mash/triangle/main'
include { CLUSTY } from './modules/nf-core/clusty/main'

process HDBSCAN {
    conda "${projectDir}/modules/local/hdbscan/environment.yml"
    input:
    path (triangle_dist)

    output:
    path ("${triangle_dist.baseName}_clusters.tsv")

    script:
    def min_cluster_size = params.min_cluster_size
    """
    python ${projectDir}/bin/hdbscan_clusters.py \
        ${triangle_dist} \
        ${triangle_dist.baseName}_clusters.tsv \
        --min-cluster-size ${min_cluster_size}
    """
}

process FILTER_MASH_DIST {
    tag "$meta.id"
    label 'process_low'
    input:
    tuple val(meta), path(edgelist)
    output:
    tuple val(meta), path("${edgelist.baseName}_filtered.tsv")
    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def cutoff = params.mash_cutoff ?: 0.05
    """
    echo "name1,name2,ani" | tr ',' '\t' > ${edgelist.baseName}_filtered.tsv
    awk -v CUTOFF=${cutoff} '\$1 != \$2 && \$3 <= CUTOFF {print \$1 "\t" \$2 "\t" \$3}' ${edgelist} >> ${edgelist.baseName}_filtered.tsv
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_filtered.tsv
    """
}

workflow {
    reads_ch = channel.fromPath(params.fasta, checkIfExists: true)
    | map { fasta -> tuple(id: fasta.baseName, file(fasta))}

    MASH_SKETCH(
        reads_ch
    )

    MASH_DIST(
        MASH_SKETCH.out.mash,
        MASH_SKETCH.out.mash.map {n -> n.get(1)}
    )

    MASH_TRIANGLE(
        MASH_SKETCH.out.mash,
    )

    // FILTER_MASH_DIST(MASH_DIST.out.dist)
    // CLUSTY(
    //     FILTER_MASH_DIST.out,
    //     [[],[]]
    // )
    HDBSCAN(
        MASH_TRIANGLE.out.triangle.map { n -> n.get(1)}
    )

}
