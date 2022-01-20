#!/bin/bash
#SBATCH --partition=compute
#SBATCH --job-name=xcms-combine
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=klongnecker@whoi.edu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=175gb
#SBATCH --time=01:00:00
#SBATCH --output=xcms-combine.out
#SBATCH --error=xcms-combine.error

dir="$HOME/UntargCode"

in_dir="$HOME/UntargCode/output_dir/xcms1"
cd $in_dir

log_dir="$dir/output_dir/log_dir/$SLURM_JOB_NAME" #make a folder to hold the output results text files - there are zillions of them. 

if [ ! -d "$log_dir" ]; then
    mkdir -p "$log_dir"
fi


echo `date`
echo This is job $SLURM_JOB_ID

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargKL4

Rscript --no-save --no-restore --verbose $dir/scripts_dir/xcms_combine.R "$in_dir" "$ionMode" > "$log_dir/${SLURM_JOB_NAME}_$ionMode.Rout" 2>&1 > "$log_dir/${SLURM_JOB_NAME}_$ionMode.log"
