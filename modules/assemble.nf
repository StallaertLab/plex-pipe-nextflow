include { opt } from './helpers.nf'

// Assembles one ROI from its channel TIFFs. `all_cut` is only there to make
// this wait until every channel has been cut.
process RUN_ASSEMBLY {

    tag { roi }

    input:
    path exp_config
    path images_csv
    tuple val(roi), val(roi_path)
    val all_cut

    output:
    tuple val(roi), val(roi_path), emit: roi

    script:
    """
    ${params.plexpipe} assemble-roi \\
        --exp_config '${exp_config}' \\
        --roi '${roi}' \\
        --images '${images_csv}' \\
        ${opt('roi_cleanup', params.roi_cleanup)}
    """
}
