#KL updated 1/11/2022 to work with SargPatch samples
#KL updated 9/20/2024 to work with interlab samples
args = commandArgs(trailingOnly=TRUE)
suppressMessages(library(xcms))
suppressMessages(library(BiocParallel))
suppressMessages(library(gtools))
#will need some code from Johannes Rainer to make the export to GNPS work
source("https://raw.githubusercontent.com/jorainer/xcms-gnps-tools/master/customFunctions.R")

date()

# Input dir
input_dir <- paste0(args[1])

# Output dir
output_dir<- paste0(args[2])

# Ion Mode
ionMode<- paste0(args[3])

# Biocparallel setting
register(BPPARAM = MulticoreParam(workers=36))

# Load params
params <- read.csv("params.csv", row.names = 1)
bw <- params['bw',ionMode]
bsize <- params['bsize',ionMode]

# Load the MS OnDisk object combined in previous script
load(file=paste0(input_dir,"/xset-",ionMode,".RData"))

# Add variable for subsetting (KL note - generic beginning to sample names)
idx<-which(xset@phenoData$Sample.Name ==  paste0("M"))
xset@phenoData$subset.name <- "other"
xset@phenoData$subset.name[idx] <- "marine"

# RT correction; update bin size (later note, 7/2024 setting binSize too small here may cause code to crash)
#bsize is a new addition from Erin McParland and Yuting Zhu 12/2022
prm <- ObiwarpParam(subset= which(xset@phenoData$subset.name == "pool"), subsetAdjust="average", binSize = bsize,distFun = "cor", gapInit = 0.3, gapExtend = 2.4)
xset_obi <- adjustRtime(xset, param = prm, msLevel = 1L)

save(list=c("xset_obi"), file = paste0(output_dir,"/xcms2_obi-",ionMode,".RData"))
rm(xset)
print("Completed xcms obiwarp")

# Add variable for grouping(subsetting)
idx<-which(xset_obi@phenoData$Sample.Name ==  paste0("M"))
xset_obi@phenoData$subset.name <- "other"
xset_obi@phenoData$subset.name[idx] <- "marine"

# Grouping (KL note - generic beginning to sample names)
pdp<-PeakDensityParam(sampleGroups = xset_obi@phenoData$subset.name, minFraction = 0.1, minSamples = 1, bw = bw, binSize = bsize)
xset_gc<-groupChromPeaks(xset_obi, param = pdp)
rm(xset_obi)
save(list=c("xset_gc"), file = paste0(output_dir,"/xcms2_gc-",ionMode,".RData"))
print("Completed xcms grouping")

# Fillpeaks
fillParam<-FillChromPeaksParam(expandMz = 0, expandRt = 0, ppm = 25)
xset_fp<-fillChromPeaks(xset_gc,fillParam)
rm(xset_gc)

# Save final product
processedData<-xset_fp
rm(xset_fp)
save(list=c("processedData"), file = paste0(output_dir,"/xcms2_final-",ionMode,".RData"))

# Output all peaks and save
allPeaks<-chromPeaks(processedData)
write.csv(allPeaks, file = paste0(output_dir,"/interlab_untarg_",ionMode,"_picked.csv"))

# Output features and save
featuresDef<-featureDefinitions(processedData)
featuresIntensities<-featureValues(processedData, value = "into", method = "maxint")
dataTable<-merge(featuresDef, featuresIntensities, by = 0, all = TRUE)
dataTable <-dataTable[, !(colnames(dataTable) %in% c("peakidx"))]
write.csv(dataTable, file = paste0(output_dir,"/interlab_untarg_",ionMode,"_aligned.csv"))


#start exporting files for GNPS (adding in 1/19/2022). Messy because I am
#retaining names from desktop computer version of this code

#```{r mgf_forGNPS}
## export the individual spectra into a .mgf file
filteredMs2Spectra <- featureSpectra(processedData, return.type = "MSpectra") #update 4/20/2021
filteredMs2Spectra <- clean(filteredMs2Spectra, all = TRUE)

#this next line uses Johannes' code to make the MS2 into a format that can be written as an mgf file and imported into GNPS for Feature Based Molecular Networking (FBMN), handy!
filteredMs2Spectra <- formatSpectraForGNPS(filteredMs2Spectra)

fName_MS2file_all = paste0(output_dir,"/ms2spectra_all_",ionMode,".mgf")
if (file.exists(fName_MS2file_all)) {
  file.rename(fName_MS2file_all,'ms2spectra_all_OLD.mgf')
}
writeMgfData(filteredMs2Spectra, fName_MS2file_all)

#```{r peakQuantTable_forGNPS}
## get data
featuresDef <- featureDefinitions(processedData)
featuresIntensities <- featureValues(processedData, value = "into")

## generate data table
dataTable <- merge(featuresDef, featuresIntensities, by = 0, all = TRUE)
dataTable <- dataTable[, !(colnames(dataTable) %in% c("peakidx"))]

#head(dataTable)
write.table(dataTable, paste0(output_dir,"/fName_featureQuant_all_",ionMode,".txt"), sep = "\t", quote = FALSE, row.names = FALSE)

#```{r combineMS2_one, eval = TRUE}
##setup which method to use:
howToCombineMS2 = 'maxTIC' 
#howToCombineMS2 = 'consensus' 
switch(howToCombineMS2, 
       maxTIC = {
         ## Select for each feature the Spectrum2 with the largest TIC.
        combinedMs2Spectra <- combineSpectra(filteredMs2Spectra,
                                            fcol = "feature_id",
                                            method = maxTic)},         
       consensus = {
         combinedMs2Spectra <- combineSpectra(filteredMs2Spectra, 
                                             fcol = "feature_id", 
                                             method = consensusSpectrum, 
                                             mzd = 0, 
                                             minProp = 0.1, 
                                             ppm = 10)}
       )


#``` {r exportMS2, eval = TRUE}
#Next we export the data to an mgf file (could be submitted to GNPS).
fName_MS2file_combined <- paste0(output_dir,"/ms2spectra_combined_",ionMode,".mgf")

if (file.exists(fName_MS2file_combined)) {
  file.rename(fName_MS2file_combined,'ms2spectra_combined_OLD.mgf')
}
writeMgfData(combinedMs2Spectra, fName_MS2file_combined)

## filter data table to contain only peaks with MSMS DF[ , !(names(DF) %in% drops)]
consensusDataTable <- dataTable[which(dataTable$Row.names %in%
                                      combinedMs2Spectra@elementMetadata$feature_id),]

write.table(consensusDataTable, paste0(output_dir,"/fName_featureQuant_combined_",ionMode,".txt"),
            sep = "\t", quote = FALSE, row.names = FALSE)

#put another save here, I need dataTable later on to export GNPS files after CAMERA
save(list=c("processedData","dataTable"), file = paste0(output_dir,"/xcms2_KLtesting-",ionMode,".RData"))

