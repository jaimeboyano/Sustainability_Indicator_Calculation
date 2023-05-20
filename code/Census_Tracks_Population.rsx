##Calculo Indicadores=group
##QgsProcessingParameterFile|INPUT|Input table
##Shapefile_Seccen=vector
##Municipio=string
##Output=output vector

library(readxl)
library(dplyr)

Censo <- read_excel(INPUT)
CCAA <- unique(Censo$ccaa)

Secciones_CCAA <- Shapefile_Seccen[Shapefile_Seccen$CCA == CCAA, ]
Secciones_CCAA$NMUN <- iconv(Secciones_CCAA$NMUN, from = "UTF-8", to = "ASCII//TRANSLIT")
Secciones_CCAA$NMUN <- toupper(Secciones_CCAA$NMUN)

municipios <- strsplit(Municipio, "[,;.]")[[1]]
municipios <- trimws(municipios)
lista_output <- vector("list", length(municipios))

for (i in 1:length(municipios)) {
  municipio <- chartr("áéíóúÁÉÍÓÚ", "aeiouAEIOU", municipios[i])
  municipio <- toupper(municipio)
  Secciones_Municipio <- Secciones_CCAA[Secciones_CCAA$NMUN == municipio, ]
  Censo$CUSEC <- paste0(Censo$cpro, Censo$cmun, Censo$dist, Censo$secc)
  join <- left_join(Secciones_Municipio, Censo, by = 'CUSEC')
  lista_output[[i]] <- join
}

Output <- do.call(rbind, lista_output)
