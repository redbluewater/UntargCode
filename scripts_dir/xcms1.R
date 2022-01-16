args = commandArgs(trailingOnly=TRUE)
suppressMessages(library(xcms))

date()
paste("This is task", Sys.getenv('SLURM_ARRAY_TASK_ID'))

usePath <- paste0(args[1])
ext <- ".mzML"
pre <- paste0(usePath,"/")

ionMode <- paste0(args[2])

# Load metadata object
file_list <- paste0("metadata_",ionMode,".txt")
files <- read.table(file = file_list,sep="\t",header=TRUE)

# Load params
params <- read.csv("params.csv", row.names = 1)
minw <- params['minw',ionMode]
maxw <- params['maxw',ionMode]
noise <- params['noise',ionMode]
ppm <- params['ppm',ionMode]
prescan <- params['prescan',ionMode]
preintensity <- params['preintensity',ionMode]
snthresh <- params['snthresh',ionMode]
rmse <- params['rmse',ionMode]
bw <- params['bw',ionMode]

# File to process based on array number
f<- as.numeric(paste0(args[3]))
raw_file <- files$FileWithExtension[f]

paste("This is xcms1 pre-process for file", raw_file)

# Output dir
output_dir<- paste0(args[4])

# Read in file as an OnDiskMsnExp object
file <- readMSData(files=paste0(pre,raw_file),pdata = new("NAnnotatedDataFrame",files[f,]) ,mode="onDisk")

# Set peak picking parameters
minWidth=minw; maxWidth=maxw; NOISE=noise; PPM=ppm; PreScan=prescan; PreIntensity=preintensity; SNTHRESH=snthresh;
#cwp <- CentWaveParam(peakwidth = c(minWidth, maxWidth), noise = NOISE, ppm = PPM, mzCenterFun = "wMean", prefilter = c(PreScan,PreIntensity),integrate = 2, mzdiff = -0.005, fitgauss = TRUE, snthresh = SNTHRESH, extendLengthMSW = TRUE, verboseColumns = TRUE)
cwp <- CentWaveParam(peakwidth = c(minWidth, maxWidth), noise = NOISE, ppm = PPM, mzCenterFun = "wMean", prefilter = c(PreScan,PreIntensity),integrate = 2, mzdiff = -0.005, fitgauss = TRUE, snthresh = SNTHRESH, verboseColumns = TRUE)

# Perform peak picking on file
xs <- findChromPeaks(file, param = cwp)

# Filter based on Gaussian RMSE
peakmat <- chromPeaks(xs)
peakmat.new <- peakmat[which(peakmat[,'egauss'] < rmse),]

xs.filt <- xs
chromPeaks(xs.filt) <- peakmat.new
xs.filt@.processHistory <- xs@.processHistory

# Perform peak cleaning
# Remove wide peaks
xset_clean <- refineChromPeaks(xs.filt, param=CleanPeaksParam(maxPeakwidth=40))
# Combine peaks
mpp <- MergeNeighboringPeaksParam(expandRt = 4,expandMz = 0,ppm = 10,minProp = 0.75)
xset <- refineChromPeaks(xset_clean, param = mpp)

# Save peak picked and filtered object
saveRDS(xset, file = paste0(output_dir,"/xcms1-",ionMode,"-", f, ".rds"))

date()
