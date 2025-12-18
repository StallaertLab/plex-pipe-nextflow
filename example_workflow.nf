#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { RUN_SETUP } from './modules/setup.nf'
include { RUN_CUTTING } from './modules/cut_image.nf'
include { RUN_ASSEMBLY } from './modules/assemble.nf'
include { RUN_SEGMENTATION } from './modules/segment.nf'
include { RUN_QUANTIFICATION } from './modules/quantify.nf'

workflow {
    
    def exp_config  = file(params.exp_config)
    
    RUN_MANAGEMENT(exp_config)

    RUN_MANAGEMENT.out.images_manifest
        .splitCsv(header: false, strip: true)
        .map { row -> tuple(row[0], row[1]) }
        .set { ch_im_paths }

    RUN_MANAGEMENT.out.cores_manifest
        .splitCsv(header: false, strip: true)
        .map { row -> tuple(row[0], row[1]) }
        .set { ch_core_paths }

    RUN_CUTTING(exp_config, ch_im_paths)

    RUN_ASSEMBLY(exp_config, ch_core_paths, RUN_CUTTING.out.channel_name.collect())

    RUN_SEGMENTATION(exp_config, RUN_ASSEMBLING.out)

    RUN_QUANTIFICATION(exp_config, RUN_SEGMENTATION.out)

}