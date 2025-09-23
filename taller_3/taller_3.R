############################################################
# Taller 3 · Estimador plug-in 
############################################################


  library(dplyr)
  library(tidyr)
  library(lme4)
  library(purrr)
  library(readr)

options(stringsAsFactors = FALSE)

#--------- Rutas --------- 
ruta_samh   <- "data/SamH.RDS"
ruta_samm   <- "data/SamM.RDS"
ruta_censoh <- "data/CensoH.RData"
ruta_censom <- "data/CensoM.RData"

salida_h <- "pobreza_plugin_hombres_por_secc.csv"
salida_m <- "pobreza_plugin_mujeres_por_secc.csv"
salida_c <- "pobreza_plugin_comparacion_secc.csv"

#--------- Utils --------- 
cargar_rdata <- function(path) {
  nm <- load(path); if (length(nm) != 1) stop("RData debe traer 1 objeto.")
  get(nm, envir = .GlobalEnv)
}

detectar_var_pobreza <- function(df) {
  cand <- c("pobreza_Ind","pobreza","pobreza_ind")
  hit  <- cand[cand %in% names(df)]
  if (!length(hit)) stop("No se encontró variable de pobreza.")
  hit[1]
}

binario_01 <- function(x) {
  if (is.numeric(x)) {
    ux <- sort(unique(x[!is.na(x)]))
    if (all(ux %in% c(0,1))) return(as.numeric(x))
    if (all(ux %in% c(1,2))) return(as.numeric(x == 2))
    stop("Variable numérica no binaria en {0,1}/{1,2}.")
  }
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x))  x <- as.character(x)
  x <- trimws(tolower(as.character(x)))
  pos <- x %in% c("1","si","sí","y","pobre","pobreza","en_pobreza")
  neg <- x %in% c("0","no","n","no_pobre","sin_pobreza")
  if (!all(pos | neg | is.na(x))) stop("No se pudo mapear a {0,1}.")
  out <- rep(NA_real_, length(x)); out[pos] <- 1; out[neg] <- 0; out
}

ajustar_plugin_binomial <- function(muestra, censo, y, secc, x) {
  stopifnot(all(c(y,secc,x) %in% names(muestra)),
            all(c(secc,x)    %in% names(censo)))
  
  muestra <- muestra %>%
    mutate(
      !!y    := binario_01(.data[[y]]),
      !!secc := factor(.data[[secc]])
    ) %>%
    mutate(across(all_of(x), ~ suppressWarnings(as.numeric(.x)))) %>%
    drop_na(all_of(c(y, secc, x)))
  
  niveles_secc <- levels(muestra[[secc]])
  
  censo <- censo %>%
    mutate(
      !!secc := factor(.data[[secc]], levels = niveles_secc),
      across(all_of(x), ~ suppressWarnings(as.numeric(.x)))
    )
  
  # Medias y SD con sapply 
  medias <- sapply(muestra[x], function(v) mean(v, na.rm = TRUE))
  sds    <- sapply(muestra[x], function(v)  sd(v,  na.rm = TRUE))
  sds[is.na(sds) | sds == 0] <- 1
  
  # Estandarizar
  xs <- paste0(x, "_s")
  for (v in x) {
    vs <- paste0(v, "_s")
    muestra[[vs]] <- (muestra[[v]] - medias[[v]]) / sds[[v]]
    censo[[vs]]   <- (censo[[v]]   - medias[[v]]) / sds[[v]]
  }
  
  fml <- as.formula(paste0(y, " ~ ", paste(xs, collapse = " + "), " + (1|", secc, ")"))
  
  fit <- lme4::glmer(
    fml, data = muestra, family = binomial(link = "logit"),
    control = lme4::glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5))
  )
  
  # Predicción SYN 
  censo$pred_syn <- stats::predict(
    fit, newdata = censo, type = "response",
    re.form = ~0, allow.new.levels = TRUE
  )
  
  est <- censo %>%
    group_by(.data[[secc]]) %>%
    summarise(pobreza = mean(pred_syn, na.rm = TRUE), .groups = "drop") %>%
    mutate(porcentaje = 100 * pobreza) %>%
    rename(!!secc := 1)
  
  list(fit = fit, est = est)
}


#--------- Cargar ---------
sam_h <- readRDS(ruta_samh)
sam_m <- readRDS(ruta_samm)
cen_h <- cargar_rdata(ruta_censoh)
cen_m <- cargar_rdata(ruta_censom)

#--------- Variables ---------
y_h   <- detectar_var_pobreza(sam_h)   
y_m   <- detectar_var_pobreza(sam_m)   
secc  <- "secc"
covs  <- c("edad","anoest")

#--------- Modelos ---------
res_h <- ajustar_plugin_binomial(sam_h, cen_h, y = y_h, secc = secc, x = covs)
res_m <- ajustar_plugin_binomial(sam_m, cen_m, y = y_m, secc = secc, x = covs)

tab_h <- res_h$est %>% rename(pobreza_h = pobreza, pct_h = porcentaje)
tab_m <- res_m$est %>% rename(pobreza_m = pobreza, pct_m = porcentaje)

comparacion <- tab_h %>%
  full_join(tab_m, by = secc) %>%
  mutate(dif_pp_menos_h = pct_m - pct_h) %>%
  arrange(desc(abs(dif_pp_menos_h)))

#--------- Salida ---------
write_csv(tab_h, salida_h)
write_csv(tab_m, salida_m)
write_csv(comparacion, salida_c)

cat("OK\n",
    "- ", salida_h, "\n",
    "- ", salida_m, "\n",
    "- ", salida_c, "\n", sep = "")
