import argparse
import os
import sys
import time
from datetime import datetime
from pathlib import Path
import pandas as pd
from loguru import logger

from multiplex_pipeline.utils.config_loaders import load_analysis_settings
from multiplex_pipeline.core_cutting.cutter import CoreCutter
from multiplex_pipeline.core_cutting.file_io import (
    read_ome_tiff,
    write_temp_tiff,
)

def configure_logging(settings, core):
    """
    Setup logging.
    """

    log_file = settings.log_dir_path / f"cutting_{core}_{datetime.now():%Y-%m-%d_%H-%M-%S}.log"

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
        "--im_path", help="Path to the image to be cut into cores.", required=True
    )

    parser.add_argument(
        "--channel", help="Name of the channels the path corresponds too.", required=True
    )

    parser.add_argument(
        "--wait_time", help="How long to wait for the image file to appear.", 
        default = 10,
    )

    parser.add_argument(
        "--remote_analysis",
        action="store_true",
        help="Use remote analysis directory as base.",
    )

    return parser.parse_args()


def wait_for_file(file_path, wait_time_hours, check_interval=10, stability_duration=5):
    path = Path(file_path)
    timeout_seconds = float(wait_time_hours) * 3600 
    end_time = time.time() + timeout_seconds
    
    last_size = -1
    stable_counter = 0

    while time.time() < end_time:
        if path.exists():
            current_size = path.stat().st_size
            if current_size == last_size and current_size > 0:
                stable_counter += 1
            else:
                stable_counter = 0 # Reset if size changed
            
            last_size = current_size

            # If size hasn't changed for 'stability_duration' checks, it's done
            if stable_counter >= stability_duration:
                return True
        
        time.sleep(check_interval)
        
    return False


def cut_cores(settings, channel, file_path):

    # get cutter
    cutter = CoreCutter(margin = 0, mask_value = 0)

    # get cores metadata
    df_path = settings.core_info_file_path.with_suffix('.pkl')
    df = pd.read_pickle(df_path)

    # get infor for saving cores
    temp_dir = settings.cores_dir_tif_path

    full_img, store = read_ome_tiff(str(file_path))

    for _, row in df.iterrows():
        core_id = row["core_name"]
        core_img = cutter.extract_core(full_img, row)
        write_temp_tiff(core_img, core_id, channel, temp_dir)


def main():

    args = parse_args()

    # read config file
    settings = load_analysis_settings(
        args.exp_config, remote_analysis=args.remote_analysis
    )

    # setup logging
    configure_logging(settings, args.channel)
    
    # waiting
    logger.info(f"Checking the file {Path(args.im_path).stem}.")
    wait_outcome = wait_for_file(args.im_path, args.wait_time)

    if wait_outcome:
        logger.info(f"Image {Path(args.im_path).stem} is available.")
    else:
        msg = f'Image {Path(args.im_path).stem} is not available.'
        logger.error(msg)
        raise ValueError (msg)
    
    # cutting
    logger.info(f"Starting cutting {Path(args.im_path).stem} into cores.")
    cut_cores(settings, args.channel, args.im_path)


if __name__ == "__main__":
    main()