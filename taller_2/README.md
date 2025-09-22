# Taller 2 – Estimación por EBP

Este informe presenta los resultados del ajuste de modelos **Empirical Best Predictor** por sexo utilizando datos de muestra y censo auxiliar. Se incluyen los pasos de preprocesamiento, estimaciones de parámetros, indicadores de pobreza y desigualdad, y la comparación entre sexos.

---

## Preprocesamiento de ingresos

Durante la revisión de las muestras se detectaron ingresos no positivos, por lo que se aplicó un **corrimiento mínimo positivo** tanto a los ingresos como a la línea de pobreza, garantizando:

- Que todos los ingresos sean positivos. 
- Que las medidas de pobreza FGT0, FGT1 se mantengan invariantes, al correrse simultáneamente el umbral de pobreza.  

### Diagnóstico

| Grupo    | Observaciones totales | Ingresos ≤ 0 | Ingreso positivo mínimo | Corrimiento aplicado | Línea base | Línea ajustada |
|----------|-----------------------|--------------|-------------------------|----------------------|------------|----------------|
| Hombres  | 22,464                | 14           | 500                     | 250                  | 3182       | 3432           |
| Mujeres  | 26,233                | 8            | 200                     | 100                  | 3182       | 3282           |

### Interpretación

- El corrimiento es de 200 unidades, que es pequeño comparado con los ingresos medios que son mayores a 8000.  
- Al aplicarlo también sobre la línea de pobreza, los indicadores FGT0 y FGT1 **son invariantes**.  
- El índice de Gini y la media pueden variar levemente, pero el impacto es mínimo y esto debe realizarse para garantizar la validez del modelo.  

---

## Resultados del modelo en Hombres


### Coeficientes principales head 10

| Parámetro      | Estimación |
|----------------|------------|
| (Intercept)1   | 9.59       |
| (Intercept)2   | 9.39       |
| (Intercept)3   | 8.57       |
| (Intercept)4   | 9.28       |
| (Intercept)5   | 8.53       |
| (Intercept)6   | 9.30       |
| (Intercept)7   | 9.49       |
| (Intercept)8   | 8.61       |
| (Intercept)9   | 8.52       |
| (Intercept)10  | 9.84       |

*(archivo completo en `coeficientes_h.csv`)*

### Interpretación
- Los interceptos estimados por dominio oscilan entre **8.5 y 9.8** en log ingreso.  
- Esto corresponde a niveles medios de ingreso en el rango aproximado de **4,900 a 18,800** al volver a la escala original.  
- Las diferencias entre interceptos reflejan heterogeneidad entre secciones.  

---

## Resultados del modelo en Mujeres


### Coeficientes principales head 10

| Parámetro      | Estimación |
|----------------|------------|
| (Intercept)1   | 9.42       |
| (Intercept)2   | 9.37       |
| (Intercept)3   | 8.56       |
| (Intercept)4   | 9.23       |
| (Intercept)5   | 8.55       |
| (Intercept)6   | 9.30       |
| (Intercept)7   | 9.49       |
| (Intercept)8   | 8.56       |
| (Intercept)9   | 8.50       |
| (Intercept)10  | 9.82       |

*(archivo completo en `coeficientes_m.csv`)*

### Interpretación
- Los interceptos femeninos también se encuentran entre **8.5 y 9.8** en log ingreso.  
- En varios dominios, los valores son menores que los masculinos, lo cual coincide con las diferencias observadas en medias de ingreso.  

---

## Indicadores de pobreza y desigualdad – Hombres

Se calcularon indicadores EBP para **25 secciones**, cada indicador incluye su EMC y CV.

### Resumen de resultados 

| Sección | Media ingreso | FGT0  | FGT1   | Gini          | Cuota quintil         |
|---------|---------------|----------------|---------------|-------|---------------|
| 1       | 26,820        | 0.20 %         | 0.03 %        | 0.343 | 5.88 %        |
| 10      | 21,401        | 0.53 %         | 0.09 %        | 0.346 | 5.99 %        |
| 11       | 9,017        | 10.9 %         | 2.7 %         | 0.348 | 6.06 %        |
| 12      | 19,193        | 0.84 %         | 0.15 %        | 0.345 | 5.96 %        |
| 13       | 8,499        | 12.8 %         | 3.2 %         | 0.348 | 6.08 %        |

