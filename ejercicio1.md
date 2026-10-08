# Robot Aspiradora Localizada

## 1. Objetivo

El objetivo de este proyecto es programar una aspiradora robótica de gama alta para que sea capaz de limpiar una casa de manera eficiente y autónoma.

Para ello se implementará el algoritmo **BSA (Backtracking Search Algorithm)** para planificar una ruta de limpieza y se desarrollará un sistema de pilotaje del robot basado en posición.

Al tratarse de una aspiradora de gama alta, se dispone de un sistema de autolocalización robusto, 
en este caso lo consideramos resuelto, que mantiene una buena estimación de la posición y orientación del robot.

Para conseguir esta funcionalidad es necesario resolver tres tareas principales:

1. **Registro del mapa de la casa.**
2. **Planificación del movimiento utilizando el algoritmo BSA.**
3. **Ejecución del camino mediante un controlador reactivo**, que permita corregir las posibles desviaciones producidas por el ruido de los actuadores.

## 2. Registro del mapa

Para que el robot pueda desplazarse correctamente por el mapa es necesario establecer una correspondencia entre las coordenadas del entorno y
las coordenadas de los píxeles de la imagen.

El registro del mapa se realiza mediante la **asociación de puntos**, 
relacionando las coordenadas `XY` del entorno con su posición correspondiente en píxeles.

Los puntos utilizados para realizar esta asociación son:

| Coordenadas XY | Pixel X | Pixel Y |
|---|---:|---:|
| `(-3.891092135313557, 1.7126816844694484)` | 966 | 592 |
| `(-3.913813019308139, -1.0838273373216938)` | 966 | 314 |
| `(-2.6933217904703053, 5.71612738702659)` | 846 | 992 |
| `(5.3051442771802195, 5.721523456973746)` | 48 | 992 |
| `(5.301613138099122, -3.4837030714243307)` | 48 | 73 |
| `(1.9074923404205295, -3.4803409425542466)` | 386 | 73 |
| `(2.9008645760721024, 1.8951491890070893)` | 289 | 607 |
| `(1.8964182476849356, 1.9266039840924098)` | 386 | 613 |

A partir de estas correspondencias se obtiene la transformación necesaria para convertir las coordenadas del sistema de referencia del robot a coordenadas de la imagen.

La transformación se define mediante:

```math
Pixel_X = aX + bY + t_X
```

```math
Pixel_Y = cX + dY + t_Y
```

donde `a`, `b`, `c` y `d` forman la matriz `XY_TO_PIXEL`, mientras que `t_X` y `t_Y` forman `XY_TO_PIXEL_OFFSET`.

Por tanto, la transformación puede escribirse como:

```math
\begin{pmatrix}
Pixel_X \\
Pixel_Y
\end{pmatrix}
=
XY\_TO\_PIXEL
\begin{pmatrix}
X \\
Y
\end{pmatrix}
+
XY\_TO\_PIXEL\_OFFSET
```

Para obtener los coeficientes de la transformación se utilizan los puntos de correspondencia de la tabla. Para cada punto se relacionan sus coordenadas `(X,Y)` con sus coordenadas en píxeles `(Pixel_X, Pixel_Y)`.

Los coeficientes se calculan mediante **mínimos cuadrados**, utilizando los puntos de correspondencia disponibles. Este método permite obtener la transformación que mejor se ajusta al conjunto de puntos, minimizando el error entre las posiciones de píxel conocidas y las calculadas.

Para convertir las coordenadas de píxel de nuevo al sistema `XY`, se aplica la transformación inversa:

```math
\begin{pmatrix}
X \\
Y
\end{pmatrix}
=
XY\_TO\_PIXEL^{-1}
\left(
\begin{pmatrix}
Pixel_X \\
Pixel_Y
\end{pmatrix}
-
XY\_TO\_PIXEL\_OFFSET
\right)
```

De esta forma se pueden realizar las dos conversiones necesarias: de coordenadas `XY` a píxeles para representar la posición del robot sobre el mapa, y de píxeles a coordenadas `XY` para relacionar una posición de la imagen con el sistema de referencia del robot.

