suppressPackageStartupMessages({
  library(tidyverse)
  library(sae)
  library(survey)
})

source("script/utils.R")
source("script/data_io.R")
source("script/modelado.R")
source("script/export.R")   

# 1)  insumos
ins <- cargar_insumos("data")

# 2) Directos
dirs <- estimar_directos(ins)

# 3) Áreas
areas <- construir_areas(dirs, ins$Aux_all)

# 4) FH
fh <- ajustar_fh_por_sexo(areas)

# 5) Consolidados
res <- consolidar_resultados(areas, fh)

# 6) Exportar 
exportar_resultados(output_dir = "output", res = res, fh = fh, dirs = dirs, areas = areas)

# GlobalEnv
list2env(c(ins, dirs, areas, fh, res), envir = .GlobalEnv)
invisible(NULL)
