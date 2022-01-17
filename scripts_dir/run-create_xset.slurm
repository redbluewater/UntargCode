#!/bin/bash
#SBATCH --partition=compute
#SBATCH --job-name=create_xset
#SBATCH --mail-type=NONE
#SBATCH --mail-user=klongnecker@whoi.edu
#SBATCH --ntasks-per-node=1
#SBATCH --mem=10gb
#SBATCH --time=1:00:00
#SBATCH --output=create_xset.out
#SBATCH --error=create_xset.error


dir="$HOME/UntargCode/output_dir/xcms2"
cd "$dir"

work_dir="/output_dir/xcms2"

echo `date`
echo This is job $SLURM_JOB_ID

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargKL4

Rscript --no-save --no-restore --verbose $dir/scripts_dir/create_xset.R "$work_dir" "neg"> "$work_dir/${SLURM_JOB_NAME}_${SLURM_JOB_ID}.Rout" 2>&1 > $work_dir/${SLURM_JOB_NAME}_${SLURM_JOB_ID}.log

echo `date`
