# Informe – Estimación de áreas (Fay–Herriot)

Este repositorio contiene los resultados del ejercicio de estimación de áreas por sección y sexo, utilizando estimadores directos de Horvitz–Thompson y el modelo de área **Fay–Herriot (REML)**.

## Datos y productos

- Fuentes de entrada: muestras `SamH.RDS`, `SamM.RDS` y censos `CensoH.RData`, `CensoM.RData`.

- Auxiliares a nivel de sección: promedios de `condacto`, `condactc`, `condactj`, `alfasi`.

- Salidas clave (carpeta `output/`):

  - `FH_ingreso_por_seccion_HM.csv` / `FH_pobreza_por_seccion_HM.csv`: tabulados finales (directo vs FH).

  - `FH_eblup_mse_ingreso.csv` / `FH_eblup_mse_pobreza.csv`: EBLUP, MSE, SE y CV del modelo.

  - `FH_betas_ingreso.csv` / `FH_betas_pobreza.csv`: coeficientes del modelo.

  - `report_tables.xlsx`: todas las tablas curadas para el reporte.

## Metodología (resumen)

1. **Estimación directa** por sección (HT) con diseño simple por pesos (`factorex`).

2. **Modelo Fay–Herriot** por sexo y variable (`ingreso`, `pobreza`) con auxiliares censales.

3. Generación de **EBLUP** y **MSE**; comparación con varianza del directo y C.V. resultante.

## Resultados agregados por sexo

| Sexo | Variable | N Secciones | CV Directo (Mediana %) | CV FH (Mediana %) | % Secciones con MSE(FH) < Var(Directo) |
| --- | --- | --- | --- | --- | --- |
| H | Ingreso | 25.000 | 4.098 | 4.073 | 1.000 |
| M | Ingreso | 25.000 | 3.748 | 3.749 | 1.000 |
| H | Pobreza | 22.000 | 40.211 | 37.898 | 1.000 |
| M | Pobreza | 19.000 | 15.332 | 14.136 | 1.000 |


**Lectura rápida:** En ingreso, el C.V. mediano se mantiene prácticamente igual pero el MSE mejora en **100%** de las secciones; en pobreza, el C.V. mediano baja y también el MSE mejora en **100%** de los casos.

## Comparación H vs M (EBLUP)

**Ingreso** – resumen por sección (H−M):

| N Secciones | Proporción H > M | Diferencia promedio | Diferencia mediana | Proporción |z|>1.96 |
| --- | --- | --- | --- | --- |
| 25 | 0.960 | 1,905.747 | 1,166.346 | 0.200 |


**Pobreza** – resumen por sección (H−M):

| N Secciones | Proporción H > M | Diferencia promedio | Diferencia mediana | Proporción |z|>1.96 |
| --- | --- | --- | --- | --- |
| 18 | 0.555556 | 0.000302 | 0.000696 | 0.000000 |


## Top/Bottom por sección (FH)

**Ingreso – Top 10 por EBLUP**

| Sexo | Sección | Ingreso FH | CV FH (%) |
| --- | --- | --- | --- |
| H | 18 | 38,237.489 | 2.933 |
| H | 24 | 29,745.424 | 3.412 |
| H | 15 | 28,805.620 | 4.869 |
| H | 6 | 28,744.329 | 7.965 |
| H | 23 | 28,042.471 | 6.170 |
| H | 7 | 24,951.781 | 6.240 |
| H | 10 | 24,573.663 | 2.534 |
| H | 4 | 24,551.732 | 8.944 |
| H | 5 | 23,046.491 | 7.702 |
| H | 14 | 22,692.003 | 4.442 |


**Ingreso – Bottom 10 por EBLUP**

| Sexo | Sección | Ingreso FH | CV FH (%) |
| --- | --- | --- | --- |
| H | 17 | 8,762.646 | 2.749 |
| H | 16 | 8,839.645 | 4.073 |
| H | 99 | 10,237.492 | 3.517 |
| H | 13 | 10,891.520 | 2.993 |
| H | 11 | 11,091.858 | 2.835 |
| H | 21 | 11,180.330 | 3.244 |
| H | 9 | 11,521.899 | 3.766 |
| H | 20 | 13,532.389 | 3.660 |
| H | 22 | 15,432.824 | 4.044 |
| H | 3 | 16,801.307 | 11.771 |


**Pobreza – Top 10 por EBLUP**

| Sexo | Sección | Pobreza FH | CV FH (%) |
| --- | --- | --- | --- |
| H | 17 | 0.120384 | 5.921990 |
| H | 13 | 0.112587 | 7.744385 |
| H | 16 | 0.106246 | 7.825353 |
| H | 99 | 0.102777 | 7.723170 |
| H | 11 | 0.099205 | 7.270463 |
| H | 20 | 0.064509 | 10.886913 |
| H | 21 | 0.063228 | 9.441878 |
| H | 9 | 0.059939 | 11.078837 |
| H | 22 | 0.056985 | 13.342917 |
| H | 2 | 0.024515 | 51.822145 |


**Pobreza – Bottom 10 por EBLUP**

| Sexo | Sección | Pobreza FH | CV FH (%) |
| --- | --- | --- | --- |
| H | 18 | 0.001666 | 69.373473 |
| H | 24 | 0.002175 | 66.163435 |
| H | 12 | 0.003353 | 52.351827 |
| H | 15 | 0.004928 | 74.353411 |
| H | 4 | 0.006088 | 115.120961 |
| H | 5 | 0.006316 | 96.020807 |
| H | 3 | 0.007080 | 124.079774 |
| H | 23 | 0.007324 | 64.779709 |
| H | 19 | 0.009852 | 46.009673 |
| H | 7 | 0.013403 | 46.310472 |


## Notas e interpretación

- Las mejoras de MSE generalizadas indican **ganancia de precisión** con FH, especialmente en pobreza.

- Las diferencias H–M en ingreso son frecuentes y positivas (H > M), pero solo una fracción resulta **estadísticamente significativa** al 95%.

- En pobreza, las diferencias H–M promedio son **muy pequeñas** y no significativas en conjunto.