Como se dispone de más puntos de los estrictamente necesarios para determinar la transformación, el sistema se resuelve mediante mínimos cuadrados, buscando los valores de los parámetros que minimizan el error entre las coordenadas de píxel conocidas y las coordenadas calculadas.

Una vez obtenida la matriz $C$, sus cuatro primeros coeficientes permiten construir XY_TO_PIXEL, mientras que los dos últimos corresponden a XY_TO_PIXEL_OFFSET.

Para calcular la transformación inversa, es decir, pasar de coordenadas de píxel a coordenadas del sistema XY, se despeja la posición original:

**XY_TO_PIXEL_OFFSET**

Para calcular la matriz de transformación, utilizamos inicialmente los seis primeros puntos de 
correspondencia para obtener una primera estimación de dicha matriz. A continuación, 
aplicamos la transformación calculada a los dos puntos restantes y comprobamos si sus coordenadas transformadas coinciden aproximadamente con las posiciones en píxeles indicadas.

De esta manera, utilizamos los seis primeros puntos para calcular la transformación y los dos últimos como puntos de validación, 
lo que nos permite comprobar si el registro del mapa es correcto y si la transformación obtenida representa adecuadamente 
la relación entre las coordenadas del entorno y las coordenadas de la imagen.

Para obtener una mayor precisión, posteriormente generamos una nueva matriz de transformación utilizando los ocho puntos disponibles.
Al comparar ambas matrices, se observa que la matriz calculada con los ocho puntos apenas presenta variaciones respecto a la obtenida inicialmente con los seis primeros puntos.
Esto confirma que los dos puntos utilizados como validación son coherentes con la transformación inicial y que el registro del mapa es consistente.

> **Nota:** La matriz resultante del registro no se muestra en este documento. Esta información se proporcionará una vez finalizado el curso.

### Tamaño de la matriz

Para utilizar el mapa en el algoritmo de planificación es necesario discretizarlo mediante una matriz.

En este caso se considera un tamaño de **33 × 33 píxeles por celda**, utilizando esta dimensión para representar aproximadamente el tamaño físico del robot.

Este cálculo se ha realizado comparando el tamaño del mapa con el tamaño del robot y asociando dicha dimensión con la imagen. Inicialmente se realizaron pruebas utilizando **34 píxeles**, pero se observó que algunas zonas que físicamente eran transitables quedaban consideradas demasiado estrechas. Por este motivo, después de realizar varios ajustes, se estableció finalmente un tamaño de 33 × 33 píxeles.

La utilización de esta dimensión permite tener en cuenta las dimensiones físicas de la aspiradora durante la planificación.

No se puede considerar el robot únicamente como un punto, ya que una trayectoria que aparentemente pasa por una zona libre podría provocar una colisión cuando se tiene en cuenta el tamaño real del robot.

Cada celda de la matriz tiene asociado un estado, que permite al algoritmo conocer la situación de esa zona del mapa.

```python
DIRTY = 0      # Zona pendiente de limpiar
CLEAN = 1      # Zona ya limpia
OCCUPIED = 2   # Zona ocupada por un obstáculo
VISITED = 3    # Zona ya recorrida por el algoritmo
```

Además, para determinar si una celda puede ser utilizada, se analiza la zona de la imagen que representa dicha celda. Si existe aunque sea una pequeña parte de obstáculo dentro de la celda, esta se considera completamente ocupada. De esta forma, se utiliza un criterio conservador que evita generar trayectorias demasiado próximas a paredes u obstáculos.

Por tanto, la representación de **33 × 33 píxeles** permite aproximar las dimensiones del robot dentro del mapa y generar una planificación teniendo en cuenta los obstáculos.

De esta forma se consigue:

- Tener en cuenta el tamaño físico del robot.
- Reducir el riesgo de colisiones.
- Evitar celdas que contengan obstáculos, aunque estos ocupen solo una parte de ellas.
- Mejorar la representación utilizada por el algoritmo de planificación.
- Generar trayectorias que puedan ser ejecutadas por el robot.

## 3. Algoritmo BSA

