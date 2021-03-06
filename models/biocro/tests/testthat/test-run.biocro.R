context("check that BioCro output is summarized correctly")

# Return precalculated BioCro 0.9 results from specified days in 2004
# Accepts same arguments as BioCro::BioGro, ignores all but day1 and dayn
mock_run <- function(WetDat = NULL, day1 = 1, dayn = 7, ...){
	load("data/result.RData", envir = environment())
	resultDT[resultDT$Year == 2004 & resultDT$DayofYear %in% day1:dayn,]
}

# Hand-calculate reference values
ref_output <- mock_run()
ref_met <- read.csv("data/US-Bo1.2004.csv", nrows=7*24)
ref_leaf1 <- max(ref_output$Leaf[ref_output$DayofYear == 1])
ref_soil5 <- sum(ref_output$SoilEvaporation[ref_output$DayofYear == 5])
ref_mat <- mean(ref_met$Temp)

# run setup
metpath <- "data/US-Bo1"
config <- PEcAn.settings::prepare.settings(PEcAn.settings::read.settings("data/pecan.biocro.xml"))
config$pft$type$genus <- "Salix"
config$run$start.date <- as.POSIXct("2004-01-01")
config$run$end.date <- as.POSIXct("2004-01-07")
config$simulationPeriod$dateofplanting <- as.POSIXct("2004-01-01")
config$simulationPeriod$dateofharvest <- as.POSIXct("2004-01-07")

test_that("daily summarizes hourly (#1738)", {

	# stub out BioCro::willowGro: 
	# calls to willowGro(...) will be replaced with calls to mock_run(...),
	# but *only* when originating inside run.biocro.
	mockery::stub(run.biocro, "BioCro::willowGro", mock_run) 

	mock_result <- run.biocro(lat = 44, lon = -88, metpath, soil.nc = NULL, config = config, coppice.interval = 1)
	expect_equal(nrow(mock_result$hourly), 24*7)
	expect_equal(nrow(mock_result$daily), 7)
	expect_equal(nrow(mock_result$annually), 1)
	expect_gt(length(unique(mock_result$daily$tmax)), 1)
	expect_equal(mock_result$daily$Leaf[mock_result$daily$doy == 1], ref_leaf1)
	expect_equal(mock_result$daily$SoilEvaporation[mock_result$daily$doy == 5], ref_soil5)
	expect_equal(mock_result$annually$mat, ref_mat)
})
