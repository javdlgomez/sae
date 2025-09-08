cargar_insumos <- function(data_dir = "data") {
  # Muestras
  SamH <- readRDS(file.path(data_dir, "SamH.RDS"))
  SamM <- readRDS(file.path(data_dir, "SamM.RDS"))
  
  # Censos 
  eH <- new.env(); load(file.path(data_dir, "CensoH.RData"), envir = eH); CensoH <- eH[["CensoH"]]
  eM <- new.env(); load(file.path(data_dir, "CensoM.RData"), envir = eM); CensoM <- eM[["CensoM"]]
  

  SamH   <- SamH   %>% mutate(secc = as.character(secc))
  SamM   <- SamM   %>% mutate(secc = as.character(secc))
  CensoH <- CensoH %>% mutate(secc = as.character(secc))
  CensoM <- CensoM %>% mutate(secc = as.character(secc))
  
  # Tamaños por dominio
  DomH <- CensoH %>% count(secc, name = "N_dom") %>% mutate(N_dom = as.numeric(N_dom)) %>% arrange(secc)
  DomM <- CensoM %>% count(secc, name = "N_dom") %>% mutate(N_dom = as.numeric(N_dom)) %>% arrange(secc)
  
  # Auxs y sexo
  AuxH <- CensoH %>% group_by(secc) %>% summarise(
    x_act  = mean(condacto,  na.rm = TRUE),
    x_cta  = mean(condactc,  na.rm = TRUE),
    x_jef  = mean(condactj,  na.rm = TRUE),
    x_alfa = mean(alfasi,    na.rm = TRUE),
    .groups = "drop"
  ) %>% mutate(sexo = "H")
  
  AuxM <- CensoM %>% group_by(secc) %>% summarise(
    x_act  = mean(condacto,  na.rm = TRUE),
    x_cta  = mean(condactc,  na.rm = TRUE),
    x_jef  = mean(condactj,  na.rm = TRUE),
    x_alfa = mean(alfasi,    na.rm = TRUE),
    .groups = "drop"
  ) %>% mutate(sexo = "M")
  
  # Indicador de pobreza 
  recod_pobre <- function(df) {
    df %>% mutate(pobre_1 = if (is.numeric(pobreza)) {
      as.integer(pobreza %in% c(1, 2))
    } else {
      as.integer(tolower(as.character(pobreza)) %in%
                   c("pobre","pobreza","pobreza extrema","extrema",
                     "pobreza no extrema","no extrema","pobre_extrema","pobre_no_extrema"))
    })
  }
  SamH <- recod_pobre(SamH); SamM <- recod_pobre(SamM)
  
  Aux_all <- bind_rows(AuxH, AuxM) %>% arrange(sexo, secc)
  
  list(SamH = SamH, SamM = SamM, CensoH = CensoH, CensoM = CensoM,
       DomH = DomH, DomM = DomM, Aux_all = Aux_all)
}
