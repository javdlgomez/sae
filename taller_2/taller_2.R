############################################################
# Taller 2
# EBP 
############################################################

rm(list = ls())
set.seed(1234)

suppressPackageStartupMessages({
  library(emdi)
  library(tidyverse)
})

dir_entrada     <- "input"
dir_salida      <- "otput"
linea_pobreza   <- 3182
replicas_boot   <- 5
transformacion  <- "log"

if (!dir.exists(dir_salida)) dir.create(dir_salida, recursive = TRUE)

# ---------------- IO ----------------
cargar_rdata_lista <- function(ruta) {
  antes <- ls(envir = .GlobalEnv)
  load(ruta, envir = .GlobalEnv)
  despues <- ls(envir = .GlobalEnv)
  nuevos <- setdiff(despues, antes)
  if (!length(nuevos)) stop("No se cargaron objetos desde: ", ruta)
  setNames(mget(nuevos, envir = .GlobalEnv), nuevos)
}

elegir_primer_df <- function(objetos, etiqueta) {
  dfl <- objetos[purrr::map_lgl(objetos, ~ is.data.frame(.x) || tibble::is_tibble(.x))]
  if (!length(dfl)) stop("Sin data.frame en: ", etiqueta)
  if (length(dfl) > 1) message("Aviso: múltiples data.frames en ", etiqueta, ". Usando: ", names(dfl)[1])
  dfl[[1]]
}

# ---------------- Util ----------------
verificar_vars <- function(df, requeridas, nombre_df) {
  faltan <- setdiff(requeridas, names(df))
  if (length(faltan)) stop("Faltan en ", nombre_df, ": ", paste(faltan, collapse = ", "))
}

normalizar_df <- function(df, tiene_y = TRUE) {
  df <- df %>%
    dplyr::mutate(
      secc      = as.character(secc),
      condacto  = ifelse(condacto  %in% c(1, "1", TRUE), 1L, 0L),
      condactc  = ifelse(condactc  %in% c(1, "1", TRUE), 1L, 0L),
      condactj  = ifelse(condactj  %in% c(1, "1", TRUE), 1L, 0L),
      alfasi    = ifelse(alfasi    %in% c(1, "1", TRUE), 1L, 0L)
    )
  if (tiene_y) df <- df %>% dplyr::mutate(ing = suppressWarnings(as.numeric(ing)))
  df
}

minimo_desplazamiento <- function(y) {
  pos <- suppressWarnings(min(y[y > 0], na.rm = TRUE))
  if (!is.finite(pos)) pos <- 1
  max(1, 0.5 * pos)
}

aplicar_desplazamiento_muestra <- function(muestra, etiqueta) {
  y <- muestra$ing
  if (any(!is.finite(y))) stop("NA/Inf en 'ing' (", etiqueta, ")")
  c_shift <- if (any(y <= 0)) minimo_desplazamiento(y) else 0
  if (c_shift != 0) message("Muestra ", etiqueta, ": c_shift = ", c_shift)
  list(muestra = dplyr::mutate(muestra, ing_shift = ing + c_shift), c_shift = c_shift)
}

coef_a_tibble <- function(coefs) {
  if (is.null(coefs)) return(tibble::tibble(parametro = character(), estimacion = numeric()))
  vec <- if (is.list(coefs)) unlist(coefs, recursive = TRUE, use.names = TRUE) else coefs
  tibble::tibble(parametro = names(vec), estimacion = as.numeric(vec))
}

# --------- Adaptadores ---------
como_df_estimadores <- function(x) {
  if (is.list(x) && !is.data.frame(x) && !is.null(x$ind) && is.data.frame(x$ind)) return(x$ind)
  as.data.frame(x)
}

renombrar_dominio <- function(df) {
  candidatos <- intersect(names(df), c("Domain","domain","secc","Secc","DOMINIO","dominio"))
  if (!length(candidatos)) stop("Sin columna de dominio en estimators()")
  dplyr::rename(df, secc = !!rlang::sym(candidatos[1]))
}

elegir_col <- function(nombres, patrones) {
  for (p in patrones) {
    hit <- grep(p, nombres, ignore.case = TRUE, value = TRUE, perl = TRUE)
    if (length(hit) >= 1) return(hit[1])
  }
  NA_character_
}

