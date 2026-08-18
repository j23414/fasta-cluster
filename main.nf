// Listed in rough order from estimated fastest to slowest to run based on the algorithm
include { MASH_SKETCH } from './modules/nf-core/mash/sketch/main'
include { MASH_DIST } from './modules/nf-core/mash/dist/main'
include { MASH_TRIANGLE } from './modules/local/mash/triangle/main'

include { CDHIT_CDHIT } from './modules/nf-core/cdhit/cdhit/main'

include { MMSEQS_CLUSTER } from './modules/nf-core/mmseqs/cluster/main'
include { MMSEQS_EASYCLUSTER } from './modules/nf-core/mmseqs/easycluster/main'

include { CLUSTY } from './modules/nf-core/clusty/main'

include { VCLUST_PREFILTER } from './modules/nf-core/vclust/prefilter/main'
include { VCLUST_ALIGN } from './modules/nf-core/vclust/align/main'
include { VCLUST_CLUSTER } from './modules/nf-core/vclust/cluster/main'

include { FASTANI } from './modules/nf-core/fastani/main'

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

    // ============= Clustering methods ==============
    cluster_methods = params.clusterby.split(",").collect { it.trim().toLowerCase() }

    valid_cluster_methods = [
        'mash',
        'cdhit',
        'mmseqs',
        'vclust',
        'fastani'
    ]

    invalid_methods = cluster_methods - valid_cluster_methods

    if (invalid_methods) {
        error """
        Unknown clustering method(s): ${invalid_methods.join(', ')}

        Supported methods:
          ${valid_cluster_methods.join(', ')}
        """
    }
    // ================================================

    if('mash' in cluster_methods) {
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

        // HDBSCAN(
        //     MASH_TRIANGLE.out.triangle.map { n -> n.get(1)}
        // )
    }

    if ('cdhit' in cluster_methods) {
        CDHIT_CDHIT(
            reads_ch
        )
    }

    if('mmseqs' in cluster_methods) {
        MMSEQS_EASYCLUSTER(
            reads_ch
        )
    }

    if ('vclust' in cluster_methods) {
        // Filter out similar genome sequence pairs before pairwise alignments for faster performance
        VCLUST_PREFILTER(
            reads_ch
        )
        // Align similar genome sequence pairs and calculate pairwise ANI scores
        VCLUST_ALIGN(
            reads_ch,
            VCLUST_PREFILTER.out.txt,
            false
        )
        // CLuster genome sequences based on given ANI and minimum threshold
            // tuple val(meta), path(tsv)
            // tuple val(meta2), path(ids)
            // val metric
            // val tani
            // val gani
            // val ani
        VCLUST_CLUSTER(
            VCLUST_ALIGN.out.tsv,
            VCLUST_ALIGN.out.ids,
            false, // metric
            false, // tani
            false, // gani
            false // ani
        )
    }

    if ('fastani' in cluster_methods) {
        // FASTANI(
        //     reads_ch,
        //     reads_ch.map{ meta, reads = tuple(meta: "ref_${meta.id}", reads) }
        // )
    }
}
