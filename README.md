# Pipeline for pre-processing a multi-batch untargeted exometabolome experiment with XCMS on a HPC
This is a *work in progress* and will be changing constantly as I learn...


## Step 1: peak picking and peak shape evaluation
Run the peak picking and peak shape on each file individually.
```sbatch scripts_dir/run-xcms1.slurm```

Update status of jobs to your screen if you're interested
```watch -n 60 squeue -u emcparland```

Important note about activating conda environment on hpc with slurm:
- Remember that this is a new compute environment for each array so it doesn't know about your conda init
- Most scripts I've seen use the 'source activate myenv' command. However, when using this my .Rout file kept throwing this error: "/vortexfs1/home/emcparland/.conda/envs/untargmetab/lib/R/bin/R: line 240: /vortexfs1/home/emcparland/.conda/envs/untargmetab/lib/R/etc/ldpaths: No such file or directory"
- This seems to be a problem for [others](https://github.com/conda-forge/r-base-feedstock/issues/67)
- One suggested solution was to use the newer command 'conda activate my env'. To do this you need to source your conda.sh, you'll see this in the code as:
```CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargmetab```
-However, as of today (3/24) the script was still throwing the same error when I run larger arrays (though not as many as before?)
-One step further, seems like this is an issue of running the array and initializing the environment every time. For some reason the conda activate initializes the path every time and sometimes the path doesn't exist?! I don't fully understand this yet but it seems to be an unresolved issue on git. A fix proposed by another git user and that seems to be working for me is to edit the activate-r-base.sh script in the environment
```nano ~/.conda/envs/untargmetab/etc/conda/activate.d/activate-r-base.sh```

comment out the "R CMD javareconf" line to look like this:
```#!/usr/bin/env sh
#R CMD javareconf > /dev/null 2>&1 || true ```
