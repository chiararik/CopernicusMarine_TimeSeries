################################################################################
# FILE: 4_trend.R
################################################################################
# Responsibilities: trend calculation per-pixel (Mann-Kendall, Sen's slope, zyp)
library(Kendall)
library(trend)
if (!requireNamespace("zyp", quietly = TRUE)) install.packages("zyp")
library(zyp)


trend_analysis_vec <- function(v, times = NULL) {
  out <- c(sen_slope = NA_real_, mk_tau = NA_real_, mk_p = NA_real_, zyp_slope = NA_real_)
  if (all(is.na(v))) return(out)
  ok <- !is.na(v)
  if (sum(ok) < 5) return(out)
  y <- v[ok]
  mm <- tryCatch(MannKendall(y), error = function(e) NULL)
  if (!is.null(mm)) {
    out["mk_tau"] <- mm$tau
    out["mk_p"] <- mm$sl
  }
  ss <- tryCatch(sens.slope(y), error = function(e) NULL)
  if (!is.null(ss)) out["sen_slope"] <- ss$estimates[[1]]
  zres <- tryCatch({ zyp::zyp.trend.vector(v, method = "yuepilon")$trend }, error = function(e) NA_real_)
  out["zyp_slope"] <- ifelse(length(zres) == 0, NA_real_, as.numeric(zres))
  return(out)
}


trend_maps_app <- function(r, cores = 1, outfile = NULL) {
  fun <- function(v) as.numeric(trend_analysis_vec(v, times = seq_along(v)))
  if (!is.null(outfile)) {
    out <- app(r, fun = fun, cores = cores, filename = outfile, overwrite = TRUE)
  } else {
    out <- app(r, fun = fun, cores = cores)
  }
  names(out) <- c("sen_slope", "mk_tau", "mk_p", "zyp_slope")
  return(out)
}