Para generar la ruta de limpieza se utiliza el algoritmo **BSA (Backtracking Search Algorithm)**.

El objetivo del algoritmo es encontrar una secuencia de movimientos que permita recorrer las zonas de interés de la vivienda de manera eficiente.

Durante el desarrollo se han considerado dos variantes:

- **BSA del estudio**
- **BSA con prioridad de avanzar**

Ambas alternativas presentan un funcionamiento similar, buscan generar una trayectoria eficiente de limpieza y ambas consiguen completar la tarea.

Los resultados obtenidos fueron:

| Algoritmo | Resultado |
|---|---:|
| BSA con prioridad de avanzar | **483** |
| BSA del estudio | **466** |

Los resultados son similares, por lo que ambas alternativas permiten comprobar el funcionamiento del algoritmo de planificación aplicado al mapa de la vivienda.

La principal diferencia se encuentra en la forma de priorizar los movimientos durante la construcción de la ruta.

**BSA del estudio**

<img width="522" height="458" alt="bas" src="https://github.com/user-attachments/assets/d0b99ec8-6fba-4759-8821-6196018e539d" />


**BSA con prioridad de avanzar**

<img width="522" height="458" alt="alternative_bsa" src="https://github.com/user-attachments/assets/00fbabf6-f965-4e30-be23-fca997591783" />


El **BSA del estudio** tiende a priorizar inicialmente la limpieza de los bordes de las zonas,
lo que puede provocar que queden pequeñas islas o zonas aisladas para limpiar posteriormente.

Por otro lado, el **BSA con prioridad de avanzar** prioriza el desplazamiento continuo y tiende a realizar la limpieza por secciones,
reduciendo la aparición de pequeñas zonas aisladas que deban ser recorridas posteriormente.

Por tanto, aunque ambos algoritmos consiguen completar la tarea y presentan resultados similares,
la estrategia de prioridad de avance modifica la forma en la que se distribuye la trayectoria de limpieza sobre el mapa.


### 3.1. Algoritmo de recuperación

Dentro del BSA se ha implementado un mecanismo de recuperación para evitar que queden zonas sin visitar.

Cuando se detecta una zona pendiente, el algoritmo revisa los pasos anteriores de la trayectoria hasta encontrar un punto cercano desde el que pueda acceder a ella.

Para realizar esta recuperación se utiliza la **distancia Manhattan sobre la cuadrícula**, 
trabajando con movimientos entre celdas adyacentes. De esta forma, la ruta respeta la estructura del mapa y
evita atravesar las celdas ocupadas, reduciendo el riesgo de colisión.

Esta solución es más sencilla que el **algoritmo de visibilidad** utilizado como referencia. 
En lugar de comprobar la visibilidad entre puntos, calcular trayectorias mediante líneas rectas y 
tener que considerar problemas de colisión en las esquinas, nuestra solución aprovecha directamente la cuadrícula discretizada del mapa.

Por tanto, la recuperación se realiza de una forma más simple: se revisa la trayectoria anterior, 
se busca una zona pendiente y se calcula un camino válido entre celdas, evitando los obstáculos.

De esta manera, el algoritmo puede recuperar zonas que hayan quedado aisladas sin necesidad de recalcular toda la trayectoria del BSA.

## 4. Movimiento local

Una vez obtenida la ruta global mediante BSA, el robot debe ser capaz de seguirla correctamente.

Para ello se utiliza un movimiento local basado en posición, utilizando la estimación del sistema de localización.

El movimiento se divide en dos fases:

1. **Corrección de orientación.**
2. **Avance hacia el siguiente punto.**

Durante el desplazamiento pueden aparecer pequeños errores en la posición del robot, principalmente asociados a la velocidad lineal.
Aunque se indique una determinada velocidad de avance, el movimiento real del robot no es perfectamente constante, lo que puede provocar pequeñas desviaciones respecto a la trayectoria teórica.

Para reducir este efecto, el controlador reactivo comprueba continuamente la posición del robot y realiza las correcciones necesarias durante el desplazamiento.
De esta forma, aunque puedan existir pequeñas diferencias entre la trayectoria calculada y el movimiento real, el robot puede corregir progresivamente su posición antes de alcanzar el siguiente punto.

