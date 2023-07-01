##Calculo Indicadores=group
##Indicadores_a_calcular=enum literal multiple 1. Densidad de viviendas;2. Compacidad Absoluta;3. Equilibrio Residencial;4. Diversidad de Usos;5. Densidad de Poblacion;6.1 Proximidad a Centros Educativos;6.2 Proximidad a Centros Sanitarios;6.3 Proximidad a Centros de Ocio;6.4 Proximidad a Centros Deportivos;6.5 Proximidad a Comercios;6.6 Proximidad a los 5 servicios 6.7
##Extension_Salida=vector
##Clasificacion_Intermedia_Clasificador_Catastral=optional vector
##Capa_Constru_Catastro=optional vector
##Seccion_Censal_con_Poblacion=optional vector
##Municipio=optional string
##Nueva_Carpeta=output folder

#Carga las librerias

library(CatastRo)
library(dplyr)

romanoo_a_arabigo <- function(romano) {
  # Tabla de correspondencia entre valores romanoos y arábigos
  valores_romanoos <- c(1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1)
  letras_romanoos <- c("M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I")
  # Inicializar valor
  valor_arabigo <- 0
  # Mientras queden letras romanoas en la cadena
  while (nchar(romano) > 0) {
    # Comprobar si la primera letra romanoa de la cadena corresponde a un valor
    # en la tabla de correspondencia
    if (substr(romano, 1, 2) %in% letras_romanoos) {
      letter <- substr(romano, 1, 2)
      romano <- substr(romano, 3, nchar(romano))
    } else {
      letter <- substr(romano, 1, 1)
      romano <- substr(romano, 2, nchar(romano))
    }
    # Sumar o restar el valor arábigos correspondiente al valor romanoo
    if (letter %in% letras_romanoos) {
      valor_arabigo <- valor_arabigo + valores_romanoos[which(letras_romanoos == letter)]
    }
  }
  # Devolver valor arábigos
  return(valor_arabigo)
}


#Define funcion para convertir de poligonos a raster de 200 x 200 metros
poligonos_a_raster_200 <- function (shapefile, extention, Columna, fun){
  centroides <- st_centroid(shapefile) #Calcula centroides
  ext <- st_bbox(extention) %>% #Obtiene la extension
    extent()
  grid <- raster(ext, res = c(200, 200)) # Crea raster vacio 
  crs(grid) <- crs(shapefile) #Asigna CRS del shapefile
  col_raster <- subset(centroides, select = Columna) #Extrae columna
  resultado <- raster::rasterize(col_raster, grid, field = col_raster[[1]], match.fun(fun)) #Rasteriza columna
  return(resultado)
}

#Funcion para obtener la interseccion entre capa fuente y buferes
proximidad_equipamientos <- function(shapefile, Uso, distancia){
  poligonos_residenciales <- edificios_join_secciones
  Equipamientos <- subset(shapefile, USO == Uso) #Filtrado por uso
  Bufer_Equipamientos <- st_as_sf(st_union(st_buffer(Equipamientos, distancia))) #Crea buffers
  #Obtengo el raster de la poblacion de dentro de los buferes
  Interseccion_Resi_Equip <- st_intersection(poligonos_residenciales, Bufer_Equipamientos)
  return(Interseccion_Resi_Equip)
}

#Obtencion de la extension del shp
extent <- st_bbox(Extension_Salida) %>%
  extent()
grid_200_rast <- raster(extent, res = c(200, 200)) #crea raster vacio 
grid_200_pol <- st_as_sf(rasterToPolygons(grid_200_rast, dissolve = FALSE)) #Conversion a poligonos
crs_constru <- crs(Extension_Salida) #Asignacion CRS
grid_200 <- st_set_crs(grid_200_pol, crs_constru)
grid_200$ID <- seq(1, nrow(grid_200_pol)) #Asigna ID a cuadricula


