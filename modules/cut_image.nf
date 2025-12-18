// modules/quantify_core.nf
nextflow.enable.dsl=2

include { opt } from '../modules/helpers.nf'

process RUN_CUTTING {
    
    tag { "cut: ${file(im_path).baseName}" }

    input:
    path exp_config
    tuple val(channel_name), val(im_path)

    output:
    path("${file(im_path).baseName}.IMAGE_DONE")
    val(channel_name), emit: channel_name

    script:
    """
    set -euo pipefail

    ${params.envpath} "${params.scripts_dir}/wait_and_cut.py" \
        --exp_config "${exp_config}" \
        --im_path "${im_path}" \
        --channel "${channel_name}" \
        ${opt('wait_time',     params.wait_time)} \
        ${opt('remote_analysis',     params.remote_analysis)} \

    touch "${file(im_path).baseName}.IMAGE_DONE"
    """
}