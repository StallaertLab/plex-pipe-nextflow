// modules/quantify_core.nf
nextflow.enable.dsl=2

include { opt } from '../modules/helpers.nf'

process RUN_ASSEMBLY {
    
    tag { "assemble: ${file(core_path).baseName}" }

    input:
    path exp_config
    tuple val(core_id), val(core_path)
    val all_channels

    output:
    tuple val(core_path), path("${file(core_path).baseName}.CORE_DONE")

    script:
    """
    set -euo pipefail

    ${params.envpath} "${params.scripts_dir}/assemble_core.py" \
        --exp_config "${exp_config}" \
        --core_path "${core_path}" \
        --core_id "${core_id}" \
        --channels "${all_channels}" \
        ${opt('remote_analysis',     params.remote_analysis)}

    touch "${file(core_path).baseName}.CORE_DONE"
    """
}