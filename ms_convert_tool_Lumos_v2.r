################ ms convert tool #############
#use this to have an r script to convert the RAW files into whatever format I want
# Krista Longnecker, Woods Hole Oceanographic Institution
# KL 3/27/2014 from code online
# KL 2/22/2018 modify for use with UPLC Lumos data...the <vendor> peak picker will do better than msConvert's peak picker
# KL 3/21/2018 corrected syntax for use with the 'vendor' peak picker

here<- getwd()
 
#update this path to the location of your RAW data files
folders <- c("Z:/_InstrumentData/yourDataHere/RAWfiles")

#note that for this to work, msconvert must be in a folder that has no spaces in the file name
#check that this path is where you have installed msconvert
msconvert <- c("C:/pwiz/msconvert.exe")

for (ii in 1:length(folders)) {
    
setwd(folders[ii])
FILES <- list.files(recursive=FALSE, full.names=TRUE, pattern="*raw")

#Notes on the 'filters' in msconvert:
#this filter must be first; this is the peak picking (convert to centroid):--filter \"peakPicking true 1-\"
#this filter will only keep peaks > 1000 (absolute intensity) --filter \"threshold absolute 1000 most-intense\"
  
  for (i in 1:length(FILES)) {
    #Use threshold with Lumos to help keep file sizes reasonable and bc the Lumos files have higher noise 

    #use this for the Lumos...note that in the interest processing ease, this is only the MS1 data
    #system(paste(msconvert, "--mzML --filter \"peakPicking true 1-3 vendor\" --filter \"msLevel 1\" -o ../mzML_Lumos_MS1_updated", FILES[i]))

    #uncopy this next line to get the MSn data   
    system(paste(msconvert, "--mzML --filter \"peakPicking true vendor 1-3\" --filter \"msLevel 1-3\" -o ../mzML_Lumos_withMSn", FILES[i]))
  }
  
  rm(i,FILES)

}
rm(ii)
setwd(here)

#do some housecleaning
rm(here,msconvert)

