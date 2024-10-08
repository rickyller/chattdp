import 'package:chatgpt/view/cancel_url.dart';
import 'package:chatgpt/view/splash_screen.dart';
import 'package:chatgpt/view/success_url.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Inicialización de Stripe para las plataformas que no sean Web
    if (!kIsWeb) {
      Stripe.publishableKey = 'pk_test_51PsYtXEFUJxc3qsy8JVYeUF41Ttoz5N3GjrNQ3FVcLcFca72QsaenVVIqH80oXrjSoQqHFsm6oPNqknc6SCaJP3P002mt9oMGW';
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
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/success': (context) => SuccessPage(),  // Ruta para la página de éxito
        '/cancel': (context) => CancelPage(),    // Ruta para la página de cancelación
      },
    );
  }
}
