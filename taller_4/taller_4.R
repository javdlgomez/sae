## ===============================================================
## Taller 4 Mapas
## ===============================================================

rm(list = ls())
options(digits = 2)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(readxl)
  library(sf)
  library(ggplot2)
  library(patchwork)
  library(writexl)
  library(png)
  library(grid)
})

## -------------------------- Helpers -------------------------

# Normalizar llaves
normalize_seccion <- function(x) {
  ch <- as.character(x)
  num <- suppressWarnings(as.numeric(ch))
  if (all(!is.na(num))) as.character(as.integer(num)) else ch
}

safe_join_sf <- function(shp_sf, df, by = "SECCION") {
  shp_key <- shp_sf %>% mutate(!!by := normalize_seccion(.data[[by]]))
  df_key  <- df %>% mutate(!!by := normalize_seccion(.data[[by]]))
  attrs <- st_drop_geometry(shp_key) %>% select(all_of(by))
  attrs_join <- left_join(attrs, df_key, by = by)
  left_join(shp_key, attrs_join, by = by)
}

# Mapa ggplot
plot_map <- function(sfobj, value_col, title, fill_lab,
                     palette = c("#deebf7","#3182bd","#08306b")) {
  ggplot(sfobj) +
    geom_sf(aes(fill = .data[[value_col]]), color = "grey30", linewidth = 0.1) +
    scale_fill_gradientn(colors = palette, name = fill_lab) +
    labs(title = title, subtitle = "Montevideo (Secciones)") +
    theme_minimal(base_size = 11) +
    theme(panel.grid = element_blank(),
          legend.position = "right",
          plot.title = element_text(face = "bold"))
}

save_plot <- function(p, filename, w = 8, h = 7) {
  if (!dir.exists("output/maps")) dir.create("output/maps", recursive = TRUE)
  ggsave(filename, p, width = w, height = h, dpi = 300)
}

## -------------------------- CARGA DE DATOS -------------------------

bhf_h <- read_delim("BHF_H.csv", delim = ";", locale = locale(decimal_mark = ","), show_col_types = FALSE)
bhf_m <- read_delim("BHF_M.csv", delim = ";", locale = locale(decimal_mark = ","), show_col_types = FALSE)
fh_h  <- read_excel("FH_H.xlsx")
fh_m  <- read_excel("FH_M.xlsx")
glmm_h <- read_delim("GLMM_Pobreza_H.csv", delim = ";", locale = locale(decimal_mark = ","), show_col_types = FALSE)
glmm_m <- read_delim("GLMM_Pobreza_M.csv", delim = ";", locale = locale(decimal_mark = ","), show_col_types = FALSE)

## -------------------------- SHAPEFILE -------------------------

shp <- read_sf("ine_seccen.shp")
shp_mvd <- shp %>%
  filter(NOMBDEPTO == "MONTEVIDEO") %>%
  mutate(SECCION = normalize_seccion(SECCION)) %>%
  select(SECCION, geometry)

## -------------------------- BHF -------------------------

join_bhf <- function(df, value_col) {
  df2 <- df %>%
    rename(SECCION = Domain) %>%
    mutate(SECCION = normalize_seccion(SECCION)) %>%
    select(SECCION, !!sym(value_col))
  safe_join_sf(shp_mvd, df2, by = "SECCION")
}

indicadores_bhf <- list(
  Mean         = "Ingreso medio (Mean)",
  Head_Count   = "FGT0 (Head Count)",
  Poverty_Gap  = "FGT1 (Poverty Gap)",
  Gini         = "Gini"
)

