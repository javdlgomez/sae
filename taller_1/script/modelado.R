# 1) Directos -----------------------------------------------------------------
estimar_directos <- function(ins) {
  dir_ingreso <- tibble()
  dir_pobreza <- tibble()
  
  for (sx in c("H","M")) {
    muestra <- if (sx == "H") ins$SamH else ins$SamM
    domsize <- if (sx == "H") ins$DomH else ins$DomM
    
    # Ingreso
    d_raw <- sae::direct(
      y       = ing,
      dom     = secc,
      sweight = factorex,
      domsize = domsize[, c("secc","N_dom")],
      data    = muestra,
      replace = FALSE
    )
    sd_col <- .pick_name(names(d_raw), c("SD","sd"))
    cv_col <- .pick_name(names(d_raw), c("CV","cv"))
    n_col  <- .pick_name(names(d_raw), c("SampSize","n"))
    
    dir_ingreso <- bind_rows(
      dir_ingreso,
      d_raw %>%
        mutate(secc_chr = as.character(Domain)) %>%
        transmute(
          sexo   = sx,
          secc   = secc_chr,
          n_obs  = .data[[n_col]],
          y_dir  = Direct,
          sd_dir = .data[[sd_col]],
          cv_dir = .data[[cv_col]],
          vardir = (.data[[sd_col]])^2
        ) %>%
        arrange(secc)
    )
    
    # Pobreza
    p_raw <- sae::direct(
      y       = pobre_1,
      dom     = secc,
      sweight = factorex,
      domsize = domsize[, c("secc","N_dom")],
      data    = muestra,
      replace = FALSE
    )
    sd_col <- .pick_name(names(p_raw), c("SD","sd"))
    cv_col <- .pick_name(names(p_raw), c("CV","cv"))
    n_col  <- .pick_name(names(p_raw), c("SampSize","n"))
    
    dir_pobreza <- bind_rows(
      dir_pobreza,
      p_raw %>%
        mutate(secc_chr = as.character(Domain)) %>%
        transmute(
          sexo   = sx,
          secc   = secc_chr,
          n_obs  = .data[[n_col]],
          p_dir  = Direct,
          sd_dir = .data[[sd_col]],
          cv_dir = .data[[cv_col]],
          vardir = (.data[[sd_col]])^2
        ) %>%
        arrange(secc)
    )
  }
  
  list(dir_ingreso = dir_ingreso, dir_pobreza = dir_pobreza)
}

# 2) Áreas --------------------------------------------------------------------
construir_areas <- function(dirs, Aux_all) {
  area_ingreso <- dirs$dir_ingreso %>%
    mutate(secc = as.character(secc), vardir = as.numeric(vardir)) %>%
    left_join(Aux_all, by = c("secc","sexo")) %>%
    select(sexo, secc, n_obs, y_dir, sd_dir, cv_dir, vardir, x_act, x_cta, x_jef, x_alfa) %>%
    filter(is.finite(y_dir), is.finite(vardir), vardir > 0) %>%
    tidyr::drop_na(x_act, x_cta, x_jef, x_alfa)
  
  area_pobreza <- dirs$dir_pobreza %>%
    mutate(secc = as.character(secc), vardir = as.numeric(vardir)) %>%
    left_join(Aux_all, by = c("secc","sexo")) %>%
    select(sexo, secc, n_obs, p_dir, sd_dir, cv_dir, vardir, x_act, x_cta, x_jef, x_alfa) %>%
    filter(is.finite(p_dir), is.finite(vardir), vardir > 0) %>%
    tidyr::drop_na(x_act, x_cta, x_jef, x_alfa)
  
  list(area_ingreso = area_ingreso, area_pobreza = area_pobreza)
}

