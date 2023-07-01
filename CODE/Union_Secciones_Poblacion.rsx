##Calculo Indicadores=group
##QgsProcessingParameterFile|INPUT|Tabla Poblacion (Excel)
##Shapefile_Seccen=vector
##Municipio=string
##Salida=output vector

#Cargo las librerias necesarias 
library(readxl)
library(dplyr)

read_data_file <- function(INPUT) {
  # Extraemos los últimos caracteres de la extensión del archivo
  file_extension <- substr(INPUT, nchar(INPUT) - 3, nchar(INPUT))

  # Verificamos si el archivo es un CSV
  if (file_extension == ".csv") {
    return(read.csv(INPUT))
  }
  
  # Verificamos si el archivo es un XLSX
  if (file_extension == "xlsx") {
    return(read_xlsx(INPUT))
  }
  
  # Verificamos si el archivo es un XLS
  if (file_extension == ".xls") {
    return(read_excel(INPUT))
  }

  # Si la extensión no coincide, mostramos un mensaje de error
  stop("El archivo no tiene una extensión compatible (.xls, .xlsx, .csv).")
}

#Lee excel, carga los datos del censo y obtiene lista unica
Censo <- read_data_file(INPUT)
CCAA <- unique(Censo$ccaa)

#Filtra las secciones censales de la CCAA y transforma los caracteres en UTF-8 y mayuscula
Secciones_CCAA <- Shapefile_Seccen[Shapefile_Seccen$CCA == CCAA, ]
Secciones_CCAA$NMUN <- iconv(Secciones_CCAA$NMUN, from = "UTF-8", to = "ASCII//TRANSLIT")
Secciones_CCAA$NMUN <- toupper(Secciones_CCAA$NMUN)


#Divide lista de municipios, elimina espacios en  blanco (al comienzo o final)
municipios <- strsplit(Municipio, "[,;.]")[[1]]
municipios <- trimws(municipios)

#Creaa lista para almacenar los nombres de municipios
lista_output <- vector("list", length(municipios))

#Para cada nombre, filtr secciones del municipio y combina los datos 
#censales a la seccion almacena el resultado en una lista

for (i in 1:length(municipios)) {
  municipio <- chartr("áéíóúÁÉÍÓÚ", "aeiouAEIOU", municipios[i])
  municipio <- toupper(municipio)
  Secciones_Municipio <- Secciones_CCAA[Secciones_CCAA$NMUN == municipio, ]
  Censo$CUSEC <- paste0(Censo$cpro, Censo$cmun, Censo$dist, Censo$secc)
  join <- left_join(Secciones_Municipio, Censo, by = 'CUSEC')
  lista_output[[i]] <- join
}

#Combina los resultados almanenados y los muestra
Salida <- do.call(rbind, lista_output)
