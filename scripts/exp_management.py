import argparse
import os
import sys
from datetime import datetime
from pathlib import Path
import pandas as pd
from loguru import logger

from multiplex_pipeline.utils.config_loaders import load_analysis_settings
from multiplex_pipeline.core_cutting.channel_scanner import discover_channels, build_transfer_map
from multiplex_pipeline.core_cutting.controller import CorePreparationController
from multiplex_pipeline.core_cutting.file_io import GlobusFileStrategy
from multiplex_pipeline.utils.globus_utils import GlobusConfig, create_globus_tc
from multiplex_pipeline.utils.file_utils import GlobusPathConverter


def configure_logging(settings):
    """
    Setup logging.
    """

    log_file = settings.log_dir_path / f"management_{datetime.now():%Y-%m-%d_%H-%M-%S}.log"

    logger.remove()
    logger.add(sys.stdout, level="DEBUG")
    logger.add(log_file, level="DEBUG", enqueue=True)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Prepare cores from OME-TIFFs using metadata and optional Globus transfers."
    )

    parser.add_argument(
        "--exp_config", help="Path to experiment YAML config.", required=True
    )

    parser.add_argument(
        "--globus_config", help="Path to Globus YAML config.",
        default = None, 
    )

    parser.add_argument(
        "--remote_analysis",
        action="store_true",
        help="Use remote analysis directory as base.",
    )

    parser.add_argument(
        "--file_checksum",
        action="store_true",
        help="File checksum through Globus for existing files.",
    )

    parser.add_argument(
        "--from_collection",
        help="Key for source collection in Globus config.",
        default="r_collection_id",
    )
    parser.add_argument(
        "--to_collection",
        help="Key for destination collection in Globus config.",
        default="crcd_collection_id",
    )
    parser.add_argument(
        "--globus_home_setting",
        help="How to change Windows to Globus paths in yaml.",
        default="single_drive",
    )

    return parser.parse_args()



def main():

    args = parse_args()

    # read config file
    settings = load_analysis_settings(
        args.exp_config, remote_analysis=args.remote_analysis
    )

    # setup logging
    configure_logging(settings)
    logger.info("Starting resource procurement.")

    # get globus config
    if args.globus_config:
        gc = GlobusConfig.from_config_files(
            args.globus_config,
            from_collection=args.from_collection,
            to_collection=args.to_collection,
        )
        tc = create_globus_tc(gc.client_id, gc.transfer_tokens)
    else:
        gc = None

    # make decisions about images
    channel_map = discover_channels(Path(settings.general.image_dir),
                                    include_channels=settings.core_cutting.include_channels,
                                    exclude_channels=settings.core_cutting.exclude_channels,
                                    use_markers=settings.core_cutting.use_markers,
                                    ignore_markers=settings.core_cutting.ignore_markers,
                                    gc=gc)

    if args.globus_config:
        # build transfer map
        transfer_cache_dir = settings.temp_dir
        transfer_map = build_transfer_map(channel_map, transfer_cache_dir)

        # create a dict of images to be transfered
        channel_map = {
            ch: str(Path(transfer_cache_dir) / Path(remote).name)
            for ch, (remote, _) in transfer_map.items()
        }

        # remove existing files from transfer list if checksum not requested
        if not args.file_checksum:
            to_remove = []

            for channel, (_, local_path) in transfer_map.items():
                if Path(local_path).exists():

                    to_remove.append(channel)

            # drop after iteration
            for channel in to_remove:
                transfer_map.pop(channel)

        # submit transfers
        logger.info(f'Submitting transfers.')
        strategy = GlobusFileStrategy(tc=tc, transfer_map=transfer_map, gc=gc, cleanup_enabled = True)

    # save manifest of images
    manifest = Path("images_manifest.txt")
    with manifest.open("w") as f:
        for channel, local_path in channel_map.items():
            f.write(f"{channel},{local_path}\n")


    ############################################################################
    df_path = settings.core_info_file_path.with_suffix('.pkl')
    df = pd.read_pickle(df_path)

    # save manifest of cores
    manifest = Path("cores_manifest.txt")
    with manifest.open("w") as f:
        for id, row in df.iterrows():
            core_path = Path(settings.cores_dir_output_path) / (row.core_name + '.zarr')
            core_id = row.core_name
            f.write(f"{core_id},{core_path}\n")

if __name__ == "__main__":
    main()