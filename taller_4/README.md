# README — Taller de SAE (Montevideo)

## 1) ¿Qué es este repo?
Este trabajo genera **indicadores por sección censal de Montevideo** y los **mapas** solicitados en la tarea (Talleres 1, 2 y 3):  
- EBP/“BHF” (Mean, Head_Count, Poverty_Gap, Gini)  
- Fay–Herriot (EBLUP de ingreso y pobreza + sus ECM/MSE)  
- GLMM binomial para pobreza  
- Mapas para **hombres (H)**, **mujeres (M)** y **diferencias H–M** (cuando aplica)

Además, incluye un **PDF con todos los mapas** y un **Excel** con los indicadores consolidados.

---

## 2) Estructura de carpetas

```
.
├── creacion_datos/            # (opcional) insumos intermedios
├── output/
│   ├── maps/                  # PNG de todos los mapas listos para el informe
│   │   ├── BHF_Gini_H.png
│   │   ├── BHF_Gini_M.png
│   │   ├── BHF_Gini_Dif_HM.png
│   │   ├── BHF_Head_Count_H.png
│   │   ├── BHF_Head_Count_M.png
│   │   ├── BHF_Head_Count_Dif_HM.png
│   │   ├── BHF_Mean_H.png
│   │   ├── BHF_Mean_M.png
│   │   ├── BHF_Mean_Dif_HM.png
│   │   ├── BHF_Poverty_Gap_H.png
│   │   ├── BHF_Poverty_Gap_M.png
│   │   ├── BHF_Poverty_Gap_Dif_HM.png
│   │   ├── FH_Eblup_Ing_H_H.png
│   │   ├── FH_Eblup_Ing_M_M.png
│   │   ├── FH_Eblup_Pobre_H_H.png
│   │   ├── FH_Eblup_Pobre_M_M.png
│   │   ├── GLMM_Pobreza_H.png
│   │   └── GLMM_Pobreza_M.png
│   ├── BHF_H.csv              # EBP (hombres)
│   ├── BHF_H.rds
│   ├── BHF_M.csv              # EBP (mujeres)
│   ├── BHF_M.rds
│   ├── GLMM_Pobreza_H.csv     # Pobreza GLMM por secc (H)
│   ├── GLMM_Pobreza_H.rds
│   ├── GLMM_Pobreza_M.csv     # Pobreza GLMM por secc (M)
│   ├── GLMM_Pobreza_M.rds
│   ├── indicadores_montevideo.xlsx  # indicadores consolidados
│   └── mapas_montevideo.pdf         # informe con todos los mapas
└── taller_4.R                 # script principal para correr todo
```

> Si tu árbol difiere, ajusta las rutas en el script o mueve los archivos a `output/` y `output/maps/`.

---

## 3) Datos de entrada esperados

- **Shapefile de secciones**: `ine_seccen.shp` (+ .dbf/.shx/.prj) con atributos `NOMBDEPTO` y `SECCION`.  
- **Resultados de estimación**:  
  - `output/BHF_H.csv`, `output/BHF_M.csv` con columnas:
    - `Domain` (id de sección como texto),  
    - `Mean`, `Mean_MSE`,  
    - `Head_Count`, `Head_Count_MSE`,  
    - `Poverty_Gap`, `Poverty_Gap_MSE`,  
    - `Gini`, `Gini_MSE`.
  - `output/GLMM_Pobreza_H.csv`, `output/GLMM_Pobreza_M.csv` con columnas:  
    - `secc` (código de sección, numérico o texto), `Pobreza`.

> Estos archivos ya están en `output/`. Si rehaces el cálculo, el script vuelve a escribirlos.

---

## 4) Cómo reproducir

1. Abre R/RStudio en la carpeta raíz del proyecto.  
2. Instala paquetes (primera vez):
   ```r
   pkgs <- c("sf","dplyr","readr","readxl","ggplot2","scales","stringr")
   inst <- pkgs[!pkgs %in% installed.packages()[,"Package"]]
   if (length(inst)) install.packages(inst)
   ```
