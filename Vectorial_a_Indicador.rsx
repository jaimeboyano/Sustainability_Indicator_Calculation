##Calculo Indicadores=group
##Capa_Entrada=vector
##Tipologia_Capa=enum literal Punto;Polígono
##Shapefile_Extension_CRS_raster_salida=vector
##Columna=field Capa_Entrada
##Funcion_de_agregacion=enum literal first;last;sum;mean;count
##Tamano_Pixel=enum literal 100;200;400;500;1000
##Salida_Resultado=output raster


if (Tipologia_Capa == "Polígono") {
  centroides <- st_centroid(Capa_Entrada)
} else {
  centroides <- Capa_Entrada  
}

ext <- st_bbox(Shapefile_Extension_CRS_raster_salida) %>% 
    extent()
grid <- raster(ext, res = c(as.numeric(Tamano_Pixel), as.numeric(Tamano_Pixel)))
col_raster <- subset(centroides, select = Columna)
resultado <- rasterize(col_raster, grid, field = col_raster[[1]], match.fun(Funcion_de_agregacion), na.rm = TRUE)
crs(resultado) <- crs(Capa_Entrada)
Salida_Resultado <- resultado