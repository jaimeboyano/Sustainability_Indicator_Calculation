##Calculo Indicadores=group
##Indicadores_a_calcular=enum literal multiple 1. Densidad de viviendas;2. Compacidad Absoluta;3. Equilibrio Residencial;4. Diversidad de Usos;5. Densidad de Poblacion;6.1 Proximidad a Centros Educativos;6.2 Proximidad a Centros Sanitarios;6.3 Proximidad a Comercios;6.4 Proximidad a Centros de Ocio;6.5 Proximidad a Centros Deportivos 6.6
##Extent_Salida=vector
##Clasificacion_Intermedia_Clasificador_Catastral=optional vector
##Capa_Constru_Catastro=optional vector
##Seccion_Censal_con_Poblacion=optional vector
##Municipio=optional string
##New_folder=output folder


library(CatastRo)
library(dplyr)

roman_to_arabic <- function(roman) {
  # Tabla de correspondencia entre valores romanos y arábigos
  roman_values <- c(1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1)
  roman_letters <- c("M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I")
  # Inicializar valor
  arabic_value <- 0
  # Mientras queden letras romanas en la cadena
  while (nchar(roman) > 0) {
    # Comprobar si la primera letra romana de la cadena corresponde a un valor
    # en la tabla de correspondencia
    if (substr(roman, 1, 2) %in% roman_letters) {
      letter <- substr(roman, 1, 2)
      roman <- substr(roman, 3, nchar(roman))
    } else {
      letter <- substr(roman, 1, 1)
      roman <- substr(roman, 2, nchar(roman))
    }
    # Sumar o restar el valor arábigos correspondiente al valor romano
    if (letter %in% roman_letters) {
      arabic_value <- arabic_value + roman_values[which(roman_letters == letter)]
    }
  }
  # Devolver valor arábigos
  return(arabic_value)
}

facility_proximity <- function(shapefile, Use){
    Residential_Poligons <- subset(Clasificacion_Intermedia_Clasificador_Catastral, USO %in% c("RES_UNI", "RES_UNI_MX", "RES_PLU", 
                                              'RES_PLU_MX'))
    Facilities <- subset(shapefile, USO == Use)
    Bufer_Facilities <- st_as_sf(st_buffer(Facilities, 300))

    #Intersección entre poligonos y el bufer
    Residential_Intersects_Facility <- st_intersection(Residential_Poligons, Bufer_Facilities)

    # Hago join espacial entre el poligono y las intersecciones

    Spatial_join <- st_join(Residential_Intersects_Facility, Residential_Poligons,  join = st_intersects, left = TRUE)

    # Contar el número de polígonos residenciales que intersectan con cada buffer de servicios básicos, agrupando por REFCAT.x, y almacenar los resultados en la variable join_count
    Bufer_Count <- Spatial_join %>%
        group_by(REFCAT.x) %>%
        summarise(count = n()) %>% 
        st_as_sf()
    return(Bufer_Count)
}

poligons_to_raster_200 <- function (shapefile, extention, Columna, fun){
  centroides <- st_centroid(shapefile)
  ext <- st_bbox(extention) %>% 
    extent()
  grid <- raster(ext, res = c(200, 200))
  col_raster <- subset(centroides, select = Columna)
  resultado <- raster::rasterize(col_raster, grid, field = col_raster[[1]], match.fun(fun))
  crs(resultado) <- crs(shapefile)
  return(resultado)
}


extent <- st_bbox(Extent_Salida) %>%
  extent()
grid_200_rast <- raster(extent, res = c(200, 200))
grid_200_pol <- rasterToPolygons(grid_200_rast, dissolve = FALSE)
grid_200_pol <- st_as_sf(grid_200_pol)
crs_constru <- crs(Extent_Salida)
grid_200 <- st_set_crs(grid_200_pol, crs_constru)
grid_200$ID <- seq(1, nrow(grid_200_pol))

