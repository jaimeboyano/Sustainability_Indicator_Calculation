# Cálculo de Indicadores de Sostenibilidad Urbana 
Repositorio para el cálculo de indicadores de sostenibilidad urbana a partir de datos catastrales del Ministerio de Hacienda y Función Pública del Gobierno de España

## 1. Instalación 
Para poder utilizar esta herramienta es necesario realizar una serie de instalaciones previas: El lenguaje de programación R con su correspondientes entorno de desarrollo Rstudio, descargar la información catastral de la Sede Electrónica del Catastro, el software de Qgis con los plugins Cadastral Classifier y R Provider
### 1.1. R y Rstudio 
La instalación de R y Rstudio se realiza desde la siguiente dirección (https://posit.co/download/rstudio-desktop/). Como se muestra, en primer lugar es necesario instalar primero el lenguaje de programación para, posteriormente instalar Rstudio. 
Para poder ejecutar la herramienta, es necesario que los paquetes que utiliza estén instalados y cargados en el entorno de R. Los paquetes utilizados en la herramienta son: 
1. **Raster** (https://cran.r-project.org/web/packages/raster/index.html): Sirve para la lectura, escritura, manipulación, análisis y modelización de datos espaciales. Es uno de los paquetes que cargará posteriormente R Provider en Qgis
3. **Sf** (https://cran.r-project.org/web/packages/sf/index.html): Es el soporte para codificar datos vectoriales espaciales. Al igual que el paquete anterior, es uno de los paquetes que se carga automáticamente en el R Provider de Qgis 
4. **dplyr** (https://cran.r-project.org/web/packages/dplyr/index.html): Herramienta general para trabajar con objetos de tipo dataframe
5. **CatastRo** (https://cran.r-project.org/web/packages/CatastRo/index.html): Peite el acceso a los datos espaciales públicos disponibles en base a la directiva INSPIRE

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
Una vez instalado R y Rstudio, el software con el que se va a trabajar es Qgis. Qgis es un Sistema de Información Geográfica  (SIG) de código abierto y multiplataforma que proporciona herramientas y funcionalidades para el tratamiento, análiis, visualización y edición de datos geoespaciales. La instalación de este software se realiza desde https://qgis.org/es/site/forusers/download.html. 
De manera específica, para poder ejecutar los scripts de R de este repositorio en QGIS es necesario instalar el complemento R Provider. 
#### 1.2.1 Processing R Provider
La intregración entre R y Qgis se hace con el complemento Processing R Provider desarrollado por NorthRoad (https://north-road.github.io/qgis-processing-r/).El proceso que se describe a continuacaión es el expuesto por Alonso Aransay, D. en MappingGIS (https://mappinggis.com/2019/09/como-integrar-r-en-qgis-3/)

Para poder relacionar QGIS y R, el primer paso es instalar el complemento dentro de . Para ello es necesario seguir la siguiente ruta: Complementos - Administrar e instalar complmentos. 

![Imagen 1. Diana Alonso Aransay](https://mappinggis.com/wp-content/uploads/2019/09/1-453x108.png) 



## 2. Fuentes de datos necesarias 
### 2.1 Sede Electrónica del Catastro 
### 2.2 Cadastral Classifier 
### 2.3 Censo 2011
## 3. Descripción de la herramienta
## 4. Relación de indicadores y fuentes de información
Repository for calculating urban sustainability indicators using cadastral data from the Ministry of Finance and Public Function of Spain
