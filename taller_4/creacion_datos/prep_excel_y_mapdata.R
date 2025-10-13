# -*- coding: UTF-8 -*-
# Construye un Excel con todos los indicadores y exporta mapas PNG

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(openxlsx)
  library(sf); library(tmap); library(ggplot2); library(stringr); library(glue)
})

# === 2.1 Cargar insumos ======================================================
# BHF / EBP
bhf_h <- read_delim("BHF_H.csv", delim = ";", locale = locale(decimal_mark = ","))
bhf_m <- read_delim("BHF_M.csv", delim = ";", locale = locale(decimal_mark = ","))

# Fay-Herriot
fh_h  <- read_delim("FH_SAE_Hombre.csv",  delim = ";", locale = locale(decimal_mark = ","))
fh_m  <- read_delim("FH_SAE_Mujeres.csv", delim = ";", locale = locale(decimal_mark = ","))

# Shapefile: filtrar Montevideo
uru  <- suppressWarnings(sf::read_sf("ine_seccen.shp"))
mvd  <- uru %>% dplyr::filter(.data$NOMBDEPTO == "MONTEVIDEO") %>%
  dplyr::transmute(SECCION = as.character(.data$SECCION), geometry)

# === 2.2 Normalizar nombres/llaves ===========================================
std <- function(x) {
  # forzar nombres estándar típicos de emdi::estimators
  nm <- names(x)
  nm <- sub("^Domain$", "Dominio", nm, ignore.case = TRUE)
  names(x) <- nm
  x %>% dplyr::mutate(Dominio = as.character(.data$Dominio))
}

bhf_h <- std(bhf_h); bhf_m <- std(bhf_m)
fh_h  <- std(fh_h);  fh_m  <- std(fh_m)

# Chequeo rápido de claves
stopifnot("Dominio" %in% names(bhf_h), "Dominio" %in% names(bhf_m))
stopifnot(all(c("Eblup_Ing_H") %in% names(fh_h)))
stopifnot(all(c("Eblup_Ing_M") %in% names(fh_m)))

# === 2.3 Construir tablas por indicador para Excel ===========================
# Indicadores EBP disponibles (ajusta si cambian nombres de columnas)
cols_h <- intersect(c("Dominio","Mean","Mean_MSE","Head_Count","Head_Count_MSE",
                      "Poverty_Gap","Poverty_Gap_MSE","Gini","Gini_MSE"), names(bhf_h))
cols_m <- intersect(c("Dominio","Mean","Mean_MSE","Head_Count","Head_Count_MSE",
                      "Poverty_Gap","Poverty_Gap_MSE","Gini","Gini_MSE"), names(bhf_m))

ebp_h <- bhf_h[, cols_h]
ebp_m <- bhf_m[, cols_m]

# Combinar H y M por indicador en hojas compactas
mk_sheet <- function(indic, base_h, base_m) {
  hh <- base_h %>% select(Dominio, value_h = all_of(indic), mse_h = any_of(paste0(indic,"_MSE")))
  mm <- base_m %>% select(Dominio, value_m = all_of(indic), mse_m = any_of(paste0(indic,"_MSE")))
  out <- hh %>% full_join(mm, by = "Dominio") %>%
    mutate(diff_m_h = value_m - value_h)
  out[order(as.numeric(out$Dominio)), , drop = FALSE]
}

sheets <- list()
for (indic in c("Mean","Head_Count","Poverty_Gap","Gini")) {
  if (all(c(indic %in% names(ebp_h), indic %in% names(ebp_m)))) {
    sheets[[indic]] <- mk_sheet(indic, ebp_h, ebp_m)
  }
}

# Hoja FH (Eblup Ingreso)
fh <- fh_h %>%
  select(Dominio, Eblup_Ing_H) %>%
  full_join(fh_m %>% select(Dominio, Eblup_Ing_M), by = "Dominio") %>%
  mutate(diff_m_h = Eblup_Ing_M - Eblup_Ing_H) %>%
  arrange(as.numeric(Dominio))

# === 2.4 Escribir Excel ======================================================
wb <- createWorkbook()
for (nm in names(sheets)) {
  addWorksheet(wb, nm)
  writeData(wb, nm, sheets[[nm]])
}
addWorksheet(wb, "FH_Eblup_Ing")
writeData(wb, "FH_Eblup_Ing", fh)