#Si se calculan indicadores 1, 3 o cualquiera con 6
if (("1. Densidad de viviendas" %in% Indicadores_a_calcular) ||
    ("3. Equilibrio Residencial" %in% Indicadores_a_calcular) ||
    ("5. Densidad de Poblacion" %in% Indicadores_a_calcular) || grepl("^6", Indicadores_a_calcular))
    #Si no se introduce municipio mostrar error 
    {if (Municipio == '') {
      Edificios <- NULL
      Edificios_interseccion <- NULL
      Num_Viv <- NULL
      print('Es necesario introducir el nombre de un municipio para calcular los indicadores 1, 3, 5 y/o 6')
    } else {
    #Si se introduce municipio o municipios. Creación de una lista
      municipios <- strsplit(Municipio, "[,;.]")[[1]] 
      municipios <- trimws(municipios)
      Edificios <- vector("list", length(municipios))
        # Para cada municipio, eliminar tildes, poner en mayusculas 
        #y obtener codigo y  edificios
      for (i in 1:length(municipios)) {
        municipio <- chartr("áéíóúÁÉÍÓÚ", "aeiouAEIOU", municipios[i])
        municipio <- toupper(municipio)
        informacion_municipios <- catr_atom_search_munic(municipio)
        informacion_municipios$munic <- substring(informacion_municipios$munic, 7)
        informacion_municipios <- informacion_municipios[grepl(paste0("^", municipio, "$"), informacion_municipios$munic, ignore.case = TRUE), ]
        cod_muni <- informacion_municipios$catrcode
        Edificios[[i]] <- catr_atom_get_buildings(cod_muni)
  }
  #Combinacion de todos los edificios de la lista, calculo de area, 
  #Obtencion de interseccion, filtrado de edificios residenciales, area de interseccion
  #Propocion de area de edificio residencial y proporcion de viviendas   
  Edificios <- do.call(rbind, Edificios)
  Edificios$Area_Unido <- round(st_area(Edificios), digits = 4)
  Edificios_interseccion <- st_intersection(Edificios, grid_200)
  Edificios_Residential <- subset(Edificios_interseccion, currentUse == "1_residential")
  Edificios_Residential$Area_interseccion <- round(st_area(Edificios_Residential), digits = 4)
  Edificios_Residential$prop_area <- round(Edificios_Residential$Area_interseccion / Edificios_Residential$Area_Unido, digits = 4)
  Edificios_Residential$Prop_Viv <- Edificios_Residential$prop_area * Edificios_Residential$numberOfDwellings
  Num_Viv <- poligonos_a_raster_200(Edificios_Residential, extent, 'Prop_Viv', 'sum')
  #Eliminacion de viviendas con menos de 1 vivienda  
  Condicion <- Num_Viv >= 1
  Num_Viv_filtered <- Num_Viv
  Num_Viv_filtered[!Condicion] <- NA
}
}

#comprobacion capa constru. Si la hay 
if (!is.null(Capa_Constru_Catastro)) {
  Capa_Constru_Catastro <- st_as_sf(Capa_Constru_Catastro)
  #Calculo del area, la interseccion y el nuevo area  
  Capa_Constru_Catastro$Area_Unido <- round(st_area(Capa_Constru_Catastro), digits = 4)
  Constru_interseccion <- st_intersection(Capa_Constru_Catastro, grid_200)
  Constru_interseccion$Area_M2 <- round(st_area(Constru_interseccion), digits = 4)
} else {
  Capa_Constru_Catastro <- NULL
  Constru_interseccion <- NULL
}

#Comprobacion clasificacion_intermedia_CC. Si la hay area e interseccion
if (!is.null(Clasificacion_Intermedia_Clasificador_Catastral)) {
  Clasificacion_Intermedia_Clasificador_Catastral <- st_as_sf(Clasificacion_Intermedia_Clasificador_Catastral)
  Clasificacion_Intermedia_Clasificador_Catastral$Area_Unido <- round(st_area(Clasificacion_Intermedia_Clasificador_Catastral), digits = 4)
  CC_interseccion <- st_intersection(Clasificacion_Intermedia_Clasificador_Catastral, grid_200)
} else {
  Clasificacion_Intermedia_Clasificador_Catastral <- NULL
  CC_interseccion <- NULL
}


