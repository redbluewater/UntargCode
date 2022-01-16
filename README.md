# Pipeline for pre-processing a multi-batch untargeted exometabolome experiment with XCMS on a HPC
:construction: :warning: This is a **work in progress** :construction: :warning:

I (Krista) am working off the code written by Erin McParland and updating the information in the README file here as I go. I am a newbie to the HPC, so some details here may be obvious to others, but I needed more information before I could get started. First up, remember to edit the slurm scripts so they send the email notifications to the right person.


**You should edit the parameter in the R scripts to values appropriate for your experimental system.**

## Some steps before getting into the R/XCMS work
1. Convert the .RAW files from the mass spectrometer into mzML files using msConvert
2. Use SCP to transfer those files to Poseidon (we are putting the files into our /omics/kujawinski/data folder)
3. Make a CSV file that contains the file names, ion mode, and good data markers. We do this from the sequence file that is created during the sample run on the LCMS and then add columns for 'ionMode' (can be pos or neg) and goodData (where we use 1 to keep data, and 0 to ignore a file).
4. Put this CSV file into the folder with the mzML files on Poseidon (again with SCP). It will be used to generate a metadata file used in various points of the analysis.

## How to access Poseidon, WHOI's HPC computing environment
I used a Git Bash terminal window to log into poseidon. From WHOI's internal Information Systems' website, I learned I needed the following command:
```ssh username@poseidon.whoi.edu```
The password is my WHOI Active Directory password. I think I have to be logged into the WHOI VPN for this to work. 

Once you are logged into Poseidon, activate the conda module with ```module load anaconda/5.1```


## Moving around code - Windows 10 - GitHub - Poseidon (Krista's setup)
I forked Erin's GitHub repository and then used Git Bash (in a separate window from the bash window I use to access Poseidon) to pull the GitHub repository onto my local desktop computer. On my local computer I use Geany to edit the text files. To get the files back to GitHub, I first had to futz around with setting up an SSH key in GitHub as I had not done that yet. My git skills are poor (and my handy cheat sheet is not available to me at the moment). I settled on using this set of commands to put the files I edit locally back into GitHub:

```git add -A```

```git commit -am "Update README.md"```

```git push```

Then, in the bash window where I have Poseidon open,  I use this command:

```git pull https://github.com/KujawinskiLaboratory/UntargCode.git```

## Install the conda environment via the yml file:
```conda env create --file untargmetab.yml```

This includes R version 3.8 plus XCMS3 and Autotuner, and jupyter notebook for later analyses. If you're not comfortable with conda or conda+R I recommend starting by reading this [blog post by Sarah Hu](https://alexanderlabwhoi.github.io/post/anaconda-r-sarah/) and then use your friend google. Remember that each sbatch command creates a new compute environment, so all the slurm scripts all have this statement in them: ```conda activate untargmetab``` where (Krista thinks) untargmetab is the name established by the untargmetab.yml file above. Also remember that you have activate conda (see above in the step about accessing Poseidon).

Later I learned that I needed R version 3.12 (or so). This required updating the YML file and that was a process. To do this, you need to set up a conda environment and install all the packages in that environment and export the yml file to use in the future. Here's the steps that worked (after logging into Poseidon)
```module load anaconda/5.1```


You only have to create the environment once, anytime you want it in the future, just activate it:
```conda activate untargmetab```

```conda config --add channels conda-forge``` (You cannot get R>3.6 from anaconda)

```conda config --set channel_priority strict``` (may not be necessary)

```conda search r-base``` (find the packages)

```conda create -n r_4.0.5``` (make the environment first, otherwise this hangs forever)

```conda activate r_4.0.5``` (activate it, nothing there yet)

```conda install -c conda-forge r-base=4.0.5```

```conda install r-essentials``` (that syntax is from memory)

```conda config --set restore_free_channel true``` (need to search older channels that are off by default to get xcms to load)

```conda install bioconductor-xcms=3.12.0``` (somehow I also have CAMERA?)

```conda env export > untargKL3.yml``` 

At this point you have your configuration file, edit it locally to change the environment to be untargKL3.yml --> do this by setting the first row to ```name: untargKL3.yml``` and at the very end of the file, edit this ```prefix: /vortexfs1/home/klongnecker/.conda/envs/untargKL3```. Then, go into the various slurm scripts which follow and change them all to read ```conda activate untargKL3```

## Step 1: Create metadata
This is a quick R script to create a tab-delimited metadata file of all the sequence files (if you have multiple batches) and keep only the mzML files you want to peak pick and align (e.g. I remove the 9 conditioning pool samples here from each batch). *Make sure you have added a column named ionMode (pos or neg) and goodData (0 or 1).* It will also add an extra column to the metadata with the path of each mzml file that is useful for later. You may need to edit the string used to match files in the create_metadata.R script. Krista's file names did not have pos/neg in the name, but Erin's did. 

