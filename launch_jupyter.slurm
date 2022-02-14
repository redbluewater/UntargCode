#!/bin/bash
#SBATCH --partition=compute
#SBATCH --mem=20gb
#SBATCH --time=02:00:00
#SBATCH --job-name=jupyter

# Setup Environment
conda activate untargKL4

jupyter lab --no-browser --ip "*" \
            --notebook-dir /vortexfs1/home/klongnecker/UntargCode
