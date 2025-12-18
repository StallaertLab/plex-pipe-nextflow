## PlexPipe-flow: Nextflow Orchestration for PlexPipe

PlexPipe-flow is the scalable execution engine for the [PlexPipe](https://github.com/StallaertLab/multiplex_pipeline) multiplex imaging suite (see Documentation). It wraps the core Python logic of PlexPipe into a [Nextflow](https://www.nextflow.io/) pipeline, enabling parallel analysis of Tissue Microarrays (TMAs) and whole-slide images.

PlexPipe-flow is a set of Nextflow wrappers (.nf modules) that call the Python scripts from PlexPipe. It manages:

- Resource Allocation: Requesting the correct CPU/RAM/GPU for each specific step.
- Data Flow: Piping outputs from one Python script into the inputs of the next.
- Fault Tolerance: Automatically retrying failed jobs (e.g., up to 3 times for segmentation/quantification asking for increasing resources).

The pipeline utilizes a two-stage parallelization strategy separated by a synchronization barrier:

- Phase 1 (Cutting Cores): Parallelizes processing by Image Channel to extract individual cores.
- The Barrier: A `.collect()` operator aggregates all outputs, ensuring data completeness before proceeding.
- Phase 2 (Analysis): Shifts parallelization to the TMA Core level. Each core is independently processed through Assembly, Segmentation, and Quantification.

![Nextflow Diagram](docs/flow_diagram.png)

## Quick Start

1. Local Execution (Testing/Development) 

Run the pipeline on your local machine. Ideal for debugging or processing small datasets.

```Bash
nextflow run example_workflow.nf \
    -profile local \
    --exp_config "/path/to/experiment.yaml"
```

2. HPC Execution (Production) 

Submit to a Slurm cluster with GPU support for segmentation (and optionally with Globus integration for data movement).

```Bash
nextflow run example_workflow.nf \
    -profile hpc \
    --exp_config "/path/to/experiment.yaml"
```

For both local and HPC execution, you can modify `nextflow.config` to match your specific hardware limits,  scheduler requirements and file paths (for details and tips see documentation).