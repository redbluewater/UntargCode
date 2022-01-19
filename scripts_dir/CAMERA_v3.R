args = commandArgs(trailingOnly=TRUE) 
suppressMessages(library(xcms))
suppressMessages(library(CAMERA))
#will need some code from Johannes Rainer to make the export to GNPS work
source("https://raw.githubusercontent.com/jorainer/xcms-gnps-tools/master/customFunctions.R")

wDir <- paste0(args[1])
setwd(wDir)

# Ion Mode
modes <- c("pos","neg")

# Repeat first parts of CAMERA separately for ion modes
for (i in 1:2){
	mode <- modes[i]
# Load the MS OnDisk object combined in previous script
	load(file=paste0("xcms2_final-",mode,".RData"))
# Load the xcmsSet object created for MetaClean
	xset <- readRDS(paste0(mode,"_xset.rds"))

# Create idx for just samples. Create annotate object. Note could use sample = NA which allows CAMERA to choose reresentative sample for each pseudospectra. Might save time?
idx <- grep("AE2114 Sarg pool |MQ Blank", processedData@phenoData@data$Sample.Name, invert = T)
nSamples <- length(idx)
xsa<-xsAnnotate(xset,sample=idx)

# Group the features initially just by retention time. I have made the window more stringent which results in more pseudospectra.
xsaF <-groupFWHM(xsa, perfwhm = 0.5)

# Figure out which features also have a matching 13C feature. Have to enter both the relative error (ppm) and the absolute error (mzabs).
xsaFI <-findIsotopes(xsaF,ppm=3,mzabs = 0.01,minfrac = 1/nSamples,intval = "into")

# Now group by the correlations based on (1) intensity, (2) EIC, (3) isotopes. I also made the correlation value slightly more stringent.
xsaC <-groupCorr(xsaFI,cor_eic_th=0.9,cor_exp_th=0.8,pval=0.05, graphMethod="hcs", calcIso = TRUE, calcCiS = TRUE, calcCaS = TRUE)

# Setup the file to also look for adducts, only primary adducts
file <-system.file(paste0("rules/primary_adducts_",mode,".csv"),package = "CAMERA")
rules <-read.csv(file)
if (mode == "neg"){
an <-findAdducts(xsaC,polarity = "negative",rules=rules,ppm=3)}
if (mode == "pos"){
an <-findAdducts(xsaC,polarity = "positive",rules=rules,ppm=3)}

# Save final product for combining modes
if (mode == "neg"){
xsa.neg <- an}
if (mode == "pos"){
xsa.pos <- an}
	
##put in pieces to export pieces needed for GNPS/IIN (adding in 1/19/2022)
#```{r getEdgeList, eval=TRUE}
edgelist <- getEdgelist(xsaFA)
edgelist[1:8, ]

#```{r eval = TRUE, message = FALSE}
camera_feature_ann <- getFeatureAnnotations(an)
dataTable <- cbind(dataTable, camera_feature_ann)

edgelist_sub <- edgelist[edgelist$Annotation != "", ]

write.csv(edgelist_sub, file = paste0("edgelist_",ionMode,".csv"), row.names = FALSE,
          quote = FALSE, na = "")
write.table(dataTable, file = paste0("fName_featureQuant_afterCAMERA_",ionMode,".txt"),
            row.names = FALSE, quote = FALSE, sep = "\t", na = "")
            
            
# Save csv of peakTable and clean up
#write.csv(file=paste0("camera_",mode,".csv"),getPeaklist(an))
rm(xset, xsa, xsaF, xsaFI, xsaC, an, processedData)
}


##from here on out, need both pos and neg mode data together
# Search for pseudospectra from the positive and the negative sample within specified retention time window. For every result the m/z differences between both samples are matched against rules, for pos and neg ion. If two ions match, the ion annotations are changed (previous annotation is wrong), confirmed or added. Returns the peaklist from one ion mode with recalculated annotations so I repeat to be able to jump between modes.

xsa.pos_all <- combinexsAnnos(xsa.pos, xsa.neg, pos=TRUE, tol=2, ruleset=NULL)
xsa.neg_all <- combinexsAnnos(xsa.pos, xsa.neg, pos=FALSE, tol=2, ruleset=NULL)

# Save final product
write.csv(file="camera_pos.csv", xsa.pos_all)
write.csv(file="camera_neg.csv", xsa.neg_all)
saveRDS(c(xsa.pos,xsa.neg), file = "camera_results.rds")           
