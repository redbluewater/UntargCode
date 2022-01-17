#KL note - why is this run using srun and not sbatch? 
suppressMessages(library(xcms))

setwd("~/UntargCode/output_dir/xcms2")

# polarity mode
mode <- "neg"

# Load the MS OnDisk object combined in previous script
load(file=paste0("xcms2_final-",mode,".RData"))

# This function retrieve a xset like object and fixes the error of sample class naming, @author Gildas Le Corguille lecorguille@sb-roscoff.fr
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
xset <- as(filterMsLevel(processedData, msLevel = 1L), "xcmsSet") #from KL code

# Use fill peaks 
xset <- fillPeaks(xset, method = "chrom")
dim(xset@groups)

# Save
saveRDS(xset, file=paste0(mode,"_xset.rds"))
