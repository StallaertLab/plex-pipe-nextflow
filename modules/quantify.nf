// modules/quantify_core.nf
nextflow.enable.dsl=2

include { opt } from '../modules/helpers.nf'

process RUN_QUANTIFICATION {

    tag { "quant: ${file(core_path).baseName}" }

    input:
    path exp_config
    tuple val(core_path), path(seg_done_file)

    output:
    tuple val(core_path), path("${file(core_path).baseName}.QUANT_DONE")

    script:
    """
    set -euo pipefail

    ${params.envpath} "${params.scripts_dir}/quantify_single_core.py" \
        --exp_config "${exp_config}" \
        --sdata_path "${core_path}" \
        ${opt('remote_analysis',     params.remote_analysis)} \
        ${opt('overwrite',       params.quantify_overwrite)}

    touch "${file(core_path).baseName}.QUANT_DONE"
    """
}