*(archivo completo en `indicadores_h.csv`)*

### Interpretación
- Las **medias de ingreso** van desde menos de **9,000** hasta más de **33,000** según la sección.  
- La **incidencia de pobreza** es muy baja en la mayoría de secciones, pero alcanza hasta **~13 %** en zonas vulnerables.  
- La **brecha de pobreza** refleja valores máximos en torno al **3 %**, concentrada en secciones con bajos ingresos.  
- El **índice de Gini** se mantiene estable entre **0.34 y 0.35**, señalando desigualdad relativamente homogénea entre dominios.  
- La **cuota del primer quintil** se sitúa consistentemente cerca de **6 %**, como se espera en quintiles equilibrados.  

---

## Indicadores de pobreza y desigualdad en Mujeres

Se calcularon indicadores EBP para **25 secciones**, cada indicador incluye su EMC y CV.

### Resumen de resultados 

| Sección | Media ingreso | FGT0  | FGT1   | Gini          | Cuota quintil         |
|---------|---------------|----------------|---------------|-------|---------------|
| 1       | 22,723        | 0.32 %         | 0.05 %        | 0.342 | 5.89 %        |
| 10      | 20,895        | 0.47 %         | 0.08 %        | 0.346 | 5.98 %        |
| 11       | 8,747        | 1.77 %         | 2.63 %        | 0.348 | 6.04 %        |
| 12      | 18,587        | 0.97 %         | 0.14 %        | 0.345 | 5.97 %        |
| 13       | 8,588        | 4.08 %         | 2.78 %        | 0.348 | 6.05 %        |

*(archivo completo en `indicadores_m.csv`)*

### Interpretación
- Las **medias de ingreso** femeninas oscilan entre ~8,500 y más de 33,500.  
- En comparación con hombres, algunas secciones muestran **medias menores**.  
- La **incidencia de pobreza** alcanza valores más altos en mujeres en secciones críticas.  
- La **brecha de pobreza** refleja concentraciones importantes en ciertos dominios.  
- Los valores de **Gini** se mantienen entre 0.34 y 0.35, similares a los de hombres.  
- La **cuota del primer quintil** está igualmente alrededor de 6 %.  

---

## Comparación Hombres vs Mujeres

Se generó una tabla de comparación con los indicadores de ambos sexos en las 25 secciones:

- **d_media**: diferencia en ingreso medio.  
- **d_fgt0**: diferencia en incidencia de pobreza.  
- **d_fgt1**: diferencia en brecha de pobreza.  
- **d_gini**: diferencia en desigualdad.  
- **d_quintil**: diferencia en la cuota del quintil más pobre.  

### Ejemplo de resultados (primeras 5 secciones)

| Sección | Δ Media ingreso | Δ Pobreza        | Δ Brecha        | Δ Gini | Δ Cuota quintil |
|---------|-----------------|------------------|-----------------|--------|-----------------|
| 1       | +4,097          | –0.12 %          | –0.02 %         | +0.0003| –0.009 |
| 10      | +506            | +0.06 %          | +0.01 %         | +0.0002| +0.018 |
| 11      | +270            | +0.05 %          | +0.04 %         | –0.0003| +0.014 |
| 12      | +605            | +0.05 %          | +0.01 %         | –0.0002| –0.0005 |
| 13      | –89             | +1.31 %          | +0.42 %         | +0.0000| +0.027 |

*(archivo completo en `comparacion_h_vs_m.csv`)*

### Interpretación
- En la mayoría de secciones, los **hombres presentan ingresos medios más altos** que las mujeres, con diferencias de hasta **~4,000 unidades**. 
- Las diferencias en **Gini** son muy pequeñas.  
- La **cuota del quintil inferior** varía poco, con desviaciones de ±0.03.  

---

## Archivos exportados

- `coeficientes_h.csv` – coeficientes del modelo EBP para hombres.  
- `coeficientes_m.csv` – coeficientes del modelo EBP para mujeres.  
- `indicadores_h.csv` – indicadores de pobreza y desigualdad para hombres.  
- `indicadores_m.csv` – indicadores de pobreza y desigualdad para mujeres.  
- `comparacion_h_vs_m.csv` – comparación de indicadores entre hombres y mujeres.  

---
