import 'package:flutter/material.dart';

class CancelPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pago Cancelado'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cancel,
              color: Colors.red,
              size: 100,
            ),
            SizedBox(height: 20),
            Text(
              'El pago ha sido cancelado.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/');  // Redirige al usuario a la página principal o donde consideres adecuado
              },
              child: Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
