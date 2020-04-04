args = commandArgs(trailingOnly=TRUE)
suppressMessages(library(xcms))
suppressMessages(library(BiocParallel))

date()

# Input dir
input_dir <- paste0(args[1])

# Output dir
output_dir<- paste0(args[2])

# Ion Mode
ionMode<- paste0(args[3])

register(BPPARAM = MulticoreParam(workers=36))

# Parameters from autotuner
PPM<-1.4
NOISE<-100
PreIntensity<-900
PreScan<-2
SNTHRESH<-3
maxWidth<-9
minWidth<-3
groupDiff<-1.1

# Load xcmsSet objects into one
input <- list.files(input_dir, pattern = ".rds", full.names = T)
input_l <- lapply(input, readRDS)
xset <- input_l[[1]]
for(i in 2:length(input_l)) {
  set <- input_l[[i]]
  xset <- c(xset, set)
  }
save(list=c("xset"), file = paste0(output_dir,"/xcms2_xset.RData"))

# RT correction
xset_obi <- adjustRtime(xset, param = ObiwarpParam(binSize = 0.1,distFun = "cor", gapInit = 0.3, gapExtend = 2.4), msLevel = 1L)
save(list=c("xset_obi"), file = paste0(output_dir,"/xcms2_obi.RData"))

# Grouping
pdp <- PeakDensityParam(sampleGroups = rep(1, length(fileNames(xset_obi))), minFraction = 0.1, minSamples = 1, bw = groupDiff)
xset_gc <- groupChromPeaks(xset_obi, param = pdp)
save(list=c("xset_gc"), file = paste0(output_dir,"/xcms2_gc.RData"))

# Fill peaks
fillParam <- FillChromPeaksParam(expandMz = 0, expandRt = 0, ppm = 0)
xset_fp <- fillChromPeaks(xset_gc,fillParam)

# Save final product
processedData <- xset_fp
save(list=c("processedData"), file = paste0(output_dir,"/xcms2_final.RData"))

# Output all peaks and save
allPeaks <- chromPeaks(xset_fp)
write.csv(allPeaks, file = paste0(output_dir,"/BATSuntarg_",ionMode,"_aligned.csv"))

# Output features and save
featuresDef <- featureDefinitions(processedData)
featuresIntensities <- featureValues(processedData, value = "into")
dataTable <- merge(featuresDef, featuresIntensities, by = 0, all = TRUE)
dataTable <- dataTable[, !(colnames(dataTable) %in% c("peakidx"))]
write.csv(dataTable, file = paste0(output_dir,"/BATSuntarg_",ionMode,"_picked.csv"))
