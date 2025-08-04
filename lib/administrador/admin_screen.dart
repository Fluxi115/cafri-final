// ignore_for_file: use_build_context_synchronously

import 'package:cafri/administrador/geolo.dart';
import 'package:flutter/material.dart';
import 'package:cafri/autentificacion/auth_service.dart';
import 'package:cafri/autentificacion/login_screen.dart';
import 'package:cafri/administrador/registeruser_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cafri/administrador/calendaradmin_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cafri/administrador/historial_screen.dart';
import 'package:cafri/administrador/calendarioacti_screen.dart';
import 'package:cafri/administrador/historial_rutacolab.dart';
import 'package:cafri/administrador/user_crud_screens.dart';
// Importa tu widget de métricas
import 'package:cafri/administrador/dashboard_metricas.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String userEmail = '';
  String? photoUrl;
  String? nombre;
  String? lastName;
  String? rol;
  String? phone;
  String? department;
  String? position;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userEmail = user?.email ?? '';
    if (user != null) {
      _loadUserInfo(user.uid);
    }
  }

  Future<void> _loadUserInfo(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        photoUrl = data['photoUrl'] as String?;
        nombre = data['name'] as String?;
        lastName = data['lastName'] as String?;
        rol = data['rol'] as String?;
        phone = data['phone'] as String?;
        department = data['department'] as String?;
        position = data['position'] as String?;
      });
    }
  }

  void _handleDrawerSelection(String value) async {
    Navigator.pop(context);

    if (value == 'salir') {
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else if (value == 'usuario') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Se seleccionó "usuario"')));
    } else if (value == 'agregar_nuevo_usuario') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisteruserScreen()),
      );
    } else if (value == 'usuarios') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UserListScreen()),
      );
    } else if (value == 'historial') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistorialActividadesScreen()),
      );
    } else if (value == 'agendar') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CalendarPage()),
      );
    } else if (value == 'calendario') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CalendarAdminScreen()),
      );
    } else if (value == 'Mapa de usuario') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HistorialRutaColabWidget(userId: ''),
        ),
      );
    } else if (value == 'Seguir') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MonitoreoTiempoRealAdmin()),
      );
    } else if (value == 'historial_ruta') {
      showDialog(
        context: context,
        builder: (context) => _UserIdSelectorDialog(
          onUserSelected: (userId) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistorialRutaColabWidget(userId: userId),
              ),
            );
          },
        ),
      );
    } else if (value == 'metricas') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DashboardMetricasScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 29, 77, 235),
                Color.fromARGB(255, 0, 0, 0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 40, bottom: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 29, 77, 235),
                      Color.fromARGB(255, 0, 0, 0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white,
                      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                          ? NetworkImage(photoUrl!)
                          : null,
                      child: photoUrl == null || photoUrl!.isEmpty
                          ? const Icon(
                              Icons.account_circle,
                              color: Colors.indigo,
                              size: 54,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ((nombre ?? 'Usuario') +
                          (lastName != null ? ' $lastName' : '')),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (rol != null)
                      Text(
                        rol!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    if (phone != null)
                      Text(
                        phone!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    if (department != null)
                      Text(
                        department!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    if (position != null)
                      Text(
                        position!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, thickness: 1, height: 0),
              _drawerItem(
                icon: Icons.person_add,
                text: 'Agregar nuevo usuario',
                onTap: () => _handleDrawerSelection('agregar_nuevo_usuario'),
              ),
              _drawerItem(
                icon: Icons.people,
                text: 'Usuarios',
                onTap: () => _handleDrawerSelection('usuarios'),
              ),
              _drawerItem(
                icon: Icons.event,
                text: 'Agendar',
                onTap: () => _handleDrawerSelection('agendar'),
              ),
              _drawerItem(
                icon: Icons.history,
                text: 'Historial de Actividades',
                onTap: () => _handleDrawerSelection('historial'),
              ),
              _drawerItem(
                icon: Icons.calendar_month,
                text: 'Calendario',
                onTap: () => _handleDrawerSelection('calendario'),
              ),
              _drawerItem(
                icon: Icons.spatial_tracking,
                text: 'Seguir',
                onTap: () => _handleDrawerSelection('Seguir'),
              ),
              _drawerItem(
                icon: Icons.timeline,
                text: 'Historial de ruta',
                onTap: () => _handleDrawerSelection('historial_ruta'),
              ),
              // --- MÉTRICAS ---
              _drawerItem(
                icon: Icons.bar_chart,
                text: 'Métricas',
                onTap: () => _handleDrawerSelection('metricas'),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24, thickness: 1),
              _drawerItem(
                icon: Icons.exit_to_app,
                text: 'Salir',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () => _handleDrawerSelection('salir'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 29, 77, 235),
              Color.fromARGB(255, 0, 0, 0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 12,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.withAlpha(220),
                          Colors.blue.withAlpha(180),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Bienvenido, Administrador!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Gestiona clientes, agenda y más desde este panel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(
                    color: Colors.indigo.withAlpha(80),
                    thickness: 1.2,
                    indent: 30,
                    endIndent: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white, size: 28),
      title: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      hoverColor: Colors.white12,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }
}

/// Dialog para seleccionar el userId de los colaboradores disponibles
class _UserIdSelectorDialog extends StatelessWidget {
  final void Function(String userId) onUserSelected;
  const _UserIdSelectorDialog({required this.onUserSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecciona un colaborador'),
      content: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ubicaciones_colaboradores')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Text('No hay colaboradores con historial.');
          }
          return DropdownButton<String>(
            hint: const Text('Selecciona un colaborador'),
            items: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final nombre = data['nombre'] ?? doc.id;
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(nombre),
              );
            }).toList(),
            onChanged: (userId) {
              if (userId != null) {
                onUserSelected(userId);
              }
            },
          );
        },
      ),
    );
  }
}

// --- Pantalla dedicada para métricas ---
class DashboardMetricasScreen extends StatelessWidget {
  const DashboardMetricasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas de Actividades'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DashboardMetricasActividades(titulo: "Métricas generales"),
      ),
    );
  }
}
