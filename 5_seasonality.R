################################################################################
# FILE: 5_seasonality.R
################################################################################
# Responsibilities: seasonality metrics via STL (requires regular sampling)


seasonality_vec <- function(v, freq = 365) {
  out <- c(seasonal_amp = NA_real_, seasonal_varfrac = NA_real_)
  if (all(is.na(v))) return(out)
  ok <- !is.na(v)
  if (sum(ok) < (2 * freq)) return(out)
  v_filled <- gap_fill_vec(v, times = seq_along(v), freq = freq)
  tsobj <- ts(v_filled, frequency = freq)
  stl_res <- tryCatch(stl(tsobj, s.window = "periodic", robust = TRUE), error = function(e) NULL)
  if (is.null(stl_res)) return(out)
  seasonal <- stl_res$time.series[, "seasonal"]
  out["seasonal_amp"] <- max(seasonal, na.rm = TRUE) - min(seasonal, na.rm = TRUE)
  total_var <- var(v_filled, na.rm = TRUE)
  seasonal_var <- var(seasonal, na.rm = TRUE)
  out["seasonal_varfrac"] <- ifelse(total_var > 0, seasonal_var / total_var, NA_real_)
  return(out)
}


seasonality_maps_app <- function(r, freq = 365, cores = 1, outfile = NULL) {
  fun <- function(v) as.numeric(seasonality_vec(v, freq = freq))
  if (!is.null(outfile)) {
    out <- app(r, fun = fun, cores = cores, filename = outfile, overwrite = TRUE)
  } else {
    out <- app(r, fun = fun, cores = cores)
  }
  names(out) <- c("seasonal_amp", "seasonal_varfrac")
  return(out)
}