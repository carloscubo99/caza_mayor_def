# PRÁCTICA CAZA MAYOR

Miembros del equipo de trabajo: Carlos Cubo Izquierdo y Joseba Ramos Martínez

## Introducción

Nuestra práctica *Caza Mayor* se ha desarrollado en Flutter, un SDK de código fuente abierto que utiliza Dart como lenguaje de programación. 

Las aplicaciones móviles desarrolladas en Flutter se componen de diversos widgets con los que se implementa la interfaz que se presenta al usuario. 

Esta práctica está compuesta por varias pantallas, representadas por widgets generales que a su vez contienen otros widgets en su interior. El paso de una a otra se lleva a cabo por medio del método push de la clase Navigator. 

## Partes Principales

Destacan 6 widgets principales, que son los siguientes: 

- **Inicio**: widget stateful que constituye la pantalla principal de la app. El contenido de esta pantalla incluye una imagen cargada desde los assets y otra recuperada al realizar el inicio de sesión con Google. 
- **TakePictureScreen**: widget stateful que visualiza en pantalla la cámara con la que se realizará la foto. A la hora de hacer la foto se tienen las opciones: 1 foto y 5 fotos. 
- **DisplayPictureScreen**: widget stateless que se visualiza en caso de realizar una única foto. Muestra al usuario la foto realizada. 
- **GaleriaFotos**: widget stateless que se visualiza en caso de realizar las 5 fotos. Muestra una galería con las 5 fotografías tomadas y permite al usuario escoger una de ellas para su posterior publicación. 
- **Publicar**: widget stateful que presenta la pantalla para la publicación del tweet. Permite al usuario introducir un texto propio, que será agregado al de la localización obtenida, visualizar un mapa a partir de la localización calculada y por último publicar el tweet. 
- **VerMapa**: widget stateless utilizado para presentar en un mapa la localización exacta donde se ha realizado la fotografía. 

## Dependencias

Para algunas de las operaciones realizadas en la práctica se ha hecho uso de clases y métodos definidos en paquetes implementados por desarrolladores de la comunidad de Flutter. 

Para su uso se han declarado las siguientes dependencias en el archivo pubspec.yaml del proyecto: 

- **camera**
- **path_provider**
- **path**
- **flutter_speed_dial**
- **geolocator**
- **firebase_auth**
- **google_sign_in**
- **twitter_api**
- **esys_flutter_share**
- **flutter_map**
- **latlong**

## Implementación

En cuanto a la implementación de la práctica destacan las siguientes características implementadas: 

- En cuanto a la implementación de la práctica destacan las siguientes características implementadas: 
- La app ofrece la opción de tomar 1 o 5 fotos
- Lectura de las coordenadas GPS
- Derivación de la dirección a partir de las coordenadas GPS
- Publicación de mensaje en red social Twitter
- La app presenta un mapa para mostrar la localización de la foto

Este proyecto también ha sido subido a la plataforma GitHub. 

