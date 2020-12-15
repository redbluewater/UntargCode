
suppressMessages(library(xcms))
suppressMessages(library(MetaClean))

# polarity mode
mode <- "pos"

# Load the MS OnDisk object combined in previous script
load(file=paste0("xcms2_final-",mode,".RData"))

# Load the xcmsSet object that you converted previously
xset <- readRDS(paste0(mode,"_xset.rds"))

## Create the development dataset for creating the global classifier. I use the pool samples to peak check.
# Create xcmsEIC object with ~2000 EIC's 
# feature index
if (mode == "neg"){
gidx <- seq(from = 1, to = 15990, by = 8)}
if (mode == "pos"){
gidx <- seq(from = 1, to = 11820, by = 6)}
# sample index
sidx <- which(pData(processedData)$subset.name == "pool")
xset_eic_devel <- getEIC(xset, groupidx = gidx, sampleidx = sidx, rt = "corrected", rtrange = 15)

# Print a pdf and csv file with your 2000 EIC to classify offline. If you have already classified and filled in the csv with GOOD/BAD classification then set this to False and just load your labels.
if(FALSE){
# Plot EIC's for classifying
cairo_pdf(file = paste0(mode,"_EIC_devel.pdf"), onefile = TRUE)
for (i in 1:length(xset_eic_devel@groupnames)){
  plot(xset_eic_devel, xset, groupidx = i, col = "blue")
}
dev.off()

# Create a csv for EIC labels for development dataset.
eic_labels_devel <- data.frame(gidx)
colnames(eic_labels_devel) <- "EICNo"
write.csv(eic_labels_devel, file = paste0(mode,"_eic_labels_devel.csv"), quote = F)
} else {
	eic_labels_devel <- read.csv(paste0(mode,"_eic_labels_devel.csv"))
}

## Create the test dataset for checking how well the global classifier worked.
# Create xcmsEIC object with 1000 EIC's 
gidx <- seq(from = 10, to = 15075, by = 16)
gidx <- seq(from = 10, to = 11820, by = 12)
sidx <- which(pData(processedData)$subset.name == "pool")
xset_eic_test <- getEIC(xset, groupidx = gidx, sampleidx = sidx, rt = "corrected", rtrange = 15)
# Print a pdf and csv file with your EIC to classify offline. If you have already classified and filled in the csv with GOOD/BAD classification then set this to False and just load your labels.
if(FALSE){
# Plot EIC's for classifying
cairo_pdf(file = paste0(mode,"_EIC_test.pdf"),onefile=TRUE)
for (i in 1:length(xset_eic_test@groupnames)){
  plot(xset_eic_test, xset, groupidx = i, col = "blue")
}
dev.off()

# Create EIC labels
eic_labels_test <- data.frame(gidx)
colnames(eic_labels_test) <- "EICNo"
write.csv(eic_labels_test, file = paste0(mode,"_eic_labels_test.csv"), quote = F)
} else{
	eic_labels_test <- read.csv(paste0(mode,"_eic_labels_test.csv"))
}

## Use the development dataset to create global classifier.
# Get eval object
eicEval_development <- getEvalObj(xs = xset_eic_devel, fill = xset)

# Calculate peak quality metrics for development dataset
pqm_development <- getPeakQualityMetrics(eicEvalData = eicEval_development, eicLabels_df = eic_labels_devel)

# Train potential classifiers. Note: M11 (default) is a union of the M4 and M7 metrics. Will create 10 (k) even subsets for the crossvalidation and perform the CV 10 (repNum) times.
models <- runCrossValidation(trainData = pqm_development, k=10, repNum=10, rand.seed = 453, models = c("DecisionTree", "AdaBoost"), metricSet = "M11")

# Calculate evaluation measures
evalMeasuresDF <- getEvaluationMeasures(models=models, k=10, repNum=10)

evalMeasuresDF %>%
	group_by(Model) %>%
	summarise_all(mean)

