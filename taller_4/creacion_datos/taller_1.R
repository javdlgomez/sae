## ================================================================
##  FH final: Directos + Auxiliares + Fay–Herriot (H y M) + Export
## ================================================================
rm(list = ls())
options(digits = 2)

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(sae)
  library(survey)   # para el auxiliar 'direct'
})

## ------------------------------------------------
## Auxiliar: 'direct()' compatible con tu script
##   - Devuelve: Domain, n, Direct, SD, CV
## ------------------------------------------------
direct <- function(y, dom, factorex, domsize = NULL, replace = FALSE) {
  df <- data.frame(
    y = y,
    dom = dom,
    weight = factorex
  )
  df <- df[!is.na(df$y) & !is.na(df$dom) & !is.na(df$weight), , drop = FALSE]
  des <- survey::svydesign(ids = ~1, weights = ~weight, data = df)
  
  est <- survey::svyby(~y, ~dom, des, survey::svymean, na.rm = TRUE, vartype = "se") %>%
    as.data.frame()
  nn <- df %>% group_by(dom) %>% summarise(n = n(), .groups = "drop")
  
  out <- est %>%
    rename(Domain = dom, Direct = y, SD = se) %>%
    left_join(nn, by = c("Domain" = "dom")) %>%
    mutate(CV = ifelse(Direct == 0, NA_real_, SD / abs(Direct) * 100)) %>%
    select(Domain, n, Direct, SD, CV) %>%
    mutate(Domain = as.character(Domain)) %>%
    arrange(suppressWarnings(as.numeric(Domain)))
  out
}

## ------------------------------------------------
## Saneo previo a FH
##   - Verifica columnas
##   - Fuerza numéricos
##   - Filtra NA/SD<=0
##   - Evita duplicados de Domain
##   - Devuelve data.frame base
## ------------------------------------------------
prep_for_fh <- function(df, y_col, sd_col,
                        aux_cols = c("condacto","condactc","condactj","alfasi")) {
  
  req_vars <- c(y_col, sd_col, aux_cols)
  faltan <- setdiff(req_vars, names(df))
  if (length(faltan)) {
    stop("Faltan columnas en la tabla para FH: ", paste(faltan, collapse = ", "))
  }
  
  df2 <- as.data.frame(df, stringsAsFactors = FALSE)
  
  # Forzar numéricos
  for (nm in req_vars) {
    df2[[nm]] <- suppressWarnings(as.numeric(df2[[nm]]))
  }
  
  # Filtrar inválidos y duplicados
  df2 <- subset(df2,
                !is.na(df2[[y_col]]) &
                  !is.na(df2[[sd_col]]) & df2[[sd_col]] > 0 &
                  !is.na(df2$condacto) & !is.na(df2$condactc) &
                  !is.na(df2$condactj) & !is.na(df2$alfasi))
  df2 <- df2[!duplicated(df2$Domain), , drop = FALSE]
  
  # Aviso si quedaron sufijos .x/.y
  suf <- grep("\\.[xy]$", names(df2), value = TRUE)
  if (length(suf)) {
    warning("Existen columnas con sufijos .x/.y: ", paste(suf, collapse = ", "),
            ". Renómbralas antes de FH si corresponden.")
  }
  
  df2
}

## ------------------------------------------------
## Cargar bases
## ------------------------------------------------
load("CensoH.RData")
load("CensoM.RData")
SamH <- readRDS("SamH.RDS")
SamM <- readRDS("SamM.RDS")

## =================================================
## ================   HOMBRES   ====================
## =================================================

## (1) Directos H
direct_ing_H <- with(SamH, direct(ing, secc, factorex))
direct_ing_H <- direct_ing_H[, -2] %>% select(-CV)         # como en tu flujo
colnames(direct_ing_H)[2] <- "Ingresos"

direct_pob_H <- with(SamH, direct(pobreza, secc, factorex))
direct_pob_H <- direct_pob_H[, -2] %>% select(-CV)
colnames(direct_pob_H)[2] <- "Pobreza"

BaseDir_H <- left_join(direct_ing_H, direct_pob_H, by = "Domain")
colnames(BaseDir_H)[c(3,5)] <- c("SD_Ing","SD_Pobre")

## (2) Auxiliares H
Aux_H <- CensoH %>%
  group_by(secc) %>%
  summarise(condacto = sum(na.omit(condacto)),
            condactc = sum(na.omit(condactc)),
            condactj = sum(na.omit(condactj)),
            alfasi   = sum(na.omit(alfasi)),
            .groups = "drop") %>%
  mutate(secc = as.character(secc)) %>%
  rename(Domain = secc)

BaseDir_H$Domain <- as.character(BaseDir_H$Domain)
Aux_H$Domain     <- as.character(Aux_H$Domain)

area_values_H <- left_join(BaseDir_H, Aux_H, by = "Domain")

## (3) FH H — Ingresos
area_values_H_ing <- prep_for_fh(area_values_H,
                                 y_col = "Ingresos",
                                 sd_col = "SD_Ing",
                                 aux_cols = c("condacto","condactc","condactj","alfasi"))

salida_Ing_H <- sae::mseFH(
  formula = Ingresos ~ condacto + condactc + condactj + alfasi,
  vardir  = area_values_H_ing[["SD_Ing"]]^2,
  method  = "REML",
  data    = area_values_H_ing
)

ECM_Ing_H   <- salida_Ing_H$mse
Eblup_Ing_H <- salida_Ing_H$est$eblup

