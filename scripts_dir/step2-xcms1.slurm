#!/bin/bash
#SBATCH --partition=compute
#SBATCH --job-name=xcms1
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=klongnecker@whoi.edu
#SBATCH --ntasks-per-node=1
#SBATCH --mem=4gb
#SBATCH --time=6:00:00
#SBATCH --output=/vortexfs1/home/klongnecker/UntargCode/logfiles_dir/xcms1.out
#SBATCH --error=/vortexfs1/home/klongnecker/UntargCode/logfiles_dir/xcms1.error
#SBATCH --array=1-68%40 

#this is the numbers for Erin's 502 files do 1 to 502 files in batches of 40. If I use this, update to match what I have
###SBATCH --array=1-502%40 
#change output to just be xcms1.out and xcms1.error - I am not sure why I would want all the individual files
#also change to sending in ionMode from the command line and using $ionMode in here

dir="$HOME/UntargCode"
cd "$dir"

in_dir="/vortexfs1/omics/kujawinski/data/SargPatch/SargPatch_MSn"
out_dir="$dir/output_dir/$SLURM_JOB_NAME"
log_dir="$dir/logfiles_dir/$SLURM_JOB_NAME" #need a folder to hold the output results text files - there are zillions of them. 

if [ ! -d "$out_dir" ]; then
    mkdir -p "$out_dir"
fi
if [ ! -d "$log_dir" ]; then
    mkdir -p "$log_dir"
fi

echo `date`
echo This is job $SLURM_JOB_ID
echo This is task $SLURM_ARRAY_TASK_ID

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargKL4

Rscript --no-save --no-restore --verbose $dir/scripts_dir/xcms1.R "$in_dir" "$ionMode" "$SLURM_ARRAY_TASK_ID" "$out_dir" > "$log_dir/${SLURM_JOB_NAME}_$ionMode_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}.Rout" 2>&1 > "$log_dir/${SLURM_JOB_NAME}_$ionMode_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log"

echo `date`
