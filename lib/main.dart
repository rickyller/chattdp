import 'package:chatgpt/view/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:io' show Platform; // Importación para detectar la plataforma

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Inicialización de Stripe para las plataformas que no sean Web
    if (!kIsWeb) {
      Stripe.publishableKey = 'pk_live_51PsYtXEFUJxc3qsyiyTDJ7L4HgZYWpye5lOsTof0t1qipKZ079gJyAyBsCUZTOZacxATmyWRnaZ8Y5j3i2T2fvVM00sB9kcCos';
    }

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
      theme: ThemeData(
        fontFamily: 'Nud',
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
