# Pipeline for pre-processing a multi-batch untargeted exometabolome experiment with XCMS on a HPC
15 February 2022\
I (Krista) am working off the code written by Erin McParland and updating the information in the README file here as I go. I am a newbie to the HPC, so some details here may be obvious to others, but I needed more information before I could get started. 

Make sure to edit the slurm scripts so they send the email notifications to the right person. Also remember to edit the parameters in the R scripts to values appropriate for your experimental system.

## Some steps before getting into the R/XCMS work
1. Convert the .RAW files from the mass spectrometer into mzML files using msConvert
2. Use SCP to transfer those files to Poseidon (we are putting the files into our /omics/kujawinski/data folder)
3. Make a CSV file that contains the file names, ion mode, and good data markers. We do this from the sequence file that is created during the sample run and then add columns for 'ionMode' (can be pos or neg) and goodData (where we use 1 to keep data, and 0 to ignore a file, see *exampleInfoFile.csv*)
4. Put this CSV file into the folder with the mzML files on Poseidon (again with SCP). It will be used to generate a metadata file used in various points of the analysis.

## How to access Poseidon, WHOI's HPC computing environment
I used a Git Bash terminal window to log into poseidon. From WHOI's internal Information Systems' website, I learned I needed the following command:
```ssh username@poseidon.whoi.edu```
The password is my WHOI Active Directory password. I think I have to be logged into the WHOI VPN for this to work. 

Once you are logged into Poseidon, activate the conda module with ```module load anaconda/5.1```


## Moving around code - Windows 10 - GitHub - Poseidon (Krista's setup)
I forked Erin's GitHub repository and then used Git Bash (in a separate window from the bash window I use to access Poseidon) to pull the GitHub repository onto my local desktop computer. On my local computer I use Geany to edit the text files. To get the files back to GitHub, I first had to futz around with setting up an SSH key in GitHub as I had not done that yet. I settled on using this set of commands to put the files I edit locally back into GitHub:

```git add -A```\
```git commit -am "Brief description goes here"``` (can use the bit in quotes to describe the update)\
```git push```\
(enter the passcode I use to get files to GitHub)

Then, in the bash window where I have Poseidon open,  I use this command:\
```git pull https://github.com/KujawinskiLaboratory/UntargCode.git``` or just ```git pull```

Remember that if I edit the README.md file here in GitHub (online), I need to do a local ```git pull``` before I can push any edits back to GitHub. I suspect there is a way around this with a more specific git command, but I haven't bothered to look into that.

In the event that you want to start all over again from the files that are in GitHub, from Poseidon enter this\
```git reset --hard HEAD```

## Create the conda environment you will need
You use conda to gather all the pieces you need: R and its various packages. For example, I needed R version 3.12 (or so) which required updating Erin's YML file. This is quite a process (read, hassle). To do this, you need to set up a conda environment, install all the packages in that environment, and export the yml file to use in the future. Erin's text file (*oldFiles/create_untargmetab_conda_poseidon.txt*) detailed what she did. Here's the steps that worked for me (after logging into Poseidon):\
```module load anaconda/5.1```\
```conda config --add channels conda-forge``` (you cannot get R>3.6 from anaconda)\
```conda config --set channel_priority strict``` (may not be necessary)\
```conda search r-base``` (find the packages)\
```conda create -n r_4.0.5``` (make the environment first, otherwise this hangs forever)\
```conda activate r_4.0.5``` (activate it, nothing there yet)\
```conda install -c conda-forge r-base=4.0.5```\
```conda install r-essentials``` \
```conda config --set restore_free_channel true``` (need to search older channels that are off by default to get xcms to install)\
```conda install bioconductor-xcms=3.12.0``` \
```conda install r-gtools```\
```conda install bioconductor-camera=1.46.0```\
```conda env export > untargKL4.yml``` 

At this point you have your configuration file, edit it locally to change the environment to be untargKL4.yml --> do this by setting the first row to ```name: untargKL4.yml``` and at the very end of the file, edit this ```prefix: /vortexfs1/home/klongnecker/.conda/envs/untargKL4```. Then, go into the various slurm scripts which follow and change them all to read ```conda activate untargKL4```

