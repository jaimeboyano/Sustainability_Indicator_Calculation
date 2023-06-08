##Calculo Indicadores=group
##Indicadores_a_calcular=enum literal multiple 1. Densidad de viviendas;2. Compacidad Absoluta;3. Equilibrio Residencial;4. Diversidad de Usos;5. Densidad de Poblacion;6.1 Proximidad a Centros Educativos;6.2 Proximidad a Centros Sanitarios;6.3 Proximidad a Centros de Ocio;6.4 Proximidad a Centros Deportivos;6.5 Proximidad a Comercios;6.6 Proximidad a los 5 servicios 6.7
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


facility_proximity <- function(shapefile, Use, distance){
    Residential_Poligons <- Buildings_Join_Sections
    Facilities <- subset(shapefile, USO == Use)
    Bufer_Facilities <- st_as_sf(st_union(st_buffer(Facilities, distance)))
    #Obtengo el raster de la poblacion de dentro de los buferes
    Residential_Intersects_Facility <- st_intersection(Residential_Poligons, Bufer_Facilities)
    return(Residential_Intersects_Facility)
}


extent <- st_bbox(Extent_Salida) %>%
  extent()
grid_200_rast <- raster(extent, res = c(200, 200))
grid_200_pol <- rasterToPolygons(grid_200_rast, dissolve = FALSE)
grid_200_pol <- st_as_sf(grid_200_pol)
crs_constru <- crs(Extent_Salida)
grid_200 <- st_set_crs(grid_200_pol, crs_constru)
grid_200$ID <- seq(1, nrow(grid_200_pol))

if (("1. Densidad de viviendas" %in% Indicadores_a_calcular) ||
    ("3. Equilibrio Residencial" %in% Indicadores_a_calcular) ||
    ("5. Densidad de Poblacion" %in% Indicadores_a_calcular) || grepl("^6", Indicadores_a_calcular))
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
    Buildings_Residential <- subset(Buildings_Intersection, currentUse == "1_residential")
    Buildings_Residential$Area_Intersection <- round(st_area(Buildings_Residential), digits = 4)
    Buildings_Residential$prop_area <- round(Buildings_Residential$Area_Intersection / Buildings_Residential$Area_Merge, digits = 4)
    Buildings_Residential$Prop_Dw <- Buildings_Residential$prop_area * Buildings_Residential$numberOfDwellings
    Num_Dw <- poligons_to_raster_200(Buildings_Residential, extent, 'Prop_Dw', 'sum')
    Condition <- Num_Dw >= 1
    Num_Dw_filtered <- Num_Dw
    Num_Dw_filtered[!Condition] <- NA
}
}


if (!is.null(Capa_Constru_Catastro)) {
    Capa_Constru_Catastro <- st_as_sf(Capa_Constru_Catastro)
    Capa_Constru_Catastro$Area_Merge <- round(st_area(Capa_Constru_Catastro), digits = 4)
    Constru_intersection <- st_intersection(Capa_Constru_Catastro, grid_200)
    Constru_intersection$Area_M2 <- round(st_area(Constru_intersection), digits = 4)
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
    Sector_Servicios <- subset(CC_intersection, USO %in% c("COM", "EQUIP_OTR", "EQUIP_EDU", "HOS_REST", "OFI", "EQUIP_SANI", "OCIO_ESP"))
    Sector_Servicios$Area_Intersection <- round(st_area(Sector_Servicios), digits = 4)
    Area_Services <- poligons_to_raster_200(Sector_Servicios, extent, "Area_Intersection", "sum")
    Equilibrio_Residencial <- Area_Services/Num_Dw_filtered
    output_raster_path <- file.path(New_folder, 'Equilibrio_Residencial.tif')
    writeRaster(Equilibrio_Residencial, output_raster_path, format = 'GTiff', overwrite = TRUE)
    print("Indicador 3. Equilibrio Residencial calculado")
  } else {
    print("No se han introducido las capas necesarias para calcular el indicador 3. Equilibrio residencial")
  }
}


if ("4. Diversidad de Usos" %in% Indicadores_a_calcular) {
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


if (("5. Densidad de Poblacion" %in% Indicadores_a_calcular) || grepl("^6", Indicadores_a_calcular)) {
    Seccion_Censal_con_Poblacion$Home_Pop <- round(Seccion_Censal_con_Poblacion$t1_1 / Seccion_Censal_con_Poblacion$t21_1, 4)
    Buildings_Join_Sections <- st_join(Buildings_Residential, Seccion_Censal_con_Poblacion, join = st_within, left = FALSE)
    Buildings_Join_Sections$Building_Pop <- Buildings_Join_Sections$Home_Pop * Buildings_Join_Sections$Prop_Dw
    Buildings_Pop_Raster <- poligons_to_raster_200(Buildings_Join_Sections, extent, 'Building_Pop', 'sum')
} 


    


if ('5. Densidad de Poblacion' %in% Indicadores_a_calcular) { 
    if (!is.null(Seccion_Censal_con_Poblacion) && !is.null(Clasificacion_Intermedia_Clasificador_Catastral)&& !is.null(Clasificacion_Intermedia_Clasificador_Catastral)){
        CC_intersection$Urb_Area <-  round(st_area(CC_intersection)/10000, digits = 4)
        Clasificacion_Intermedia_Clasificador_Catastral_out<-CC_intersection
        Urb_Area_Rast <- poligons_to_raster_200(CC_intersection, extent, 'Urb_Area', 'sum')
        Pop_Dens <- Buildings_Pop_Raster/Urb_Area_Rast
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
                Residential_Intersects_Education <- facility_proximity(Clasificacion_Intermedia_Clasificador_Catastral,'EQUIP_EDU', 300)
                Pop_Education_Raster <- poligons_to_raster_200(Residential_Intersects_Education, extent, 'Building_Pop', 'sum')
                Porc_Pop_Education <- Pop_Education_Raster/Buildings_Pop_Raster*100
                output_raster_path <- file.path(New_folder, 'Education_Proximity.tif')
                writeRaster(Porc_Pop_Education, output_raster_path, format = 'GTiff', overwrite = TRUE)
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
                Residential_Intersects_Sanitary <- facility_proximity(Clasificacion_Intermedia_Clasificador_Catastral,'EQUIP_SANI', 600)
                Pop_Sanitary_Raster <- poligons_to_raster_200(Residential_Intersects_Sanitary, extent, 'Building_Pop', 'sum')
                Porc_Pop_Sanitary <- Pop_Sanitary_Raster/Buildings_Pop_Raster*100
                output_raster_path <- file.path(New_folder, 'Sanitary_Proximity.tif')
                writeRaster(Porc_Pop_Sanitary, output_raster_path, format = 'GTiff', overwrite = TRUE)
                 print("Indicador 6.2 Proximidad a Centros Sanitarios Calculado")
        } else {
            print("El municipio no tiene Centros Sanitarios")
        }
    } else {
        print("No se han incluido las capas necesarias para calcular el indicador 6.2 Proximidad a Centros Sanitarios")
    }
}



