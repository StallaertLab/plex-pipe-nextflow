include { opt; globusArgs } from './helpers.nf'

// Finds the channels, starts Globus transfers (if any) and writes the
// lists the other processes fan out over.
process RUN_SETUP {

    tag "setup"

    input:
    path exp_config

    output:
    path "images.csv", emit: images
    path "rois.csv",   emit: rois

    script:
    """
    ${params.plexpipe} setup \\
        --exp_config '${exp_config}' \\
        --out_dir . \\
        ${globusArgs()} \\
        ${opt('file_checksum', params.file_checksum)}
    """
}
