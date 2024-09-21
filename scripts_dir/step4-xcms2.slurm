#!/bin/bash
#SBATCH --partition=compute
#SBATCH --job-name=xcms2
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=klongnecker@whoi.edu
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=15
#SBATCH --mem=175gb
#SBATCH --time=06:00:00
#SBATCH --output=/vortexfs1/home/klongnecker/UntargCode/logfiles_dir/xcms2.out
#SBATCH --error=/vortexfs1/home/klongnecker/UntargCode/logfiles_dir/xcms2.error

dir="$HOME/UntargCode"

in_dir="$HOME/UntargCode/output_dir/xcms1"
out_dir="$HOME/UntargCode/output_dir/$SLURM_JOB_NAME"

log_dir="$dir/logfiles_dir"  

if [ ! -d "$out_dir" ]; then
    mkdir -p "$out_dir"
fi

echo `date`
echo This is job $SLURM_JOB_ID

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargKL4

Rscript --no-save --no-restore --verbose $dir/scripts_dir/xcms2.R "$in_dir" "$out_dir" "$ionMode" > "$log_dir/${SLURM_JOB_NAME}_$ionMode.Rout" 2>&1 > "$log_dir/${SLURM_JOB_NAME}_$ionMode.log"
