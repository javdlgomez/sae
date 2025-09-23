suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(scales)
  library(tidyr)
  library(forcats)
})

#--- Path #--- 
ruta_h <- "pobreza_plugin_hombres_por_secc.csv"
ruta_m <- "pobreza_plugin_mujeres_por_secc.csv"
ruta_c <- "pobreza_plugin_comparacion_secc.csv"

#--- output #--- 
dir.create("plots", showWarnings = FALSE)

#--- Lectura #---
tab_h <- read_csv(ruta_h, show_col_types = FALSE)
tab_m <- read_csv(ruta_m, show_col_types = FALSE)
cmp   <- read_csv(ruta_c, show_col_types = FALSE)

tab_h <- tab_h %>% mutate(secc = factor(secc))
tab_m <- tab_m %>% mutate(secc = factor(secc))
cmp   <- cmp   %>% mutate(secc = factor(secc))

#============================
# 1) Barras: TOP 15 por % H
#============================
top_n <- 15

p_h <- tab_h %>%
  arrange(desc(pct_h)) %>%
  slice_head(n = top_n) %>%
  mutate(secc = fct_reorder(secc, pct_h)) %>%
  ggplot(aes(x = secc, y = pct_h)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(title = "Top 15 secciones por % de pobreza (Hombres, SYN)",
       x = "secc", y = "% pobreza (H)") 

ggsave("plots/top15_pct_h.png", p_h, width = 7, height = 6, dpi = 150)

#============================
# 2) Barras: TOP 15 por % M
#============================
p_m <- tab_m %>%
  arrange(desc(pct_m)) %>%
  slice_head(n = top_n) %>%
  mutate(secc = fct_reorder(secc, pct_m)) %>%
  ggplot(aes(x = secc, y = pct_m)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(title = "Top 15 secciones por % de pobreza (Mujeres, SYN)",
       x = "secc", y = "% pobreza (M)")

ggsave("plots/top15_pct_m.png", p_m, width = 7, height = 6, dpi = 150)

#============================
# 3) Brecha: barras ordenadas
#============================
p_gap <- cmp %>%
  mutate(secc = fct_reorder(secc, dif_pp_menos_h)) %>%
  ggplot(aes(x = secc, y = dif_pp_menos_h)) +
  geom_col() +
  coord_flip() +
  labs(title = "Brecha por sección (M y H) en puntos porcentuales",
       x = "secc", y = "pp (M y H)")

ggsave("plots/brecha_pp_por_secc.png", p_gap, width = 7, height = 6, dpi = 150)

#============================
# 4) Dispersión H vs M
#============================
p_scatter <- cmp %>%
  ggplot(aes(x = pct_h, y = pct_m)) +
  geom_point(alpha = 0.8) +
  geom_abline(slope = 1, intercept = 0, linetype = 2) +
  scale_x_continuous(labels = label_percent(scale = 1)) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(title = "H vs M: % de pobreza por sección (SYN)",
       x = "% H", y = "% M")

ggsave("plots/scatter_h_vs_m.png", p_scatter, width = 6.5, height = 6, dpi = 150)

#============================
# 5) Distribución de % y brechas
#============================
p_hist_h <- ggplot(tab_h, aes(x = pct_h)) +
  geom_histogram(bins = 20) +
  scale_x_continuous(labels = label_percent(scale = 1)) +
  labs(title = "Distribución del % de pobreza (H)", x = "% H", y = "Frecuencia")

p_hist_m <- ggplot(tab_m, aes(x = pct_m)) +
  geom_histogram(bins = 20) +
  scale_x_continuous(labels = label_percent(scale = 1)) +
  labs(title = "Distribución del % de pobreza (M)", x = "% M", y = "Frecuencia")

p_hist_gap <- ggplot(cmp, aes(x = dif_pp_menos_h)) +
  geom_histogram(bins = 20) +
  labs(title = "Distribución de brechas (M – H) en pp",
       x = "pp (M – H)", y = "Frecuencia")

ggsave("plots/hist_pct_h.png", p_hist_h, width = 6.5, height = 5, dpi = 150)
ggsave("plots/hist_pct_m.png", p_hist_m, width = 6.5, height = 5, dpi = 150)
ggsave("plots/hist_brecha.png", p_hist_gap, width = 6.5, height = 5, dpi = 150)

#============================
# 6) Resumen estadístico (CSV)
#============================
resumen <- tibble(
  indicador = c("H_media","H_min","H_max","M_media","M_min","M_max","gap_media","gap_min","gap_max"),
  valor = c(
    mean(tab_h$pct_h, na.rm = TRUE),
    min(tab_h$pct_h, na.rm = TRUE),
    max(tab_h$pct_h, na.rm = TRUE),
    mean(tab_m$pct_m, na.rm = TRUE),
    min(tab_m$pct_m, na.rm = TRUE),
    max(tab_m$pct_m, na.rm = TRUE),
    mean(cmp$dif_pp_menos_h, na.rm = TRUE),
    min(cmp$dif_pp_menos_h, na.rm = TRUE),
    max(cmp$dif_pp_menos_h, na.rm = TRUE)
  )
)

write_csv(resumen, "plots/resumen.csv")

cat("Listo. Gráficos en carpeta 'plots/'.\n")
