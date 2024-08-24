import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'chat_screen_user.dart';
import 'package:flutter/material.dart';
import 'package:chatgpt/view/login.dart';

import 'login.dart';  // Importa la página de inicio de sesión

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Future.delayed(const Duration(milliseconds: 4000)).then((value) {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const LoginPage(),  // Cambia a SignInPage en lugar de ChatScreen
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.bounceOut;

          var tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kBg500Color,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Image.asset(
                "assets/top-bg-splash.png",
                width: width * 0.8,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Image.asset(
                "assets/bot_bg_splash.png",
                width: width * 0.7,
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 44.0,
                      fontFamily: 'Nud',
                      color: Colors.white,
                    ),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'ChatTDP',
                          speed: const Duration(milliseconds: 50),
                          textStyle: const TextStyle(
                            fontSize: 44,
                          ),
                        ),
                        TypewriterAnimatedText(
                          'by Ricardo Murillo',
                          speed: const Duration(milliseconds: 50),
                          textStyle: const TextStyle(
                            fontSize: 22,
                          ),
                        ),
                      ],
                      totalRepeatCount: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
