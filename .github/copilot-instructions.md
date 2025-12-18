<!-- Copilot / AI agent guidance for the PlexPipe-flow repository -->
# PlexPipe-flow — AI assistant guidance

Purpose: quickly orient code-writing agents to this repository so they can make safe, useful edits.

- **Big picture**: This repo implements a Nextflow DSL2 pipeline (top-level `workflow.nf` / `workflow_parallel.nf`) that orchestrates a multi-stage image-processing flow: core cutting (`modules/cut_cores.nf`), assembly (`modules/assemble.nf` → `scripts/assemble_core.py`), segmentation (`modules/segment.nf` + `scripts/segment_*.py`), and quantification (`modules/quantify.nf`). The pipeline delegates heavy work to standalone Python scripts in `scripts/` and uses a shared config YAML (`--exp_config`) for runtime settings.

- **Key files / entry points**:
  - `workflow.nf` / `workflow_parallel.nf`: top-level DSL2 workflows — modify these only to change orchestration.
  - `nextflow.config`: profiles (`local`, `hpc`) + resource presets and `params` (notably `params.exp_config`, `params.scripts_dir`, `params.envpath`, and log/report locations).
  - `modules/*.nf`: modular processes. See `modules/helpers.nf` for the `opt(name,value)` helper used to render optional CLI flags.
  - `scripts/*.py`: actual work happens here (e.g., `assemble_core.py` uses `multiplex_pipeline` package and reads the experiment YAML).

- **How data and control flow**:
  - `CUT_CORES` outputs a newline-separated list of core paths, which is converted to a channel (`ch_core_paths`) and passed to segmentation and assembling modules.
  - Modules exchange Nextflow `path` and `tuple` values (e.g., `tuple val(core_id), val(core_path)` → see `modules/assemble.nf`).
  - Each process typically calls a script via `${params.envpath} "${params.scripts_dir}/..."` so `params.envpath` must point to a Python executable with required packages installed.

- **Project-specific conventions** (follow these exactly):
  - Process names follow `RUN_*` / `CUT_*` uppercase naming (e.g. `RUN_ASSEMBLING`).
  - Optional CLI flags are built with `opt()` from `modules/helpers.nf` — preserve this pattern when adding flags to modules.
  - Scripts should log to `settings.log_dir_path` (see `scripts/assemble_core.py`) and avoid printing secrets.
  - Processes create sentinel files (e.g., `*.CORE_DONE`) after successful runs — keep this pattern if adding new end-of-step checks.

- **How to run locally (examples)**:
  - Basic local run (passes `--exp_config` into workflow):

    nextflow run workflow.nf -profile local --exp_config ./path/to/exp.yaml

  - Use HPC profile when submitting to cluster:

    nextflow run workflow.nf -profile hpc --exp_config /abs/path/exp.yaml

  - To reproduce a single process locally, run the underlying Python script with the same CLI used by the module. Example (assemble):

    python scripts/assemble_core.py --exp_config ./path/to/exp.yaml --core_path /abs/core --core_id CORE01 --channels "DAPI,TRITC"

- **Dependencies & environment**:
  - The Nextflow `params.envpath` should point to a Python interpreter that has the required packages (scripts import `multiplex_pipeline`, `pandas`, `loguru`, etc.). The repository does not contain a `requirements.txt` — verify the environment used in CI or HPC modules.

- **Testing and debugging tips**:
  - Start with `-profile local` for quick iteration. Check generated reports under the configured `params.logdir` (`../pipeline_logs/pipeline_reports` by default) — timeline, report, and trace are enabled in `nextflow.config`.
  - Reproduce failing process runs by invoking the script directly with the same CLI flags; logs are written by `loguru` to the configured `log_dir_path`.
  - When changing a module, run the pipeline with a minimal `exp_config` subset that exercises the changed module.

- **Safe edit rules for AI agents (do this first on every code edit)**:
  1. Preserve `params.scripts_dir` usage and existing CLI flag formatting (use `opt()` when adding optional flags).  
  2. Keep process `tag`/`withName` resource hints in `nextflow.config` in sync (don't silently increase memory or cpus).  
  3. If a Python script interface changes, update the calling `modules/*.nf` script invocation and add a sentinel artifact (e.g., `touch ... .DONE`) for backward compatibility.  
  4. Run a local Nextflow invocation (`-profile local`) and verify the pipeline produces the same sentinel files and log entries before creating a PR.

If anything above is ambiguous or you want me to include specific examples from other modules (e.g., segmentation/quantification CLI details), tell me which module to inspect and I'll update this file.
