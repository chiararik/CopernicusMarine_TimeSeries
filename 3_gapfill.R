################################################################################
# FILE: 3_gapfill.R
################################################################################
# Responsibilities: gap-filling strategies (linear, loess, seasonal if needed)
library(zoo)


#' gap_fill_vec: linear approx + loess fallback + locf ends
gap_fill_vec <- function(v, times = NULL, freq = 365) {
  if (all(is.na(v))) return(v)
  n <- length(v)
  if (is.null(times)) times <- seq_len(n)
  v_f <- tryCatch(approx(x = times[!is.na(v)], y = v[!is.na(v)], xout = times, rule = 2)$y,
                  error = function(e) rep(NA_real_, n))
  if (any(is.na(v_f))) {
    ok <- !is.na(v)
    if (sum(ok) >= 5) {
      dfx <- data.frame(t = times[ok], y = v[ok])
      span <- min(0.5, max(0.1, 10 / sum(ok)))
      lo <- tryCatch(loess(y ~ t, data = dfx, span = span), error = function(e) NULL)
      if (!is.null(lo)) {
        pred <- tryCatch(predict(lo, newdata = data.frame(t = times)), error = function(e) rep(NA_real_, n))
        nas <- is.na(v_f)
        v_f[nas & !is.na(pred)] <- pred[nas & !is.na(pred)]
      }
    }
    v_f <- na.locf(v_f, na.rm = FALSE)
    v_f <- na.locf(v_f, fromLast = TRUE, na.rm = FALSE)
  }
  return(v_f)
}


#' gap_fill_app: apply to raster
gap_fill_app <- function(r, freq = 365, cores = 1, outfile = NULL) {
  fun <- function(v) gap_fill_vec(v, times = seq_along(v), freq = freq)
  if (!is.null(outfile)) {
    out <- app(r, fun = fun, cores = cores, filename = outfile, overwrite = TRUE)
  } else {
    out <- app(r, fun = fun, cores = cores)
  }
  return(out)
}