# Pipeline for pre-processing a multi-batch untargeted exometabolome experiment with XCMS on a HPC
:construction: :warning: This is a **work in progress** :construction: :warning:

*A big thank you to Krista Longnecker (WHOI) who laid the groundwork for this code and Elzbieta Lauzikaite (Imperial College London) who setup [a similar framework for pbs](https://github.com/lauzikaite/Imperial-HPC-R) that I built off*

**As is, you could run this in your own compute space by installing the conda environment and altering the paths and inputs in the run files. But if you have a different experimental setup, you should also have a look at the R scripts**

## Install the conda environment via the yml file:
```conda env create --file untargmetab.yml```

This includes R version 3.6 plus XCMS3 and Autotuner, and jupyter notebook for later analyses. If you're not comfortable with conda or conda+R I recommend starting by reading  this [blog post by Sarah Hu](https://alexanderlabwhoi.github.io/post/anaconda-r-sarah/) and then use your friend google.

## Note about activating this conda environment on hpc with slurm:
- Remember that your sbatch command will create a new compute environment for each array so it doesn't know about your conda init
- Most scripts I've seen use the 'source activate myenv' command. However, when using this my .Rout file kept randomly throwing this error: "/vortexfs1/home/emcparland/.conda/envs/untargmetab/lib/R/bin/R: line 240: /vortexfs1/home/emcparland/.conda/envs/untargmetab/lib/R/etc/ldpaths: No such file or directory"
- This seems to be a problem for [others](https://github.com/conda-forge/r-base-feedstock/issues/67)
- One suggested solution was to use the newer command 'conda activate myenv'. To do this you need to source your conda.sh, you'll see this in the code as:

```CONDA_BASE=$(conda info --base)```
```source $CONDA_BASE/etc/profile.d/conda.sh```
```conda activate untargmetab```

-However, the script was still throwing the same error randomly when I run larger arrays (though not as many as before?)

-One step further, seems like this is an issue of running the array and initializing the environment every time. For some reason the conda activate initializes the path every time and sometimes the path doesn't exist?! I don't fully understand this yet but it seems to be an unresolved issue on git. A fix proposed by another git user and that seems to be working for me is to edit the activate-r-base.sh script in the environment:

```nano ~/.conda/envs/untargmetab/etc/conda/activate.d/activate-r-base.sh```

comment out the "R CMD javareconf" line to look like this: 

```#!/usr/bin/env sh```

```#R CMD javareconf > /dev/null 2>&1 || true ```

## Step 1: Create metadata
This is a quick R script to create a tab-delimited metadata file of all the sequence files (if you have multiple batches) and keep only the mzML files you want to peak pick and align (e.g. I remove the 9 conditioning pool samples here from each batch). *Make sure you have added a column named ionMode (pos or neg) and goodData (0 or 1).* It will also add an extra column to the metadata with the path of each mzml file that is useful for later.

```sbatch scripts_dir/run-metadata.slurm```

Check how many files you have ```wc -l metadata.txt```

I have 502 and I will use this number in Step 3 to set the total number of array jobs that will be run.

## Step 2: Run Autotuner for XCMS parameter selection
My peak picking parameters are for marine dissolved organic matter extracted with PPL per the Kuj lab protocol, [Kido Soule et al. 2015](https://doi.org/10.1016/j.marchem.2015.06.029), use the R package[Autotuner](https://doi.org/10.1021/acs.analchem.9b04804) to find parameters appropriate for your sample types. I run Autotuner interactively with a jupyter notebook with the notebook file provided here. 

If you have not used jupyter remotely on an hpc check out the [blog posts by the Alexander lab](https://alexanderlabwhoi.github.io/post/2019-03-08_jpn_slurm/). For first time users, remember to configure jupyter. For reference, I call jupyter on hpc as follows: 

```jupyter notebook --no-browser --port=9000 --ip=0.0.0.0```

Make sure I know the login number and node and then create an ssh tunnel on my local computer with: ```ssh -N -f -L port:node:port username@hpc```

Type into local browser: ```localhost:9000``` and voila!

## Step 3: peak picking and peak shape evaluation
Run the peak picking and peak shape on each file individually with an array job. This step is an 'embarassingly parallel' computation so I use a job array to quickly process hundreds of files. I run 40 jobs at a time and each jobs takes about 20 minutes each. With >20,000 features the peak shape evaluation script actually takes longer than the peak picking step. For 500 files, I am done with Step 3 in ~4 hours and 45 minutes :clap: :grin: :clap:

```sbatch scripts_dir/run-xcms1.slurm```

Update status of jobs to your screen if you're interested (this is how I got the issue below of skipping files) ```watch -n 60 squeue -u emcparland```

## Step 4: combine picked peaks
To speed up peak picking, we performed peak picking as an array. Now combine into a single MS OnDisk object

```sbatch scripts_dir/run-xcms2_combine.slurm```

## Step 5: perform retention time correction, grouping and fill peaks
This will use xcms to perform orbiwarp retention time correction, peak grouping, and fill peaks. As I ran a pooled sample every five samples in these batches, I use the subset option for retention time alignment and peak grouping. At each stage a new RData object is saved in case something crashes in the middle or you want to look at the files while they are running. Finally it will output two csv files, one with all of the peaks ("aligned.csv") and the second with the feature count table ("picked.csv")

Note: For reference, when I was testing this code with ~100 samples, I could run this on one 'small' memory node of 185GB. However, my actual dataset of 500+ samples required being run on the 'bigmem' partition with 500GB of memory.

```sbatch scripts_dir/run-xcms2.slurm```