normalizar_tabla_indicador <- function(tbl, tipo) {
  tbl <- renombrar_dominio(tbl)
  nms <- names(tbl)
  
  mse_col <- elegir_col(nms, c("^MSE($|[_\\.])","^mse($|[_\\.])","mse"))
  cv_col  <- elegir_col(nms, c("^CV($|[_\\.])","^cv($|[_\\.])","cv"))
  
  valor_col <- switch(
    tipo,
    "Mean"           = elegir_col(nms, c("^Mean($|[_\\.])","^media$")),
    "Head_Count"     = elegir_col(nms, c("^Head(_|\\-|\\s)?Count$", "HeadCount$", "FGT0$", "Head$")),
    "Poverty_Gap"    = elegir_col(nms, c("^Poverty(_|\\-|\\s)?Gap$", "PovertyGap$", "FGT1$", "Gap$")),
    "Gini"           = elegir_col(nms, c("^Gini$", "Gini")),
    "Quintile_Share" = elegir_col(nms, c("^Quintile(_|\\-|\\s)?Share$", "QuintileShare$"))
  )
  
  if (is.na(valor_col)) {
    cand_val <- setdiff(nms, c("secc", mse_col, cv_col))
    if (length(cand_val) >= 1) valor_col <- cand_val[1]
  }
  
  if (is.na(mse_col) || is.na(cv_col) || is.na(valor_col)) {
    stop(sprintf("No se pudieron mapear columnas para '%s'. Names: %s", tipo, paste(nms, collapse=", ")))
  }
  
  dplyr::transmute(
    tbl,
    secc  = secc,
    valor = .data[[valor_col]],
    mse   = .data[[mse_col]],
    cv    = .data[[cv_col]]
  )
}

extraer_indicadores <- function(ajuste, c_shift = 0) {
  media_raw <- como_df_estimadores(estimators(ajuste, MSE = TRUE, CV = TRUE, indicator = "Mean"))
  media_tbl <- normalizar_tabla_indicador(media_raw, "Mean") %>%
    dplyr::rename(media = valor, emc_media = mse, cv_media = cv)
  if (c_shift != 0) media_tbl <- dplyr::mutate(media_tbl, media = pmax(media - c_shift, 0))
  
  fgt0_raw <- como_df_estimadores(estimators(ajuste, MSE = TRUE, CV = TRUE, indicator = "Head_Count"))
  fgt0_tbl <- normalizar_tabla_indicador(fgt0_raw, "Head_Count") %>%
    dplyr::rename(fgt0 = valor, emc_fgt0 = mse, cv_fgt0 = cv)
  
  fgt1_raw <- como_df_estimadores(estimators(ajuste, MSE = TRUE, CV = TRUE, indicator = "Poverty_Gap"))
  fgt1_tbl <- normalizar_tabla_indicador(fgt1_raw, "Poverty_Gap") %>%
    dplyr::rename(fgt1 = valor, emc_fgt1 = mse, cv_fgt1 = cv)
  
  gini_raw <- como_df_estimadores(estimators(ajuste, MSE = TRUE, CV = TRUE, indicator = "Gini"))
  gini_tbl <- normalizar_tabla_indicador(gini_raw, "Gini") %>%
    dplyr::rename(gini = valor, emc_gini = mse, cv_gini = cv)
  
  quintil_raw <- como_df_estimadores(estimators(ajuste, MSE = TRUE, CV = TRUE, indicator = "Quintile_Share"))
  quintil_tbl <- normalizar_tabla_indicador(quintil_raw, "Quintile_Share") %>%
    dplyr::rename(cuota_quintil = valor, emc_quintil = mse, cv_quintil = cv)
  
  media_tbl %>%
    dplyr::left_join(fgt0_tbl,   by = "secc") %>%
    dplyr::left_join(fgt1_tbl,   by = "secc") %>%
    dplyr::left_join(gini_tbl,   by = "secc") %>%
    dplyr::left_join(quintil_tbl,by = "secc") %>%
    dplyr::arrange(secc)
}

# --------- Revision Gini ---------
# comparar_shift_vs_filtrado <- function(muestra, censo) {
#
#   Con c
#   des <- (function(df){ y <- df$ing; cs <- if (any(y <= 0)) max(1, 0.5 * min(y[y>0], na.rm=TRUE)) else 0
#   list(df = mutate(df, ing_shift = ing + cs), cs = cs) })(muestra)
#   fit_shift <- ebp(
#     fixed = ing_shift ~ condacto + condactc + condactj + alfasi,
#     pop_data = normalizar_df(censo, FALSE), pop_domains = "secc",
#     smp_data = normalizar_df(des$df, TRUE), smp_domains = "secc",
#     na.rm = TRUE, MSE = TRUE, B = 3,  # B más chico solo para probar rápido
#     threshold = linea_pobreza + des$cs, transformation = transformacion
#   )
#   ind_shift <- extraer_indicadores(fit_shift, c_shift = des$cs)
#   
#   Sin c
#   smp_filtra <- muestra %>% filter(is.finite(ing), ing > 0) %>% mutate(ing_shift = ing)
#   fit_filtra <- ebp(
#     fixed = ing_shift ~ condacto + condactc + condactj + alfasi,
#     pop_data = normalizar_df(censo, FALSE), pop_domains = "secc",
#     smp_data = normalizar_df(smp_filtra, TRUE), smp_domains = "secc",
#     na.rm = TRUE, MSE = TRUE, B = 3,
#     threshold = linea_pobreza, transformation = transformacion
#   )
#   ind_filtra <- extraer_indicadores(fit_filtra, c_shift = 0)
#   
#   ind_shift %>%
#     select(secc, media, fgt0, fgt1, gini) %>%
#     rename(media_shift = media, fgt0_shift = fgt0, fgt1_shift = fgt1, gini_shift = gini) %>%
#     inner_join(ind_filtra %>% select(secc, media, fgt0, fgt1, gini) %>%
#                  rename(media_filtra = media, fgt0_filtra = fgt0, fgt1_filtra = fgt1, gini_filtra = gini),
#                by = "secc") %>%
#     mutate(
#       d_fgt0 = fgt0_shift - fgt0_filtra,
#       d_fgt1 = fgt1_shift - fgt1_filtra,
#       d_gini = gini_shift - gini_filtra
#     )
# }