La estrategia utilizada es:

**Orientación correcta → avance → corrección → siguiente punto**

## 5. Problemas

Durante el desarrollo del proyecto surgieron varios problemas relacionados principalmente con la representación del mapa,
la discretización de la cuadrícula, el comportamiento del algoritmo BSA y la correspondencia entre las dimensiones teóricas del robot y las dimensiones observadas en el entorno.

### 5.1. Discretización inicial de la cuadrícula

Inicialmente se planteó realizar directamente la conversión entre la posición real del robot y la celda de la cuadrícula utilizando el tamaño fijo de **34 × 34 píxeles**.
Es decir, la posición del robot se transformaba directamente en una fila y una columna de la matriz y, de forma inversa, una celda se convertía directamente en una posición del entorno.

Aunque este método funcionaba para el tamaño de cuadrícula utilizado inicialmente, presentaba una limitación importante:
la conversión dependía directamente del tamaño de las celdas. Si posteriormente se modificaba el tamaño de la cuadrícula, era necesario modificar también las conversiones entre posición y celda.

Para evitar esta dependencia, se decidió separar ambos problemas. Primero se realiza la transformación entre las coordenadas reales `(X,Y)` y
los píxeles del mapa mediante la matriz `XY_TO_PIXEL`. Posteriormente, a partir de las coordenadas de píxel obtenidas, se realiza la discretización de la imagen en celdas.

De esta forma, el tamaño de la cuadrícula puede modificarse sin tener que recalcular la transformación entre el sistema real y el mapa.
Esto proporciona una representación más flexible y permite probar diferentes tamaños de celda para ajustar mejor la discretización al tamaño físico del robot.

### 5.2. Comportamiento del BSA y aparición de islas

Otro de los problemas encontrados fue el comportamiento del **BSA del estudio** durante la limpieza.

Aunque el algoritmo consigue recorrer las zonas transitables, su estrategia de exploración puede provocar que algunas pequeñas zonas queden aisladas y
tengan que ser recuperadas posteriormente. Estas zonas pueden aparecer como pequeñas "islas" dentro de una sección que aparentemente ya había sido explorada.

Este comportamiento llevó a plantear si era conveniente utilizar únicamente el algoritmo del estudio o investigar otras alternativas. Desde el punto de vista de una aspiradora
resulta poco intuitivo que una sección aparentemente terminada tenga que abandonarse y posteriormente volver a ella para limpiar una pequeña zona pendiente.

Por este motivo se investigaron diferentes estrategias de recorrido y se desarrolló una variante del BSA con **prioridad de avance**,
buscando favorecer trayectorias más continuas y reducir la aparición de estas zonas aisladas.

Aunque finalmente ambas estrategias son capaces de completar la limpieza, la comparación permitió comprobar que la forma de priorizar los movimientos
tiene una influencia importante en la distribución de la trayectoria.

### 5.3. Ajuste entre el tamaño del robot y el mapa

Otro problema importante fue determinar qué tamaño debía tener una celda de la cuadrícula para representar correctamente las dimensiones del robot.

Inicialmente se utilizó un tamaño de **34 × 34 píxeles**,
pero durante las pruebas se observó que algunas zonas que físicamente parecían transitables quedaban clasificadas como demasiado estrechas en la representación discretizada.

Por ello, no se consideró suficiente realizar únicamente el cálculo teórico del tamaño del robot a partir de las dimensiones del mapa.
Fue necesario comprobar experimentalmente si la escala obtenida se correspondía realmente con el entorno.

Para realizar esta comprobación se comparó visualmente el tamaño representado del robot con elementos reales del mapa,
especialmente **puertas, pasillos y zonas de paso**. Moviendo el robot por estas zonas y comparando las dimensiones observadas con las dimensiones teóricas esperadas,
fue posible comprobar si la escala utilizada resultaba razonable.

Este procedimiento permitió detectar diferencias que no eran evidentes únicamente mediante el cálculo matemático. Finalmente, tras realizar diferentes pruebas,
se estableció el tamaño de **33 × 33 píxeles por celda**, obteniendo una representación que se ajustaba mejor al comportamiento observado del robot.