#Si se ha solicitado el indicador 1, se calcula y se guarda
if ("1. Densidad de viviendas" %in% Indicadores_a_calcular && !is.null(Num_Viv)) {
  densidad_viviendas <- Num_Viv/4
  output_raster_path <- file.path(Nueva_Carpeta, 'densidad_viviendas.tif')
  writeRaster(densidad_viviendas, output_raster_path, format = 'GTiff', overwrite = TRUE)
  print("Indicador 1. Densidad de viviendas calculado")
}

#Si se ha solicitado el indicador 2, se limpia la columna y se calculan
#los volumenes y se guarda
if ('2. Compacidad Absoluta' %in% Indicadores_a_calcular) {
  if (!is.null(Constru_interseccion)) { 
    Constru_interseccion$CONSTRU_Edit <- gsub("B|T|Z|TZA|POR|SOP|PJE|MAR|P|CO|EPT|SS|ALT|PI|TEN|ETQ|ZBE|SILO|SUELO|PRG|DEP|ESC|TRF|JD|YJD|FUT|VOL|ZD|RUINA|CONS|ZPAV|GOLF|?", "", Constru_interseccion$CONSTRU)
    Constru_interseccion$CONSTRU_Edit <- gsub(".*\\+", "", Constru_interseccion$CONSTRU_Edit)
    Constru_interseccion$CONSTRU_Edit <- gsub("-.*$", "", Constru_interseccion$CONSTRU_Edit)
    Constru_interseccion$CONSTRU_Edit <- gsub("\\d.*$", "", Constru_interseccion$CONSTRU_Edit)
    Constru_interseccion$CONSTRU_Edit <- gsub("[.?]", "", Constru_interseccion$CONSTRU_Edit)
    Constru_interseccion$CONSTRU_Edit_Arab <- as.numeric(lapply(Constru_interseccion$CONSTRU_Edit, romanoo_a_arabigo))
    Constru_interseccion$Altura <- (Constru_interseccion$CONSTRU_Edit_Arab - 1) * 3 + 4.5
    Constru_interseccion$Vol_M3 <- round((Constru_interseccion$Altura * Constru_interseccion$Area_M2), digits = 4)
    Vol_M3 <- poligonos_a_raster_200(Constru_interseccion, extent, 'Vol_M3', 'sum')
    Compacidad_Absoluta <- Vol_M3/40000
    output_raster_path <- file.path(Nueva_Carpeta, 'Compacidad_Absoluta.tif')
    writeRaster(Compacidad_Absoluta, output_raster_path, format = 'GTiff', overwrite = TRUE)
    print("Indicador 2. Compacidad Absoluta calculado")
  } else {
    print("No se han introducido las capas necesarias para calcular el indicador 2. Compacidad Absoluta")
  }
}

# Si se ha seleccionado el indicador 3. Filtrado de usos sector terciario
# Obtencion del area de servicios, calculo del indicador y guardado

if ("3. Equilibrio Residencial" %in% Indicadores_a_calcular) {
  if (!is.null(Num_Viv) && !is.null(CC_interseccion)) {
    Sector_Servicios <- subset(CC_interseccion, USO %in% c("COM", "EQUIP_OTR", "EQUIP_EDU", "HOS_REST", "OFI", "EQUIP_SANI", "OCIO_ESP"))
    Sector_Servicios$Area_interseccion <- round(st_area(Sector_Servicios), digits = 4)
    Area_Servicios <- poligonos_a_raster_200(Sector_Servicios, extent, "Area_interseccion", "sum")
    Equilibrio_Residencial <- Area_Servicios/Num_Viv_filtered
    output_raster_path <- file.path(Nueva_Carpeta, 'Equilibrio_Residencial.tif')
    writeRaster(Equilibrio_Residencial, output_raster_path, format = 'GTiff', overwrite = TRUE)
    print("Indicador 3. Equilibrio Residencial calculado")
  } else {
    print("No se han introducido las capas necesarias para calcular el indicador 3. Equilibrio residencial")
  }
}


