args = commandArgs(trailingOnly=TRUE)
suppressMessages(library(xcms))

date()
paste("This is task", Sys.getenv('SLURM_ARRAY_TASK_ID'))

usePath <- paste0(args[1])
ext <- ".mzML"
pre <- paste0(usePath,"/")

ionMode <- paste0(args[2])

# Parameters from Autotuner
load(paste0("autotuneparams_",ionMode,".RData"))

# Load metadata object
file_list <- paste0("metadata_",ionMode,".txt")
files <- read.table(file = file_list,sep="\t",header=TRUE)

# File to process based on array number
f<- as.numeric(paste0(args[3]))
raw_file <- files$FileWithExtension[f]

paste("This is xcms1 pre-process for file", raw_file)

# Output dir
output_dir<- paste0(args[4])

# Read in file as an OnDiskMsnExp object
file <- readMSData(files=paste0(pre,raw_file),pdata = new("NAnnotatedDataFrame",files[f,]) ,mode="onDisk")

# Set peak picking parameters
cwp <- CentWaveParam(peakwidth = c(minWidth, maxWidth), noise = NOISE, ppm = PPM, mzCenterFun = "wMean", prefilter = c(PreScan,PreIntensity),integrate = 2, mzdiff = -0.005, fitgauss = TRUE, snthresh = SNTHRESH,verboseColumns=TRUE)

# Perform peak picking on file
xs <- findChromPeaks(file, param = cwp)

# Perform peak shape filtering
source("/vortexfs1/home/emcparland/untarg_xcms/scripts_dir/peakShape_XCMS3.r")
xdata<-peakShape_XCMS3(xs,cor.val = 0.9,useNoise = NOISE)

# Save peak picked and filtered object
saveRDS(xdata, file = paste0(output_dir,"/xcms1-",ionMode,"-", f, ".rds"))

date()
