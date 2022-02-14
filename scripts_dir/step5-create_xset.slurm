#!/bin/bash
#SBATCH --partition=bigmem
#SBATCH --job-name=create_xset
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=klongnecker@whoi.edu
#SBATCH --ntasks-per-node=1
#SBATCH --mem=200gb
#SBATCH --time=1:00:00
#SBATCH --output=/vortexfs1/home/klongnecker/UntargCode/logfiles_dir/create_xset.out
#SBATCH --error=/vortexfs1/home/klongnecker/UntargCode/logfiles_dir/create_xset.error
 
dir="$HOME/UntargCode"
cd "$dir"

work_dir="$dir/output_dir/xcms2"

log_dir="$dir/logfiles_dir"  

if [ ! -d "$log_dir" ]; then
    mkdir -p "$log_dir"
fi

echo `date`
echo This is job $SLURM_JOB_ID

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargKL4

Rscript --no-save --no-restore --verbose $dir/scripts_dir/create_xset.R "$work_dir" "$ionMode"> "$log_dir/${SLURM_JOB_NAME}_$ionMode.Rout" 2>&1 > "$log_dir/${SLURM_JOB_NAME}_$ionMode.log"

echo `date`
