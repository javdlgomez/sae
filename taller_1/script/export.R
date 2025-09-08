# script/export.R
exportar_resultados <- function(
    output_dir = "output",
    res,     # list(Res_Ingreso, Res_Pobreza)
    fh,      # list(FH_Ingreso, FH_Pobreza, Betas_Ing, Betas_Pov)
    dirs,    # list(dir_ingreso, dir_pobreza)
    areas    # list(area_ingreso, area_pobreza)
){
  # 1) Crear carpeta 
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  
  # 2) Guardar resultados 
  readr::write_csv(res$Res_Ingreso,  file.path(output_dir, "FH_ingreso_por_seccion_HM.csv"))
  readr::write_csv(res$Res_Pobreza,  file.path(output_dir, "FH_pobreza_por_seccion_HM.csv"))
  
  # 3) Guardar EBLUP MSE betas
  readr::write_csv(fh$FH_Ingreso,    file.path(output_dir, "FH_eblup_mse_ingreso.csv"))
  readr::write_csv(fh$FH_Pobreza,    file.path(output_dir, "FH_eblup_mse_pobreza.csv"))
  readr::write_csv(fh$Betas_Ing,     file.path(output_dir, "FH_betas_ingreso.csv"))
  readr::write_csv(fh$Betas_Pov,     file.path(output_dir, "FH_betas_pobreza.csv"))
  
  # 4) tablas 
  readr::write_csv(dirs$dir_ingreso, file.path(output_dir, "directos_ingreso.csv"))
  readr::write_csv(dirs$dir_pobreza, file.path(output_dir, "directos_pobreza.csv"))
  readr::write_csv(areas$area_ingreso, file.path(output_dir, "area_ingreso.csv"))
  readr::write_csv(areas$area_pobreza, file.path(output_dir, "area_pobreza.csv"))
  
  # 5) RDS ccompleto
  saveRDS(
    list(res = res, fh = fh, dirs = dirs, areas = areas),
    file.path(output_dir, "paquete_resultados.rds")
  )
  
  invisible(TRUE)
}
