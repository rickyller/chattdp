import 'package:chatgpt/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';  // Asegúrate de importar firebase_options.dart aquí

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,  // Usa las opciones correctas para cada plataforma
    );
    runApp(const MyApp());
  } catch (e) {
    // Manejo de errores durante la inicialización de Firebase
    print('Error al inicializar Firebase: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),  // Asegúrate de que SplashScreen esté correctamente definido
    );
  }
}
