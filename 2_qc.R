################################################################################
# FILE: 2_qc.R
################################################################################
# Responsibilities: detect and remove outliers, basic inspection
library(terra)


#' detect_outliers_vec: z-score + MAD hybrid
detect_outliers_vec <- function(v, z_thr = 3, mad_mul = 3) {
  if (all(is.na(v))) return(rep(FALSE, length(v)))
  mu <- mean(v, na.rm = TRUE)
  sdv <- sd(v, na.rm = TRUE)
  zflag <- rep(FALSE, length(v))
  if (!is.na(sdv) && sdv > 0) {
    zflag <- abs((v - mu) / sdv) > z_thr
  }
  medv <- median(v, na.rm = TRUE)
  madv <- mad(v, constant = 1, na.rm = TRUE)
  madflag <- rep(FALSE, length(v))
  if (!is.na(madv) && madv > 0) madflag <- abs(v - medv) > (mad_mul * madv)
  out <- zflag | madflag
  out[is.na(out)] <- FALSE
  return(out)
}


#' remove_outliers_vec: set outliers to NA
remove_outliers_vec <- function(v, z_thr = 3, mad_mul = 3) {
  o <- detect_outliers_vec(v, z_thr = z_thr, mad_mul = mad_mul)
  v[o] <- NA
  return(v)
}


#' remove_outliers_app: terra::app wrapper for rasters
remove_outliers_app <- function(r, z_thr = 3, mad_mul = 3, cores = 1, outfile = NULL) {
  fun <- function(v) remove_outliers_vec(v, z_thr = z_thr, mad_mul = mad_mul)
  if (!is.null(outfile)) {
    out <- app(r, fun = fun, cores = cores, filename = outfile, overwrite = TRUE)
  } else {
    out <- app(r, fun = fun, cores = cores)
  }
  return(out)
}


#' inspect_stack: lightweight inspection (dimensions, CRS, time summary)
inspect_stack <- function(r, sample_cells = 10000) {
  # header
  cat(sprintf("Raster: cols=%d rows=%d layers=%d\n", ncol(r), nrow(r), nlyr(r)))
  # extent (format S4 -> character)
  e <- tryCatch(ext(r), error = function(e) NULL)
  if (!is.null(e)) {
    ex <- c(xmin = xmin(e), xmax = xmax(e), ymin = ymin(e), ymax = ymax(e))
    cat("Extent:", paste(names(ex), round(ex, 6), sep="=", collapse=", "), "\n")
  } else {
    cat("Extent: <unavailable>\n")
  }
  # CRS (format SpatCRS -> character)
  cr <- tryCatch(crs(r), error = function(e) NULL)
  if (!is.null(cr) && !is.na(cr)) {
    cat("CRS:", as.character(cr), "\n")
  } else {
    cat("CRS: NA\n")
  }
  # time / z info
  z <- tryCatch(zvalues(r), error = function(e) NULL)
  if (is.null(z) || length(z) == 0) {
    z <- tryCatch(attr(r, "time"), error = function(e) NULL)
  }
  if (!is.null(z) && length(z) > 0) {
    cat("Time layers:", length(z), " range:", paste(range(z, na.rm=TRUE), collapse=" to "), "\n")
  } else {
    cat("Time layers: not found\n")
  }
  # quick sample summary (robust)
  samp_n <- min(ncell(r), sample_cells)
  s <- tryCatch(sampleRandom(r, size = samp_n, na.rm = TRUE, sp = FALSE), error = function(e) NULL)
  if (!is.null(s)) {
    cat("Sampled pixel summary (first few layers):\n")
    print(summary(as.data.frame(s)[, seq_len(min(5, ncol(s))) ]))
  }
}
