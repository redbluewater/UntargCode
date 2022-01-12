#!/bin/bash
#SBATCH --partition=compute
#SBATCH --job-name=xcms1
#SBATCH --mail-type=NONE
#SBATCH --mail-user=klongnecker@whoi.edu
#SBATCH --ntasks-per-node=1
#SBATCH --mem=4gb
#SBATCH --time=4:00:00

dir="$HOME/UntargCode"
cd "$dir"

in_dir="/vortexfs1/omics/kujawinski/data/SargPatch"
out_dir="$dir/output_dir/$SLURM_JOB_NAME"
if [ ! -d "$out_dir" ]; then
    mkdir -p "$out_dir"
fi

echo `date`
echo This is job $SLURM_JOB_ID
echo This is task $SLURM_ARRAY_TASK_ID

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargmetabR4

Rscript --no-save --no-restore --verbose $dir/scripts_dir/xcms1.R "$in_dir" "pos" "$SLURM_ARRAY_TASK_ID" "$out_dir" > "$out_dir/${SLURM_JOB_NAME}_pos_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}.Rout" 2>&1 > "$out_dir/${SLURM_JOB_NAME}_pos_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log"

echo `date`
