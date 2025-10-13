# -*- coding: UTF-8 -*-
# main.R — Orquestador de la actividad
rm(list = ls()); options(stringsAsFactors = FALSE, scipen = 99, digits = 3)

# Paquetes usados a lo largo del pipeline
req <- c(
  "readr","readxl","dplyr","tidyr","purrr","stringr","openxlsx","sf","tmap",
  "ggplot2","glue","forcats","rmarkdown"
)
invisible(lapply(setdiff(req, rownames(installed.packages())), install.packages))
invisible(lapply(req, library, character.only = TRUE))

dir.create("output", showWarnings = FALSE)
dir.create("output/maps", showWarnings = FALSE)

# 1) Construir Excel con estimaciones (Req. #1)
source("prep_excel_y_mapdata.R", local = TRUE)

# 2) Generar mapas (Req. #2) — el script anterior ya exporta los PNG
#    (se guardan en output/maps)

# 3) Renderizar PDF con mapas y conclusiones (Req. #3)
rmarkdown::render(
  input  = "informe_mapas_MVD.Rmd",
  output_file = "Informe_Mapas_SAE_Montevideo.pdf",
  output_dir  = "output",
  params = list(
    excel_path = "output/indicadores_montevideo.xlsx",
    maps_dir   = "output/maps"
  ),
  quiet = TRUE
)

message("Listo. Revisa output/ para el Excel y el PDF.")
