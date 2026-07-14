process MASH_TRIANGLE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mash:2.3--he348c14_1':
        'quay.io/biocontainers/mash:2.3--he348c14_1' }"

    input:
    tuple val(meta), path(sketch)

    output:
    tuple val(meta), path("*.triangle"), emit: triangle
    tuple val("${task.process}"), val("mash"), eval("mash --version 2>&1"), emit: versions_mash, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mash \\
        triangle \\
        ${args} \\
        ${sketch} \\
        > ${prefix}.triangle
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.triangle
    """
}