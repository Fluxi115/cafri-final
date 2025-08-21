// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cafri/autentificacion/auth_service.dart';
import 'package:cafri/autentificacion/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cafri/colaborador/calendarcolab_screen.dart';
import 'package:cafri/colaborador/pdf.dart';
import 'package:cafri/colaborador/ubicacion.dart';
import 'package:cafri/colaborador/actividades_screen.dart'; // Asegúrate de tener este archivo
// import 'package:cafri/colaborador/historial_rutas.dart';
import 'package:cafri/colaborador/ruta.dart';

enum ColaboradorSection { actividades, calendario, documento, mapa }

class ColaboradorScreen extends StatefulWidget {
  const ColaboradorScreen({super.key});

  @override
  State<ColaboradorScreen> createState() => _ColaboradorScreenState();
}

class _ColaboradorScreenState extends State<ColaboradorScreen> {
  late String userEmail;
  late String userId;
  ColaboradorSection selectedSection = ColaboradorSection.actividades;
  final AuthService _authService = AuthService();
  final String googleMapsApiKey = 'AIzaSyDgJ6emXC-cKpFJ-CFhWiglhp0pq2xWf2c';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userEmail = user?.email ?? '';
    userId = user?.uid ?? '';

    _crearDocumentoInicialColaborador(userId: userId, email: userEmail).then((
      _,
    ) {
      SeguimientoTiempoRealService.start(userId, nombre: userEmail);
    });
  }

  Future<void> _crearDocumentoInicialColaborador({
    required String userId,
    required String email,
  }) async {
    if (userId.isEmpty) return;
    final docRef = FirebaseFirestore.instance
        .collection('ubicaciones_colaboradores')
        .doc(userId);

    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'email': email,
        'creado': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void dispose() {
    SeguimientoTiempoRealService.stop();
    super.dispose();
  }

  void _handleDrawerSelection(ColaboradorSection section) async {
    Navigator.pop(context);
    setState(() {
      selectedSection = section;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.logout();
      await SeguimientoTiempoRealService.stop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Widget _buildActividades() {
    return ColaboradorActividadesScreen(); // Asegúrate de importar y tener este widget
  }

  Widget _buildCalendario() {
    return ColaboradorCalendario(userEmail: userEmail);
  }

  Widget _buildMapa() {
    return MapaConRutaDesdeUrl(apiKey: googleMapsApiKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Colaborador'),
        backgroundColor: Colors.indigo,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              accountName: null,
              accountEmail: null,
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.indigo, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Actividades'),
              selected: selectedSection == ColaboradorSection.actividades,
              onTap: () =>
                  _handleDrawerSelection(ColaboradorSection.actividades),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendario de actividades'),
              selected: selectedSection == ColaboradorSection.calendario,
              onTap: () =>
                  _handleDrawerSelection(ColaboradorSection.calendario),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Generar documento'),
              selected: selectedSection == ColaboradorSection.documento,
              onTap: () => _handleDrawerSelection(ColaboradorSection.documento),
            ),
            // ListTile(
            //   leading: const Icon(Icons.map),
            //   title: const Text('Mapa con ruta desde URL'),
            //   selected: selectedSection == ColaboradorSection.mapa,
            //   onTap: () => _handleDrawerSelection(ColaboradorSection.mapa),
            // ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Salir', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Builder(
        builder: (context) {
          switch (selectedSection) {
            case ColaboradorSection.actividades:
              return _buildActividades();
            case ColaboradorSection.calendario:
              return _buildCalendario();
            case ColaboradorSection.documento:
              return const FormularioPDF();
            case ColaboradorSection.mapa:
              return _buildMapa();
          }
        },
      ),
    );
  }
}
