# Dron de rescate

## 1. Objetivo

Programa un drone para que busque personas en el mar tras un accidente aéreo del que se saben sólo las coordenadas en las que se perdió contacto con la aeronave.
El drone tiene que barrer una área (en espirales, barrido sistemático cuadrado, etc..) detectando las personas que encuentra.
Debe evitar repetidos y estimar para cada persona sus coordenadas concretas. Esas son las que proporciona al equipo de rescate humano que va exactamente a auxiliar a las víctimas.

La detección de caras se hará con el detector Haar de OpenCV y debe ser robusta a que el drone se encuentre con la persona en cualquier orientacion.
También debe ser general y detectar, si acaso, varias caras dentro de la misma imagen.

Ha de simular el desgaste de la batería, que va menguando su nivel con el tiempo. Llegado a cierto umbral, el drone debe interrumpir su búsqueda de personas,
regresar a la lancha, allí recarga la batería y vuelve luego a la zona de búsqueda para continuar por donde iba.


### Problemas
Los principales problemas que se deben resolver son:

-Planificación del movimiento: cubrir la zona de búsqueda mediante una trayectoria que reduzca las áreas sin explorar.

-Control de posición: relacionar las coordenadas de los puntos de búsqueda con la posición del dron.

-Visión artificial: detectar caras en las imágenes de la cámara ventral, incluso cuando presentan diferentes orientaciones.

-Localización: transformar las detecciones de la imagen en posiciones del mapa y, posteriormente, en coordenadas GPS.

-Eliminación de duplicados: identificar las detecciones repetidas de una misma persona.

-Gestión de batería: determinar cuándo regresar a la base y cuándo continuar la búsqueda.

-Autonomía: coordinar el despegue, la búsqueda, el regreso, el aterrizaje, la recarga y la finalización.

## 2. Movimiento

### Selección de Patron de Búsqueda

El patrón de búsqueda determina cómo se desplaza el dron para inspeccionar la superficie del mar.
Debe permitir cubrir una zona extensa de manera ordenada y reducir los espacios que quedan sin observar.

- Barrido de Rejilla

**Opción 1**

<img width="597" height="316" alt="images" src="https://github.com/user-attachments/assets/984a57c0-1522-4bdb-a733-d6ffccab6c61" />

Realizar un recorrido en zigzag mediante pasadas paralelas que permitan cubrir sistemáticamente toda la zona de búsqueda.
Al alternar el sentido de cada pasada, se reducen los desplazamientos innecesarios y se aprovecha mejor el tiempo de vuelo.

**Opción 2**

<img width="405" height="319" alt="SAR parallel search 4" src="https://github.com/user-attachments/assets/4f5d03d4-b0d9-46b7-9f47-fb66d420dc66" />

Combinar dos barridos en zigzag superpuestos, realizando una segunda pasada sobre la zona inspeccionada en la primera.
El objetivo es volver a observar las áreas de interés desde una trayectoria diferente para aumentar las posibilidades de detectar personas 
que no se hayan identificado inicialmente y confirmar detecciones anteriores.

- Espiral Cuadrada

<img width="320" height="320" alt="Square-spiral-search-routine-used-by-the-MVS_Q320" src="https://github.com/user-attachments/assets/deb9b26a-5270-403b-9594-80b8bccdce10" />

El dron recorre una trayectoria formada por segmentos rectos que crean una espiral de forma cuadrada.
El recorrido se amplía progresivamente alrededor de una posición inicial.

Puede resultar útil cuando se conoce aproximadamente el punto donde podría encontrarse una persona y se desea ampliar la búsqueda hacia el exterior.

- Barrido de Ruta

<img width="476" height="463" alt="valle" src="https://github.com/user-attachments/assets/87f7f068-e629-4ebf-b49b-1966d280d957" />

El dron sigue un recorrido condicionado por la forma del terreno o por una ruta previamente definida. Puede ser útil en zonas alargadas, como caminos, valles o corredores.

A diferencia de una rejilla regular, la trayectoria puede adaptarse a la geometría de la zona de búsqueda.

### ¿Cuál seleccionar?

Para elegir el patrón de búsqueda más adecuado, se tienen en cuenta tres aspectos: la información disponible sobre el accidente, la eficiencia del recorrido y las condiciones del mar.

En primer lugar, descarto el barrido de ruta, ya que se ha confirmado que la aeronave se ha estrellado. Por tanto, el objetivo no es seguir una ruta concreta,
sino localizar a posibles supervivientes en la zona del accidente. Aunque se conoce un punto aproximado del impacto,
no se puede asegurar que las personas se encuentren exactamente allí, ya que podrían haberse desplazado por efecto de las corrientes o del viento.

La espiral cuadrada también podría ser una opción, porque permite ampliar la búsqueda progresivamente desde un punto conocido. Sin embargo,
resulta menos adecuada para cubrir una superficie marítima extensa de forma uniforme, ya que concentra el recorrido alrededor de una posición inicial.

Por este motivo, selecciono el barrido de rejilla en zigzag, ya que permite recorrer la zona mediante pasadas paralelas y cubrirla de forma ordenada.
Además, facilita la planificación del vuelo, reduce los desplazamientos innecesarios y permite aprovechar mejor el tiempo de vuelo y la batería del dron.

Entre las dos variantes de este patrón, elijo la opción 1: zigzag simple. Como las condiciones del mar son relativamente calmadas,
considero que un único barrido es suficiente para realizar la búsqueda inicial, sin necesidad de repetir todo el recorrido con una segunda pasada superpuesta.
De esta forma, se ahorra tiempo y batería, que pueden aprovecharse para revisar zonas concretas si se detecta algún posible objetivo.

En definitiva, el zigzag simple es la opción más adecuada para este escenario, ya que ofrece un buen equilibrio entre la cobertura de la zona,
el tiempo de vuelo y el consumo de batería. Si durante la búsqueda se encuentra alguna detección dudosa,
se puede realizar una segunda pasada sobre esa zona para comprobarla con mayor detalle.

### Implementación del movimiento

Cómo nos movemos espacios, marcas, altura, ...


## 3. Localización

### 3.1 Localización Local

### 3.2 Localización Global

### 3.3 Localización de Personas

Explicar altura del drón, cámara


## 4. Detección de personas

### 4.1 Marcarlas

### 4.2 Filtrar

### 4.3 Localizar


## 5. Autonomía


## 6. Vídeo
