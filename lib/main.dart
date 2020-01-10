import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart'; //Paquete que da acceso a las cámaras del dispositivo
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart'; //Paquete para encontrar localizaciones comúnmente usadas dentro del dispositivo
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; //Paquete utilizado para implementar los botones de las opciones de la cámara
import 'package:geolocator/geolocator.dart'; //Paquete para recuperar las coordenadas y obtener la dirección a partir de ellas
import 'package:flutter_map/flutter_map.dart'; //Paquete para mostrar el mapa
import 'package:latlong/latlong.dart'; //Paquete para construir un objeto de la clase LatLng
import 'package:firebase_auth/firebase_auth.dart'; //Paquete para realizar la autenticación de usuario con Firebase
import 'package:google_sign_in/google_sign_in.dart'; //Paquete para realizar el inicio de sesión con Google
import 'package:twitter_api/twitter_api.dart'; //Paquete para publicar tweet por medio de la API de Twitter
import 'dart:convert'; //Paquete convertir tipos de datos en Dart (como json)
import 'package:esys_flutter_share/esys_flutter_share.dart'; //Paquete para compartir imágenes y texto con otras aplicaciones (como Twitter)


final FirebaseAuth auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

main() {
  WidgetsFlutterBinding.ensureInitialized();

  //Para cerrar sesión y que pueda hacerse login con otra cuenta de usuario
  googleSignIn.signOut();
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Inicio(),
    ),
  );
}

//Widget para la pantalla de inicio
class Inicio extends StatefulWidget {
  @override
  InicioState createState() => InicioState();
}

class InicioState extends State<Inicio> {
  var nombre = "Sin nombre";
  var foto = 'Sin foto';

  InicioState(){
    hacerLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Caza Mayor")),
      body: ListView(
          children: <Widget>[
            Center(
              child: Text(
                "Bienvenido a Caza Mayor",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.blue,
                  fontSize: 20,
                ),
              ),
            ),
            Center(
              child: Text(
                "Tu app para denunciar la presencia de perros peligrosos",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.blue,
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.0),
              child: Image.asset('images/perroInicio.jpg', width: 400, height: 300, fit: BoxFit.cover,),
            ),
            if(foto != 'Sin foto') Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: <Widget>[
                    Text(
                      nombre,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.network(foto),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              child: Text('Menú Opciones'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Acceso a Cámara'),
              onTap: () async {
                // Obtiene una lista de las cámaras disponibles en el dispositivo.
                final cameras = await availableCameras();
                // Obtiene una cámara específica de la lista de cámaras disponibles
                final firstCamera = cameras.first;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TakePictureScreen(camera: firstCamera),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<FirebaseUser> signInWithGoogle() async {
    print("Que voy !!");
    final GoogleSignInAccount googleSignInAccount = await
    googleSignIn.signIn();
    print("ha pasado signin");
    final GoogleSignInAuthentication googleSignInAuthentication =
    await googleSignInAccount.authentication;
    print("ha pasado autentication");
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );
    print("Got credential");
    final AuthResult authResult = await
    auth.signInWithCredential(credential);
    print("ha pasado sign with credential");
    final FirebaseUser user = authResult.user;
    print (user.toString());
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);
    final FirebaseUser currentUser = await auth.currentUser();
    assert(user.uid == currentUser.uid);
    return user;
  }

  void hacerLogin(){
    print("Click");
    signInWithGoogle().then(
            (m){
          setState(() {
            nombre = "Hola "+m.displayName;
            foto = m.photoUrl;
            print("La misma url que la asignada a la variable foto: "+ m.providerData[0].photoUrl.toString());
          });
          print(m.toString());}
    );
  }

}


//Widget que permite a los usuarios tomar una fotografía utilizando una cámara determinada.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  //Variable Lista para almacenar todos los path de las imágenes tomadas
  List<String> imagenes = List();

  String pathBase = "Sin directorio";
  String path = "";
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  TakePictureScreenState(){
    print("Constructor del TakePictureScreenState");
    getExternalStorageDirectory().then(
            (x){
          setState(() {
            pathBase = x.path;
            print("Directorio donde se almacenará la imagen: "+ pathBase);
          });
        }
    );
  }

  @override
  void initState() {
    super.initState();
    // Para visualizar la salida actual de la cámara, se crea un CameraController.
    _controller = CameraController(
      // Obtiene una cámara específica de la lista de cámaras disponibles
      widget.camera,
      // Define la resolución a utilizar
      ResolutionPreset.medium,
    );

    //Inicializar el controlador
    _initializeControllerFuture = _controller.initialize();
  }


  @override
  void dispose() {
    //Deshacerte del controlador cuando se deshace del Widget.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tira 5 fotos al delincuente')),
      //Espera hasta que el controlador se inicialice antes de mostrar la vista previa de la cámara.
      //Se utiliza un FutureBuilder para mostrar un spinner de carga hasta que el controlador haya terminado de inicializar.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            print("Sí disponible");
            //Si el Future está completo, muestra la vista previa
            return CameraPreview(_controller);
          } else {
            print("No disponible");
            //Si el Future no está completo, muestra un indicador de carga
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: SpeedDial(
        marginRight: 18,
        marginBottom: 20,
        child: Icon(Icons.camera_alt),
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: 22.0),
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () => print('OPENING DIAL'),
        onClose: () => print('DIAL CLOSED'),
        tooltip: 'Speed Dial',
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 8.0,
        shape: CircleBorder(),
        children: [
          SpeedDialChild(
            child: Icon(Icons.camera_alt),
            backgroundColor: Colors.red,
            label: '1 foto',
            labelStyle: TextStyle(fontSize: 14.0, color: Colors.black),
            onTap: () async {
              // Toma la foto en un bloque de try / catch. Si algo sale mal se atrapa el error.
              try {
                //Asegura que la cámara se ha inicializado
                await _initializeControllerFuture;

                //Se construye la ruta donde la imagen debe ser guardada usando el paquete path.

                //Si la función asíncrona llamada en el constructor de TakePictureScreenState ha devuelto ya el directorio
                if(pathBase != "Sin directorio"){
                  path = join(pathBase, '${DateTime.now()}.png');
                  print("La ruta de la imagen es: "+ path);
                  await _controller.takePicture(path); //Hace la primera foto
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisplayPictureScreen(imagePath: path),
                  ),
                );
              } catch (e) {
                // Si se produce un error, se registra en la consola.
                print(e);
              }
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.filter_5),
            backgroundColor: Colors.blue,
            label: '5 fotos',
            labelStyle: TextStyle(fontSize: 14.0, color: Colors.black),
            onTap: () async {
              // Toma la foto en un bloque de try / catch. Si algo sale mal se atrapa el error.
              try {
                //Asegura que la cámara se ha inicializado
                await _initializeControllerFuture;

                //Se construye la ruta donde la imagen debe ser guardada usando el paquete path.

                var counter = 0;

                //Si la función asíncrona llamada en el constructor de TakePictureScreenState ha devuelto ya el directorio
                if(pathBase != "Sin directorio"){
                  path = join(pathBase, '${DateTime.now()}.png');
                  print("La ruta de la imagen es: "+ path);
                  imagenes.add(path);
                  for(var i in imagenes){print("Imagen es: "+i);}
                  await _controller.takePicture(path); //Hace la primera foto

                  counter ++;
                  var timer;
                  timer = Timer.periodic(Duration(
                      seconds: 2), (timer) async {
                    path = join(pathBase, '${DateTime.now()}.png');
                    print("La ruta de la imagen es: "+ path);
                    imagenes.add(path);
                    for(var i in imagenes){print("Imagen es: "+i);}
                    await _controller.takePicture(path); //Se hacen 5 fotos en total, una cada 2 segundos
                    counter++;

                    if( counter == 5 ){
                      timer.cancel();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GaleriaFotos(imagenes: imagenes),
                        ),
                      );
                    }

                    setState(() {});
                  });
                }

              } catch (e) {
                // Si se produce un error, se registra en la consola.
                print(e);
              }
            },
          ),
        ],
      ),

    );
  }
}

