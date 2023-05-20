# Cálculo de Indicadores de Sostenibilidad Urbana 
Repositorio para el cálculo de indicadores de sostenibilidad urbana a partir de datos catastrales del Ministerio de Hacienda y Función Pública del Gobierno de España

## 1. Instalación 
Para poder utilizar esta herramienta es necesario realizar una serie de instalaciones previas: El lenguaje de programación R con su correspondientes entorno de desarrollo Rstudio, descargar la información catastral de la Sede Electrónica del Catastro, el software de Qgis con los plugins Cadastral Classifier y R Provider
### 1.1. R y Rstudio 
La instalación de R y Rstudio se realiza desde la siguiente dirección (https://posit.co/download/rstudio-desktop/). Como se muestra, en primer lugar es necesario instalar el lenguaje de programación para, posteriormente instalar Rstudio. 
Para poder ejecutar la herramienta, es necesario que los paquetes que utiliza estén instalados y cargados en el entorno de R. Los paquetes utilizados en la herramienta son: 
1. **Raster** (https://cran.r-project.org/web/packages/raster/index.html): Sirve para la lectura, escritura, manipulación, análisis y modelización de datos espaciales. Es uno de los paquetes que cargará posteriormente R Provider en Qgis
3. **Sf** (https://cran.r-project.org/web/packages/sf/index.html): Es el soporte para codificar datos vectoriales espaciales. Al igual que el paquete anterior, es uno de los paquetes que se carga automáticamente en el R Provider de Qgis 
4. **dplyr** (https://cran.r-project.org/web/packages/dplyr/index.html): Herramienta general para trabajar con objetos de tipo dataframe
5. **CatastRo** (https://cran.r-project.org/web/packages/CatastRo/index.html): Permite el acceso a los datos espaciales públicos disponibles en base a la directiva INSPIRE

Para poder instalar los paquetes es necesario ejecutar las siguientes líneas de código: 
```
install.packages("raster")
install.packages("sf")
install.packages("dplyr")
install.packages("catastRo")
library(raster)
library(sf)
library(dplyr)
library(catastRo)
```
### 1.2. QGIS
Una vez instalado R y Rstudio, el software con el que se va a trabajar es Qgis. Qgis es un Sistema de Información Geográfica  (SIG) de código abierto y multiplataforma que proporciona herramientas y funcionalidades para el tratamiento, análisis, visualización y edición de datos geoespaciales. La instalación de este software se realiza desde https://qgis.org/es/site/forusers/download.html. 
De manera específica, para poder ejecutar los scripts de R de este repositorio en QGIS es necesario instalar el complemento R Provider. 
#### 1.2.1 Processing R Provider
La intregración entre R y Qgis se hace con el complemento Processing R Provider desarrollado por NorthRoad (https://north-road.github.io/qgis-processing-r/).El proceso que se describe a continuacaión es el expuesto por Alonso Aransay, D. en MappingGIS (https://mappinggis.com/2019/09/como-integrar-r-en-qgis-3/)

Para poder relacionar QGIS y R, el primer paso es instalar el complemento. Para ello es necesario seguir la siguiente ruta: Complementos - Administrar e instalar complmentos. 
  
  ![Imagen 1. Abrir Complmentos](https://github.com/jaimeboyano/Sustainability_Indicator_Calculation/blob/main/Images/Complementos_1.png?raw=true)  

Tras ello, se abrirá una ventana con todos los complementos posibles. En la barra de búsqueda introducir el nombre del complemento: Processing R Provider. Seleccionar el complemento e Instalar. 

 ![Imagen 2. Instalar Complemento](https://github.com/jaimeboyano/Sustainability_Indicator_Calculation/blob/main/Images/Complementos_2.png)

Una vez instalado el complemento es necesario determinar una serie de rutas a las diferentes carpetas en las que está instalado R, los scripts y los paquetes. Para ello, en primer lugar hay que seleccionar configuración - opciones 

 ![Imagen 3. Opciones](https://github.com/jaimeboyano/Sustainability_Indicator_Calculation/blob/main/Images/Complementos_3.png?raw=true)  

En la ventana emergente buscar Procesos - Proveedores - R 
Una vez aquí. Introducir las siguientes rutas a las carpetas: 
 1. **Package Repository:** Introducir https://cran.r-project.org 
 2. **R Folder:** Ruta a la carpeta donde está instalado R (no la carpeta bin). Suele estar en PRogram Files 
 3. **R Scripts folder:** Cualquier directorio del ordenador en el que se encuentren o vayan a encontrar los scripts de R. Solo se mostrarán las herramientas en esta carpeta. En este caso se ha utilizado: C:/Users/Jaime/AppData/Roaming/QGIS/QGIS3/profiles/default/processing/rscripts
 4. **Use 64 bit version:** Activado en caso de que la versión de R sea de 64 bits
 5. **Use user library folder instead of system libraries:** Activado
 6. **User library folder:** Directorio rlibs dónde se tienen instaladas las bibliotecas R para QGIS. Se suele encontrar en la carpeta processing de la instalación de QGIS 3. 
 
![Imagen 4. Rutas](https://github.com/jaimeboyano/Sustainability_Indicator_Calculation/blob/main/Images/Complementos_4.png?raw=true)  

Si se han configurado correctamente todas las carpetas ya se pueden utilizar los scripts introducidos con R dentro de Qgis, siempre y cuando se ubiquen en la ruta establecida para Rscripts. Una manera de confirmar si los procesos de ejecución se han llevado a cabo correctamente es verificar la presencia de los símbolos de R en la caja de herramientas de procesos. Además, al desplegar el menú inferior de R, deberían mostrarse los scripts correspondientes a esta herramienta. Estos indicadores visuales son una señal de que la integración de R está funcionando correctamente.

 ![Imagen 5. Confirmación](https://github.com/jaimeboyano/Sustainability_Indicator_Calculation/blob/main/Images/Complementos_5.png?raw=true)
 
Después de verificar la correcta instalación del complemento y proporcionar las rutas correspondientes a las diferentes carpetas, se pueden descargar los scripts desde este repositorio. Para ello, es necesario seguir estos pasos:

1. Seleccionar el botón desplegable "Code" (en verde) y elegir la opción "Download ZIP".
2. Descargar un archivo comprimido que contiene todos los documentos del repositorio.
 ![Imagen 6. Confirmación](https://github.com/jaimeboyano/Sustainability_Indicator_Calculation/blob/main/Images/Complementos_6.png?raw=true)
3. Descomprimir el archivo descargado y obtener una carpeta.
4. Abrir la carpeta y dirigirse a la subcarpeta "code".
5. Copiar todos los archivos de la carpeta "code".
6. Navegar a la ruta establecida como "rscripts" durante la instalación del complemento de Processing R Provider.
7. Pegar los archivos copiados en esa ubicación.
Una vez completados estos pasos y si todo el proceso se ha realizado correctamente, los scripts estarán disponibles y se podrá ejecutar la herramienta.

## 2. Descripción de la herramienta
La herramienta para el cálculo de indicadores consta de tres scripts distintos. El primero de ellos, y el más importante, es el script "Indicators_Calculation". Este script permite calcular los seis indicadores de sostenibilidad utilizando información catastral como base. Como complemento a este cálculo, se proporcionan otros dos scripts. El segundo script, llamado "Census_Tracks_Population", facilita la correlación entre las capas de secciones censales y la información tabulada de los indicadores del censo. Por último, el tercer script, denominado "Vector_to_Indicator", se encarga de convertir una capa vectorial (de puntos o polígonos) al formato de los indicadores de sostenibilidad urbana, generando una rejilla ráster con diferentes resoluciones espaciales.

A continuación, se van a detallar las funcionalidades, entradas y salidas de cada uno de los scripts. Sin embargo, no se van a desarrollar hasta el siguiente apartado las fuentes de datos necesarias para la ejecución de la herramienta.

### 2.1 Indicators Calculation 
Herramienta para calcular indicadores de sostenibilidad urbana a partir de diferentes fuentes de información catastral
1. **Indicadores a calcular:** Selección de los indicadores que se van a calcular
2. **Extent Salida:** Archivo shapefile del que se tomarán la extensión y el CRS 
3. **Clasificación Intermedia Clasificador Catastral:** Capa poligonal con la Clasificación Intermedia obtenida del Plugin Cadastral Classifier
4. **Capa Constru Catastro:** Capa poligonal Constru resultado de la descarga de la Sede Electrónica del Catastro
5. **Sección Censal con Población:** Capa Shapefile con las secciones censales y los indicadores de población y vivienda (INE, 2011). Puede ser el resutlado de la herramienta Census_Tracks_Population 
6. **Munincipio:** Nombre del municipio o municipios (separados por ,;.) de los que se quieren calcular los indicadores. Importante, para seleccionar varios municipios es necesario incluir como Extent Salida una capa que contenga todos. 
7. **New Folder:** Salida en la que se guardarán todos los resultados 

Nota: Los resultados no se visualizan directamente en QGIS, simplemente se guardan en la carpeta. 

### 2.2 Census Tracks Population 
Herramienta para unir la información vectorial de las secciones censales con los indicadores del censo 2011 (INE)
1. **Input table:** Tabla con la información de los indicadores de población y vivienda del INE (2011). El INE las tiene como agrupadas por autonomías 
2. **Shapefile Seccen:** Capa vectorial con todas las secciones censales. Pueden ser las de todo el estado español. 
3. **Municipio:** Cadena o lista con los municipios que se quiere generar la cartografía. Nota: solo se pueden ejecutar municipios de la misma autonomía 
4. **Output:** Ruta en la que se guardará el archivo de salida resultante.

### 2.3 Vector to Indicator 
Herramienta para calcular indicadores de sostenibilidad a partir de capas vectoriales
1. **Capa Entrada:** Capa vectorial (de puntos o polígonos) con la que se desea calcular un indicador de sostenibilidad 
2. **Tipología de la capa:** Determinación si la capa vectorial es de puntos o polígonos
3. **Shapefile Extension CRS Raster Salida:** Capa de la que se quiere obtener tanto la extensión como el CRS de la capa resultante
4. **Columna:** Columna de la capa vectorial que se quiere utilizar para la conversión del vectorial al ráster
5. **Tamaño Pixel:** Determinación del tamaño del píxel (en metros)
6. **Funcion de agregacion:** Función de Agregación para convertir del vectorial al ráster. First: Primer valor, last: último valor, sum: suma y mean: media 
7. **Salida Resultado:** Dirección de salida en la que se quiere guardar el resultado

## 3. Fuentes de datos necesarias 
### 3.1 Sede Electrónica del Catastro 
### 3.2 Cadastral Classifier 
### 3.3 Censo 2011
## 4. Relación de indicadores y fuentes de información