saveWorkbook(wb, "output/indicadores_montevideo.xlsx", overwrite = TRUE)

# === 2.5 Datasets para mapas y exportación de PNG ============================
# Helper: une un indicador por sexo con el shapefile de Montevideo
join_map <- function(df, col_name, sexo = c("H","M")) {
  sexo <- match.arg(sexo)
  key  <- if (sexo == "H") col_name else col_name
  df   <- df %>% select(Dominio, value = all_of(col_name)) %>%
    mutate(Dominio = as.character(Dominio))
  mvd  %>% left_join(df, by = c("SECCION" = "Dominio")) %>%
    mutate(value = ifelse(is.na(value), NA_real_, value))
}

# Lista de indicadores a mapear desde BHF/EBP
to_map <- c(
  "Mean" = "Ingresos medios",
  "Head_Count" = "Incidencia de pobreza (FGT α=0)",
  "Poverty_Gap" = "Brecha de pobreza (FGT α=1)",
  "Gini" = "Índice de Gini"
)

tmap_mode("plot")

# Exportar mapas H y M para cada indicador
for (ind in names(to_map)) {
  if (!(ind %in% names(ebp_h)) || !(ind %in% names(ebp_m))) next
  
  shp_h <- join_map(ebp_h, ind, "H")
  shp_m <- join_map(ebp_m, ind, "M")
  
  pal <- "-YlOrRd"  # secuencia agradable; invierte con prefijo '-'
  
  map_h <- tm_shape(shp_h) + tm_polygons("value", title = glue("{to_map[[ind]]} — H"),
                                         palette = pal, colorNA = "grey90") +
    tm_layout(frame = FALSE)
  map_m <- tm_shape(shp_m) + tm_polygons("value", title = glue("{to_map[[ind]]} — M"),
                                         palette = pal, colorNA = "grey90") +
    tm_layout(frame = FALSE)
  
  tmap_save(map_h, filename = glue("output/maps/{ind}_H.png"),
            width = 2000, height = 1600, units = "px")
  tmap_save(map_m, filename = glue("output/maps/{ind}_M.png"),
            width = 2000, height = 1600, units = "px")
  
  # Mapa de diferencias (M - H)
  shp_diff <- mvd %>%
    left_join(ebp_h %>% select(Dominio, H = all_of(ind)), by = c("SECCION" = "Dominio")) %>%
    left_join(ebp_m %>% select(Dominio, M = all_of(ind)), by = c("SECCION" = "Dominio")) %>%
    mutate(diff = M - H)
  
  map_d <- tm_shape(shp_diff) +
    tm_polygons("diff", title = glue("Diferencia (M - H) — {to_map[[ind]]}"),
                palette = "PuOr", midpoint = 0, colorNA = "grey90") +
    tm_layout(frame = FALSE)
  tmap_save(map_d, filename = glue("output/maps/{ind}_Diff_MmenosH.png"),
            width = 2000, height = 1600, units = "px")
}

# Mapas FH (Eblup ingreso)
shp_fh <- mvd %>%
  left_join(fh_h %>% select(Dominio, Eblup_Ing_H), by = c("SECCION" = "Dominio")) %>%
  left_join(fh_m %>% select(Dominio, Eblup_Ing_M), by = c("SECCION" = "Dominio")) %>%
  mutate(diff = Eblup_Ing_M - Eblup_Ing_H)

map_fh_h <- tm_shape(shp_fh) + tm_polygons("Eblup_Ing_H", title = "FH Ingreso — H", palette = "-YlGnBu") +
  tm_layout(frame = FALSE)
map_fh_m <- tm_shape(shp_fh) + tm_polygons("Eblup_Ing_M", title = "FH Ingreso — M", palette = "-YlGnBu") +
  tm_layout(frame = FALSE)
map_fh_d <- tm_shape(shp_fh) + tm_polygons("diff", title = "FH Ingreso — Diferencia (M - H)",
                                           palette = "PuOr", midpoint = 0) +
  tm_layout(frame = FALSE)

tmap_save(map_fh_h, "output/maps/FH_Ingreso_H.png", width = 2000, height = 1600, units = "px")
tmap_save(map_fh_m, "output/maps/FH_Ingreso_M.png", width = 2000, height = 1600, units = "px")
tmap_save(map_fh_d, "output/maps/FH_Ingreso_Diff_MmenosH.png", width = 2000, height = 1600, units = "px")
