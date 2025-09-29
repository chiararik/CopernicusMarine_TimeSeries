################################################################################
# FILE: 7_utils.R
################################################################################
# Small helpers


#' safe_run: wrap a function with tryCatch and informative message
safe_run <- function(expr, msg = NULL) {
  tryCatch({
    eval(expr)
  }, error = function(e) {
    warning(if (!is.null(msg)) paste0(msg, ": ", e$message) else e$message)
    return(NULL)
  })
}


################################################################################
# USAGE example (save as run_example.R or call from console):
# source("1_io.R"); source("2_qc.R"); source("3_gapfill.R"); source("4_trend.R"); source("5_seasonality.R"); source("6_pipeline.R"); source("7_utils.R")
# res <- run_pipeline(
# input_folder = "E:/Adriatico/Lesina/input",
# output_folder = "E:/Adriatico/Lesina/output",
# filename = "SST_MED_SST_L4_NRT_OBSERVATIONS_010_004_c_V2_multi-vars_14.41E-16.29E_41.54N-42.30N_2020-01-01-2025-06-30.nc",
# varname = NULL, # leave NULL for auto-detection
# cores = 4,
# freq = 365
# )


# End of modular files