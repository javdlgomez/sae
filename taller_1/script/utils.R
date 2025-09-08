# abreviar dplyr
select    <- dplyr::select
transmute <- dplyr::transmute
summarise <- dplyr::summarise
mutate    <- dplyr::mutate
arrange   <- dplyr::arrange
filter    <- dplyr::filter
left_join <- dplyr::left_join
count     <- dplyr::count

# solucionar nombres de sae direct
.pick_name <- function(nms, candidates) {
  nm <- intersect(nms, candidates)
  if (length(nm) == 0) stop("No se encontró ninguna de: ", paste(candidates, collapse = ", "))
  nm[[1]]
}

# Extrae betas en matriz, vector o NULL
.extraer_betas_seguro <- function(fit_obj, sx){
  b <- tryCatch(fit_obj$fit$estcoef$beta, error = function(e) NULL)
  v <- tryCatch(fit_obj$fit$estcoef$cov,  error = function(e) NULL)
  
  if (is.null(b)) {
    return(tibble(sexo = sx, termino = character(), beta = numeric(), se = numeric()))
  }
  if (is.matrix(b)) {
    beta_vals <- as.numeric(b[, 1])
    terminos  <- rownames(b)
  } else {
    beta_vals <- as.numeric(b)
    terminos  <- names(b)
  }
  if (is.null(terminos) || length(terminos) != length(beta_vals)) {
    terminos <- paste0("b", seq_along(beta_vals))
  }
  
  se_vals <- if (is.null(v)) {
    rep(NA_real_, length(beta_vals))
  } else {
    d <- tryCatch(diag(as.matrix(v)), error = function(e) rep(NA_real_, length(beta_vals)))
    if (length(d) != length(beta_vals)) d <- rep(NA_real_, length(beta_vals))
    sqrt(pmax(d, 0))
  }
  tibble(sexo = sx, termino = terminos, beta = beta_vals, se = se_vals)
}
