import 'package:chatgpt/view/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  void _signIn() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Obtener el rol del usuario desde Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('role')) {
          String role = userData['role'];

          if (role == 'admin') {
            // Redirigir al administrador a una pantalla gratuita
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ChatScreenAdmin()),  // Pantalla de admin
            );
          } else {
            // Redirigir al usuario a la pantalla de pago
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
      // Manejar errores aquí, como mostrar un mensaje de error
      _showError("Error al iniciar sesión: ${e.toString()}");
    }
  }

  void _showError(String message) {
    print(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  Future<void> _signInWithGoogle() async {
    try {
      // Configura el proveedor de autenticación de Google
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Utiliza signInWithPopup para la autenticación en la web
      UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);

      // Obtener el rol del usuario desde Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
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
      // Intenta enviar el correo de restablecimiento de contraseña sin verificar previamente si el correo está registrado
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
        height: size.height,
        padding: const EdgeInsets.only(left: 20, right: 20, top: 150, bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          Text(
          "Hola, \nBienvenido a ChatTdp",
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: kWhiteColor),  // Color de texto principal
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click, // Cambia el cursor a una manita
                  child: ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: Image.asset('assets/icons/google.png', height: 24, width: 24),
                    label: const Text("Inicia sesión con Google"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),  // Ajuste de padding para un botón más grande
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: kBg300Color,  // Usar kBg300Color para el fondo del botón
                      elevation: 0,
                      foregroundColor: kWhiteColor,  // Usar kWhiteColor para el color del texto
                    ),
                  ),
                ),
                const SizedBox(
                  width: 30,
                ),
              ],
            ),
            const SizedBox(
              height: 50,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: kBg300Color,  // Color de fondo de los campos de texto
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: TextField(
                controller: _emailController,
                style: const TextStyle(color: kWhiteColor),  // Color del texto dentro de los campos
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Correo",
                  hintStyle: TextStyle(color: kWhiteColor),  // Color del hint text
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: kBg300Color,  // Color de fondo de los campos de texto
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: kWhiteColor),  // Color del texto dentro de los campos
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Contraseña",
                  hintStyle: TextStyle(color: kWhiteColor),  // Color del hint text
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,  // Cambia el cursor a una manita
              child: GestureDetector(
                onTap: _resetPassword,  // Llama al método de restablecimiento de contraseña
                child: Text(
                  "¿Olvidó su contraseña?",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: kWhiteColor),  // Color del texto "Forget Password?"
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
          ElevatedButton(
          onPressed: _signIn,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.all(18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: kPrimaryColor,  // Color del botón de Login
          ),
          child: const Center(
            child: Text(
              "Iniciar sesión",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kWhiteColor,  // Color del texto del botón
              ),
            ),
          ),
        ),
        const SizedBox(height: 30,),
        Center(
        child: MouseRegion(
        cursor: SystemMouseCursors.click,  // Cambia el cursor a una manita
        child: GestureDetector(
        onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const RegisterPage()),
      );
        },
          child: const Text(
            "Crear cuenta",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kWhiteColor,
            ),
          ),
        ),
        ),
        ),
          ],
        ),
          ],
        ),
        ),
        ),
    );
  }
}