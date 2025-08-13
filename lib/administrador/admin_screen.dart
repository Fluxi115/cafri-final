// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cafri/autentificacion/auth_service.dart';
import 'package:cafri/autentificacion/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa tus pantallas aquí
import 'package:cafri/administrador/user_crud_screens.dart';
import 'package:cafri/clientes/ver_cliente.dart';
import 'package:cafri/catalogo_servicios/ver_cat_servicio_screen.dart';
import 'package:cafri/administrador/cotizacion/cotizacion_screen.dart';
import 'package:cafri/administrador/cotizacion/cotizaciones_listar_screen.dart';
import 'package:cafri/administrador/calendaradmin_screen.dart';
import 'package:cafri/administrador/historial_screen.dart';
import 'package:cafri/administrador/calendarioacti_screen.dart';
import 'package:cafri/administrador/geolo.dart';
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
  String? rol;
  String? phone;
  String? department;
  String? position;
  final AuthService _authService = AuthService();

  // Estado para el contenido principal
  Widget? _mainContentWidget;

  // Menú agrupado por categorías (sin "Inicio")
  late final List<_MenuGroup> _menuGroups;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userEmail = user?.email ?? '';
    if (user != null) {
      _loadUserInfo(user.uid);
    }
    _mainContentWidget = _buildMainContent();

    _menuGroups = [
      _MenuGroup('Usuarios', Icons.people, [
        _MenuOption('Usuarios', Icons.people, const UserListScreen()),
        _MenuOption('Clientes', Icons.people_alt, const ClientesListarScreen()),
      ]),
      _MenuGroup('Servicios', Icons.miscellaneous_services, [
        _MenuOption(
          'Servicios',
          Icons.miscellaneous_services,
          const ListarServiciosScreen(),
        ),
        _MenuOption('Cotización', Icons.people_alt, const CotizacionScreen()),
        _MenuOption(
          'Cotizaciones',
          Icons.list_alt,
          const CotizacionesListarScreen(),
        ),
      ]),
      _MenuGroup('Agenda', Icons.event, [
        _MenuOption('Agendar', Icons.event, const CalendarPage()),
        _MenuOption(
          'Calendario',
          Icons.calendar_month,
          const CalendarAdminScreen(),
        ),
      ]),
      _MenuGroup('Actividades', Icons.history, [
        _MenuOption(
          'Historial de Actividades',
          Icons.history,
          const HistorialActividadesScreen(),
        ),
        _MenuOption(
          'Seguir',
          Icons.spatial_tracking,
          const MonitoreoTiempoRealAdmin(),
        ),
      ]),
      _MenuGroup('Reportes', Icons.bar_chart, [
        _MenuOption(
          'Métricas',
          Icons.bar_chart,
          DashboardMetricasActividadesConFiltro(),
        ),
      ]),
    ];
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
        rol = data['rol'] as String?;
        phone = data['phone'] as String?;
        department = data['department'] as String?;
        position = data['position'] as String?;
      });
    }
  }

  void _handleMenuSelection(_MenuOption option) {
    setState(() {
      _mainContentWidget = option.screen;
    });
  }

  void _goHome() {
    setState(() {
      _mainContentWidget = _buildMainContent();
    });
  }

  Future<void> _handleLogout() async {
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
  }

  Widget _buildMainContent() {
    return Container(
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
    );
  }

  Widget _buildProfileInfo() {
    String displayName = '';
    if (nombre != null && nombre!.isNotEmpty) {
      displayName = nombre!;
    } else {
      displayName = 'Usuario';
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
              ? NetworkImage(photoUrl!)
              : null,
          child: photoUrl == null || photoUrl!.isEmpty
              ? Icon(Icons.account_circle, color: Colors.indigo, size: 32)
              : null,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            if (rol != null)
              Text(
                rol!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 29, 77, 235),
        elevation: 0,
        title: _buildProfileInfo(),
        actions: [
          // Botón de inicio directo
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.home, color: Colors.white, size: 20),
            label: const Text(
              'Inicio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: _goHome,
          ),
          // Menú agrupado por categorías con ícono y texto
          ..._menuGroups.map((group) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: PopupMenuButton<_MenuOption>(
                tooltip: group.title,
                offset: const Offset(0, 40),
                onSelected: _handleMenuSelection,
                itemBuilder: (context) => group.options
                    .map(
                      (option) => PopupMenuItem<_MenuOption>(
                        value: option,
                        child: Row(
                          children: [
                            Icon(option.icon, size: 20, color: Colors.black54),
                            const SizedBox(width: 8),
                            Text(option.title),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: Icon(group.icon, color: Colors.white, size: 20),
                  label: Text(
                    group.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: null, // El trigger es el PopupMenuButton
                ),
              ),
            );
          }),
          // Botón de salir
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            tooltip: 'Salir',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _mainContentWidget ?? _buildMainContent(),
    );
  }
}

class _MenuGroup {
  final String title;
  final IconData icon;
  final List<_MenuOption> options;
  const _MenuGroup(this.title, this.icon, this.options);
}

class _MenuOption {
  final String title;
  final IconData icon;
  final Widget? screen; // screen puede ser null para "Inicio"
  const _MenuOption(this.title, this.icon, this.screen);
}
