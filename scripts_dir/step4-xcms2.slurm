#!/bin/bash
#SBATCH --partition=medmem
#SBATCH --job-name=xcms2
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=klongnecker@whoi.edu
#SBATCH --ntasks-per-node=5
#SBATCH --mem=500gb
#SBATCH --time=6:00:00
#SBATCH --output=/vortexfs1/home/klongnecker/UntargCode/logfiles_dir/xcms2.out
#SBATCH --error=/vortexfs1/home/klongnecker/UntargCode/logfiles_dir/xcms2.error

dir="$HOME/UntargCode"
#cd $dir

in_dir="$dir/output_dir/xcms1"
out_dir="$dir/output_dir/$SLURM_JOB_NAME"

if [ ! -d "$out_dir" ]; then
    mkdir -p "$out_dir"
fi

log_dir="$dir/logfiles_dir" 

echo `date`
echo This is job $SLURM_JOB_ID

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargKL4

Rscript --no-save --no-restore --verbose $dir/scripts_dir/xcms2.R "$in_dir" "$out_dir" "$ionMode" > "$log_dir/${SLURM_JOB_NAME}_$ionMode.Rout" 2>&1 > "$log_dir/${SLURM_JOB_NAME}_$ionMode.log"
