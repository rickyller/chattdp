import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
class IncidentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> canPerformIncident() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    // Verificar y registrar el Device ID
    String deviceId = await _getDeviceId();
    bool deviceAllowed = await _checkAndRegisterDevice(user.uid, deviceId);
    if (!deviceAllowed) {
      throw Exception("Máximo de dispositivos permitidos alcanzado.");
    }

    // Continuar con la lógica para verificar el límite de incidentes
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data();

    if (data == null) {
      throw Exception("No se pudieron obtener los datos del usuario");
    }

    final String subscriptionType = data['subscriptionType'] ?? 'free';
    final int incidentCount = data['incidentCount'] ?? 0;
    final DateTime? lastIncidentReset = (data['lastIncidentReset'] as Timestamp?)?.toDate();

    // Determinar el límite de incidentes según el tipo de suscripción
    final int maxIncidents = subscriptionType == 'premium' ? 200 : 10;

    final now = DateTime.now();

    if (lastIncidentReset == null || now.difference(lastIncidentReset).inDays >= 30) {
      // Resetear el contador de incidentes si ha pasado más de un mes
      await _firestore.collection('users').doc(user.uid).update({
        'incidentCount': 0,
        'lastIncidentReset': now,
      });
      return true;
    }

    if (incidentCount >= maxIncidents) {
      return false;
    }

    return true;
  }

  Future<void> incrementIncidentCount() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    final userDoc = _firestore.collection('users').doc(user.uid);

    final currentData = await userDoc.get();
    if (currentData.exists) {
      final incidentCount = currentData.data()?['incidentCount'] ?? 0;

      await userDoc.update({
        'incidentCount': incidentCount + 1,
      });
    } else {
      throw Exception("No se pudo obtener la información del usuario.");
    }
  }

  Future<String> _getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (kIsWeb) {
      // En el entorno web, utilizamos un identificador generado aleatoriamente almacenado en localStorage
      String deviceId = await _getWebDeviceId();
      return deviceId;
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? 'unknown';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    } else {
      return 'unknown';
    }
  }

  Future<String> _getWebDeviceId() async {
    // Puedes utilizar SharedPreferences para almacenar un ID generado en la primera carga.
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? webDeviceId = prefs.getString('webDeviceId');

    if (webDeviceId == null) {
      // Genera un nuevo ID si no existe
      webDeviceId = Uuid().v4();
      await prefs.setString('webDeviceId', webDeviceId);
    }

    return webDeviceId;
  }

  Future<bool> _checkAndRegisterDevice(String userId, String deviceId) async {
    DocumentReference userDoc = _firestore.collection('users').doc(userId);
    DocumentSnapshot userSnapshot = await userDoc.get();

    if (!userSnapshot.exists) {
      return false;
    }

    Map<String, dynamic>? data = userSnapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      return false;
    }

    List<dynamic> devices = data['devices'] ?? [];

    if (!devices.contains(deviceId)) {
      if (devices.length >= 2) {
        return false; // Límite de dispositivos alcanzado
      }
      devices.add(deviceId);
      await userDoc.update({'devices': devices});
    }

    return true;
  }
}
