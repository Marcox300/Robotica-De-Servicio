# [Robots de Logística y Transporte](index.md)

## 1. Objetivo

Programa un robot servicio en logística para que mueva autónomamente estanterías de un lugar a otro en un almacén. 

Para ello utiliza la biblioteca de planificación de caminos OMPL y un pilotaje reactivo basado sólamente en posición. Empieza por (a) una planificación puramente puntual con el robot cuadrado holonómico y obstáculos engordados. Continúa (b) sin engordar los obstáculos pero incorporando geometrías diferentes en el trayecto de ida y el trayecto de vuelta, porque en este último caso el robot lleva la estantería a bordo. (c) Finalmente resuelve la navegación con el robot rectangular, que tiene dinámica que Ackermann (y por ello sus restricciones de movimiento).

Hay que resolverlo en el almacén Warehouse-1, moviendo las 6 estanterías.

## 2. Objetivo de implementación

Se busca desarrollar una solución modular y reutilizable que permita adaptar el código a los distintos apartados de la práctica realizando el menor número de modificaciones posible.

Para ello, se pretende separar las distintas funcionalidades en módulos independientes y centralizar los parámetros modificables,
de forma que los cambios se limiten principalmente a la geometría del robot, los obstáculos y las restricciones de movimiento, manteniendo el resto de la implementación.

## 3. Apartado (a): Robot puntual y obstáculos engordados
En este apartado considero el robot como un punto y aplico una dilatación morfológica a los obstáculos mediante OpenCV (`inflate_obstacles`), incorporando así las dimensiones del robot al mapa.

Las coordenadas del mundo real y las de la imagen se relacionan mediante `world_to_pixel` y `pixel_to_world`.
Como conocemos las dimensiones del almacén y el tamaño de la imagen, establecemos una escala para convertir las posiciones del mundo en píxeles y viceversa.
También tenemos en cuenta que el origen está en el centro del almacén y que el eje vertical de la imagen está invertido.

La planificación se realiza con OMPL, una biblioteca que permite encontrar rutas evitando obstáculos.
Utilizo `SE2StateSpace` para representar la posición y orientación del robot, y RRT*, que explora posibles caminos y busca mejorarlos para encontrar rutas más cortas.
En isStateValid únicamente compruebo que el píxel correspondiente a la posición del robot no contenga un obstáculo en el mapa engrosado; no se comprueba su orientación ni su geometría.

Para simplificar el movimiento, aprovecho que el robot es holonómico: primero lo oriento hacia el siguiente punto y, una vez alineado, avanzo hacia él.

Finalmente, una máquina de estados organiza la recogida y el depósito de las seis estanterías. Sus posiciones se almacenan en una lista para reutilizar el mismo procedimiento.
Además, actualizo el mapa al recoger y depositar cada estantería para que las siguientes planificaciones tengan en cuenta los cambios del entorno.

<video width="640" height="360" controls>
  <source src="video/expansion_muros.mp4" type="video/mp4">
  Tu navegador no soporta el video.
</video>

> NOTA: video acelerado x4

## 4. Apartado (b): Geometría del robot y transporte de estanterías

Respecto al apartado anterior, la estructura general del programa apenas cambia.
Se mantiene la planificación con OMPL y la máquina de estados, pero se amplía la comprobación de colisiones para tener en cuenta la geometría del robot y si está transportando una estantería.

Ahora `isStateValid` comprueba la colisión de un rectángulo orientado según el ángulo del robot.
Sus dimensiones dependen de si lleva una estantería: sin ella se utiliza la geometría del robot y, al recogerla, se considera la geometría de la carga.

Hay una discrepancia entre el enunciado y el modelo URDF/Xacro: el ejercicio establece unas dimensiones de 30 × 30 cm, mientras que el modelo presenta una plataforma de 55 × 55 cm.
Finalmente utilizo unas dimensiones de 0,7 × 0,7 m para la planificación.
Esta decisión se debe a que inicialmente no tuve en cuenta las ruedas ni un margen adicional para facilitar las maniobras y absorber pequeños errores de movimiento.

Para la estantería, considero unas dimensiones aproximadas de 1,85 × 0,80 m (`PALLET_LENGTH` y `PALLET_WIDTH`).
También utilizo un margen de 2,4 m (`PALLET_HEIGHT_MARGIN`) para actualizar el mapa al recogerla, aunque en la práctica reduzco esta zona a 1,8 m (`PALLET_WIDTH_MARGIN`).

Por último, el mapa se actualiza según la situación de la carga: al recoger una estantería se elimina su zona de obstáculos y, al depositarla, se incorporan sus patas al mapa.
Así, las siguientes planificaciones tienen en cuenta los cambios del entorno.


En el segundo vídeo muestro una prueba para comprobar que el análisis de geometría funciona correctamente:
al intentar colocar todas las estanterías en horizontal, algunas colisionarían entre sí. OMPL detecta estas colisiones y evita generar una ruta que permita realizar esa disposición.

> NOTA: videos acelerados x4

<video width="640" height="360" controls>
  <source src="video/holonomica.mp4" type="video/mp4">
  Tu navegador no soporta el video.
</video>

### 5. Apartado (c): Robot con geometría Ackermann

En este apartado el cambio principal es adaptar la planificación y el controlador a las restricciones de movimiento del robot Ackermann.
El desarrollo fue progresivo: primero probé únicamente movimientos hacia delante y, posteriormente, incorporé la marcha atrás mediante `ReedsSheppStateSpace`,
que permite planificar trayectorias con cambios de sentido. También probé `Dubins`, que solo permite avanzar.