Esta comprobación práctica resulta especialmente importante porque un pequeño error en la estimación del tamaño puede tener un efecto considerable sobre la planificación:
una cuadrícula demasiado grande puede bloquear zonas transitables, mientras que una demasiado pequeña puede generar trayectorias demasiado próximas a obstáculos.

### 5.4. Relación entre precisión y flexibilidad

Los problemas anteriores mostraron que no era conveniente fijar todos los parámetros del sistema a una única discretización.

La transformación `XY_TO_PIXEL` permite mantener independiente la relación entre el entorno real y la imagen,
mientras que el tamaño de la cuadrícula se puede modificar posteriormente según las necesidades del algoritmo de planificación.

Esta separación facilita realizar pruebas con diferentes tamaños de celda y permite ajustar la representación del mapa sin afectar al sistema de localización ni a la transformación de coordenadas.

En conjunto, los problemas encontrados durante el desarrollo permitieron mejorar la estructura del sistema y hacer que la representación utilizada por el BSA fuese menos dependiente de valores fijados inicialmente.

## 6. Mejoras futuras

El sistema desarrollado puede ampliarse para conseguir una limpieza más robusta y eficiente.

### 6.1. Barrido inicial siguiendo las paredes

Una posible mejora consiste en realizar un primer barrido siguiendo las paredes de la vivienda antes o 
después de ejecutar la trayectoria principal generada mediante BSA.

El objetivo sería recorrer inicialmente el perímetro de las habitaciones para asegurar que las zonas próximas a las paredes y, 
especialmente, las esquinas, queden correctamente cubiertas.

Esta estrategia permitiría complementar la ruta generada por BSA y reducir las zonas que pueden quedar sin limpiar en las esquinas.

### 6.2. Optimización de la trayectoria y recuperación

Una posible mejora sería optimizar conjuntamente la trayectoria generada por el BSA y el mecanismo de recuperación.

El objetivo sería **reducir el número de giros y la longitud total de la ruta**, evitando desplazamientos innecesarios.
En algunas situaciones, el BSA puede generar pequeñas islas de celdas sin limpiar (como se aprecia en el apartado de BSA) que posteriormente obligan al robot a volver sobre sus pasos.

Una estrategia de recuperación más inteligente podría integrar estas zonas en la trayectoria principal mediante barridos,
evitando que queden aisladas y reduciendo así los desplazamientos adicionales.

De esta forma, se busca obtener una ruta más continua y eficiente, 
manteniendo una optimización el desplazamiento frente al coste computacional del algoritmo.

### 6.3. Control adaptativo de velocidad

La velocidad del robot podría adaptarse en función de la zona en la que se encuentre.

Por ejemplo, se podría reducir la velocidad cuando el robot esté cerca de paredes u obstáculos y aumentarla cuando se encuentre en zonas despejadas.

## 7. Vídeo y explicación

En esta sección se muestra el funcionamiento final del robot y se explica el proceso completo de planificación y ejecución de la trayectoria.

### Vídeo


<video width="640" height="360" controls>
  <source src="video/limpiando_2.mp4" type="video/mp4">
  Tu navegador no soporta el video.
</video>


El vídeo debe mostrar el funcionamiento completo del sistema:

1. El mapa de la vivienda.
2. La planificación mediante BSA.
3. La trayectoria generada.
4. La orientación del robot antes de cada desplazamiento.
5. El avance siguiendo los puntos de la trayectoria.
6. Las correcciones realizadas por el controlador reactivo.
7. El resultado final de la limpieza.


### Explicación del funcionamiento

En el vídeo se puede apreciar especialmente, en los minutos **2:30 y 2:40**, la precisión de la transformación entre las coordenadas reales del robot y su representación en el dibujo del mapa, observándose cómo la posición del robot se corresponde correctamente con su ubicación en la representación utilizada.

A diferencia de los gifs en esta parte he decidido no poner el mapa ocupado de negro en la imagen para demostrar la asociación de la posición respecto al robot.
