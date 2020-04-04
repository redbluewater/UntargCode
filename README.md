# Pipeline for pre-processing a multi-batch untargeted exometabolome experiment with XCMS on a HPC
:construction: :warning: This is a **work in progress** and will be changing constantly as I learn... :construction: :warning:


## Step 1: Create metadata
This is a quick R script to create a tab-delimited metadata file of all the sequence files (if you have multiple batches) and keep only the mzML files you want to peak pick and align (e.g. I remove the 9 conditioning pool samples here from each batch). It will also add an extra column to the metadata with the path of each mzml file that is useful for later.

```sbatch scripts_dir/run-metadata.slurm```

Check how many files you have
```wc -l metadata.txt```

I have 502 and I will use this number in Step 2 to set the total number of array jobs that will be run.

## Step 2: peak picking and peak shape evaluation
Run the peak picking and peak shape on each file individually.
```sbatch scripts_dir/run-xcms1.slurm```

Update status of jobs to your screen if you're interested (this is how I got the issue below of skipping files)
```watch -n 60 squeue -u emcparland```

Important note about activating conda environment on hpc with slurm:
- Remember that this is a new compute environment for each array so it doesn't know about your conda init
- Most scripts I've seen use the 'source activate myenv' command. However, when using this my .Rout file kept randomly throwing this error: "/vortexfs1/home/emcparland/.conda/envs/untargmetab/lib/R/bin/R: line 240: /vortexfs1/home/emcparland/.conda/envs/untargmetab/lib/R/etc/ldpaths: No such file or directory"
- This seems to be a problem for [others](https://github.com/conda-forge/r-base-feedstock/issues/67)
- One suggested solution was to use the newer command 'conda activate myenv'. To do this you need to source your conda.sh, you'll see this in the code as:

```CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate untargmetab```

-However, as of today (3/24) the script was still throwing the same error randomly when I run larger arrays (though not as many as before?)
-One step further, seems like this is an issue of running the array and initializing the environment every time. For some reason the conda activate initializes the path every time and sometimes the path doesn't exist?! I don't fully understand this yet but it seems to be an unresolved issue on git. A fix proposed by another git user and that seems to be working for me is to edit the activate-r-base.sh script in the environment:

```nano ~/.conda/envs/untargmetab/etc/conda/activate.d/activate-r-base.sh```
comment out the "R CMD javareconf" line to look like this:
```#!/usr/bin/env sh
#R CMD javareconf > /dev/null 2>&1 || true ```

## Step 3: combine picked peaks and perform retention time correction
This will combine all of your peak picked and filtered xcms objects into one object. Then it will use xcms to perform orbiwarp retention time correction, peak grouping, and fill peaks. At each stage a new RData object is saved in case something crashes in the middle or you want to look at the files while they are running. Finally it will output two csv files, one with all of the peaks ("aligned.csv") and the second with the feature count table ("picked.csv")

```sbatch scripts_dir/run-xcms2.slurm```