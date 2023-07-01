##Calculo Indicadores=group
##Capa_Entrada=vector
##Tipologia_Capa=enum literal Punto;Polígono
##Shapefile_Extension_CRS_raster_salida=vector
##Columna=field Capa_Entrada
##Funcion_de_agregacion=enum literal first;last;sum;mean;count
##Tamano_Pixel=enum literal 100;200;400;500;1000
##Salida_Resultado=output raster

#Verifica si la capa es polígono. Si es asi, calcula centroides y almacena
if (Tipologia_Capa == "Polígono") {
  centroides <- st_centroid(Capa_Entrada)
} else {
#Si la capa es puntos, asigna centroides a la capa de entrada
  centroides <- Capa_Entrada  
}

#Obtiene coordenadas de la extension del shpaefile de  y CRS
ext <- st_bbox(Shapefile_Extension_CRS_raster_salida) %>% 
    extent()

#Crea cuadricula raster con la extension y tamaño especifico
grid <- raster(ext, res = c(as.numeric(Tamano_Pixel), as.numeric(Tamano_Pixel)))

#Obtiene la columna de datos de la capa de entrada especificada
col_raster <- subset(centroides, select = Columna)

#Asigna CRS
resultado <- rasterize(col_raster, grid, field = col_raster[[1]], match.fun(Funcion_de_agregacion), na.rm = TRUE)
crs(resultado) <- crs(Capa_Entrada)

#Muestra resultado
Salida_Resultado <- resultado