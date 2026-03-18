#!/bin/bash

#SBATCH -J gbif-partition
#SBATCH --chdir=/work/berti
#SBATCH --output=/work/berti/%x.out
#SBATCH --mem-per-cpu=10G
#SBATCH --time=1-00:00:00
#SBATCH --mail-type=BEGIN,END

module load Conda
source activate gbif
module load GCC/12.2.0 OpenMPI/4.1.4 R/4.2.2

array_or_job_id=${SLURM_ARRAY_JOB_ID:-$SLURM_JOB_ID}

Rscript --vanilla /home/berti/gbif/partition-vertebrates.R
