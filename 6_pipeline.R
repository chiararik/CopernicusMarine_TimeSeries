################################################################################
# FILE: 6_pipeline.R
################################################################################
# Responsibilities: orchestrate the modules into a pipeline
library(terra)
library(parallel)


#' run_pipeline: top-level function
#' @param input_folder folder containing input NetCDF/raster
#' @param output_folder folder to save outputs
#' @param filename name of the NetCDF/raster inside input_folder
#' @param varname variable name inside NetCDF (if NULL, auto-detect)
#' @param cores number of cores to use
#' @param freq seasonality frequency (e.g., 365 for daily)
run_pipeline <- function(input_folder, output_folder, filename, varname = NULL, cores = NULL, freq = 365) {
  if (is.null(cores)) cores <- max(1, parallel::detectCores() - 1)
  dir.create(output_folder, showWarnings = FALSE, recursive = TRUE)
  
  
  nc_path <- file.path(input_folder, filename)
  
  
  message("Loading stack...")
  r <- load_stack(nc_path, varname = varname)
  inspect_stack(r)
  
  
  cleaned_path <- file.path(output_folder, "cleaned_stack.tif")
  cleaned <- remove_outliers_app(r, z_thr = 3, mad_mul = 3, cores = cores, outfile = cleaned_path)
  
  
  filled_path <- file.path(output_folder, "gapfilled_stack.tif")
  filled <- gap_fill_app(cleaned, freq = freq, cores = cores, outfile = filled_path)
  
  
  trend_path <- file.path(output_folder, "trend_maps.tif")
  trend_r <- trend_maps_app(filled, cores = cores, outfile = trend_path)
  
  
  seasonal_path <- file.path(output_folder, "seasonality_maps.tif")
  season_r <- seasonality_maps_app(filled, freq = freq, cores = cores, outfile = seasonal_path)
  
  
  combined <- c(trend_r, season_r)
  combined_path <- file.path(output_folder, "trend_seasonality.tif")
  writeRaster(combined, filename = combined_path, overwrite = TRUE)
  
  
  message("Pipeline finished. Outputs written to: ", output_folder)
  return(list(cleaned = cleaned_path, filled = filled_path, trend = trend_path, seasonality = seasonal_path, combined = combined_path))
}

source("1_io.R")
source("2_qc.R")
source("3_gapfill.R")
source("4_trend.R")
source("5_seasonality.R")
source("6_pipeline.R")
source("7_utils.R")


input_folder <- file.path("E:/Adriatico/Lesina/input")
output_folder <- file.path("E:/Adriatico/Lesina/output")
filename <- "cmems_obs_oc_med_bgc_tur-spm-chl_nrt_l4-hr-mosaic_P1D-m_CHL-SPM-TUR_14.41E-16.29E_41.53N-42.30N_2020-01-01-2025-06-30.nc"
cores <- detectCores()-2

res <- run_pipeline(
  input_folder  = input_folder,
  output_folder = output_folder,
  filename      = filename,
  varname       = NULL,  # or "chl" / "tur" / "spm" if you know which variable you want
  cores         = cores,
  freq          = 365
)
