# Taller 4 

Se generan **indicadores por sección censal de Montevideo** y los **mapas** de las tareas 1-3.  
Además, incluye un **PDF con todos los mapas** y un **Excel** con los indicadores consolidados.

---

## Estructura de carpetas

```
.
├── creacion_datos/            
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
│   ├── BHF_H.csv              
│   ├── BHF_H.rds
│   ├── BHF_M.csv            
│   ├── BHF_M.rds
│   ├── GLMM_Pobreza_H.csv     
│   ├── GLMM_Pobreza_H.rds
│   ├── GLMM_Pobreza_M.csv     
│   ├── GLMM_Pobreza_M.rds
│   ├── indicadores_montevideo.xlsx 
│   └── mapas_montevideo.pdf         
└── taller_4.R                
```


---

## Indicadores

- **Mean**: ingreso medio EBP por sección.  
- **FGT α=0**: incidencia de pobreza.  
- **FGT α=1**: brecha promedio de pobreza.  
- **Gini**: desigualdad de ingreso intra-sección.  
- **FH EBLUP**: estimaciones Fay Herriot para ingreso y pobreza.  
- **GLMM Pobreza**: probabilidad estimada de pobreza.  

---



## Conclusiones  

- **Diferencias Geográficas**: las secciones costeras del sur concentran ingresos medios más altos, con menor incidencia y brecha de pobreza.  
- **H vs M**: los ingresos medios de los hombres son moderadamente más altos en la mayoría de las secciones.
- **Parsimonía**: EBP, FH y GLMM muestran resultados consistentes, reforzando la validez de los resultados.




