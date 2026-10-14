include { opt; globusArgs } from './helpers.nf'

// Cuts every ROI from one channel image. With Globus, first waits for that
// channel's transfer task to succeed.
// Not retried: with --cleanup the transferred image is gone after cutting.
// (`channel_name`, not `channel`: `channel` is a Nextflow keyword.)
process RUN_CUTTING {

    tag { channel_name }

    input:
    path exp_config
    tuple val(channel_name), val(image_path), val(task_id)

    output:
    val channel_name, emit: channel

    script:
    def wait = task_id ? "--task_id '${task_id}' ${globusArgs()} --wait_hours ${params.wait_hours}" : ""
    """
    ${params.plexpipe} cut-image \\
        --exp_config '${exp_config}' \\
        --channel '${channel_name}' \\
        --image_path '${image_path}' \\
        ${wait} \\
        ${opt('cleanup', params.cleanup)}
    """
}
