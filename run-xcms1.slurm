#!/bin/bash
#SBATCH --partition=compute
#SBATCH --job-name=xcms1
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=emcparland@whoi.edu
#SBATCH --ntasks=1
#SBATCH --mem=4000
#SBATCH --time=01:30:00
#SBATCH --output=xcms1_%A-%a.out
#SBATCH --error=xcms1_%A-%a.error
#SBATCH --array=1-107%40

dir="$HOME/untarg_xcms"
cd "$dir"

file_list="$dir/metadata.txt"
out_dir="$dir/output_dir/$SLURM_JOB_NAME"
if [ ! -d "$out_dir" ]; then
    mkdir -p "$out_dir"
fi

echo `date`
echo This is job $SLURM_JOB_ID
echo This is task $SLURM_ARRAY_TASK_ID

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargmetab

Rscript --no-save --no-restore --verbose $dir/scripts_dir/xcms1.R "$file_list" "$SLURM_ARRAY_TASK_ID" "$out_dir" > "$out_dir/${SLURM_JOB_NAME}_${SLURM_ARRAY_TASK_ID}.Rout" 2>&1 > "$out_dir/${SLURM_JOB_NAME}_${SLURM_ARRAY_TASK_ID}.log"

echo `date`