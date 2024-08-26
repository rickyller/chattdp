import 'package:chatgpt/view/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen_admin.dart';
import 'chat_screen_user.dart';
import '../theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _passwordVisible = false; // Estado para controlar la visibilidad de la contraseña

  @override
  void initState() {
    super.initState();
    _loadUserCredentials(); // Cargar credenciales guardadas si existen
  }

  // Cargar credenciales almacenadas
  void _loadUserCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('email') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  // Guardar credenciales si 'Recordar contraseña' está activado
  void _saveUserCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('email', _emailController.text);
    prefs.setString('password', _passwordController.text);
    prefs.setBool('remember_me', _rememberMe);
  }

  // Eliminar credenciales guardadas
  void _clearUserCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('email');
    prefs.remove('password');
    prefs.remove('remember_me');
  }

  void _signIn() async {
    if (_rememberMe) {
      _saveUserCredentials(); // Guardar credenciales
    } else {
      _clearUserCredentials(); // Borrar credenciales
    }
    try {
      print('Intentando iniciar sesión con el correo: ${_emailController.text}');
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      print('Inicio de sesión exitoso: UID = ${userCredential.user!.uid}');

      // Obtener el rol del usuario desde Firestore
      print('Obteniendo datos del usuario desde Firestore...');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        print('Datos del usuario encontrados en Firestore.');
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('role')) {
          String role = userData['role'];
          print('Rol del usuario: $role');

          if (role == 'admin') {
            print('Redirigiendo al administrador a la pantalla de admin.');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ChatScreenAdmin()),  // Pantalla de admin
            );
          } else {
            print('Redirigiendo al usuario a la pantalla de usuario.');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ChatScreenUser()),  // Pantalla de usuario
            );
          }
        } else {
          _showError("Rol de usuario no encontrado. Por favor, contacta con soporte.");
        }
      } else {
        _showError("No se encontró un rol para este usuario.");
      }
    } catch (e) {
      print('Error durante el inicio de sesión: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'network-request-failed') {
          _showError("Error de red: Verifique su conexión a internet.");
        } else {
          _showError("Error al iniciar sesión: ${e.message}");
        }
      } else {
        _showError("Error desconocido: ${e.toString()}");
      }
    }
  }

  void _showError(String message) {
    print('Mostrando error: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      print('Intentando iniciar sesión con Google.');
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      print('Inicio de sesión con Google exitoso: UID = ${userCredential.user!.uid}');

      print('Obteniendo datos del usuario desde Firestore...');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'];
        print('Rol del usuario: $role');

        if (role == 'admin') {
          print('Redirigiendo al administrador a la pantalla de admin.');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ChatScreenUser()),  // Pantalla de admin
          );
        } else {
          print('Redirigiendo al usuario a la pantalla de usuario.');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ChatScreenUser()),  // Pantalla de usuario
          );
        }
      } else {
        print("No se encontró un rol para este usuario.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cuenta no encontrada. Por favor regístrate.")),
        );
      }
    } catch (e) {
      print("Error al iniciar sesión con Google: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, ingresa tu correo electrónico.")),
      );
      return;
    }

    try {
      print('Enviando enlace de restablecimiento de contraseña a: ${_emailController.text}');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Si existe una cuenta asociada con este correo, se ha enviado un enlace para restablecer la contraseña.")),
      );
    } catch (e) {
      print("Error al enviar enlace de restablecimiento de contraseña: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    return Scaffold(
      backgroundColor: kBg500Color,  // Fondo de la pantalla
      body: SingleChildScrollView(
        child: Container(
          width: size.width,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Hola, \nBienvenido a ChatTDP",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: kWhiteColor,
                  fontFamily: 'Nud', // Aplicar la fuente 'Nud'
                ),
              ),

              const SizedBox(height: 50),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: Image.asset('assets/icons/google.png', height: 24, width: 24),
                      label: const Text(
                        "Inicia sesión con Google",
                        style: TextStyle(
                          fontFamily: 'Nud', // Especifica la fuente Nud aquí
                          color: kWhiteColor,
                          fontWeight: FontWeight.bold, // Si deseas mantener el texto en negrita
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: kBg300Color,
                        elevation: 0,
                        foregroundColor: kWhiteColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: kBg300Color,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(color: kWhiteColor),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Correo",
                        hintStyle: TextStyle(
                          fontFamily: 'Nud',  // Especifica la fuente Nud aquí
                          fontWeight: FontWeight.bold,
                          color: kWhiteColor,
                        ),

                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Campo de contraseña con ícono de ojo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: kBg300Color,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible, // Aquí se controla si la contraseña es visible
                      style: const TextStyle(color: kWhiteColor),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Contraseña",
                        hintStyle: const TextStyle(
                          fontFamily: 'Nud',  // Especifica la fuente Nud aquí
                          fontWeight: FontWeight.bold,
                          color: kWhiteColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible ? Icons.visibility : Icons.visibility_off,
                            color: kWhiteColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  // Casilla de verificación 'Recordar contraseña'
                  Row(
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                          unselectedWidgetColor: kWhiteColor, // Color del borde cuando no está seleccionado
                        ),
                        child: Checkbox(
                          value: _rememberMe,
                          checkColor: kBg500Color, // Color del checkmark
                          activeColor: kPrimaryColor, // Color de fondo cuando está seleccionado
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value!;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5), // Esquinas redondeadas
                          ),
                        ),
                      ),
                      const Text(
                        'Recordar contraseña',

                        style: TextStyle(
                          fontFamily: 'Nud',  // Especifica la fuente Nud aquí
                          fontWeight: FontWeight.bold,
                          color: kWhiteColor,
                        ),                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _resetPassword,
                      child: Text(
                        "¿Olvidó su contraseña?",
                        style: TextStyle(
                          fontFamily: 'Nud',  // Especifica la fuente Nud aquí
                          fontWeight: FontWeight.bold,
                          color: kWhiteColor,
                        ),

                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),  // Espacio entre las secciones
              ElevatedButton(
                onPressed: _signIn,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: kPrimaryColor,
                ),
                child: const Center(
                  child: Text(
                    "Iniciar sesión",
                    style: TextStyle(
                      fontFamily: 'Nud',  // Especifica la fuente Nud aquí
                      fontWeight: FontWeight.bold,
                      color: kWhiteColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),  // Ajuste del espacio entre los botones
              ElevatedButton(
                onPressed: () {
                  print("Navegando a la pantalla de registro.");
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: kPrimaryColor,
                ),
                child: const Center(
                  child: Text(
                    "Crear cuenta",
                    style: TextStyle(
                      fontFamily: 'Nud',  // Especifica la fuente Nud aquí
                      fontWeight: FontWeight.bold,
                      color: kWhiteColor,
                    ),
                  ),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }

}
