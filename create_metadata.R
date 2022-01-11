##KL working in file from Erin McParland...making notes as I go
# first issue, files named in different format for SargPatch cfd to Erin's samples
##KL 1/11/2021
args = commandArgs(trailingOnly=TRUE)
suppressMessages(library(dplyr))

# #use these rows for troubleshooting locally
# in_dir="C:/Users/klongnecker/Documents/Current projects/Kujawinski_BIOS-SCOPE/RawData/Lumos/sequence_fromMethods"
# usePath <- paste0(in_dir)
# ionMode <- "pos"

#this is the version for the HPC and the slurm script
usePath <- paste0(args[1])
ionMode<-paste0(args[2])

# Read in list of all mz files and specify (in sbatch command) the ion Mode
ext <- ".mzML"
pre <- paste0(usePath,"/")

#Erin had this - BUT her file names had pos/neg in the file name, which is redundant from 
#later processing (though does make file tracking easier)
#mzdatafiles <- list.files(usePath,recursive = FALSE, full.names=TRUE, pattern=glob2rx(paste0("*",ionMode,"*",ext)))
mzdatafiles <- list.files(usePath,recursive = FALSE, full.names=TRUE, pattern=glob2rx(paste0("*",ext)))

# Read in list of all csv files from sequence methods and specificy ion Mode
#csvfile <- list.files(usePath, recursive=FALSE, full.name=TRUE, pattern=glob2rx(paste0("*",ionMode,"*",".csv")))
csvfile <- list.files(usePath, recursive=FALSE, full.name=TRUE, pattern=glob2rx(paste0("*",".csv")))

# Combine all of your files into one
#bind_rows will require library(dplyr)
all_csv<-bind_rows(lapply(csvfile,read.csv,skip=1))

# This is just a blank row generated when exported that I don't need
if("Sample.ID" %in% colnames(all_csv)){all_csv$Sample.ID<-NULL}

# Filter all to keep just the ionMode and goodData of interest
all_csv<-all_csv[which(all_csv$ionMode==ionMode & all_csv$goodData==1),]

# Add a column with the full file basename
all_csv$FileWithExtension<-paste0(all_csv$File.Name,ext)

# Check you didn't make any mistakes and then write file
#if nothing is found, no file will be created...but code shows success, change that with if/else something
if(all(all_csv$FileWithExtension %in% basename(mzdatafiles))==TRUE)
{ write.table(all_csv,paste0("metadata_",ionMode,".txt"),append = FALSE, sep = "\t",row.names = FALSE,col.names=TRUE,quote=FALSE)
	} else {
		file.create("metadata_mismatchissue.csv")
	}
	
