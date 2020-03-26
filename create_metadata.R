usePath <- "/vortexfs1/omics/kujawinski/data/biosscope_untarg"
ext <- ".mzML"
pre <- paste0(usePath,"/")
mzdatafiles <- list.files(usePath,recursive = FALSE, full.names=TRUE, pattern=ext)
wDir <-  "/vortexfs1/home/emcparland/untarg_xcms"
csvfile <- list.files(usePath,recursive=FALSE,full.name=TRUE,pattern=".csv")
all<-read.csv(csvfile,skip=1,header=TRUE)
putDataHere <-data.frame()

#what data do I want to keep...put that here
keep = "pos.1"

for(i in 1:length(all$File.Name)) {
  h <- all$File.Name[i] 
  h <-paste0(pre,h,ext)
  
  # pull tData now, so I can look for a match with the 'keep' variable I set at line 63
  tData <- all[i,]
  test = paste0(tData$ionMode,".",tData$goodData)
  
  # only proceed if test == keep
  tm = match(test,keep)
  if (!is.na(tm)) {

  # this will pick up the right row in mzdatafiles
    m <- match(basename(h),basename(mzdatafiles))
    if (!is.na(m)) {
      if (nrow(putDataHere)==0) {
        putDataHere <- tData
        putDataHere$FileWithExtension <- basename(h)
        } else {
          useIdx = nrow(putDataHere)+1
          putDataHere[useIdx,] <-tData
          putDataHere$FileWithExtension[useIdx] <- basename(h)
          rm(useIdx)
        }
    }
    rm(m)
  } #this ends the final if statement
    rm(h,test,tData,tm) 
}
rm(all)
write.table(putDataHere,"metadata.txt",append = FALSE, sep = "\t",row.names = FALSE,col.names=TRUE,quote=FALSE)