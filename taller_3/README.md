# Taller 3  Estimación de pobreza plugin

## Objetivo
Estimar el porcentaje de pobreza por sección (`secc`) en Montevideo usando un modelo logístico con intercepto aleatorio por sección, ajustado por sexo.  
**plug-in (SYN)** con **efectos fijos** (`re.form=~0`).

---

## Modelo
Para cada sexo:

\[
\text{logit}\{P(\text{pobreza}=1)\} = \beta_0 + \beta_1 \cdot \widetilde{\text{edad}} + \beta_2 \cdot \widetilde{\text{anoest}} + u_{\text{secc}},\quad u_{\text{secc}}\sim \mathcal{N}(0,\sigma^2)
\]

- Las covariables se estandarizan con medias y desviaciones de la **muestra**.  
- La predicción en el censo se hace **sin efectos aleatorios**.  
- Se promedian probabilidades predichas por sección.  

---

## Resultados estadísticos

| Indicador              | Valor (%) |
|-------------------------|-----------|
| Media Hombres           | 1.52 |
| Mín Hombres             | 1.12 |
| Máx Hombres             | 2.08 |
| Media Mujeres           | 1.40 |
| Mín Mujeres             | 1.01 |
| Máx Mujeres             | 1.98 |
| Brecha media M/H      | –0.13 |
| Brecha mínima M/)     | –0.17 |
| Brecha máxima M/H     | –0.02 |

**Hallazgos:**
- Las tasas de pobreza predicha se ubican en un rango de 1–2%.  
- Hombres muestran valores levemente superiores en promedio.  
- En todas las secciones, la pobreza predicha en mujeres es igual o menor que en hombres. 

---

## Gráficas

1. **Top 15 secciones por % de pobreza**  
   - `plots/top15_pct_h.png` Hombres
   - `plots/top15_pct_m.png` Mujeres  

2. **Distribución del % de pobreza**  
   - `plots/hist_pct_h.png` Hombres 
   - `plots/hist_pct_m.png` Mujeres  

3. **Comparación H vs M**  
   - `plots/scatter_h_vs_m.png` 

4. **Brechas por sección (M–H en pp)**  
   - `plots/brecha_pp_por_secc.png` Barras  
   - `plots/hist_brecha.png`  Histograma

---

## Conclusiones
- El estimador plug-in SYN suaviza las estimaciones y limita la variabilidad entre secciones.  
- La pobreza predicha es estable en todos los dominios. 
- Se observan **brechas sistemáticas negativas**.  
- El análisis ilustra cómo el SYN refleja principalmente diferencias asociadas a las covariables edad y años de estudio, más que a variación contextual por sección.  

---

## Datos
- **Muestras:** `SamH.RDS` (Hombres), `SamM.RDS` (Mujeres)  
- **Censos:** `CensoH.RData` (Hombres), `CensoM.RData` (Mujeres)  

**Variables clave**
- Respuesta:  
  - Hombres → `pobreza_Ind`  
  - Mujeres → `pobreza`  
- Covariables: `edad`, `anoest`  
- Dominio: `secc`  



