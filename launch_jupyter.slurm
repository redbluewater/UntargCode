#!/bin/bash
#SBATCH --partition=compute
##SBATCH --partition=bigmem
#SBATCH --mem=20gb
#SBATCH --time=02:00:00
#SBATCH --ntasks-per-node=2
#SBATCH --job-name=jupyter

# Setup Environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargKL4

jupyter notebook --no-browser --ip "*" \
            --notebook-dir /vortexfs1/home/klongnecker/UntargCode