```sbatch scripts_dir/run-metadata.slurm```

Check how many files you have 
```wc -l metadata.txt```

I (Erin) have 502 and I will use this number in Step 3 to set the total number of array jobs that will be run.

I (Krista) edited the script so that it spits out a file ("metadata_mismatchissue.csv") if there are no matches found between the list of files provided and the files actually available on Poseidon. 

## Step 2: Run Autotuner for XCMS parameter selection (Krista skipping this for now)
My peak picking parameters are for marine dissolved organic matter extracted with PPL per the Kuj lab protocol, [Kido Soule et al. 2015](https://doi.org/10.1016/j.marchem.2015.06.029), use the R package[Autotuner](https://doi.org/10.1021/acs.analchem.9b04804) to find parameters appropriate for your sample types. I run Autotuner interactively with a jupyter notebook with the notebook file provided here. 

If you have not used jupyter remotely on an hpc check out the [blog posts by the Alexander lab](https://alexanderlabwhoi.github.io/post/2019-03-08_jpn_slurm/). For first time users, remember to configure jupyter. For reference, I call jupyter on hpc as follows: 

```jupyter notebook --no-browser --port=9000 --ip=0.0.0.0```

Make sure I know the login number and node and then create an ssh tunnel on my local computer with: ```ssh -N -f -L port:node:port username@hpc```

Type into local browser: ```localhost:9000``` and voila!

## Step 3: peak picking and peak shape evaluation
Run the peak picking and peak shape on each file individually with an array job. This step is an 'embarassingly parallel' computation so I use a job array to quickly process hundreds of files. I run 40 jobs at a time and each jobs takes about 20 minutes each. I filter the peaks based on RMSE < 0.125 Then use peak cleaning functions to remove wide peaks (<40 s) and merge neighboring peaks. For 500 files, I am done with Step 3 in ~3 hours :clap: :grin: :clap:

```sbatch scripts_dir/run-xcms1.slurm```

Update status of jobs to your screen if you're interested (this is how I discovered the issue mentioned above of skipping files) ```watch -n 60 squeue -u emcparland```

## Step 4: combine picked peaks
To speed up peak picking, we performed peak picking as an array. Now combine into a single MS OnDisk object

```sbatch scripts_dir/run-xcms_combine.slurm```

## Step 5: perform retention time correction, grouping and fill peaks
This will use xcms to clean up peak picking with refineChromPeaks, then perform orbiwarp retention time correction, correspondence (peak grouping), and fill peaks. As I ran a pooled sample every five samples in these batches, I use the subset option for retention time alignment and peak grouping. At each stage a new RData object is saved in case something crashes in the middle or you want to look at the files while they are running. Finally it will output two csv files, one with all of the peaks ("aligned.csv") and the second with the feature count table ("picked.csv")

Note: For reference, when I was testing this code with ~100 samples, I could run this on one 'small' memory node of 185GB. However, my actual dataset of 500+ samples required being run on the 'bigmem' partition with 500GB of memory. The refinechrompeaks and fill peaks steps require loading the original raw files and therefore required the bigmem memory space (obiwarp and correspondence require much less memory).

```sbatch scripts_dir/run-xcms2.slurm```

## Step 6: Create an xset object
Both CAMERA and MetaClean will require your data object to be in the 'old' XCMS format. This script will create this object for you. Note the fix-around for the error thrown by sample class naming. I had to use bigmem to make fillPeaks run. Make sure you edit the polarity mode.

```srun -p bigmem --time=04:00:00 --ntasks-per-node=1 --mem=500gb --pty bash```

```conda activate untargmetabR4```

```R```

```source("create_xset.R")```

## Step 7: Use CAMERA to create pseudospectra.
CAMERA also uses the xcmsSet object which you already made for MetaClean.

```sbatch scripts_dir/run-camera.slurm```

## Step 8: Use MetaClean for peak checking
Note to self: this is not installed yet

[Chetnik et al. 2020](https://link.springer.com/article/10.1007/s11306-020-01738-3) published MetaClean for a less biased and much faster method to clean up peaks.
Use the MetaClean.R script to train the classifier and then apply to the full dataset. Before you create the global classifier, you need to create a pdf of EIC's (I classified 2000 for development and 1000 for testing the resulting classifier) as GOOD or BAD peaks. See Chetnik et al. for helpful examples to classify your peaks. After training the classifier then apply to the full dataset.

## Misc. handy functions I seem to use over and over
```conda info --envs```
```conda search r-base```
```squeue -u klongnecker```

## Some other notes from Erin McParland's version of the README file.
*A big thank you to Krista Longnecker (WHOI) who laid the groundwork for this code and Elzbieta Lauzikaite (Imperial College London) who setup [a similar framework for pbs](https://github.com/lauzikaite/Imperial-HPC-R) that I built off*