for (col in names(indicadores_bhf)) {
  nom <- indicadores_bhf[[col]]
  
  shp_H <- join_bhf(bhf_h, col)
  shp_M <- join_bhf(bhf_m, col)
  
  pH <- plot_map(shp_H, col, paste0(nom, " — Hombres (BHF)"), nom)
  save_plot(pH, paste0("output/maps/BHF_", col, "_H.png"))
  
  pM <- plot_map(shp_M, col, paste0(nom, " — Mujeres (BHF)"), nom)
  save_plot(pM, paste0("output/maps/BHF_", col, "_M.png"))
  
  dif <- bhf_h %>%
    inner_join(bhf_m, by = "Domain", suffix = c("_H", "_M")) %>%
    mutate(SECCION = normalize_seccion(Domain),
           Dif = .data[[paste0(col, "_H")]] - .data[[paste0(col, "_M")]]) %>%
    select(SECCION, Dif)
  shp_Dif <- safe_join_sf(shp_mvd, dif, by = "SECCION")
  pD <- plot_map(shp_Dif, "Dif", paste0(nom, " — Diferencia H–M (BHF)"), "H - M",
                 palette = c("#67000d","#fb6a4a","#fcae91","#fee5d9",
                             "#deebf7","#9ecae1","#3182bd","#08519c"))
  save_plot(pD, paste0("output/maps/BHF_", col, "_Dif_HM.png"))
}

## -------------------------- FH -------------------------

fh_h <- fh_h %>%
  rename(SECCION = Dominio) %>%
  mutate(SECCION = normalize_seccion(SECCION))
fh_m <- fh_m %>%
  rename(SECCION = Dominio) %>%
  mutate(SECCION = normalize_seccion(SECCION))

fh_join_plot <- function(df, col, title, tag) {
  shp_fh <- safe_join_sf(shp_mvd, df %>% select(SECCION, !!sym(col)), by = "SECCION")
  p <- plot_map(shp_fh, col, title, tag)
  save_plot(p, paste0("output/maps/FH_", col, "_", tag, ".png"))
}

fh_join_plot(fh_h, "Eblup_Ing_H", "FH — Ingreso (Hombres)", "H")
fh_join_plot(fh_h, "Eblup_Pobre_H", "FH — Pobreza (Hombres)", "H")
fh_join_plot(fh_m, "Eblup_Ing_M", "FH — Ingreso (Mujeres)", "M")
fh_join_plot(fh_m, "Eblup_Pobre_M", "FH — Pobreza (Mujeres)", "M")

## -------------------------- GLMM -------------------------

glmm_h <- glmm_h %>% rename(SECCION = secc) %>% mutate(SECCION = normalize_seccion(SECCION))
glmm_m <- glmm_m %>% rename(SECCION = secc) %>% mutate(SECCION = normalize_seccion(SECCION))

shp_glmm_H <- safe_join_sf(shp_mvd, glmm_h %>% select(SECCION, Pobreza), by = "SECCION")
p_glmm_H <- plot_map(shp_glmm_H, "Pobreza", "GLMM — Pobreza (Hombres)", "Pobreza (H)")
save_plot(p_glmm_H, "output/maps/GLMM_Pobreza_H.png")

shp_glmm_M <- safe_join_sf(shp_mvd, glmm_m %>% select(SECCION, Pobreza), by = "SECCION")
p_glmm_M <- plot_map(shp_glmm_M, "Pobreza", "GLMM — Pobreza (Mujeres)", "Pobreza (M)")
save_plot(p_glmm_M, "output/maps/GLMM_Pobreza_M.png")

## -------------------------- EXPORTACIÓN -------------------------

if (!dir.exists("output")) dir.create("output")

write_xlsx(list(
  BHF_H = bhf_h,
  BHF_M = bhf_m,
  FH_H = fh_h,
  FH_M = fh_m,
  GLMM_H = glmm_h,
  GLMM_M = glmm_m
), "output/indicadores_montevideo.xlsx")

pngs <- list.files("output/maps", full.names = TRUE, pattern = "\\.png$")
pdf("output/mapas_montevideo.pdf", width = 10, height = 8)
for (f in sort(pngs)) {
  grid.newpage()
  img <- png::readPNG(f)
  grid.raster(img)
  grid.text(basename(f), x = 0.02, y = 0.02, just = c("left","bottom"),
            gp = gpar(col = "grey30", cex = 0.7))
}
dev.off()

cat("\n✔ Listo.\n- PNGs: output/maps/\n- Excel: output/indicadores_montevideo.xlsx\n- PDF: output/mapas_montevideo.pdf\n")
