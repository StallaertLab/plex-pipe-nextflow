# Changelog

All notable changes to plex-pipe-nextflow. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-10-16

First versioned release.

### Added

- Runs PlexPipe one channel image or one ROI per job through the `plexpipe` command: setup, cutting per channel, then assembly, segmentation and quantification per ROI.
- Profiles `local` and `hpc` (Slurm), retries with more resources for segmentation and quantification, optional Globus transfers.
- Cluster profiles `bridges2` (PSC Bridges-2) and `pitt_crc` in `conf/`, used after `hpc` (`-profile hpc,bridges2`).
- Requires PlexPipe 0.1.0: the first job checks `plexpipe --version` (`--plexpipe_version`).

[0.1.0]: https://github.com/plexpipe/plex-pipe-nextflow/releases/tag/v0.1.0
