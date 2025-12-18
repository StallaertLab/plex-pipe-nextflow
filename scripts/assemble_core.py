import argparse
import os
import sys
from datetime import datetime
from pathlib import Path
import pandas as pd
from loguru import logger

from multiplex_pipeline.utils.config_loaders import load_analysis_settings
from multiplex_pipeline.core_cutting.assembler import CoreAssembler


def configure_logging(settings, core):
    """
    Setup logging.
    """

    log_file = settings.log_dir_path / f"Assembling_{core}_{datetime.now():%Y-%m-%d_%H-%M-%S}.log"

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
        "--core_path", help="Path to the output SpatialData object.", required=True
    )

    parser.add_argument(
        "--core_id", help="Core ID to cut.", required=True
    )

    parser.add_argument(
        "--channels", help="A list of channels to process.", required=True
    )

    parser.add_argument(
        "--remote_analysis",
        action="store_true",
        help="Use remote analysis directory as base.",
    )

    return parser.parse_args()

def main():

    args = parse_args()

    # read config file
    settings = load_analysis_settings(
        args.exp_config, remote_analysis=args.remote_analysis
    )

    # setup logging
    configure_logging(settings, args.core_id)
    logger.info(f"Assembling core {args.core_id}.")

    assembler = CoreAssembler(
        temp_dir=settings.cores_dir_tif_path,
        output_dir=settings.cores_dir_output_path,
        max_pyramid_levels=settings.sdata_storage.max_pyramid_level,
        chunk_size=settings.sdata_storage.chunk_size,
        downscale = settings.sdata_storage.downscale,
        allowed_channels=args.channels,
        cleanup=False,
    )

    assembler.assemble_core(args.core_id)

if __name__ == "__main__":
    main()