Estima_SAE_Ing_H <- data.frame(
  Dominio     = area_values_H_ing$Domain,
  Eblup_Ing_H = Eblup_Ing_H,
  ECM_Ing_H   = ECM_Ing_H
)

## (4) FH H — Pobreza
area_values_H_pob <- prep_for_fh(area_values_H,
                                 y_col = "Pobreza",
                                 sd_col = "SD_Pobre",
                                 aux_cols = c("condacto","condactc","condactj","alfasi"))

salida_Pobre_H <- sae::mseFH(
  formula = Pobreza ~ condacto + condactc + condactj + alfasi,
  vardir  = area_values_H_pob[["SD_Pobre"]]^2,
  method  = "REML",
  data    = area_values_H_pob
)

ECM_Pobre_H   <- salida_Pobre_H$mse
Eblup_Pobre_H <- salida_Pobre_H$est$eblup

Estima_SAE_Pobre_H <- data.frame(
  Dominio       = area_values_H_pob$Domain,
  Eblup_Pobre_H = Eblup_Pobre_H,
  ECM_Pobre_H   = ECM_Pobre_H
)

Estima_SAE_Hombres <- left_join(Estima_SAE_Ing_H, Estima_SAE_Pobre_H, by = "Dominio")

## =================================================
## ================   MUJERES   ====================
## =================================================

## (1) Directos M
direct_ing_M <- with(SamM, direct(ing, secc, factorex))
direct_ing_M <- direct_ing_M[, -2] %>% select(-CV)
colnames(direct_ing_M)[2] <- "Ingresos"

direct_pob_M <- with(SamM, direct(pobreza, secc, factorex))
direct_pob_M <- direct_pob_M[, -2] %>% select(-CV)
colnames(direct_pob_M)[2] <- "Pobreza"

BaseDir_M <- left_join(direct_ing_M, direct_pob_M, by = "Domain")
colnames(BaseDir_M)[c(3,5)] <- c("SD_Ing","SD_Pobre")

## (2) Auxiliares M
Aux_M <- CensoM %>%
  group_by(secc) %>%
  summarise(condacto = sum(na.omit(condacto)),
            condactc = sum(na.omit(condactc)),
            condactj = sum(na.omit(condactj)),
            alfasi   = sum(na.omit(alfasi)),
            .groups = "drop") %>%
  mutate(secc = as.character(secc)) %>%
  rename(Domain = secc)

BaseDir_M$Domain <- as.character(BaseDir_M$Domain)
Aux_M$Domain     <- as.character(Aux_M$Domain)

area_values_M <- left_join(BaseDir_M, Aux_M, by = "Domain")

## (3) FH M — Ingresos
area_values_M_ing <- prep_for_fh(area_values_M,
                                 y_col = "Ingresos",
                                 sd_col = "SD_Ing",
                                 aux_cols = c("condacto","condactc","condactj","alfasi"))

salida_Ing_M <- sae::mseFH(
  formula = Ingresos ~ condacto + condactc + condactj + alfasi,
  vardir  = area_values_M_ing[["SD_Ing"]]^2,
  method  = "REML",
  data    = area_values_M_ing
)

ECM_Ing_M   <- salida_Ing_M$mse
Eblup_Ing_M <- salida_Ing_M$est$eblup

Estima_SAE_Ing_M <- data.frame(
  Dominio     = area_values_M_ing$Domain,
  Eblup_Ing_M = Eblup_Ing_M,
  ECM_Ing_M   = ECM_Ing_M
)

## (4) FH M — Pobreza
area_values_M_pob <- prep_for_fh(area_values_M,
                                 y_col = "Pobreza",
                                 sd_col = "SD_Pobre",
                                 aux_cols = c("condacto","condactc","condactj","alfasi"))

salida_Pobre_M <- sae::mseFH(
  formula = Pobreza ~ condacto + condactc + condactj + alfasi,
  vardir  = area_values_M_pob[["SD_Pobre"]]^2,
  method  = "REML",
  data    = area_values_M_pob
)

ECM_Pobre_M   <- salida_Pobre_M$mse
Eblup_Pobre_M <- salida_Pobre_M$est$eblup

Estima_SAE_Pobre_M <- data.frame(
  Dominio       = area_values_M_pob$Domain,
  Eblup_Pobre_M = Eblup_Pobre_M,
  ECM_Pobre_M   = ECM_Pobre_M
)

Estima_SAE_Mujeres <- left_join(Estima_SAE_Ing_M, Estima_SAE_Pobre_M, by = "Dominio")

## ------------------------------------------------
## Exportación
## ------------------------------------------------
dir.create("output", showWarnings = FALSE)

write.csv2(Estima_SAE_Hombres, "FH_SAE_Hombre.csv", row.names = FALSE)
write.csv2(Estima_SAE_Mujeres, "FH_SAE_Mujeres.csv", row.names = FALSE)

write.csv2(Estima_SAE_Hombres, "output/FH_SAE_Hombre.csv", row.names = FALSE)
write.csv2(Estima_SAE_Mujeres, "output/FH_SAE_Mujeres.csv", row.names = FALSE)

saveRDS(Estima_SAE_Hombres, "output/FH_SAE_Hombre.rds")
saveRDS(Estima_SAE_Mujeres, "output/FH_SAE_Mujeres.rds")

cat("\nListo. Objetos en memoria:\n- Estima_SAE_Hombres\n- Estima_SAE_Mujeres\n")
