suppressMessages(library(xcms))

setwd("~/UntargCode/output_dir/xcms2")
#this fails, but I cannot figure out why
#input_dir <- paste0(args[1])
#setwd(input_dir)

# polarity mode
mode <- "pos"
#this also fails
#mode <- paste0(args[2])

# Load the MS OnDisk object combined in previous script
load(file=paste0("xcms2_final-",mode,".RData"))

# This function retrieve a xset like object and fixes the error of sample class naming, @author Gildas Le Corguille lecorguille@sb-roscoff.fr
#? Does this help me? KL
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
#I think I need this too (KL 1/17/2022)
sampclass(xset) <- xset@phenoData$subset.name

# Use fill peaks 
xset <- fillPeaks(xset, method = "chrom")
dim(xset@groups)

# Save
saveRDS(xset, file=paste0(mode,"_xset.rds"))
