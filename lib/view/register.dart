import 'dart:async';

import 'package:chatgpt/view/chat_screen_admin.dart';
import 'package:chatgpt/view/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'chat_screen_user.dart';
import '../theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPollingForEmailVerification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPollingForEmailVerification() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _checkEmailVerified(context);
    });
  }

  Future<void> _checkEmailVerified(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    if (user != null && user.emailVerified) {
      // Actualizar el campo en Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'emailVerified': true});

      // Navegar a la pantalla principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<void> _resendVerificationEmail(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correo de verificación reenviado.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg500Color,
      appBar: AppBar(
        backgroundColor: kBg300Color,
        title: Text(
          "Verificación de Correo Electrónico",
          style: TextStyle(
            fontFamily: 'Nud',
            color: kWhiteColor,
            fontWeight: kSemiBold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Hemos enviado un enlace de verificación a tu correo electrónico.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nud',
                  color: kWhiteColor,
                  fontSize: 18,
                  fontWeight: kRegular,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _checkEmailVerified(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "He verificado mi correo",
                  style: TextStyle(
                    fontFamily: 'Nud',
                    fontSize: 16,
                    fontWeight: kSemiBold,
                    color: kWhiteColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _resendVerificationEmail(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  "Reenviar correo de verificación",
                  style: TextStyle(
                    fontFamily: 'Nud',
                    fontSize: 16,
                    fontWeight: kMedium,
                    color: kPrimaryColor,
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

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;

  // Esta lista almacenará los requisitos que faltan o se han cumplido
  List<String> _passwordFeedback = [];

  // Método para actualizar la lista de retroalimentación en tiempo real
  void _updatePasswordFeedback(String password) {
    setState(() {
      _passwordFeedback = getPasswordFeedback(password);
    });
  }

  void _register() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    if (!_isPasswordValid(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La contraseña no cumple con los requisitos: al menos 8 caracteres, incluir una letra mayúscula, una minúscula y un número.")),
      );
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: password,
      );

      // Enviar correo de verificación
      await userCredential.user!.sendEmailVerification();

      // Guardar el rol del usuario en Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text,
        'role': 'user',
        'emailVerified': false,  // Añadir un campo para controlar la verificación
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registro exitoso. Por favor, verifica tu correo electrónico.")),
      );

      // Navegar a la pantalla de espera de verificación
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const EmailVerificationScreen()),  // Nueva pantalla de espera de verificación
      );
    } catch (e) {
      print("Error al registrar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  bool _isPasswordValid(String password) {
    final hasMinLength = password.length >= 8;
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')); // Caracteres especiales

    return hasMinLength && hasUpperCase && hasLowerCase && hasDigits && hasSpecialCharacters;
  }

  List<String> getPasswordFeedback(String password) {
    List<String> feedback = [];

    if (password.length < 8) {
      feedback.add("Debe tener al menos 8 caracteres.");
    } else {
      feedback.add("✔ Tiene al menos 8 caracteres.");
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      feedback.add("Debe incluir una letra mayúscula.");
    } else {
      feedback.add("✔ Incluye una letra mayúscula.");
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      feedback.add("Debe incluir una letra minúscula.");
    } else {
      feedback.add("✔ Incluye una letra minúscula.");
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      feedback.add("Debe incluir un número.");
    } else {
      feedback.add("✔ Incluye un número.");
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      feedback.add("Debe incluir un carácter especial.");
    } else {
      feedback.add("✔ Incluye un carácter especial.");
    }

    return feedback;
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
                          onChanged: _updatePasswordFeedback, // Se actualiza en tiempo real
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
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_passwordVisible, // Controla si la contraseña es visible o no
                          style: const TextStyle(color: kWhiteColor),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Confirmar contraseña",
                            hintStyle: const TextStyle(
                              fontFamily: 'Nud',  // Especifica la fuente Nud aquí
                              fontWeight: FontWeight.bold,
                              color: kWhiteColor,
                            ),
                          ),
                          inputFormatters: [
                            // Bloquear copiado y pegado
                            FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x1F\x7F-\x9F]')), // Restringe caracteres de control
                          ],
                          enableInteractiveSelection: false, // Deshabilita selección de texto
                        ),


                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Validación dinámica de la contraseña
                  Align(
                    alignment: Alignment.centerLeft, // Mantiene la alineación a la izquierda
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10.0), // Añade un pequeño margen a la izquierda
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _passwordFeedback.map((specification) => Text(
                          specification,
                          style: TextStyle(
                            color: specification.startsWith("✔") ? Colors.green : Colors.red, // Verde si se ha cumplido, rojo si no.
                            fontSize: 12,
                            fontFamily: 'Nud', // Aplicar la fuente 'Nud'
                          ),
                        )).toList(),
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

      String newSessionToken = Uuid().v4();

      if (!userDoc.exists) {
        // Si el documento no existe, crear uno nuevo con un rol por defecto y emailVerified en true
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'role': 'user', // O 'admin' si es necesario
          'emailVerified': true, // Marcar el email como verificado
          'sessionToken': newSessionToken, // Establecer el token de sesión
        });
      } else {
        // Si el documento ya existe, asegurarse de que emailVerified esté en true y actualizar el sessionToken
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).update({
            'emailVerified': true,
            'sessionToken': newSessionToken, // Actualizar el token de sesión
          });
        }
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('sessionToken', newSessionToken);

      // Verificar el rol del usuario
      userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      String role = userDoc['role'];

      if (role == 'admin') {
        // Redirigir al administrador a una pantalla gratuita
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatScreenAdmin()),  // Pantalla de admin
        );
      } else {
        // Redirigir al usuario a la pantalla de usuario
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


}