# Compare classifiers and select best performing
barPlots <- getBarPlots(evalMeasuresDF, emNames = "All")
cairo_pdf(file = paste0(mode,"_barplots.pdf",onefile=TRUE)
plot(barPlots$M11$Pass_FScore) # Pass_FScore
plot(barPlots$M11$Fail_FScore) # Fail_FScore
plot(barPlots$M11$Accuracy) # Accuracy
dev.off()

## Train final classifier
# Identify the best performing model, here it is AdaBoost M11 as it was in the original publication. Hyperparameters here are nIter = 150 and method = "Adaboost.M1"

# There's a weird NA error associated with the caret package (I think). Even though I have no missing values, this package's function throws an error saying I do. I break down the wrapper function below so I can include na.action = na.exclude to the model train function to avoid this.
hyperparameters <- models$AdaBoost_M11$pred[,c("nIter", "method")]
hyperparameters <- unique(hyperparameters)
metricSet = "M11"
if (metricSet == "M11") {
        mCols <- c("ApexBoundaryRatio_mean", "ElutionShift_mean", 
            "FWHM2Base_mean", "Jaggedness_mean", "Modality_mean", 
            "RetentionTimeCorrelation_mean", "Symmetry_mean", 
            "GaussianSimilarity_mean", "Sharpness_mean", "TPASR_mean", 
            "ZigZag_mean")}
trainData <- pqm_development[, c(mCols, "Class")]
trControl <- trainControl(method = "none", savePredictions = "final", classProbs = TRUE)
mc_model <- train(Class ~ ., trainData, method = "adaboost", trControl = trControl, tuneGrid = hyperparameters, na.action = na.exclude)

# Save model
saveRDS(mc_model, file = paste0(mode,"_mcmodel.rds"))


## Make predictions for test set to check performance.
eicEval_test <- getEvalObj(xs = xset_eic_test, fill = xset)
pqm_test <- getPeakQualityMetrics(eicEvalData = eicEval_test)
mc_predictions <- getPredicitons(model = mc_model, testData = pqm_test, eicColumn = "EICNo")
calculateEvaluationMeasures(pred = mc_predictions$Pred_Class, true = as.factor(eic_labels_test$Label))

## Make predictions for all peaks
# Create xcmsEIC object for all EIC's 
gidx <- 1:length(xset@groupidx)
sidx <- which(pData(processedData)$subset.name == "pool")
xset_eic_all <- getEIC(xset, groupidx = gidx, sampleidx = sidx, rt = "corrected", rtrange = 15)

# Create eval object
eicEval_all <- getEvalObj(xs = xset_eic_all, fill = xset)

# Calculate peak quality metrics for development and test dataset
pqm_all <- getPeakQualityMetrics(eicEvalData = eicEval_all)

# Make predictions. Again the function as is throws an issue with NA's. In this case I did have NA's for 43 peaks, particularly for the metric TPASR_mean but also others. Here I break down the wrapper function and add an index for the NA's
model = mc_model
testData = pqm_all
eicColumn = "EICNo"

eic_nums <- testData[,eicColumn]
testData <- testData[,colnames(testData) != eicColumn]
idx <- apply(testData, 1, function(x) any(is.na(x)==T))
no.na <- which(idx == FALSE)
yes.na <- which(idx == TRUE)
testData <- testData[no.na,]

predictions_prob <- stats::predict(model, testData, type="prob")
colnames(predictions_prob) <- c("Pred_Prob_Fail", "Pred_Prob_Pass")
predictions_prob <- predictions_prob[,c(2,1)]
predictions_class <- stats::predict(model, testData)

model_predictions <- cbind("EIC"=eic_nums[no.na], "Pred_Class"=predictions_class, predictions_prob)
no_predictions <- data.frame(yes.na, rep(NA,length(yes.na)), rep(NA,length(yes.na)), rep(NA,length(yes.na)))
colnames(no_predictions) <- colnames(model_predictions)
model_predictions <- rbind(model_predictions,no_predictions)

write.csv(model_predictions, file = paste0(mode,"_metaclean_results.csv"))