Install the conda environment via the yml file:\
```conda env create --file untargKL4.yml```

You only have to create the environment once, anytime you want it in the future, just activate it:
```conda activate untargKL4```

Remember that each sbatch command creates a new compute environment, so all the slurm scripts all have this statement in them: ```conda activate untargKL4``` where untargKL4 is the name established by the yml file above. Also remember that you have activate the module with conda before doing anything (see above in the step about accessing Poseidon, repeating here because I keep forgetting).


## Step 1: Create metadata
This is a quick R script to create a tab-delimited metadata file of all the sequence files (if you have multiple batches) and keep only the mzML files you want to peak pick and align (e.g. I remove the 9 conditioning pool samples here from each batch). Make sure you have added a column named ionMode (pos or neg) and goodData (0 or 1, see exampleInfoFile.csv) It will also add an extra column to the metadata with the path of each mzml file that is useful for later. You may need to edit the string used to match files in the create_metadata.R script. Krista's file names did not have pos/neg in the name, but Erin's did. Also, if you change the files you want (by changing goodData), make sure old rds files are removed from the output_dir/xcms1. Any rds files in that folder will get read into the final data file.

Set this up to send in ionMode as a variable so I don't have to edit all the slurm scripts each time I change ion mode\
```sbatch --export=ionMode="pos" scripts_dir/step1-metadata.slurm```

Check how many files you have 
```wc -l metadata_{neg/pos}.txt```

Use this number in Step 2 to set the total number of array jobs that will be run.

## Step 2: peak picking and peak shape evaluation
Run the peak picking and peak shape on each file individually with an array job. This step is an 'embarassingly parallel' computation so I use a job array to quickly process hundreds of files. I run 40 jobs at a time and each jobs takes about 20 minutes each. I filter the peaks based on RMSE < 0.125 Then use peak cleaning functions to remove wide peaks (<40 s) and merge neighboring peaks. For 500 files, I am done with Step 3 in ~3 hours :clap: :grin: :clap:

```sbatch --export=ionMode="pos" scripts_dir/step2-xcms1.slurm```

## Step 3: combine picked peaks
To speed up peak picking, we performed peak picking as an array. Now combine into a single MS OnDisk object

```sbatch --export=ionMode="pos" scripts_dir/step3-xcms_combine.slurm```

## Step 4: perform retention time correction, grouping and fill peaks
This will use xcms to clean up peak picking with refineChromPeaks, then perform orbiwarp retention time correction, correspondence (peak grouping), and fill peaks. As I ran a pooled sample every five samples in these batches, I use the subset option for retention time alignment and peak grouping. At each stage a new RData object is saved in case something crashes in the middle or you want to look at the files while they are running. Finally it will output two csv files, one with all of the peaks ("aligned.csv") and the second with the feature count table ("picked.csv")

Note: For reference, when I was testing this code with ~100 samples, I could run this on one 'small' memory node of 185GB. However, my actual dataset of 500+ samples required being run on the 'bigmem' partition with 500GB of memory. The refinechrompeaks and fill peaks steps require loading the original raw files and therefore required the bigmem memory space (obiwarp and correspondence require much less memory).

```sbatch --export=ionMode="pos" scripts_dir/step4-xcms2.slurm```

## Step 5: Create an xset object 
Both CAMERA and MetaClean will require your data object to be in the 'old' XCMS format. This script will create this object for you. Note the fix-around for the error thrown by sample class naming. I (Erin) had to use bigmem to make fillPeaks run. 
There is a note/comment that one step in create_xset.R makes and it will break the slurm script. Krista did some extra pieces to make this step work as a slurm script.

```sbatch --export=ionMode="pos" scripts_dir/step5-create_xset.slurm```

Now go back and repeat steps #1 through 5 for the other ion mode (or get smart and run pos/neg with each slurm script in pairs)

