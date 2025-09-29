# Modular pixel-wise time-series workflow (multiple files concatenated)
# Save each section into its own file as indicated by the header comments.

################################################################################
# FILE: 1_io.R
################################################################################
# Responsibilities: read NetCDF/rasters, write outputs, helper to extract time vector
library(terra)


#' load_stack: load a variable from NetCDF (or multi-layer raster)
#' @param nc_path character path to NetCDF
#' @param varname character variable name inside NetCDF; if NULL, try to auto-detect
#' @return SpatRaster with z (time) set when available
load_stack <- function(nc_path, varname = NULL) {
  if (!file.exists(nc_path)) stop("Input file does not exist: ", nc_path)
  r <- NULL
  if (is.null(varname)) {
    sds <- tryCatch(terra::sds(nc_path), error = function(e) NULL)
    if (!is.null(sds) && length(sds) > 0) {
      r <- rast(sds[[1]])
      message("Auto-detected variable: ", names(r)[1])
    } else {
      r <- rast(nc_path)
    }
  } else {
    r <- tryCatch(rast(nc_path, subds = varname), error = function(e) rast(nc_path))
  }
  # try to read time/z values (but don't call setZ to avoid terra version issues)
  tz <- tryCatch(time(r), error = function(e) NULL)
  if (!is.null(tz)) {
    # store time vector as an attribute on the SpatRaster
    attr(r, "time") <- as.numeric(tz)
    message("Read time vector (stored in attr(r, 'time')).")
  } else {
    message("No time vector found in raster (continuing without time).")
  }
  return(r)
}

get_time_vector <- function(r) {
  # 1) check if we stored a time attribute
  tz_attr <- tryCatch(attr(r, "time"), error = function(e) NULL)
  if (!is.null(tz_attr)) return(as.numeric(tz_attr))
  # 2) fallback to terra's zvalues/time if available
  z <- tryCatch(zvalues(r), error = function(e) NULL)
  if (!is.null(z) && length(z) > 0) return(as.numeric(z))
  tz2 <- tryCatch(time(r), error = function(e) NULL)
  if (!is.null(tz2)) return(as.numeric(tz2))
  # 3) final fallback
  return(seq_len(nlyr(r)))
}



#' save_rasters: write SpatRaster to disk (GeoTIFF or NetCDF if requested)
save_rasters <- function(r, outpath, format = c("GTiff", "CDF")) {
  format <- match.arg(format)
  dir.create(dirname(outpath), showWarnings = FALSE, recursive = TRUE)
  if (format == "GTiff") {
    writeRaster(r, filename = outpath, overwrite = TRUE)
  } else {
    tryCatch({
      writeCDF(r, filename = outpath, overwrite = TRUE)
    }, error = function(e) {
      writeRaster(r, filename = file.path(dirname(outpath), paste0(tools::file_path_sans_ext(basename(outpath)), ".tif")), overwrite = TRUE)
    })
  }
}


