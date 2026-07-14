include { MASH_SKETCH } from './modules/nf-core/mash/sketch/main'
include { MASH_DIST } from './modules/nf-core/mash/dist/main'
include { MASH_TRIANGLE } from './modules/local/mash/triangle/main'

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
}
