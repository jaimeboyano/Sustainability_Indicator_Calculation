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
Una vez instalado R y Rstudio, el software con el que se va a trabajar es Qgis. Qgis es un Sistema de Información Geográfica  (SIG) de código abierto y multiplataforma que proporciona herramientas y funcionalidades para el tratamiento, análiis, visualización y edición de datos geoespaciales. La instalación de este software se realiza desde https://qgis.org/es/site/forusers/download.html. 
De manera específica, para poder ejecutar los scripts de R de este repositorio en QGIS es necesario instalar el complemento R Provider. 
#### 1.2.1 Processing R Provider
La intregración entre R y Qgis se hace con el complemento Processing R Provider desarrollado por NorthRoad (https://north-road.github.io/qgis-processing-r/).El proceso que se describe a continuacaión es el expuesto por Alonso Aransay, D. en MappingGIS (https://mappinggis.com/2019/09/como-integrar-r-en-qgis-3/)

Para poder relacionar QGIS y R, el primer paso es instalar el complemento dentro de . Para ello es necesario seguir la siguiente ruta: Complementos - Administrar e instalar complmentos. 
  
  ![Imagen 1. Abrir Complmentos](https://github.com/jaimeboyano/Sustainability_Indicator_Calculation/blob/main/Images/Complementos_1.png?raw=true)  

Tras ello, se abrirá una ventana con todos los complementos posibles. En la barra de búsqueda introducir el nombre del complemento: Processing R Provider. Seleccionar el complemento e Instalar. 

 ![Imagen 2. Instalar Complemento](https://github.com/jaimeboyano/Sustainability_Indicator_Calculation/blob/main/Images/Complementos_2.png)

Una vez instalado el complemento es necesario determinar una serie de rutas a las diferentes carpetas en las que está instalado R, los scripts y los paquetes. Para ello, en primer lugar hay que seleccionar configuración - opciones 
 ![Imagen 3. Opciones](https://github.com/jaimeboyano/Sustainability_Indicator_Calculation/blob/main/Images/Complementos_3.png?raw=true)  

En la ventana emergente buscar Procesos - Proveedores - R 
Una vez aquí. Introducir las siguientes rutas a las carpetas: 
 1. **Package Repository:** https://cran.r-project.org 
 2. **R Folder:** Ruta a la carpeta donde está instalado R (no la carpeta bin). Suele estar en PRogram Files 
 3. **R Scripts folder:** Cualquier directorio del ordenador en el que se encuentren o vayan a encontrar los scripts de R. Solo se mostraraán las herramientas en esta carpeta. En este caso se ha utilizado: C:/Users/Jaime/AppData/Roaming/QGIS/QGIS3/profiles/default/processing/rscripts
 4. **Use 64 bit version:** Activado en caso de que la versión de R sea de 64 bits
 5. **Use user library folder instead of system libraries:** Activado
 6. **User library folder:** Directorio rlibs dónde se tienen instaladas las bibliotecas R para QGIS. Se suele encontrar en la carpeta processing de la instalación de QGIS 3. 
 
![Imagen 4. Rutas](https://github.com/jaimeboyano/Sustainability_Indicator_Calculation/blob/main/Images/Complementos_4.png?raw=true)  

Si se han configurado correctamente todas las carpetas ya se pueden utilizar los scripts introducidos con R dentro de Qgis, siempre y cuando se ubiquen en la ruta establecida para Rscripts. Una manera de confirmar que se han ejecutado adecuadamente es porque en la caja de herramientas de procesos aparecen los símbolos de R. Adicionalmente, cuandos se despliegue el menú inferior de R, deberían aparecer los scripts de esta herramienta. 

 ![Imagen 5. Confirmación](https://github.com/jaimeboyano/Sustainability_Indicator_Calculation/blob/main/Images/Complementos_5.png?raw=true)  

## 2. Fuentes de datos necesarias 
### 2.1 Sede Electrónica del Catastro 
### 2.2 Cadastral Classifier 
### 2.3 Censo 2011
## 3. Descripción de la herramienta
## 4. Relación de indicadores y fuentes de información