3. Ejecuta el script principal:
   ```r
   source("taller_4.R")
   ```
   Esto:
   - lee `ine_seccen.*` y filtra **Montevideo**,
   - carga `output/BHF_*.csv` y `output/GLMM_*.csv`,
   - armoniza IDs (`SECCION` ↔ `Domain`/`secc`),
   - genera todos los **mapas PNG** en `output/maps/`,
   - exporta **`indicadores_montevideo.xlsx`**,
   - arma el **PDF `mapas_montevideo.pdf`** con todas las figuras.

---

## 5) Indicadores y definiciones

- **Mean**: ingreso medio EBP por sección.  
- **Head_Count (FGT α=0)**: incidencia de pobreza.  
- **Poverty_Gap (FGT α=1)**: brecha promedio de pobreza.  
- **Gini**: desigualdad de ingreso intra-sección.  
- **FH EBLUP**: estimaciones Fay–Herriot para ingreso/pobreza.  
- **GLMM Pobreza**: probabilidad estimada de pobreza (modelo logístico con intercepto aleatorio por sección).  

> Todos los indicadores se reportan por **sección censal**, y donde aplica, por **sexo** (H y M) y **diferencia H–M**.

---

## 6) Contenidos del PDF `output/mapas_montevideo.pdf`

El documento reúne los mapas en este orden:

1. **EBP (BHF) — Hombres**: Mean, Head_Count, Poverty_Gap, Gini.  
2. **EBP (BHF) — Mujeres**: Mean, Head_Count, Poverty_Gap, Gini.  
3. **Diferencias H–M**: Mean, Head_Count, Poverty_Gap, Gini.  
4. **Fay–Herriot**: Eblup_Ing_H, Eblup_Ing_M, Eblup_Pobre_H, Eblup_Pobre_M.  
5. **GLMM Pobreza**: Hombres y Mujeres.

Cada figura utiliza una escala continua y una leyenda clara; las diferencias H–M usan paleta **divergente** (azul-rojo).

---

## 7) Excel de entrega

- **`output/indicadores_montevideo.xlsx`**:  
  - Hoja **`BHF_H`**: indicadores EBP hombres.  
  - Hoja **`BHF_M`**: indicadores EBP mujeres.  
  - Hoja **`Diff_HM`**: diferencias H–M (Mean, Head_Count, Poverty_Gap, Gini).  
  - Hoja **`FH`**: EBLUP ingreso/pobreza por sexo (si se incluyen).  
  - Hoja **`GLMM`**: pobreza GLMM por sexo.

> Si alguna hoja no aplica en tu corrida, el script deja solo las disponibles.

---

## 8) Conclusiones sugeridas (para el informe)

- **Patrones espaciales**: las secciones costeras del sur concentran **ingresos medios más altos**, con **menor incidencia y brecha de pobreza**.  
- **H vs M**: las **diferencias H–M** son **moderadas** en la mayoría de las secciones; localiza en los mapas divergentes dónde se concentran.  
- **Coherencia entre métodos**: EBP, FH y GLMM muestran **gradientes consistentes**, reforzando la validez de los resultados.

> Ajusta o amplía estas conclusiones con observaciones de tu corrida (ej. valores atípicos, secciones con MSE altos, etc.).

---

## 9) Problemas comunes

- **Unión shapefile–indicadores**: asegúrate de que `SECCION` (shp) y `Domain`/`secc` (tablas) tengan el **mismo tipo** (`character`) y el **mismo formato** (sin ceros a la izquierda perdidos).  
- **Leyendas “raras”**: si hay valores extremos, prueba con escalas recortadas o transformaciones log.  
- **Fuentes del shapefile**: deben estar todos los archivos auxiliares (`.dbf`, `.shx`, `.prj`).

---

## 10) Entregables a subir a Moodle

- `output/mapas_montevideo.pdf` (mapas)  
- `output/indicadores_montevideo.xlsx` (tabla de indicadores)  
- Este **README.md** (resumen y guía de reproducción)

---

### Contacto
Si otro compañero corre el proyecto, basta con colocar sus resultados en `output/` y ejecutar `taller_4.R` para regenerar mapas y el PDF.

