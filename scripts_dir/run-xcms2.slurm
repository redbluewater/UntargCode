#!/bin/bash
#SBATCH --partition=compute
#SBATCH --job-name=xcms2
#SBATCH --mail-type=NONE
#SBATCH --mail-user=klongnecker@whoi.edu
#SBATCH --ntasks-per-node=36
#SBATCH --mem=170gb
#SBATCH --time=4:00:00
#SBATCH --output=xcms2.out
#SBATCH --error=xcms2.error

dir="$HOME/UntargCode"
cd "$dir"

in_dir="$dir/output_dir/xcms1"
out_dir="$dir/output_dir/$SLURM_JOB_NAME"

if [ ! -d "$out_dir" ]; then
    mkdir -p "$out_dir"
fi

echo `date`
echo This is job $SLURM_JOB_ID

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargKL4

Rscript --no-save --no-restore --verbose $dir/scripts_dir/xcms2.R "$in_dir" "$out_dir" "pos" > "$out_dir/${SLURM_JOB_NAME}_pos.Rout" 2>&1 >$out_dir/${SLURM_JOB_NAME}_pos.log