//Widget que muestra la imagen tomada por el usuario
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Foto Cazada')),
      // La imagen se almacena como un archivo en el dispositivo. Se usa el constructor Image.file con la ruta dada para mostrar la imagen
      body: Image.file(File(imagePath)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Publicar(imagePath: imagePath),
            ),
          );
        },
        child: Icon(Icons.navigate_next),
        backgroundColor: Colors.green,
      ),
    );
  }
}


//Widget para mostrar las fotos tomadas y permitir al usuario elegir una de ellas
class GaleriaFotos extends StatelessWidget {
  final List<String> imagenes;
  String imagenElegida = "";

  GaleriaFotos({Key key, this.imagenes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Galería Fotos')),
      // La imagen se almacena como un archivo en el dispositivo. Usa el constructor Image.file con la ruta dada para mostrar la imagen
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3 ,
        ),
        itemBuilder: (context, index){
          return GestureDetector(
              onTap: (){
                print("Imagen elegida");
                imagenElegida = imagenes[index];

                //Bucle para eliminar las imágenes tomadas que no han sido elegidas
                for(var imagen in imagenes) {
                  if(imagen != imagenElegida){
                    var directorioEliminar = new Directory(imagen);
                    directorioEliminar.deleteSync(recursive: true);
                  }
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Publicar(imagePath: imagenElegida),
                  ),
                );
              },
              child: Image.file(File(imagenes[index]))
          );
        },
        itemCount: imagenes.length,
      ),
    );
  }
}

//Widget para publicar la foto elegida
class Publicar extends StatefulWidget {
  final String imagePath;

  const Publicar({
    Key key,
    @required this.imagePath,
  }) : super(key: key);

  @override
  PublicarState createState() => PublicarState(imagePath);
}

class PublicarState extends State<Publicar> {
  final controlador = TextEditingController();

  String imagePath;
  Geolocator geolocator = Geolocator();
  Position userLocation;
  List<Placemark> placemark;
  double latitud=0.0;
  double longitud=0.0;
  String calle="";
  String numero="";
  String ciudad="";
  String codigoPostal="";
  String pais="";

