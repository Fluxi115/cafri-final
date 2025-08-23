import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'autentificacion/login_screen.dart';
import 'administrador/admin_screen.dart';
import 'colaborador/colaborador_screen.dart';
import 'package:cafri/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

// Manejo de mensajes cuando la app está en segundo plano o terminada
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log(
    '📩 [Background] Mensaje recibido: ${message.messageId}',
    name: 'FCM',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa la localización para español antes de runApp
  await initializeDateFormatting('es_ES', null);

  // Configura el handler de mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> _getUserRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data()?['rol'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!snapshot.hasData) {
            return const LoginScreen();
          }
          final user = snapshot.data!;
          return FutureBuilder<String?>(
            future: _getUserRole(user.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (roleSnapshot.hasError || !roleSnapshot.hasData) {
                return const Scaffold(
                  body: Center(
                    child: Text('Error al obtener el rol de usuario'),
                  ),
                );
              }
              final rol = roleSnapshot.data;
              if (rol == 'administrador') {
                return const AdminScreen();
              } else if (rol == 'colaborador') {
                return const ColaboradorScreen();
              } else {
                return const Scaffold(
                  body: Center(child: Text('Rol de usuario desconocido')),
                );
              }
            },
          );
        },
      ),
    );
  }
}
