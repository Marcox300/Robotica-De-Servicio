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

Descarto el barrido de ruta, ya que se ha confirmado que la aeronave se ha estrellado y el objetivo es localizar posibles supervivientes, que podrían haberse desplazado por las corrientes o el viento. También descarto la espiral cuadrada, ya que resulta menos adecuada para cubrir una superficie marítima extensa de forma uniforme.

Por este motivo, selecciono el barrido de rejilla en zigzag y elijo la opción 1: zigzag simple. Como las condiciones del mar son relativamente calmadas, considero que un único barrido permite cubrir la zona de forma ordenada, ahorrando tiempo y batería. Si se detecta algún posible objetivo, se puede realizar una segunda pasada localizada para comprobarlo.

En definitiva, el zigzag simple ofrece un buen equilibrio entre la cobertura de la zona, el tiempo de vuelo y el consumo de batería.

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

<video width="640" height="360" controls>
  <source src="video/dron.mp4" type="video/mp4">
  Tu navegador no soporta el video.
</video>
