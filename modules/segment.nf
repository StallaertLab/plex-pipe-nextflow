include { opt } from './helpers.nf'

// Runs the additional_elements steps (enhancement, segmentation, masks) on
// one ROI. A retry overwrites what a failed attempt may have written.
process RUN_SEGMENTATION {

    tag { roi }

    input:
    path exp_config
    tuple val(roi), val(roi_path)

    output:
    tuple val(roi), val(roi_path), emit: roi

    script:
    def overwrite = params.overwrite || task.attempt > 1
    """
    ${params.plexpipe} segment-roi \\
        --exp_config '${exp_config}' \\
        --roi_path '${roi_path}' \\
        ${opt('overwrite', overwrite)}
    """
}
