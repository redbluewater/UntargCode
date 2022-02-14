#!/bin/bash
#SBATCH --partition=compute
#SBATCH --mem=4gb
#SBATCH --time=02:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --job-name=jupyter

# Setup Environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargKL4

jupyter notebook --no-browser --ip "*" \
            --notebook-dir /vortexfs1/home/klongnecker/UntargCode