  PublicarState(imagePath){
    this.imagePath = imagePath;
    print("Constructor del PublicarState");
  }

  @override
  void initState() {
    super.initState();
    _getLocation().then((position){
      setState(() {
        userLocation = position;
      });
      latitud = userLocation.latitude;
      longitud = userLocation.longitude;
      obtenerCoordenadas();
    });
  }

  void obtenerCoordenadas() async {
    if(userLocation != null){
      placemark = await Geolocator().placemarkFromCoordinates(userLocation.latitude, userLocation.longitude);
      setState(() {
        calle = placemark[0].thoroughfare;
        numero = placemark[0].subThoroughfare;
        ciudad = placemark[0].locality;
        codigoPostal = placemark[0].postalCode;
        pais = placemark[0].country;
      });
    }
  }

  Future<Position> _getLocation() async {
    var currentLocation;
    try {
      currentLocation = await geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
    } catch (e) {
      currentLocation = null;
    }
    return currentLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Publicar Foto')),
      body: ListView(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(8.0),
            child: Image.file(File(imagePath), height: 200, width: 400,),
          ),
          Container(
            padding: EdgeInsets.all(8.0),
            child: TextFormField(
              controller: controlador,
              decoration: InputDecoration(
                  labelText: 'Escribe un comentario'
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.0),
            child: Text("Localización perro peligroso: "+calle+" "+numero+", "+codigoPostal+" "+ciudad+", "+pais),
          ),
          Container(
            padding: EdgeInsets.only(top: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  padding: const EdgeInsets.all(12.0),
                  textColor: Colors.white,
                  color: Colors.green,
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => VerMapa(latitud, longitud)
                    ));

                  },
                  child: Text("Ver Mapa"),
                ),
                RaisedButton(
                  padding: const EdgeInsets.all(12.0),
                  textColor: Colors.white,
                  color: Colors.orange,
                  onPressed: () async {
                    String mensaje = controlador.text;
                    mensaje += ". Localización perro peligroso: "+calle+" "+codigoPostal+" "+ciudad+", "+pais;

                    File ficheroImagen = File(imagePath);
                    await Share.file("Foto Caza Mayor", "fotocazamayor.png", ficheroImagen.readAsBytesSync(), "image/png", text: mensaje);

                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => Inicio()
                    ));

                  },
                  child: Text("Compartir"),
                ),
                RaisedButton(
                  textColor: Colors.white,
                  color: Colors.blue,
                  padding: const EdgeInsets.all(12.0),
                  onPressed: () async {
                    print("Se publica el tweet");
                    String mensaje = controlador.text;

                    Image imagen = Image.file(File(imagePath));

                    publicarTweet(mensaje, imagen, imagePath);

                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => Inicio()
                    ));
                  },
                  child: Text(
                    "Twittear",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void publicarTweet(String mensaje, Image imagen, String imagePath) async {
    final _twitterOauth = new twitterApi(
        consumerKey: "QR9V0mekAzVm7CBmrWWxYV2Yp",
        consumerSecret: "nri7DCR6Zfn6bw0UxU7aCwEQ7bTJb3GhNrJcv9k9yPXdUyfhOq",
        token: "1213463248663531521-UjYDhg8Chl7Cb4hiBDTedojJGkpt5O",
        tokenSecret: "fPabHVlN7K4yschvtzsthIrj088DngXb1sNEG2K80tfzL"
    );

    mensaje += ". Localizado perro peligroso en "+ciudad;

    Future twitterRequest = _twitterOauth.getTwitterRequest(
      //Método HTTP utilizado
      "POST",
      //Url a la que hacer la petición
      "statuses/update.json",

      //Opciones(parámetros) para la petición
      options: {
        "status": mensaje,
      },
    );

    //Espera a que el Future asociado a la respuesta llegue
    var res = await twitterRequest;

    print("Antes de la llegada de la respuesta");

    // Print off the response
    print(res.statusCode);
    print(res.body);

    //Convierte el resultado devuelto por la petición a un objeto JSON
    final body = json.decode(res.body);

    print("Después de la llegada de la respuesta"+ body['created_at']);
  }

}

//Widget para mostrar el mapa a partir de la localización donde se tomó la foto
class VerMapa extends StatelessWidget {
  double latitud=0.0;
  double longitud=0.0;

  VerMapa(lat, long){
    latitud = lat;
    longitud = long;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(title: new Text('Map Application'),),
      body: Stack(
        children: <Widget>[
          FlutterMap(
              options: MapOptions(minZoom: 10.0,center:  new LatLng(latitud, longitud)),
              layers: [
                TileLayerOptions(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a','b','c']),
                MarkerLayerOptions(
                    markers: [
                      Marker(
                          width: 70.0,
                          height: 70.0,
                          point: LatLng(latitud, longitud),
                          builder: (context)=> Container(child: Icon(Icons.location_on, color: Colors.red),
      ))])])
    ],),);
  }
}