if ("1. Densidad de viviendas" %in% Indicadores_a_calcular ||
    "3. Equilibrio Residencial" %in% Indicadores_a_calcular ||
    "5. Densidad de Poblacion" %in% Indicadores_a_calcular)
 {if (Municipio == '') {
    Buildings <- NULL
    Buildings_Intersection <- NULL
    Num_Dw <- NULL
    print('Es necesario introducir el nombre de un municipio para calcular los indicadores 1, 3 y/o 5')
  } else {
    municipios <- strsplit(Municipio, "[,;.]")[[1]]
    municipios <- trimws(municipios)
    Buildings <- vector("list", length(municipios))
    
    for (i in 1:length(municipios)) {
      municipio <- chartr("áéíóúÁÉÍÓÚ", "aeiouAEIOU", municipios[i])
      municipio <- toupper(municipio)
      informacion_municipios <- catr_atom_search_munic(municipio)
      informacion_municipios$munic <- substring(informacion_municipios$munic, 7)
      informacion_municipios <- informacion_municipios[grepl(paste0("^", municipio, "$"), informacion_municipios$munic, ignore.case = TRUE), ]
      cod_muni <- informacion_municipios$catrcode
      Buildings[[i]] <- catr_atom_get_buildings(cod_muni)
    }
    
    Buildings <- do.call(rbind, Buildings)
    Buildings$Area_Merge <- round(st_area(Buildings), digits = 4)
    Buildings_Intersection <- st_intersection(Buildings, grid_200)
    Buildings_Intersection$Area_Intersection <- round(st_area(Buildings_Intersection), digits = 4)
    Buildings_Intersection$prop_area <- round(Buildings_Intersection$Area_Intersection / Buildings_Intersection$Area_Merge, digits = 4)
    Buildings_Intersection$Prop_Dw <- Buildings_Intersection$prop_area * Buildings_Intersection$numberOfDwellings
    Num_Dw <- poligons_to_raster_200(Buildings_Intersection, extent, 'Prop_Dw', 'sum')
  }
}


if (!is.null(Capa_Constru_Catastro)) {
  Capa_Constru_Catastro <- st_as_sf(Capa_Constru_Catastro)
  Capa_Constru_Catastro$Area_Merge <- round(st_area(Capa_Constru_Catastro), digits = 4)
  Constru_intersection <- st_intersection(Capa_Constru_Catastro, grid_200)
} else {
  Capa_Constru_Catastro <- NULL
  Constru_intersection <- NULL
}


if (!is.null(Clasificacion_Intermedia_Clasificador_Catastral)) {
  Clasificacion_Intermedia_Clasificador_Catastral <- st_as_sf(Clasificacion_Intermedia_Clasificador_Catastral)
  Clasificacion_Intermedia_Clasificador_Catastral$Area_Merge <- round(st_area(Clasificacion_Intermedia_Clasificador_Catastral), digits = 4)
  CC_intersection <- st_intersection(Clasificacion_Intermedia_Clasificador_Catastral, grid_200)
} else {
  Clasificacion_Intermedia_Clasificador_Catastral <- NULL
  CC_intersection <- NULL
}


if ("1. Densidad de viviendas" %in% Indicadores_a_calcular && !is.null(Num_Dw)) {
    Dwelling_Density <- Num_Dw/4
    output_raster_path <- file.path(New_folder, 'Dwelling_Density.tif')
    writeRaster(Dwelling_Density, output_raster_path, format = 'GTiff', overwrite = TRUE)
    print("Indicador 1. Densidad de viviendas calculado")
}


if ('2. Compacidad Absoluta' %in% Indicadores_a_calcular) {
    if (!is.null(Constru_intersection)) { 
        Constru_intersection$Area_M2 <- round(st_area(Constru_intersection), digits = 4)
        Constru_intersection$CONSTRU_Edited <- gsub("B|T|Z|TZA|POR|SOP|PJE|MAR|P|CO|EPT|SS|ALT|PI|TEN|ETQ|ZBE|SILO|SUELO|PRG|DEP|ESC|TRF|JD|YJD|FUT|VOL|ZD|RUINA|CONS|ZPAV|GOLF|?", "", Constru_intersection$CONSTRU)
        Constru_intersection$CONSTRU_Edited <- gsub(".*\\+", "", Constru_intersection$CONSTRU_Edited)
        Constru_intersection$CONSTRU_Edited <- gsub("-.*$", "", Constru_intersection$CONSTRU_Edited)
        Constru_intersection$CONSTRU_Edited <- gsub("\\d.*$", "", Constru_intersection$CONSTRU_Edited)
        Constru_intersection$CONSTRU_Edited <- gsub("[.?]", "", Constru_intersection$CONSTRU_Edited)
        Constru_intersection$CONSTRU_Edited_Arab <- as.numeric(lapply(Constru_intersection$CONSTRU_Edited, roman_to_arabic))
        Constru_intersection$Altura <- (Constru_intersection$CONSTRU_Edited_Arab - 1) * 3 + 4.5
        Constru_intersection$Vol_M3 <- round((Constru_intersection$Altura * Constru_intersection$Area_M2), digits = 4)
        Vol_M3 <- poligons_to_raster_200(Constru_intersection, extent, 'Vol_M3', 'sum')
        Compacidad_Absoluta <- Vol_M3/40000
        output_raster_path <- file.path(New_folder, 'Compacidad_Absoluta.tif')
        writeRaster(Compacidad_Absoluta, output_raster_path, format = 'GTiff', overwrite = TRUE)
        print("Indicador 2. Compacidad Absoluta calculado")
    } else {
        print("No se han introducido las capas necesarias para calcular el indicador 2. Compacidad Absoluta")
        }
}


