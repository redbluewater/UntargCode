args = commandArgs(trailingOnly=TRUE) #need this to use slurm(so it seems)  
suppressMessages(library(xcms))

#setwd("~/UntargCode/output_dir/xcms2")
work_dir <- paste0(args[1])
setwd(work_dir)

# polarity mode
ionMode <- paste0(args[2])

# Load the MS OnDisk object combined in previous script
load(file=paste0("xcms2_final-",ionMode,".RData"))

# Create the xcmsSet object
#xset <- as(filterMsLevel(processedData, msLevel = 1L), "xcmsSet") #from KL code
#need the tryCatch to get this to run this in slurm
tryCatch(xset <- as(filterMsLevel(processedData, msLevel = 1L), "xcmsSet"))

#I need this too (KL 1/17/2022), that's the warning I just skipped over in the previous line
sampclass(xset) <- xset@phenoData$subset.name

# Use fill peaks 
xset <- fillPeaks(xset, method = "chrom")
dim(xset@groups)

# Save
saveRDS(xset, file=paste0(ionMode,"_xset.rds"))