# 3) FH por sexo --------------------------------------------------------------
ajustar_fh_por_sexo <- function(areas) {
  f_ing <- y_dir ~ x_act + x_cta + x_jef + x_alfa
  f_pov <- p_dir ~ x_act + x_cta + x_jef + x_alfa
  
  FH_Ingreso <- tibble()
  FH_Pobreza <- tibble()
  Betas_Ing  <- tibble()
  Betas_Pov  <- tibble()
  
  for (sx in c("H","M")) {
    ai <- areas$area_ingreso %>% filter(sexo == sx)
    ap <- areas$area_pobreza %>% filter(sexo == sx)
    
    fh_i  <- sae::eblupFH(f_ing, vardir = vardir, method = "REML", data = as.data.frame(ai))
    mse_i <- sae::mseFH  (f_ing, vardir = vardir, method = "REML", data = as.data.frame(ai))
    
    fh_p  <- sae::eblupFH(f_pov, vardir = vardir, method = "REML", data = as.data.frame(ap))
    mse_p <- sae::mseFH  (f_pov, vardir = vardir, method = "REML", data = as.data.frame(ap))
    
    FH_Ingreso <- bind_rows(
      FH_Ingreso,
      tibble(
        sexo  = sx,
        secc  = ai$secc,
        eblup = as.numeric(fh_i$eblup),
        mse   = as.numeric(mse_i$mse),
        se    = sqrt(pmax(mse, 0)),
        cv    = 100 * se / pmax(eblup, 1e-12)
      )
    )
    
    FH_Pobreza <- bind_rows(
      FH_Pobreza,
      tibble(
        sexo  = sx,
        secc  = ap$secc,
        eblup = pmin(pmax(as.numeric(fh_p$eblup), 0), 1),
        mse   = as.numeric(mse_p$mse),
        se    = sqrt(pmax(mse, 0)),
        cv    = 100 * se / pmax(eblup, 1e-12)
      )
    )
    
    Betas_Ing <- bind_rows(Betas_Ing, .extraer_betas_seguro(fh_i, sx))
    Betas_Pov <- bind_rows(Betas_Pov, .extraer_betas_seguro(fh_p, sx))
  }
  
  list(FH_Ingreso = FH_Ingreso, FH_Pobreza = FH_Pobreza,
       Betas_Ing = Betas_Ing, Betas_Pov = Betas_Pov)
}

# 4) Consolidados -------------------------------------------------------------
consolidar_resultados <- function(areas, fh) {
  Res_Ingreso <- areas$area_ingreso %>%
    select(sexo, secc, n_obs, y_dir, vardir, cv_dir) %>%
    left_join(fh$FH_Ingreso %>% select(sexo, secc, eblup, mse, se, cv),
              by = c("sexo","secc")) %>%
    rename(
      n_ingreso       = n_obs,
      ingreso_dir     = y_dir,
      var_ingreso_dir = vardir,
      cv_ingreso_dir  = cv_dir,
      ingreso_fh      = eblup,
      mse_ingreso_fh  = mse,
      se_ingreso_fh   = se,
      cv_ingreso_fh   = cv
    ) %>%
    arrange(sexo, secc)
  
  Res_Pobreza <- areas$area_pobreza %>%
    select(sexo, secc, n_obs, p_dir, vardir, cv_dir) %>%
    left_join(fh$FH_Pobreza %>% select(sexo, secc, eblup, mse, se, cv),
              by = c("sexo","secc")) %>%
    mutate(p_dir = pmin(pmax(p_dir, 0), 1)) %>%
    rename(
      n_pobreza       = n_obs,
      pobreza_dir     = p_dir,
      var_pobreza_dir = vardir,
      cv_pobreza_dir  = cv_dir,
      pobreza_fh      = eblup,
      mse_pobreza_fh  = mse,
      se_pobreza_fh   = se,
      cv_pobreza_fh   = cv
    ) %>%
    arrange(sexo, secc)
  
  list(Res_Ingreso = Res_Ingreso, Res_Pobreza = Res_Pobreza)
}
