#!/bin/bash
#SBATCH --partition=compute
#SBATCH --job-name=camera
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=klongnecker@whoi.edu
#SBATCH --ntasks-per-node=12
#SBATCH --mem=20gb
#SBATCH --time=6:00:00
#SBATCH --output=/vortexfs1/home/klongnecker/UntargCode/logfiles_dir/camera.out
#SBATCH --error=/vortexfs1/home/klongnecker/UntargCode/logfiles_dir/camera.error

dir="$HOME/UntargCode"
cd "$dir"

work_dir="$dir/output_dir/xcms2"

log_dir="$dir/logfiles_dir" #use a folder to hold the output results 

echo `date`
echo This is job $SLURM_JOB_ID

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargKL4

Rscript --no-save --no-restore --verbose $dir/scripts_dir/CAMERA_KL.R "$work_dir" > "$log_dir/${SLURM_JOB_NAME}.Rout" 2>&1 > $log_dir/${SLURM_JOB_NAME}.log
 
echo `date`
