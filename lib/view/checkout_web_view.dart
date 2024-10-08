import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutWebView extends StatelessWidget {
  final String sessionUrl;

  CheckoutWebView({required this.sessionUrl});

  @override
  Widget build(BuildContext context) {
    // Lanza la URL del Checkout al cargar la pantalla
    _launchCheckoutUrl(sessionUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text('Redireccionando al Checkout...'),
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Función para abrir la URL de Checkout
  void _launchCheckoutUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
