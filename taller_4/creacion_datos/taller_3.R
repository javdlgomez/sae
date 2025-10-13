## Limpiar la memoria y cargue de librer�as
rm(list = ls())
options(digits = 2)

library(sae)
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

## Ajuste del modelo

Pluginreg <- glmer(pobreza_Ind  ~ 1  + edad + anoest +  (1|secc), 
                   family = "binomial",
                   data = SamH)
## Predicciones


res<- predict(Pluginreg, type ="response")
# Cantidad de pobre
sum(res) 
sum(SamH$pobreza_Ind)

CensoH$y_predic<- predict(Pluginreg, newdata = CensoH,type ="response")

Pobreza_Dom<- CensoH %>% group_by(secc) %>% 
  summarise(Pobreza = mean(y_predic)) %>% 
  as.data.frame()

# === Exportar resultados HOMBRES ===
dir.create("output", showWarnings = FALSE)
write.csv2(Pobreza_Dom, file = "GLMM_Pobreza_H.csv", row.names = FALSE)
write.csv2(Pobreza_Dom, file = "output/GLMM_Pobreza_H.csv", row.names = FALSE)
saveRDS(Pobreza_Dom, "output/GLMM_Pobreza_H.rds")

# MUJERES TERMINAR ESTO------------------------------------------

## Ajuste del modelo

Pluginreg <- glmer(pobreza  ~ 1  + edad + anoest +  (1|secc), 
                   family = "binomial",
                   data = SamM)
## Predicciones


res<- predict(Pluginreg, type ="response")
# Cantidad de pobre
sum(res) 
sum(SamM$pobreza)

CensoM$y_predic<- predict(Pluginreg, newdata = CensoM,type ="response")

Pobreza_Dom<- CensoM %>% group_by(secc) %>% 
  summarise(Pobreza = mean(y_predic)) %>% 
  as.data.frame()

# === Exportar resultados MUJERES ===
if (!dir.exists("output")) dir.create("output")
write.csv2(Pobreza_Dom, file = "GLMM_Pobreza_M.csv", row.names = FALSE)
write.csv2(Pobreza_Dom, file = "output/GLMM_Pobreza_M.csv", row.names = FALSE)
saveRDS(Pobreza_Dom, "output/GLMM_Pobreza_M.rds")