#Si se ha seleccionado el indicador 4
if ("4. Diversidad de Usos" %in% Indicadores_a_calcular) {
  if (!is.null(CC_interseccion)) {
    # cuenta el número de ocurrencias de cada uso del suelo para cada identificador (id) ("individuos")
    Num_Usos <- CC_interseccion %>% 
      group_by(ID, USO) %>% 
      summarize(Count = n()) %>% 
      ungroup()
    
    # calcula el número total de usos del suelo para cada identificador (id) ("individuos totales")
    Total_Usos <- Num_Usos %>% 
      group_by(ID) %>% 
      summarize(Total = sum(Count)) %>% 
      ungroup() %>% 
      st_drop_geometry() # Elimino la geometría para poder unir las tablas
    #Union de tablas 
    Abundancia_Usos <- merge(Num_Usos, Total_Usos, by = "ID")
    Abundancia_Usos$prop <- Abundancia_Usos$Count / Abundancia_Usos$Total
    #Calculo de indice de shannon
    Indice_Shannon <- Abundancia_Usos %>%
      group_by(ID) %>%
      summarize(Shannon = -sum(prop * log(prop)))
    #Guardado del resultado 
    Indice_Shannon_Raster <- poligonos_a_raster_200(Indice_Shannon, extent, 'Shannon', 'sum')
    output_raster_path <- file.path(Nueva_Carpeta, 'complejidad_urbana.tif')
    writeRaster(Indice_Shannon_Raster, output_raster_path, format = 'GTiff', overwrite = TRUE)
    print("Indicador 4. Indice de Shannon (complejidad urbana) Calculado ")
  } else {
    print("No se han introducido las capas necesarias para calcular el indicador 4. Indice de Shannon")
  }
}


#Comprobacion de indicadores 5 y 6 y capasa necesariasl. Si es así calculo de 
#la poblacion por poblacion por edificio y ceacion de raster de poblacion por edificio
if ((("5. Densidad de Poblacion" %in% Indicadores_a_calcular) || grepl("^6", Indicadores_a_calcular)) && !is.null(Seccion_Censal_con_Poblacion)){
  Seccion_Censal_con_Poblacion$Pob_Viv <- round(Seccion_Censal_con_Poblacion$t1_1 / Seccion_Censal_con_Poblacion$t21_1, 4)
  edificios_join_secciones <- st_join(Edificios_Residential, Seccion_Censal_con_Poblacion, join = st_within, left = FALSE)
  edificios_join_secciones$Pob_Edif <- edificios_join_secciones$Pob_Viv * edificios_join_secciones$Prop_Dw
  Edificios_Pob_Raster <- poligonos_a_raster_200(edificios_join_secciones, extent, 'Pob_Edif', 'sum')
} else{
  print("No se ha introducido la capa con las secciones censales de poblacion para calcular los indicadores 5 y 6")
}

#Si se ha seleccionado el indicador 5. Calculo del area urbana y 
#la densidad de poblacion
if ('5. Densidad de Poblacion' %in% Indicadores_a_calcular) { 
  if (!is.null(Seccion_Censal_con_Poblacion) && !is.null(CC_interseccion)&& !is.null(Clasificacion_Intermedia_Clasificador_Catastral)){
    CC_interseccion$Urb_Area <-  round(st_area(CC_interseccion)/10000, digits = 4)
    Urb_Area_Rast <- poligonos_a_raster_200(CC_interseccion, extent, 'Urb_Area', 'sum')
    Dens_Pob <- Edificios_Pob_Raster/Urb_Area_Rast
    output_raster_path <- file.path(Nueva_Carpeta, 'densidad_poblacion.tif')
    writeRaster(Dens_Pob, output_raster_path, format = 'GTiff', overwrite = TRUE)
    print("Indicador 5. Densidad de Poblacion Calculado")
  } else {
    print("No se han introducido las capas necesarias para calcular el indicador 5. Densidad de Poblacion")
  }
}