# ---------------- EBP ----------------
ajustar_ebp <- function(muestra, censo, etiqueta = "H") {
  req_muestra <- c("secc","ing","condacto","condactc","condactj","alfasi")
  req_censo   <- c("secc",      "condacto","condactc","condactj","alfasi")
  
  verificar_vars(muestra, req_muestra, paste0("muestra ", etiqueta))
  verificar_vars(censo,   req_censo,   paste0("censo ", etiqueta))
  
  muestra <- normalizar_df(muestra, TRUE)
  censo   <- normalizar_df(censo,   FALSE)
  
  des <- aplicar_desplazamiento_muestra(muestra, etiqueta)
  muestra  <- des$muestra
  c_shift  <- des$c_shift
  umbral   <- linea_pobreza + c_shift
  
  message("Censo ", etiqueta, " columnas: ", paste(names(censo), collapse = ", "))
  if (c_shift != 0) message("Umbral: ", linea_pobreza, " -> ", umbral)
  
  ajuste <- ebp(
    fixed          = ing_shift ~ condacto + condactc + condactj + alfasi,
    pop_data       = censo,
    pop_domains    = "secc",
    smp_data       = muestra,
    smp_domains    = "secc",
    na.rm          = TRUE,
    MSE            = TRUE,
    B              = replicas_boot,
    threshold      = umbral,
    transformation = transformacion
  )
  
  indicadores <- extraer_indicadores(ajuste, c_shift)
  list(ajuste = ajuste, indicadores = indicadores, c_shift = c_shift)
}

# ---------------- Carga ----------------
m_h <- readRDS(file.path(dir_entrada, "SamH.RDS"))
m_m <- readRDS(file.path(dir_entrada, "SamM.RDS"))
c_h <- elegir_primer_df(cargar_rdata_lista(file.path(dir_entrada, "CensoH.RData")), "CensoH.RData")
c_m <- elegir_primer_df(cargar_rdata_lista(file.path(dir_entrada, "CensoM.RData")), "CensoM.RData")

# ------------- Exportación -------------
message("Hombres")
res_h <- ajustar_ebp(m_h, c_h, etiqueta = "H")
betas_h <- coefficients(res_h$ajuste)
tibble_h <- coef_a_tibble(betas_h)
write.csv(tibble_h, file = file.path(dir_salida, "coeficientes_h.csv"), row.names = FALSE)
write.csv(res_h$indicadores, file = file.path(dir_salida, "indicadores_h.csv"), row.names = FALSE)

message("Mujeres")
res_m <- ajustar_ebp(m_m, c_m, etiqueta = "M")
betas_m <- coefficients(res_m$ajuste)
tibble_m <- coef_a_tibble(betas_m)
write.csv(tibble_m, file = file.path(dir_salida, "coeficientes_m.csv"), row.names = FALSE)
write.csv(res_m$indicadores, file = file.path(dir_salida, "indicadores_m.csv"), row.names = FALSE)

comparacion <- res_h$indicadores %>%
  dplyr::rename_with(~ paste0(.x, "_h"), -secc) %>%
  dplyr::inner_join(res_m$indicadores %>% dplyr::rename_with(~ paste0(.x, "_m"), -secc), by = "secc") %>%
  dplyr::mutate(
    d_media   = media_h  - media_m,
    d_fgt0    = fgt0_h   - fgt0_m,
    d_fgt1    = fgt1_h   - fgt1_m,
    d_gini    = gini_h   - gini_m,
    d_quintil = cuota_quintil_h - cuota_quintil_m
  ) %>%
  dplyr::arrange(secc)

write.csv(comparacion, file = file.path(dir_salida, "comparacion_h_vs_m.csv"), row.names = FALSE)

cat("\nListo. Carpeta de salida: ", normalizePath(dir_salida), "\n")





