#!/bin/bash
#SBATCH --partition=compute
#SBATCH --job-name=meta
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=klongnecker@whoi.edu 
#SBATCH --ntasks=1
#SBATCH --mem=4000
#SBATCH --time=00:10:00
#SBATCH --output=/vortexfs1/home/klongnecker/UntargCode/logfiles_dir/meta.out
#SBATCH --error=/vortexfs1/home/klongnecker/UntargCode/logfiles_dir/meta.error

#change to send in ionMode as a variable, will call this way
#sbatch --export=ionMode="pos" scripts_dir/run-metadata.slurm
#and then down later use $ionMode

dir="$HOME/UntargCode"
cd "$dir"

in_dir="/vortexfs1/omics/kujawinski/data/SargPatch/SargPatch_MSn"

#setup the places to hold stuff
log_dir="$dir/logfiles_dir/$SLURM_JOB_NAME" #make a folder to hold the output results text files - there are zillions of them. 

if [ ! -d "$log_dir" ]; then
    mkdir -p "$log_dir"
fi



CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargKL4

#Rscript --no-save --no-restore --verbose $dir/scripts_dir/create_metadata.R "$in_dir" "pos" > $dir/$SLURM_JOB_NAME.Rout 2>&1 >$dir/$SLURM_JOB_NAME.log
Rscript --no-save --no-restore --verbose $dir/scripts_dir/create_metadata.R "$in_dir" "$ionMode" > "$log_dir/${SLURM_JOB_NAME}_$ionMode.Rout" 2>&1 > "$log_dir/${SLURM_JOB_NAME}_$ionMode.log"
