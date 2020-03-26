args = commandArgs(trailingOnly=TRUE)
suppressMessages(library(xcms))

date()
paste("This is task", Sys.getenv('SLURM_ARRAY_TASK_ID'))

# Parameters from Autotuner
PPM<-1.4
NOISE<-100
PreIntensity<-900
PreScan<-2
SNTHRESH<-3
maxWidth<-9
minWidth<-3
groupDiff<-1.1

usePath <- "/vortexfs1/omics/kujawinski/data/biosscope_untarg"
ext <- ".mzML"
pre <- paste0(usePath,"/")

# Filelist
file_list <- paste0(args[1])
files <- read.table(file = file_list,sep="\t",header=TRUE)

# Datafile to process
f<- as.numeric(paste0(args[2]))
raw_file <- files$FileWithExtension[f]

paste("This is xcms1 pre-process for file", raw_file)

# Output dir
output_dir<- paste0(args[3])

# Read in as an OnDiskMsnExp object
file <- readMSData(files=paste0(pre,raw_file),pdata = new("NAnnotatedDataFrame",files[f,]) ,mode="onDisk")

# Peak picking
cwp <- CentWaveParam(peakwidth = c(minWidth, maxWidth), noise = NOISE, ppm = PPM, mzCenterFun = "wMean", prefilter = c(PreScan,PreIntensity),integrate = 2, mzdiff = -0.005, fitgauss = TRUE, snthresh = SNTHRESH,verboseColumns=TRUE)
xs <- findChromPeaks(file, param = cwp)

# Peak shape filtering
source("/vortexfs1/home/emcparland/untarg_xcms/scripts_dir/peakShape_XCMS3.r")
xdata<-peakShape_XCMS3(xs,cor.val = 0.9,useNoise = NOISE)

saveRDS(xdata, file = paste0(output_dir,"/xcms1-", f, ".rds"))

date()
