nextflow.enable.dsl=2

include { opt } from '../modules/helpers.nf'

process CUT_CORES {

    tag "cut_cores"

    input:
    path exp_config

    output:
    path "cores_manifest.txt", emit: cores_manifest

    script:
    """
    echo "Using globus config: ${params.globus_config}"
    set -euo pipefail

    ${params.envpath} "${params.scripts_dir}/cut_cores.py" \
        --exp_config "${exp_config}" \
        ${opt('remote_analysis', params.remote_analysis)} \
        ${opt('globus_config', params.globus_config)} \
        ${opt('from_collection', params.from_collection)} \
        ${opt('to_collection', params.to_collection)} \
        ${opt('globus_home_setting', params.globus_home_setting)}

    """
}