#Si se ha indicado el 6.1 filtrado por equipamientos, ejecucion de funcion 
#Proximidad equipamientos y guardado. mismo proceso para todos los indicadores
#de proximidad salvo el total
if('6.1 Proximidad a Centros Educativos' %in% Indicadores_a_calcular){
  if (!is.null(CC_interseccion)) {
    if ('EQUIP_EDU' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
      Interseccion_Res_Edu <- proximidad_equipamientos(Clasificacion_Intermedia_Clasificador_Catastral,'EQUIP_EDU', 300)
      Pob_Edu_Raster <- poligonos_a_raster_200(Interseccion_Res_Edu, extent, 'Pob_Edif', 'sum')
      Porc_Pob_Edu <- Pob_Edu_Raster/Edificios_Pob_Raster*100
      output_raster_path <- file.path(Nueva_Carpeta, 'proximidad_educacion.tif')
      writeRaster(Porc_Pob_Edu, output_raster_path, format = 'GTiff', overwrite = TRUE)
      print("Indicador 6.1 Proximidad a Centros Educativos Calculado")
    } else {
      print("El municipio no tiene Centros Educativos")
    }
  } else {
    print("No se han incluido las capas necesarias para calcular el indicador 6.1 Proximidad a Centros Educativos")
  }
}

if('6.2 Proximidad a Centros Sanitarios' %in% Indicadores_a_calcular){
  if (!is.null(CC_interseccion)) {
    if ('EQUIP_SANI' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
      Interseccion_Res_San <- proximidad_equipamientos(Clasificacion_Intermedia_Clasificador_Catastral,'EQUIP_SANI', 600)
      Pob_San_Raster <- poligonos_a_raster_200(Interseccion_Res_San, extent, 'Pob_Edif', 'sum')
      Porc_Pob_Sani <- Pob_San_Raster/Edificios_Pob_Raster*100
      output_raster_path <- file.path(Nueva_Carpeta, 'proximidad_sanitario.tif')
      writeRaster(Porc_Pob_Sani, output_raster_path, format = 'GTiff', overwrite = TRUE)
      print("Indicador 6.2 Proximidad a Centros Sanitarios Calculado")
    } else {
      print("El municipio no tiene Centros Sanitarios")
    }
  } else {
    print("No se han incluido las capas necesarias para calcular el indicador 6.2 Proximidad a Centros Sanitarios")
  }
}



if('6.3 Proximidad a Centros de Ocio' %in% Indicadores_a_calcular){
  if (!is.null(CC_interseccion)) {
    if ('OCIO_ESP' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
      Interseccion_Res_Ocio <- proximidad_equipamientos(Clasificacion_Intermedia_Clasificador_Catastral,'OCIO_ESP', 600)
      Pob_Ocio_Raster <- poligonos_a_raster_200(Interseccion_Res_Ocio, extent, 'Pob_Edif', 'sum')
      Porc_Pob_Ocio <- Pob_Ocio_Raster/Edificios_Pob_Raster*100
      output_raster_path <- file.path(Nueva_Carpeta, 'proximidad_ocio.tif')
      writeRaster(Porc_Pob_Ocio, output_raster_path, format = 'GTiff', overwrite = TRUE)
      print("Indicador 6.4 Proximidad a Centros de Ocio Calculado")
    } else {
      print("El municipio no tiene Centros de Ocio")
    }
  } else {
    print("No se han incluido las capas necesarias para calcular el indicador 6.4 Proximidad a Centros de Ocio")
  }
}