if('6.3 Proximidad a Centros de Ocio' %in% Indicadores_a_calcular){
    if (!is.null(CC_intersection)) {
        if ('OCIO_ESP' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
                Residential_Intersects_entertainment <- facility_proximity(Clasificacion_Intermedia_Clasificador_Catastral,'OCIO_ESP', 600)
                Pop_Entertainment_Raster <- poligons_to_raster_200(Residential_Intersects_entertainment, extent, 'Building_Pop', 'sum')
                Porc_Pop_Entertainment <- Pop_Entertainment_Raster/Buildings_Pop_Raster*100
                output_raster_path <- file.path(New_folder, 'Entertainment_Proximity.tif')
                writeRaster(Porc_Pop_Entertainment, output_raster_path, format = 'GTiff', overwrite = TRUE)
                 print("Indicador 6.4 Proximidad a Centros de Ocio Calculado")
        } else {
            print("El municipio no tiene Centros de Ocio")
        }
    } else {
        print("No se han incluido las capas necesarias para calcular el indicador 6.4 Proximidad a Centros de Ocio")
    }
}

if('6.4 Proximidad a Centros Deportivos' %in% Indicadores_a_calcular){
    if (!is.null(CC_intersection)) {
        if ('EQUIP_OTR' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
                Residential_Intersects_Sports <- facility_proximity(Clasificacion_Intermedia_Clasificador_Catastral,'EQUIP_OTR', 600)
                Pop_Sports_Raster <- poligons_to_raster_200(Residential_Intersects_Sports, extent, 'Building_Pop', 'sum')
                Porc_Pop_Sports <- Pop_Sports_Raster/Buildings_Pop_Raster*100
                output_raster_path <- file.path(New_folder, 'Sports_Proximity.tif')
                writeRaster(Porc_Pop_Sports, output_raster_path, format = 'GTiff', overwrite = TRUE)
                 print("Indicador 6.5 Proximidad a Centros Deportivos Calculado")
        } else {
            print("El municipio no tiene Centros Deportivos")
        }
    } else {
        print("No se han incluido las capas necesarias para calcular el indicador 6.5 Proximidad a Centros Deportivos")
    }
}

if('6.5 Proximidad a Comercios' %in% Indicadores_a_calcular){
    if (!is.null(CC_intersection)) {
        if ('COM' %in% Clasificacion_Intermedia_Clasificador_Catastral$USO){
                Residential_Intersects_Stores <- facility_proximity(Clasificacion_Intermedia_Clasificador_Catastral,'COM', 600)
                Pop_Stores_Raster <- poligons_to_raster_200(Residential_Intersects_Stores, extent, 'Building_Pop', 'sum')
                Porc_Pop_Stores <- Pop_Stores_Raster/Buildings_Pop_Raster*100
                output_raster_path <- file.path(New_folder, 'Store_Proximity.tif')
                writeRaster(Porc_Pop_Stores, output_raster_path, format = 'GTiff', overwrite = TRUE)
                 print("Indicador 6.5 Proximidad a Comercios calculado")
        } else {
            print("El municipio no tiene Comercios")
        }
    } else {
        print("No se han incluido las capas necesarias para calcular el indicador 6.5 Proximidad a Comercios")
    }
}


if ('6.6 Proximidad a los 5 servicios' %in% Indicadores_a_calcular) {
    Residential_Intersects_Tot_600 <- facility_proximity(Clasificacion_Intermedia_Clasificador_Catastral,c('EQUIP_EDU', 'COM', 'EQUIP_OTR', 'OCIO_ESP', 'EQUIP_SANI') , c(300, 600, 600, 600, 600))
    Pop_Tot_600_Raster <- poligons_to_raster_200(Residential_Intersects_Tot_600, extent, 'Building_Pop', 'sum')
    Porc_Pop_Tot <- Pop_Tot_600_Raster/Buildings_Pop_Raster*100
    output_raster_path <- file.path(New_folder, 'Total_Proximity.tif')
    writeRaster(Porc_Pop_Tot, output_raster_path, format = 'GTiff', overwrite = TRUE)
}


   
    


    
