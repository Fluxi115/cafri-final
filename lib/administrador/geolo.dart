import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class MonitoreoTiempoRealAdmin extends StatefulWidget {
  const MonitoreoTiempoRealAdmin({super.key});

  @override
  State<MonitoreoTiempoRealAdmin> createState() =>
      _MonitoreoTiempoRealAdminState();
}

class _MonitoreoTiempoRealAdminState extends State<MonitoreoTiempoRealAdmin> {
  late final MapController _mapController;
  String? _selectedUserId;
  LatLng? _lastFollowedUserPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _centerMapOnUser(Map<String, dynamic> userData) {
    if (userData['lat'] != null && userData['lng'] != null) {
      final newPosition = LatLng(userData['lat'], userData['lng']);
      _mapController.move(newPosition, _mapController.camera.zoom);
      _lastFollowedUserPosition = newPosition;
    }
  }

  void _centerMapOnAll(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return;
    final points = users.map((u) => LatLng(u['lat'], u['lng'])).toList();
    if (points.length == 1) {
      _mapController.move(points.first, 16);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    final cameraFit = CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(60),
    );
    final cameraState = _mapController.camera;
    final fitted = cameraFit.fit(cameraState);
    _mapController.move(fitted.center, fitted.zoom);
  }

  void _unfollowUser() {
    setState(() {
      _selectedUserId = null;
      _lastFollowedUserPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoreo en tiempo real'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_rounded),
            tooltip: 'Centrar en todos',
            onPressed: () {
              setState(() {
                _selectedUserId = null;
                _lastFollowedUserPosition = null;
              });
            },
          ),
          if (_selectedUserId != null)
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Dejar de seguir',
              onPressed: _unfollowUser,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ubicaciones_colaboradores')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          List<Map<String, dynamic>> users = [];
          List<Marker> markers = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.id;

            if (data['lat'] != null && data['lng'] != null) {
              users.add({
                'userId': userId,
                'nombre': data['nombre'] ?? userId,
                'lat': data['lat'],
                'lng': data['lng'],
                'avatarUrl': data['avatarUrl'], // Opcional
              });

              markers.add(
                Marker(
                  point: LatLng(data['lat'], data['lng']),
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  child: AnimatedScale(
                    scale: _selectedUserId == userId ? 1.3 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedUserId = userId;
                          _lastFollowedUserPosition = null;
                        });
                        _centerMapOnUser(data);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(51),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: _selectedUserId == userId
                              ? Colors.indigo[100]
                              : Colors.white,
                          backgroundImage: data['avatarUrl'] != null
                              ? NetworkImage(data['avatarUrl'])
                              : null,
                          child: data['avatarUrl'] == null
                              ? Icon(
                                  Icons.location_on,
                                  color: _selectedUserId == userId
                                      ? theme.colorScheme.primary
                                      : Colors.red,
                                  size: 32,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          }

          // Seguir automáticamente al usuario seleccionado
          if (_selectedUserId != null) {
            final user = users.firstWhere(
              (u) => u['userId'] == _selectedUserId,
              orElse: () => <String, dynamic>{},
            );
            if (user.isNotEmpty && user['lat'] != null && user['lng'] != null) {
              final currentPosition = LatLng(user['lat'], user['lng']);
              if (_lastFollowedUserPosition == null ||
                  _lastFollowedUserPosition != currentPosition) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_selectedUserId == user['userId']) {
                    _centerMapOnUser(user);
                  }
                });
              }
            }
          } else if (users.isNotEmpty) {
            // Si no hay usuario seleccionado, centra en todos
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _centerMapOnAll(users);
            });
          }

          final initialCenter = users.isNotEmpty
              ? LatLng(users[0]['lat'], users[0]['lng'])
              : const LatLng(0, 0);

          return Column(
            children: [
              // Selector de usuario
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_search, color: Colors.blueGrey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: const Text(
                                'Selecciona un usuario para seguir',
                              ),
                              value: _selectedUserId,
                              items: users.map((user) {
                                return DropdownMenuItem<String>(
                                  value: user['userId'],
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blue[100],
                                        backgroundImage:
                                            user['avatarUrl'] != null
                                            ? NetworkImage(user['avatarUrl'])
                                            : null,
                                        child: user['avatarUrl'] == null
                                            ? Text(
                                                user['nombre']
                                                    .toString()
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        user['nombre'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (userId) {
                                final user = users.firstWhere(
                                  (u) => u['userId'] == userId,
                                );
                                setState(() {
                                  _selectedUserId = userId;
                                  _lastFollowedUserPosition = null;
                                });
                                _centerMapOnUser(user);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Mapa
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: users.isNotEmpty ? 14 : 2,
                      crs: const Epsg3857(),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                ),
              ),
              if (users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No hay usuarios activos con ubicación disponible.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