if('6.4 Proximidad a Centros Deportivos' %in% Indicadores_a_calcular){
  if (!is.null(CC_interseccion)) {
    if ('EQUIP_OTR' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
      Interseccion_Res_Dep <- proximidad_equipamientos(Clasificacion_Intermedia_Clasificador_Catastral,'EQUIP_OTR', 600)
      Pob_Dep_Raster <- poligonos_a_raster_200(Interseccion_Res_Dep, extent, 'Pob_Edif', 'sum')
      Porc_Pob_Dep <- Pob_Dep_Raster/Edificios_Pob_Raster*100
      output_raster_path <- file.path(Nueva_Carpeta, 'proximidad_deporte.tif')
      writeRaster(Porc_Pob_Dep, output_raster_path, format = 'GTiff', overwrite = TRUE)
      print("Indicador 6.5 Proximidad a Centros Deportivos Calculado")
    } else {
      print("El municipio no tiene Centros Deportivos")
    }
  } else {
    print("No se han incluido las capas necesarias para calcular el indicador 6.5 Proximidad a Centros Deportivos")
  }
}

if('6.5 Proximidad a Comercios' %in% Indicadores_a_calcular){
  if (!is.null(CC_interseccion)) {
    if ('COM' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
      Interseccion_Res_Com <- proximidad_equipamientos(Clasificacion_Intermedia_Clasificador_Catastral,'COM', 600)
      Pop_Stores_Raster <- poligonos_a_raster_200(Interseccion_Res_Com, extent, 'Pob_Edif', 'sum')
      Porc_Pob_Com <- Pop_Stores_Raster/Edificios_Pob_Raster*100
      output_raster_path <- file.path(Nueva_Carpeta, 'proximidad_comercios.tif')
      writeRaster(Porc_Pob_Com, output_raster_path, format = 'GTiff', overwrite = TRUE)
      print("Indicador 6.5 Proximidad a Comercios calculado")
    } else {
      print("El municipio no tiene Comercios")
    }
  } else {
    print("No se han incluido las capas necesarias para calcular el indicador 6.5 Proximidad a Comercios")
  }
}


#Comprueba si se ha seleccionado el indicador 6.6. Si es así, filtrado por uso 
#(600 y 300 m)  y bufer. Interseccion en un bufer total y guardado del indicador
if ('6.6 Proximidad a los 5 servicios' %in% Indicadores_a_calcular) {
  Equipamientos_600 <- subset(Clasificacion_Intermedia_Clasificador_Catastral, USO == "EQUIP_OTR" | USO == "OCIO_ESP" | USO == "EQUIP_EDU" | USO == "EQUIP_SANI")
  Bufer_Equipamientos_600 <- st_as_sf(st_union(st_buffer(Equipamientos_600, 600)))
  Equipamientos_300 <- subset(Clasificacion_Intermedia_Clasificador_Catastral, USO == "COM")
  Bufer_Equipamientos_300 <- st_as_sf(st_union(st_buffer(Equipamientos_300, 300)))
  Bufer_tot <- st_intersection(Bufer_Equipamientos_600, Bufer_Equipamientos_300)
  Interserccion_Res_Buffer <- st_intersection(edificios_join_secciones, Bufer_tot)
  Pob_Tot_Raster <- poligonos_a_raster_200(Interserccion_Res_Buffer, Edificios_Pob_Raster, 'Pob_Edif', 'sum')
  Porc_Tot <- Pob_Tot_Raster/Edificios_Pob_Raster*100
  output_raster_path <- file.path(Nueva_Carpeta, 'proximidad_total.tif')
  writeRaster(Porc_Tot, output_raster_path, format = 'GTiff', overwrite = TRUE)
  print("Indicador 6.6 Proximidad a Servicios calculado")
}
    


    