if ("3. Equilibrio Residencial" %in% Indicadores_a_calcular) {
  if (!is.null(Num_Dw) && !is.null(CC_intersection)) {
    Sector_Servicios <- subset(CC_intersection, USO %in% c("COM", "EQUIP_OTR", "EQUIP_EDU", "HOS_REST", "OFI", "EQUIP_SANI", "OCIO_ESP", "RES_PLU_MX"))
    Sector_Servicios$Area_Intersection <- round(st_area(Sector_Servicios), digits = 4)
    Area_Services <- poligons_to_raster_200(Sector_Servicios, extent, "Area_Intersection", "sum")
    Equilibrio_Residencial <- Area_Services/Num_Dw
    output_raster_path <- file.path(New_folder, 'Equilibrio_Residencial.tif')
    writeRaster(Equilibrio_Residencial, output_raster_path, format = 'GTiff', overwrite = TRUE)
    print("Indicador 3. Equilibrio Residencial calculado")
  } else {
    print("No se han introducido las capas necesarias para calcular el indicador 3. Equilibrio residencial")
  }
}


if ("4. Diversidad de usos de suelo" %in% Indicadores_a_calcular) {
    if (!is.null(CC_intersection)) {
        # cuenta el número de ocurrencias de cada uso del suelo para cada identificador (id) ("individuos")
        Num_Uses <- CC_intersection %>% 
            group_by(ID, USO) %>% 
            summarize(Count = n()) %>% 
            ungroup()

        # calcula el número total de usos del suelo para cada identificador (id) ("individuos totales")
        Total_Uses <- Num_Uses %>% 
            group_by(ID) %>% 
            summarize(Total = sum(Count)) %>% 
            ungroup() %>% 
            st_drop_geometry() # Elimino la geometría para poder unir las tablas

        Abundance_Uses <- merge(Num_Uses, Total_Uses, by = "ID")
        Abundance_Uses$prop <- Abundance_Uses$Count / Abundance_Uses$Total

        Shannon_Index <- Abundance_Uses %>%
            group_by(ID) %>%
            summarize(Shannon = -sum(prop * log(prop)))

        Shannon_Index_Raster <- poligons_to_raster_200(Shannon_Index, extent, 'Shannon', 'sum')
        output_raster_path <- file.path(New_folder, 'Shannon_Index.tif')
        writeRaster(Shannon_Index_Raster, output_raster_path, format = 'GTiff', overwrite = TRUE)
        print("Indicador 4. Indice de Shannon Calculado")
    } else {
        print("No se han introducido las capas necesarias para calcular el indicador 4. Indice de Shannon")
    }
}

if ('5. Densidad de Poblacion' %in% Indicadores_a_calcular) { 
    if (!is.null(Seccion_Censal_con_Poblacion)){
        Seccion_Censal_con_Poblacion$Home_Pop <- round(Seccion_Censal_con_Poblacion$t1_1/Seccion_Censal_con_Poblacion$t21_1, 4)
        Buildings_Join_Sections <- st_join(Buildings_Intersection, Seccion_Censal_con_Poblacion, join = st_within, left = FALSE)
        Buildings_Join_Sections$Building_Pop <- Buildings_Join_Sections$Home_Pop*Buildings_Join_Sections$Prop_Dw

        Buildings_Pop_Raster <- poligons_to_raster_200(Buildings_Join_Sections, extent, 'Building_Pop', 'sum')
        Pop_Dens <- Buildings_Pop_Raster/4
        output_raster_path <- file.path(New_folder, 'Pop_Dens.tif')
        writeRaster(Pop_Dens, output_raster_path, format = 'GTiff', overwrite = TRUE)
        print("Indicador 5. Densidad de Poblacion Calculado")
    } else {
         print("No se han introducido las capas necesarias para calcular el indicador 5. Densidad de Poblacion")
    }
}

