nextflow.enable.dsl=2

include { opt } from '../modules/helpers.nf'

process RUN_SETUP {

    tag "Manage analysis."

    input:
    path exp_config

    output:
    path "images_manifest.txt", emit: images_manifest
    path "cores_manifest.txt", emit: cores_manifest

    script:
    """
    set -euo pipefail

    ${params.envpath} "${params.scripts_dir}/exp_management.py" \
        --exp_config "${exp_config}" \
        ${opt('remote_analysis', params.remote_analysis)} \
        ${opt('globus_config', params.globus_config)} \
        ${opt('from_collection', params.from_collection)} \
        ${opt('to_collection', params.to_collection)} \
        ${opt('globus_home_setting', params.globus_home_setting)} \
        ${opt('file_checksum', params.file_checksum)} 

    """
}