## Step 6: Use CAMERA to create pseudospectra
Once you have both ion modes done, you are ready to run the script for CAMERA.\
```sbatch scripts_dir/step6-camera.slurm```

## Misc. handy functions
```conda info --envs```\
```conda search r-base```\
```squeue -u klongnecker```

This will let you open up an R window for testing on Poseidon (useful for testing):\
```srun -p compute --time=01:00:00 --ntasks-per-node=1 --mem=10gb --pty bash```\
```conda activate untargKL4```\
```R```\
```source("create_xset.R")``` (for example - could run the create_xset.R script)

You can also edit text files on the HPC, though I confused myself keeping track of what is where when I did this. The most basic way to do this is \
```nano yourTextFile.txt```\
Then, when you run into issues with files changing in mulitple places\
```git stash```

## Setting up to use Jupyter notebook remotely on HPC
I thought I could avoid this, but in order to plot anything I needed to setup a way to access the data and the mzML files. I was tempted to mess around and change the paths in the R file, but then I would need to move 100 gb of files to my local computer. It took me multiple hoops to figure this out. Also, my local computer is running Windows 10, and I use Anaconda.\
Log into the HPC site and activate the conda module with ```module load anaconda/5.1```\
Set up to require a password for Juypter notebook (You only have to do this once):\
```jupyter notebook --generate-config``` - this makes the .jupyter\juptyer_notebook.config.py file\
```jupyter notebook password``` - this sets the password. Enter it twice, and remember it because you will need it later on the local computer.

Then I made a slurm script to launch jupyter notebook:\
```sbatch launch_jupyter.slurm```

Once the script is run, use this to find the jobid: ```squeue -u klongnecker``` and then use that information to get the port number (e.g., 'pn083')

On my local computer, I used the Anaconda Power Shell to run this ```ssh -L 8888:<port number>:8888 klongnecker@poseidon.whoi.edu```\
 Open a browser window and enter: ```localhost:8888``` and enter the password set above.

# Bits from Erin's README.md file
*A big thank you to Krista Longnecker (WHOI) who laid the groundwork for this code and Elzbieta Lauzikaite (Imperial College London) who setup [a similar framework for pbs](https://github.com/lauzikaite/Imperial-HPC-R) that I built off*\
If you're not comfortable with conda or conda+R I recommend starting by reading this [blog post by Sarah Hu](https://alexanderlabwhoi.github.io/post/anaconda-r-sarah/) and then use your friend google.

## Run Autotuner for XCMS parameter selection
My peak picking parameters are for marine dissolved organic matter extracted with PPL per the Kuj lab protocol, [Kido Soule et al. 2015](https://doi.org/10.1016/j.marchem.2015.06.029), use the R package[Autotuner](https://doi.org/10.1021/acs.analchem.9b04804) to find parameters appropriate for your sample types. I run Autotuner interactively with a jupyter notebook with the notebook file provided here. 

If you have not used jupyter remotely on an hpc check out the [blog posts by the Alexander lab](https://alexanderlabwhoi.github.io/post/2019-03-08_jpn_slurm/). For first time users, remember to configure jupyter. For reference, I call jupyter on hpc as follows: 

```jupyter notebook --no-browser --port=9000 --ip=0.0.0.0```

Make sure I know the login number and node and then create an ssh tunnel on my local computer with: ```ssh -N -f -L port:node:port username@hpc```

Type into local browser: ```localhost:9000``` and voila!

## Use MetaClean for peak checking
[Chetnik et al. 2020](https://link.springer.com/article/10.1007/s11306-020-01738-3) published MetaClean for a less biased and much faster method to clean up peaks.
Use the MetaClean.R script to train the classifier and then apply to the full dataset. Before you create the global classifier, you need to create a pdf of EIC's (I classified 2000 for development and 1000 for testing the resulting classifier) as GOOD or BAD peaks. See Chetnik et al. for helpful examples to classify your peaks. After training the classifier then apply to the full dataset.

##
Update status of jobs to your screen if you're interested (this is how I discovered the issue mentioned above of skipping files) ```watch -n 60 squeue -u klongnecker```