if('6.1 Proximidad a Centros Educativos' %in% Indicadores_a_calcular){
    if (!is.null(CC_intersection)) {
        if ('EQUIP_EDU' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
                Bufer_Education_Count <- facility_proximity(Clasificacion_Intermedia_Clasificador_Catastral,'EQUIP_EDU')
                Education_Proximity <- poligons_to_raster_200(Bufer_Education_Count, extent, 'count', 'mean')
                output_raster_path <- file.path(New_folder, 'Education_Proximity.tif')
                writeRaster(Education_Proximity, output_raster_path, format = 'GTiff', overwrite = TRUE)
                 print("Indicador 6.1 Proximidad a Centros Educativos Calculado")
        } else {
            print("El municipio no tiene Centros Educativos")
        }
    } else {
        print("No se han incluido las capas necesarias para calcular el indicador 6.1 Proximidad a Centros Educativos")
    }
}
    
if('6.2 Proximidad a Centros Sanitarios' %in% Indicadores_a_calcular){
    if (!is.null(CC_intersection)) {
        if ('EQUIP_SANI' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
                Bufer_Sanitary_Count <- facility_proximity(Clasificacion_Intermedia_Clasificador_Catastral,'EQUIP_SANI')
                Sanitary_Proximity <- poligons_to_raster_200(Bufer_Sanitary_Count, extent, 'count', 'mean')
                output_raster_path <- file.path(New_folder, 'Sanitary_Proximity.tif')
                writeRaster(Sanitary_Proximity, output_raster_path, format = 'GTiff', overwrite = TRUE)
                 print("Indicador 6.2 Proximidad a Centros Sanitarios Calculado")
        } else {
            print("El municipio no tiene Centros Sanitarios")
        }
    } else {
        print("No se han incluido las capas necesarias para calcular el indicador 6.2 Proximidad a Centros Sanitarios")
    }
}

if('6.3 Proximidad a Comercios' %in% Indicadores_a_calcular){
    if (!is.null(CC_intersection)) {
        if ('COM' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
                Bufer_Store_Count <- facility_proximity(Clasificacion_Intermedia_Clasificador_Catastral,'COM')
                Store_Proximity <- poligons_to_raster_200(Bufer_Store_Count, extent, 'count', 'mean')
                output_raster_path <- file.path(New_folder, 'Store_Proximity.tif')
                writeRaster(Store_Proximity, output_raster_path, format = 'GTiff', overwrite = TRUE)
                 print("Indicador 6.3 Proximidad a Comercios Calculado")
        } else {
            print("El municipio no tiene Comercios")
        }
    } else {
        print("No se han incluido las capas necesarias para calcular el indicador 6.3 Proximidad a Comercios")
    }
}

if('6.4 Proximidad a Centros de Ocio' %in% Indicadores_a_calcular){
    if (!is.null(CC_intersection)) {
        if ('OCIO_ESP' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
                Bufer_entertainment_Count <- facility_proximity(Clasificacion_Intermedia_Clasificador_Catastral,'OCIO_ESP')
                Entertainment_Proximity <- poligons_to_raster_200(Bufer_entertainment_Count, extent, 'count', 'mean')
                output_raster_path <- file.path(New_folder, 'Entertainment_Proximity.tif')
                writeRaster(Entertainment_Proximity, output_raster_path, format = 'GTiff', overwrite = TRUE)
                 print("Indicador 6.4 Proximidad a Centros de Ocio Calculado")
        } else {
            print("El municipio no tiene Centros de Ocio")
        }
    } else {
        print("No se han incluido las capas necesarias para calcular el indicador 6.4 Proximidad a Centros de Ocio")
    }
}

if('6.5 Proximidad a Centros Deportivos' %in% Indicadores_a_calcular){
    if (!is.null(CC_intersection)) {
        if ('EQUIP_OTR' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
                Bufer_sports_Count <- facility_proximity(Clasificacion_Intermedia_Clasificador_Catastral,'EQUIP_OTR')
                Sports_Proximity <- poligons_to_raster_200(Bufer_sports_Count, extent, 'count', 'mean')
                output_raster_path <- file.path(New_folder, 'Sports_Proximity.tif')
                writeRaster(Sports_Proximity, output_raster_path, format = 'GTiff', overwrite = TRUE)
                 print("Indicador 6.5 Proximidad a Centros Deportivos Calculado")
        } else {
            print("El municipio no tiene Centros Deportivos")
        }
    } else {
        print("No se han incluido las capas necesarias para calcular el indicador 6.5 Proximidad a Centros Deportivos")
    }
}




    
