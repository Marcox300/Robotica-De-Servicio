# [Aparcamiento autónomo con Ackermann y LiDAR](index.md)

## 1. Objetivo

El coche tiene dinámica Ackermann, se controla en V-W. Además cuenta con sensor GPS (+brújula para orientación) y principalmente un sensor LIDAR 360 que le da información de distancia a obstáculos alrededor. Vuestro coche tiene que aparcar usando el LIDAR, aunque para pruebas iniciales de las decisiones de movimiento podeís probar también, alternativamente, con tres láseres, en el lateral, frontal y parte trasera. La detección de hueco para aparcar tiene que ser segura y robusta incluso a que haya árboles finos o paredes junto a la calle. El algoritmo tiene que ser robusto a que el coche aparque en calles en cualquier orientación absoluta, por lo que no es adecuado el uso de posición GPS (salvo incrementalmente, en cualquier orientación). El vehículo deber aparcar sin problemas en el hueco entre dos coches y también cuando sólo hay coche delantero o sólo con coche trasero como referencia. El coche puede arrancar no alineado con respecto a la calle y a una distancia adecuada no adecuada del lateral de la calle. Por ello se recomienda estimar la dirección de la calle (a partir de los datos de sensores láser) e incluir una primera fase en el algoritmo para que el robot se alinee correctamente y se sitúe a una distancia del lateral derecho razonable.

### Estrategia de resolución
Para abordar este problema, nos basaremos en una maniobra de aparcamiento con un giro inicial de aproximadamente 45° respecto a la línea de vehículos.
Esta estrategia permite introducir el coche en el hueco mediante una trayectoria progresiva, reduciendo el número de correcciones necesarias y consiguiendo una maniobra más limpia.

El algoritmo se organiza en varias fases: filtrado de los datos del LiDAR, estimación de la orientación de la línea de aparcamiento, aproximación y búsqueda de un hueco adecuado,
alineación para iniciar la maniobra y ejecución del aparcamiento con las correcciones finales necesarias.

## 2. Procesamiento del LiDAR

Antes de utilizar los datos del sensor, es necesario realizar un filtrado para quedarnos únicamente con los puntos relevantes para la maniobra.

- Filtrado por altura: seleccionamos una franja de altura para eliminar puntos del suelo y elementos que no resultan útiles para detectar los vehículos en mi caso entre (-1.2, -1.3).
- Eliminación del propio vehículo: descartamos los puntos que se encuentran dentro de los límites de nuestro coche, definidos mediante `CAR_X_MIN`, `CAR_X_MAX`, `CAR_Y_MIN` y `CAR_Y_MAX`.

> **Visualización:** En la siguiente imagen se muestra el recuadro que delimita el vehículo y cuyos puntos LiDAR se descartan durante el filtrado.

<img width="948" height="517" alt="coche" src="https://github.com/user-attachments/assets/7427dbcb-a160-468e-8308-c0bbcd7ce849" />

## 3. Detección de la orientación de la línea de coches — Estado 0

En este estado detectamos los puntos correspondientes a los vehículos aparcados y utilizamos un ajuste polinómico por el método de mínimos cuadrados para estimar la orientación de la línea de coches.

A partir de la pendiente de la recta ajustada calculamos el ángulo respecto a nuestro vehículo. De esta forma podemos corregir nuestra orientación y colocarnos paralelos a la línea de aparcamiento.

**Problema encontrado y solución:** cuando queremos aparcar utilizando únicamente una referencia frontal, disponemos de muy pocos puntos de la línea lateral de coches. 
Además, podemos detectar muchos más puntos pertenecientes al maletero de otro vehículo, que forman una línea distinta y pueden distorsionar el ajuste. 
Por este motivo, en ese caso comenzamos directamente en el estado siguiente, asumiendo que el vehículo ya está paralelo a la línea de aparcamiento.

## 4. Aproximación a la línea de aparcamiento — Estado 1

Una vez establecida la orientación, nos aproximamos a la línea de coches para dejar espacio suficiente respecto a la zona de maniobra. 
Esto también permite que otros vehículos puedan circular y facilita la posterior entrada en el hueco.

Durante esta fase utilizamos las diferencias de posición para determinar cuándo debemos realizar los giros y corregir nuestra trayectoria. 
El objetivo es alcanzar una posición adecuada antes de comenzar a buscar un espacio libre.

## 5. Búsqueda del hueco — Estado 2

Como ya conocemos la orientación de la línea de coches, podemos buscar los espacios libres utilizando las coordenadas del LiDAR.

Primero ordenamos los puntos en función de su coordenada Y, de manera que podamos recorrerlos y detectar los huecos entre vehículos consecutivos.

Para aceptar un hueco comprobamos dos condiciones:

1. Longitud disponible: descartamos los huecos cuya longitud sea inferior a 4.45 m, garantizando así que exista espacio suficiente para el largo del vehículo.
2. Anchura disponible: una vez localizado un hueco con longitud suficiente, comprobamos que también exista espacio en el eje X para que el coche pueda entrar.

Cuando ambas condiciones se cumplen, guardamos los puntos que delimitan el espacio para utilizarlos durante la siguiente fase.

