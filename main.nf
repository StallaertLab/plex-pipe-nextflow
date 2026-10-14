#!/usr/bin/env nextflow
/*
 * PlexPipe-flow: runs PlexPipe one channel image / one ROI per job.
 *
 *   RUN_SETUP           once      -> images.csv, rois.csv
 *   RUN_CUTTING         per channel
 *   (barrier: all channels cut)
 *   RUN_ASSEMBLY        per ROI
 *   RUN_SEGMENTATION    per ROI
 *   RUN_QUANTIFICATION  per ROI
 *
 * Every process calls the `plexpipe` command of the installed PlexPipe
 * package (see https://stallaertlab.github.io/plex-pipe/usage/cli/).
 */

include { RUN_SETUP }          from './modules/setup.nf'
include { RUN_CUTTING }        from './modules/cut_image.nf'
include { RUN_ASSEMBLY }       from './modules/assemble.nf'
include { RUN_SEGMENTATION }   from './modules/segment.nf'
include { RUN_QUANTIFICATION } from './modules/quantify.nf'

workflow {

    if( !params.exp_config ) {
        error "Missing --exp_config: path to the PlexPipe config YAML (all paths in it must be absolute)."
    }
    def exp_config = file(params.exp_config, checkIfExists: true)

    RUN_SETUP(exp_config)

    // one item per channel: (channel, image path, Globus task id or '')
    def images = RUN_SETUP.out.images
        .splitCsv(header: true)
        .map { row -> tuple(row['channel'], row['path'], row['task_id'] ?: '') }

    // one item per ROI: (roi name, path of its .zarr store)
    def rois = RUN_SETUP.out.rois
        .splitCsv(header: true)
        .map { row -> tuple(row['roi_name'], row['path']) }

    RUN_CUTTING(exp_config, images)

    // barrier: assembly starts only when every channel has been cut
    def all_cut = RUN_CUTTING.out.channel.collect()

    RUN_ASSEMBLY(exp_config, RUN_SETUP.out.images, rois, all_cut)
    RUN_SEGMENTATION(exp_config, RUN_ASSEMBLY.out.roi)
    RUN_QUANTIFICATION(exp_config, RUN_SEGMENTATION.out.roi)
}
