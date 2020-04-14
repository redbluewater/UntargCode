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
load("autotuneparams.RData")

load(file=paste0(input_dir,"/xset-",ionMode,".RData"))

# RT correction
xset_obi <- adjustRtime(xset, param = ObiwarpParam(binSize = 0.1,distFun = "cor", gapInit = 0.3, gapExtend = 2.4), msLevel = 1L)
rm(xset)
save(list=c("xset_obi"), file = paste0(output_dir,"/xcms2_obi-",ionMode,".RData"))
print("Completed xcms obiwarp")

# Grouping
pdp<-PeakDensityParam(sampleGroups = rep(1, length(fileNames(xset_obi))), minFraction = 0.1, minSamples = 1, bw = groupDiff)
xset_gc<-groupChromPeaks(xset_obi, param = pdp)
rm(xset_obi)
save(list=c("xset_gc"), file = paste0(output_dir,"/xcms2_gc-",ionMode,".RData"))
print("Completed xcms grouping")

# Fillpeaks
fillParam<-FillChromPeaksParam(expandMz = 0, expandRt = 0, ppm = 0)
xset_fp<-fillChromPeaks(xset_gc,fillParam)
rm(xset_gc)

# Save final product
processedData<-xset_fp
rm(xset_fp)
save(list=c("processedData"), file = paste0(output_dir,"/xcms2_final-",ionMode,".RData"))

# Output all peaks and save
allPeaks<-chromPeaks(processedData)
write.csv(allPeaks, file = paste0(output_dir,"/BATSuntarg_",ionMode,"_aligned.csv"))

# Output features and save
featuresDef<-featureDefinitions(processedData)
featuresIntensities<-featureValues(processedData, value = "into")
dataTable<-merge(featuresDef, featuresIntensities, by = 0, all = TRUE)
dataTable <-dataTable[, !(colnames(dataTable) %in% c("peakidx"))]
write.csv(dataTable, file = paste0(output_dir,"/BATSuntarg_",ionMode,"_picked.csv"))
