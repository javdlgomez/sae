## Limpiar la memoria y cargue de librer�as
rm(list = ls())
options(digits = 2)

library(emdi)
library(dplyr)

## El ejercicio inicia con la definici�n del directorio 


## Se procede al cargue  de las bases de datos
load("CensoH.RData")
load("CensoM.RData")
SamH<- readRDS("SamH.RDS")
SamM<- readRDS("SamM.RDS")

## Una vez cargadas las bases de datos, primero, se har�n todas las predicciones 
## pedidas para los hombres. Posteriormente, se realizar� para las mujeres.

# HOMBRE ------------------------------------------

## Generando la informaci�n auxiliar para los hombres

# X <- cbind.data.frame(CensoH$secc, 1, CensoH$condacto,
#                       CensoH$condactc, CensoH$condactj,
#                       CensoH$alfasi)

## Ajuste del modelo.

modelo_EBP_H<- ebp(ing  ~ condacto + condactc + condactj + alfasi, 
                   pop_data = CensoH,
                   pop_domains = "secc", smp_data = SamH, smp_domains = "secc", 
                   na.rm = TRUE, MSE = T, B = 2, transformation = "log", 
                   threshold = 3182)

## Generaci�n de los indicadores

#Ingreso medio
Ing<- estimators(modelo_EBP_H, MSE = T, indicator = "Mean" ) %>% as.data.frame()
#Porcentaje de pobres FGT alpha = 0
HC<- estimators(modelo_EBP_H, MSE = T, indicator = "Head_Count" ) %>% as.data.frame()
#Porcentaje de pobres FGT alpha = 1
PG<- estimators(modelo_EBP_H, MSE = T, indicator = "Poverty_Gap" ) %>% as.data.frame()
#Gini
Gi<- estimators(modelo_EBP_H, MSE = T, indicator = "Gini" ) %>% as.data.frame()
BHF_H<- full_join(full_join(full_join(Ing, HC), PG), Gi)

# Mujer ------------------------------------------


## Ajuste del modelo.

modelo_EBP_M<- ebp(ing ~ condacto + condactc + condactj+ alfasi, 
                   pop_data = CensoM,
                   pop_domains = "secc", smp_data = SamM, smp_domains = "secc", 
                   na.rm = TRUE, MSE = T, B = 5,
                   transformation = "log", 
                   threshold = 3182)

## Generaci�n de los indicadores

#Ingreso medio
Ing<- estimators(modelo_EBP_M, MSE = T, indicator = "Mean" ) %>% as.data.frame()
#Porcentaje de pobres FGT alpha = 0
HC<- estimators(modelo_EBP_M, MSE = T, indicator = "Head_Count" )%>% as.data.frame()
#Porcentaje de pobres FGT alpha = 1
PG<- estimators(modelo_EBP_M, MSE = T, indicator = "Poverty_Gap" )%>% as.data.frame()
#Gini
Gi<- estimators(modelo_EBP_M, MSE = T, indicator = "Gini" )%>% as.data.frame()

BHF_M<- full_join(full_join(full_join(Ing, HC), PG), Gi)


# === Exportar archivos requeridos para mapas ===
# (usa ; como separador y , como separador decimal)

dir.create("output", showWarnings = FALSE)

# CSV principales en el directorio de trabajo (compatibles con read.csv(..., sep=";", dec=","))
write.csv2(BHF_H, file = "BHF_H.csv", row.names = FALSE)
write.csv2(BHF_M, file = "BHF_M.csv", row.names = FALSE)

# (opcional) duplicados ordenados en /output
write.csv2(BHF_H, file = "output/BHF_H.csv", row.names = FALSE)
write.csv2(BHF_M, file = "output/BHF_M.csv", row.names = FALSE)

# (opcional) versiones RDS para uso interno
saveRDS(BHF_H, "output/BHF_H.rds")
saveRDS(BHF_M, "output/BHF_M.rds")