Inicialmente desarrollé un controlador que eliminaba algunos bucles (*loops*) de las rutas para simplificar el movimiento.
Sin embargo, al refinar el generador de trayectorias, esta solución terminó complicando el seguimiento, ya que no siempre interpretaba correctamente los cambios de dirección.
Finalmente, implementé un seguimiento basado en *Pure Pursuit*, que utiliza un punto de anticipación para calcular la curvatura y ajustar la velocidad y el giro,
teniendo en cuenta los cambios entre avance y retroceso.

Para la planificación se utiliza la geometría de la carga, con un *footprint* de `1.85 × 0.80 m`.
El radio mínimo de giro viene determinado por la distancia entre ejes y el ángulo máximo de dirección:

$$
R_{\min}=\frac{0.488}{\tan(0.64)}
$$

Sin embargo, no he conseguido afinar completamente el control de retroceso.
Esto, junto con los errores de seguimiento, me ha llevado a aumentar el tamaño considerado en los cálculos geométricos para disponer de más margen de seguridad.

Otro problema aparece al depositar las estanterías: al girarse durante la simulación, pueden provocar colisiones con el robot o con otras estanterías.
En este sentido, he seguido la indicación del profesor:
*«para simplificar podéis eliminarla del escenario a mano una vez la habéis depositado en su posición de destino, y así dejar más espacio para las otras»*.

Por estos motivos, también he aumentado el radio de giro utilizado por el planificador respecto al mínimo teórico:

```python
MIN_TURNING_RADIUS = (WHEEL_BASE / math.tan(STEERING_LIMIT)) + 1.0
```

Este margen adicional busca generar trayectorias más amplias y facilitar su seguimiento, aunque supone una aproximación conservadora respecto a las capacidades reales del robot.

> NOTA: video acelerado x4

<video width="640" height="360" controls>
  <source src="video/ackerman.mp4" type="video/mp4">
  Tu navegador no soporta el video.
</video>

### 6. Revisión de la estructura del código

A lo largo de los distintos apartados he mantenido prácticamente la estructura inicial del programa. 
La organización mediante módulos independientes, funciones auxiliares y una máquina de estados ha permitido adaptar la planificación, 
la geometría y el controlador sin tener que rehacer la implementación desde cero.

Aunque he tenido que introducir cambios importantes en la lógica de movimiento para adaptarla al modelo Ackermann,
considero que la estructura original ha resultado adecuada y ha facilitado la evolución del código.
Esto ha permitido reutilizar gran parte de las funcionalidades anteriores, reduciendo la necesidad de duplicar código y evitando modificaciones innecesarias en el resto del programa.

### 7. Análisis de la planificación y los resultados

Durante el desarrollo he utilizado diferentes algoritmos de planificación de OMPL. 
RRT explora el espacio de estados mediante la generación de nuevos nodos y permite encontrar una solución válida en un tiempo razonable, aunque no busca optimizarla. 
Por su parte, RRT* incorpora conexiones y reajustes de nodos para mejorar progresivamente la solución encontrada, buscando rutas de menor coste a medida que aumenta el tiempo de planificación.

También he utilizado `solution_path.interpolate(200)` para aumentar el número de puntos de la trayectoria.
Esto permite obtener una representación más densa del camino y facilita su seguimiento por el controlador, aunque no implica que la ruta original sea más óptima.

Posteriormente, simplifico la trayectoria mediante `PathSimplifier`, una vez comprobado que la solución alcanza correctamente el objetivo:

```python
# Simplify the path only after validating the goal
simplifier = og.PathSimplifier(si)
simplifier.simplifyMax(solution_path)
```

Esta simplificación intenta eliminar puntos innecesarios y reducir la longitud de la ruta,manteniendo la validez de la trayectoria respecto a las restricciones del espacio de planificación.
No obstante, durante las pruebas comprobé que simplificar demasiado algunas rutas podía dificultar su seguimiento, especialmente al realizar maniobras de marcha atrás.

Por otro lado, inicialmente el enunciado proponía utilizar el sensor láser para obtener información del entorno.
Su utilización habría permitido detectar mejor la posición real de las estanterías y actualizar el mapa con mayor precisión, especialmente después de depositarlas.
Al no haber implementado esta funcionalidad, he asumido que las posiciones de depósito y las dimensiones consideradas son correctas.
Esto limita la precisión del mapa y hace que la planificación dependa de que la simulación se comporte de acuerdo con estas estimaciones.

### 8. Posibles mejoras futuras

Como posibles mejoras, considero necesario seguir trabajando en los siguientes aspectos:

- **Precisión del controlador:** mejorar el seguimiento de las trayectorias, reduciendo los errores de posición y orientación, especialmente en curvas y maniobras próximas a obstáculos.
- **Marcha atrás:** realizar un análisis más exhaustivo del comportamiento del robot en retroceso y ajustar los parámetros del controlador para conseguir maniobras más estables y fiables.
- **Recuperación de posición y orientación:** mejorar el mecanismo de corrección final. Actualmente permite ajustar razonablemente el ángulo del robot, pero no consigue corregir adecuadamente su posición, por lo que sería conveniente implementar un procedimiento que permita alcanzar ambas condiciones simultáneamente.
- **Uso del sensor láser:** incorporar la información del láser para detectar la posición real de las estanterías y actualizar el mapa tras cada operación, reduciendo la dependencia de las posiciones estimadas.
- **Planificación y simplificación:** estudiar cómo simplificar las trayectorias sin perjudicar su seguimiento, buscando un equilibrio entre la longitud del camino, la seguridad y la facilidad de ejecución.
