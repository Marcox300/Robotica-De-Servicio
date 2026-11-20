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

Respecto al apartado anterior, la estructura general del programa apenas cambia. Se mantiene la planificación con OMPL y la máquina de estados, pero se amplía la comprobación de colisiones para tener en cuenta la geometría del robot y si está transportando una estantería.

Ahora `isStateValid` comprueba la colisión de un rectángulo orientado según el ángulo del robot. Sus dimensiones dependen de si lleva una estantería: sin ella se utiliza la geometría del robot y, al recogerla, se considera la geometría de la carga.

Hay una discrepancia entre el enunciado y el modelo URDF/Xacro: el ejercicio establece unas dimensiones de 30 × 30 cm, mientras que el modelo presenta una plataforma de 55 × 55 cm. Finalmente utilizo unas dimensiones de 0,7 × 0,7 m para la planificación. Esta decisión se debe a que inicialmente no tuve en cuenta las ruedas ni un margen adicional para facilitar las maniobras y absorber pequeños errores de movimiento.

Para la estantería, considero unas dimensiones aproximadas de 1,85 × 0,80 m (`PALLET_LENGTH` y `PALLET_WIDTH`). También utilizo un margen de 2,4 m (`PALLET_HEIGHT_MARGIN`) para actualizar el mapa al recogerla, aunque en la práctica reduzco esta zona a 1,8 m (`PALLET_WIDTH_MARGIN`).

Por último, el mapa se actualiza según la situación de la carga: al recoger una estantería se elimina su zona de obstáculos y, al depositarla, se incorporan sus patas al mapa. Así, las siguientes planificaciones tienen en cuenta los cambios del entorno.


En el segundo vídeo muestro una prueba para comprobar que el análisis de geometría funciona correctamente: al intentar colocar todas las estanterías en horizontal, algunas colisionarían entre sí. OMPL detecta estas colisiones y evita generar una ruta que permita realizar esa disposición.

> NOTA: videos acelerados x4

<video width="640" height="360" controls>
  <source src="video/holonomica.mp4" type="video/mp4">
  Tu navegador no soporta el video.
</video>
