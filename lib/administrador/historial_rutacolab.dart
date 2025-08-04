import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class HistorialRutaColabWidget extends StatelessWidget {
  final String userId;
  final DateTime? fecha; // Para filtrar por día, si se desea

  const HistorialRutaColabWidget({super.key, required this.userId, this.fecha});

  @override
  Widget build(BuildContext context) {
    // Filtrado por día si se pasa una fecha
    DateTime? startOfDay;
    DateTime? endOfDay;
    if (fecha != null) {
      startOfDay = DateTime(fecha!.year, fecha!.month, fecha!.day);
      endOfDay = startOfDay.add(const Duration(days: 1));
    }

    Query historialQuery = FirebaseFirestore.instance
        .collection('ubicaciones_colaboradores')
        .doc(userId)
        .collection('historial')
        .orderBy('timestamp');

    if (startOfDay != null && endOfDay != null) {
      historialQuery = historialQuery
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay);
    }

    // Para mostrar detalles del usuario
    final userDocRef = FirebaseFirestore.instance
        .collection('ubicaciones_colaboradores')
        .doc(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de ruta'),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: userDocRef.get(),
        builder: (context, userSnapshot) {
          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

          return StreamBuilder<QuerySnapshot>(
            stream: historialQuery.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay historial de ruta para este usuario.',
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }

              // Construye la lista de puntos para la polyline
              final points = docs
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['lat'] != null && data['lng'] != null) {
                      return LatLng(data['lat'], data['lng']);
                    }
                    return null;
                  })
                  .whereType<LatLng>()
                  .toList();

              final initialCenter = points.first;

              return Column(
                children: [
                  if (userData != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            backgroundImage: userData['avatarUrl'] != null
                                ? NetworkImage(userData['avatarUrl'])
                                : null,
                            child: userData['avatarUrl'] == null
                                ? Text(
                                    (userData['nombre'] ?? userId)
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
                          title: Text(
                            userData['nombre'] ?? userId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          subtitle: Text(
                            'ID: $userId',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: initialCenter,
                          initialZoom: 16,
                          crs: const Epsg3857(),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: points,
                                color: Colors.blue,
                                strokeWidth: 5,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              // Punto de inicio
                              Marker(
                                point: points.first,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.flag,
                                  color: Colors.green,
                                  size: 32,
                                ),
                              ),
                              // Punto final
                              Marker(
                                point: points.last,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.flag,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
