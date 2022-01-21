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


dir="$HOME/UntargCode/output_dir/xcms2"
cd "$dir"

work_dir="/output_dir/xcms2"

echo `date`
echo This is job $SLURM_JOB_ID

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargKL4

Rscript --no-save --no-restore --verbose $dir/scripts_dir/CAMERA_KL2.R "$work_dir" > "$dir/${SLURM_JOB_NAME}_${SLURM_JOB_ID}.Rout" 2>&1 > $dir/${SLURM_JOB_NAME}_${SLURM_JOB_ID}.log
 
echo `date`
