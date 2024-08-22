import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'chat_screen.dart';
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
      // Navegar a la pantalla principal si el inicio de sesión es exitoso
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ChatScreen()),  // Reemplaza ChatScreen con tu pantalla principal
      );
    } catch (e) {
      // Manejar errores aquí, como mostrar un mensaje de error
      print("Error al iniciar sesión: $e");
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
                "Hello, \nWelcome Back",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: kWhiteColor),  // Color de texto principal
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Image(
                          width: 30,
                          image: AssetImage('assets/icons/google.png')),
                      SizedBox(
                        width: 40,
                      ),
                      Image(
                          width: 30,
                          image: AssetImage('assets/icons/facebook.png'))
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
                        hintText: "Email or Phone Number",
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
                        hintText: "Password",
                        hintStyle: TextStyle(color: kWhiteColor),  // Color del hint text
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    "Forget Password?",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: kWhiteColor),  // Color del texto "Forget Password?"
                  )
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
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kWhiteColor,  // Color del texto del botón
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30,),
                  const Center(
                    child: Text(
                      "Create Account",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kWhiteColor,  // Color del texto "Create Account"
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
