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

  void _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      // Mostrar error si las contraseñas no coinciden
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    try {
      // Crear usuario en Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
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
        height: size.height,
        padding: const EdgeInsets.only(left: 20, right: 20, top: 150, bottom: 80),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Text(
    "Create Account",
    style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: kWhiteColor),  // Color de texto principal
    ),
    Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
    Align(
    alignment: Alignment.centerLeft,  // Coloca el botón en el lado izquierdo
    child: ElevatedButton.icon(
    onPressed: _signInWithGoogle,
    icon: Image.asset('assets/icons/google.png', height: 24, width: 24),
    label: const Text("Regístrate con Google"),
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

    const SizedBox(height: 30),
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
    Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    decoration: BoxDecoration(
    color: kBg300Color,  // Color de fondo de los campos de texto
    borderRadius: const BorderRadius.all(Radius.circular(20)),
    ),
    child: TextField(
    controller: _confirmPasswordController,
    obscureText: true,
    style: const TextStyle(color: kWhiteColor),  // Color del texto dentro de los campos
    decoration: const InputDecoration(
    border: InputBorder.none,
    hintText: "Confirmar contraseña",
    hintStyle: TextStyle(color: kWhiteColor),  // Color del hint text
    ),
    ),
    ),
    const SizedBox(
    height: 20,
    ),
    ],
    ),
    Column(
    children: [
    ElevatedButton(
    onPressed: _register,
    style: ElevatedButton.styleFrom(
    elevation: 0,
    padding: const EdgeInsets.all(18),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    ),
    backgroundColor: kPrimaryColor,  // Color del botón de registro
    ),
    child: const Center(
    child: Text(
    "Registrarse",
    style: TextStyle(
    fontWeight: FontWeight.bold,
    color: kWhiteColor,  // Color del texto del botón
    ),
    ),
    ),
    ),
    const SizedBox(height: 30,),
    MouseRegion(
    cursor: SystemMouseCursors.click, // Cambia el cursor a una manita
    child: GestureDetector(                    onTap: () {
      // Navegar a la página de inicio de sesión
      Navigator.of(context).pop();
    },
      child: const Center(
        child: Text(
          "¿Ya tienes una cuenta? Inicia sesión.",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kWhiteColor,  // Color del texto "Sign In"
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
    ));
  }
}
