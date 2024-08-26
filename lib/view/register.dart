import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'chat_screen_user.dart';
import '../theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;

  void _register() async {
    // Validar las características de la contraseña
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      // Mostrar error si las contraseñas no coinciden
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    if (!_isPasswordValid(password)) {
      // Mostrar error si la contraseña no cumple con los requisitos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La contraseña no cumple con los requisitos: al menos 8 caracteres, incluir una letra mayúscula, una minúscula y un número.")),
      );
      return;
    }

    try {
      // Crear usuario en Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: password,
      );

      // Enviar verificación de correo electrónico
      await userCredential.user!.sendEmailVerification();

      // Almacenar el rol del usuario en Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text,
        'role': 'user', // O 'admin' si es un administrador
      });

      // Mostrar mensaje que indique que se ha enviado un correo de verificación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registro exitoso. Por favor, verifica tu correo electrónico.")),
      );

      // Navegar a la pantalla principal si el registro es exitoso
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ChatScreenUser()),  // Reemplaza ChatScreen con tu pantalla principal
      );
    } catch (e) {
      // Manejar errores aquí, como mostrar un mensaje de error
      print("Error al registrar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  bool _isPasswordValid(String password) {
    // Requisitos de la contraseña
    final hasMinLength = password.length >= 8;
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));

    return hasMinLength && hasUpperCase && hasLowerCase && hasDigits;
  }


  Future<void> _signInWithGoogle() async {
    try {
      // Iniciar el flujo de autenticación de Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // El usuario canceló el flujo de inicio de sesión
        return;
      }

      // Obtener los detalles de autenticación de la solicitud
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Crear una nueva credencial
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Una vez que se realiza el inicio de sesión, retorna el UserCredential
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Obtener el documento del usuario en Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Si el documento no existe, crear uno nuevo con un rol por defecto
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'role': 'user', // O 'admin' si es necesario
        });
      }

      // Verificar el rol del usuario
      userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      String role = userDoc['role'];

      if (role == 'admin') {
        // Redirigir al administrador a una pantalla gratuita
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatScreenUser()),  // Pantalla de admin
        );
      } else {
        // Redirigir al usuario a la pantalla de pago
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatScreenUser()),  // Pantalla de usuario
        );
      }
    } catch (e) {
      print("Error al iniciar sesión con Google: $e");
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
                "Crear Cuenta",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
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
                      "Regístrate con Google",
                      style: TextStyle(
                        fontFamily: 'Nud', // Especifica la fuente Nud aquí
                        color: kWhiteColor,
                        fontWeight: FontWeight.bold, // Mantén el texto en negrita si es necesario
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

                  const SizedBox(height: 30),
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
                        hintStyle: const TextStyle(
                          fontFamily: 'Nud',  // Especifica la fuente Nud aquí
                          fontWeight: FontWeight.bold,
                          color: kWhiteColor,
                        ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible, // Controla si la contraseña es visible o no
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

                      ],

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
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: kWhiteColor),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Confirmar contraseña",
                        hintStyle: const TextStyle(
                          fontFamily: 'Nud',  // Especifica la fuente Nud aquí
                          fontWeight: FontWeight.bold,
                          color: kWhiteColor,
                        ),

                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerLeft, // Mantiene la alineación a la izquierda
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10.0), // Añade un pequeño margen a la izquierda
                      child: const Text(
                        "Debe tener al menos 8 caracteres, incluir una letra mayúscula, una minúscula y un número.",
                        style: TextStyle(
                          color: kWhiteColor,
                          fontSize: 12,
                          fontFamily: 'Nud', // Aplicar la fuente 'Nud'
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _register,
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
                    "Registrarse",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kWhiteColor,
                      fontFamily: 'Nud',  // Especifica la fuente Nud aquí

                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Center(
                    child: Text(
                      "¿Ya tienes una cuenta? Inicia sesión.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nud',  // Especifica la fuente Nud aquí
                        color: kWhiteColor,
                      ),
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