> **Visualización:** En la siguiente imagen se muestra el hueco detectado y validado por el algoritmo.

<img width="948" height="517" alt="aparcar" src="https://github.com/user-attachments/assets/e8b0b846-6837-4333-ae1a-d4a36f11207d" />

**Problema encontrado y solución:** en algunos casos el hueco puede estar delimitado únicamente por una referencia detectable. Para poder representar correctamente los límites del espacio y facilitar los cálculos posteriores, añadimos dos puntos artificiales en coordenadas del LiDAR:

- Uno en Y = 10.
- Otro en Y = -10.

Estos puntos se sitúan por debajo del alcance máximo del LiDAR (15 m) y permiten simular referencias en los extremos del hueco, incluso cuando solo se detecta uno de sus límites.

## 6. Alineación para comenzar el aparcamiento — Estado 3

Una vez localizado el hueco, nos colocamos a una distancia suficiente de la referencia más lejana para disponer de espacio para realizar el giro.

A continuación giramos hasta conseguir que la esquina trasera derecha del vehículo quede aproximadamente alineada con el coche o punto de referencia, formando un ángulo de unos 45° respecto a la línea de vehículos.

Esta posición inicial permite comenzar la maniobra de marcha atrás con una trayectoria adecuada para introducir el vehículo en el hueco.

## 7. Maniobra de aparcamiento — Estado 4

La maniobra se divide en dos movimientos:

1. Primera marcha atrás: retrocedemos manteniendo el giro inicial para introducir la parte trasera del vehículo en el hueco.
2. Inversión del giro: después de avanzar la distancia prevista, invertimos el sentido del giro mientras continuamos retrocediendo. De esta forma conseguimos introducir el vehículo y aproximarlo a la orientación final.

Durante toda esta fase comprobamos los datos del LiDAR para detectar posibles colisiones por la parte trasera. Si nos acercamos demasiado a un obstáculo, detenemos la maniobra para evitar chocar.

## 8. Corrección de la posición final — Estado 5

En el último estado corregimos la posición del vehículo si la maniobra anterior no ha terminado de dejarlo paralelo a la línea de coches.
Si nos hemos pasado de la posición deseada, rectificamos avanzando hacia delante y terminamos de alinear el vehículo.
Además, comprobamos si existen obstáculos demasiado cerca tanto delante como detrás.
Si es necesario, desplazamos ligeramente el coche para dejar algo más de espacio y permitir que los demás conductores puedan maniobrar.

## 9. Finalización — Estado 6

Cuando el vehículo se encuentra correctamente aparcado, detenemos el movimiento y damos por finalizada la maniobra.

## 10. Resultados

### 10.1. Aparcamiento con dos referencias

<video width="640" height="360" controls>
  <source src="video/2_ref.mp4" type="video/mp4">
  Tu navegador no soporta el video.
</video>

En este vídeo se muestra cómo el vehículo detecta el hueco delimitado por dos coches y realiza la maniobra de aparcamiento de forma directa,
necesitando muy pocas correcciones. Además, una vez finalizada la maniobra, ajusta su posición para dejar una distancia de seguridad respecto al vehículo trasero,
facilitando así las maniobras de salida y entrada de otros conductores.

### 10.2. Aparcamiento utilizando únicamente la referencia trasera

<video width="640" height="360" controls>
  <source src="video/ref_tra.mp4" type="video/mp4">
  Tu navegador no soporta el video.
</video>

### 10.3. Aparcamiento utilizando únicamente la referencia delantera

<video width="640" height="360" controls>
  <source src="video/ref_del.mp4" type="video/mp4">
  Tu navegador no soporta el video.
</video>

El vehículo aparca utilizando únicamente el coche delantero como referencia. Debido a la dificultad para detectar la orientación con pocos puntos,
se omite la fase inicial y se asume que ya está paralelo a la línea de aparcamiento.

### 10.4. Aparcamiento con una orientación inicial inclinada

<video width="640" height="360" controls>
  <source src="video/ang.mp4" type="video/mp4">
  Tu navegador no soporta el video.
</video>

## 11. Mejoras futuras

A partir de las limitaciones encontradas durante el desarrollo, proponemos las siguientes mejoras:

- Incorporación de cámaras: el sistema depende actualmente de las referencias del LiDAR, lo que dificulta aparcar sin vehículos cercanos.
Las cámaras permitirían reconocer líneas de aparcamiento y otros elementos del entorno.

- Orientación con una única referencia trasera: cuando solo disponemos de un vehículo detrás y no estamos paralelos a la línea de aparcamiento,
el sistema tiene dificultades para estimar su orientación. Se podría implementar un método alternativo que permita corregirla antes de iniciar la maniobra.

- Mayor precisión en la estimación de la orientación: el ajuste por mínimos cuadrados puede verse afectado por puntos de otros elementos, como los maleteros.
Métodos más robustos, como RANSAC, permitirían reducir esta influencia.

- Mejora de la seguridad durante las maniobras: se podría tener en cuenta la trayectoria prevista del vehículo, además de la distancia actual a los obstáculos,
para anticipar posibles colisiones durante los giros y las correcciones.
