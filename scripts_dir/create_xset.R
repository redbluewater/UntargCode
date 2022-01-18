args = commandArgs(trailingOnly=TRUE) #need this to use slurm(so it seems)  
suppressMessages(library(xcms))

#work_dir <- paste0(args[1])
#setwd(work_dir)
setwd("~/UntargCode/output_dir/xcms2")


# polarity mode
ionMode <- paste0(args[2])

# Load the MS OnDisk object combined in previous script
load(file=paste0("xcms2_final-",ionMode,".RData"))

# This function retrieve a xset like object and fixes the error of sample class naming, @author Gildas Le Corguille lecorguille@sb-roscoff.fr
#? Does this help me? I think the code inserted at line 35 (from me) does the same thing
getxcmsSetObject <- function(xobject) {
    # XCMS 1.x
    if (class(xobject) == "xcmsSet")
        return (xobject)
    # XCMS 3.x
    if (class(xobject) == "XCMSnExp") {
        # Get the legacy xcmsSet object
        suppressWarnings(xset <- as(xobject, 'xcmsSet'))
        if (is.null(xset@phenoData$subset.name)) #KL change, Erin had xset@phenoData$sample_group ...which doesn't exist
            sampclass(xset) = "."
        else
            sampclass(xset) <- xset@phenoData$subset.name
        return (xset)
    }
}

# Create the xcmsSet object
#xset <- getxcmsSetObject(processedData) ? this will complain about MS2 data, not sure how Erin got it to work
suppressWarnings(xset <- as(filterMsLevel(processedData, msLevel = 1L), "xcmsSet"))

#xset <- as(filterMsLevel(processedData, msLevel = 1L), "xcmsSet") #from KL code

#I need this too (KL 1/17/2022), that's the warning I just suppressed
sampclass(xset) <- xset@phenoData$subset.name

# Use fill peaks 
xset <- fillPeaks(xset, method = "chrom")
dim(xset@groups)

print("just before save")
# Save
file.create(paste0(ionMode,"testing.csv"))
saveRDS(xset, file=paste0(ionMode,"_xset.rds"))

print("just after save")
