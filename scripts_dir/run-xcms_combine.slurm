#!/bin/bash
#SBATCH --partition=compute
#SBATCH --job-name=xcms-combine
#SBATCH --mail-type=NONE
#SBATCH --mail-user=klongnecker@whoi.edu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=175gb
#SBATCH --time=01:00:00
#SBATCH --output=xcms-combine.out
#SBATCH --error=xcms-combine.error

in_dir="$HOME/UntargCode/output_dir/xcms1"
cd $in_dir

echo `date`
echo This is job $SLURM_JOB_ID

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargmetab

Rscript --no-save --no-restore --verbose $HOME/untarg_xcms/scripts_dir/xcms_combine.R "$in_dir" "pos" > "$in_dir/${SLURM_JOB_NAME}_pos.Rout" 2>&1 >$in_dir/${SLURM_JOB_NAME}_pos.log
