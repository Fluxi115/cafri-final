// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ColaboradorActividadesScreen extends StatefulWidget {
  const ColaboradorActividadesScreen({super.key});

  @override
  State<ColaboradorActividadesScreen> createState() =>
      _ColaboradorActividadesScreenState();
}

class _ColaboradorActividadesScreenState
    extends State<ColaboradorActividadesScreen> {
  String? get userEmail => FirebaseAuth.instance.currentUser?.email;

  String _construirEnlaceMaps(String ubicacion) {
    final urlPattern = RegExp(r'^(http|https):\/\/');
    final latLngPattern = RegExp(r'^\s*-?\d{1,3}\.\d+,\s*-?\d{1,3}\.\d+\s*$');
    final placeIdPattern = RegExp(r'^[A-Za-z0-9_-]{27}$');
    if (urlPattern.hasMatch(ubicacion)) {
      return ubicacion;
    } else if (latLngPattern.hasMatch(ubicacion)) {
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(ubicacion)}';
    } else if (placeIdPattern.hasMatch(ubicacion)) {
      return 'https://www.google.com/maps/search/?api=1&query=place_id:${Uri.encodeComponent(ubicacion)}';
    } else {
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(ubicacion)}';
    }
  }

  Future<void> _abrirUbicacionEnMaps(
    BuildContext context,
    String ubicacion,
  ) async {
    final url = _construirEnlaceMaps(ubicacion);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede abrir Google Maps para esta ubicación'),
        ),
      );
    }
  }

  /// Solo muestra actividades asignadas de hoy, aún no terminadas.
  Stream<QuerySnapshot> getActividadesDeHoy(String? email) {
    if (email == null) {
      return const Stream.empty();
    }
    final ahora = DateTime.now();
    final desde = DateTime(ahora.year, ahora.month, ahora.day, 0, 0, 0);
    final hasta = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('actividades')
        .where('colaborador', isEqualTo: email)
        .where('estado', isNotEqualTo: 'terminada')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(hasta))
        .orderBy('fecha')
        .snapshots();
  }

  Future<void> _cambiarEstado(String docId, String nuevoEstado) async {
    var data = <String, dynamic>{'estado': nuevoEstado};
    switch (nuevoEstado) {
      case 'aceptada':
        data['hora_aceptada'] = Timestamp.now();
        break;
      case 'en_proceso':
        data['hora_en_proceso'] = Timestamp.now();
        break;
      case 'pausada':
        data['hora_pausada'] = Timestamp.now();
        break;
      case 'terminada':
        data['hora_terminada'] = Timestamp.now();
        break;
    }
    await FirebaseFirestore.instance
        .collection('actividades')
        .doc(docId)
        .update(data);
  }

  @override
  Widget build(BuildContext context) {
    if (userEmail == null) {
      return const Center(child: Text('No hay usuario autenticado.'));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mis actividades')),
      body: StreamBuilder<QuerySnapshot>(
        stream: getActividadesDeHoy(userEmail),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar actividades: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final actividades = snapshot.data!.docs;
          if (actividades.isEmpty) {
            return const Center(
              child: Text('No tienes actividades asignadas para hoy.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: actividades.length,
            itemBuilder: (context, index) {
              final doc = actividades[index];
              final actividad = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              final fecha = (actividad['fecha'] as Timestamp?)?.toDate();
              final ubicacion = actividad['ubicacion'] ?? '';
              final direccionManual = actividad['direccion_manual'] ?? '';
              final estado = actividad['estado'] ?? '';
              final esColaboradorAsignado =
                  actividad['colaborador'] == userEmail;

              Color estadoColor;
              switch (estado) {
                case 'aceptada':
                  estadoColor = Colors.blue;
                  break;
                case 'en_proceso':
                  estadoColor = Colors.amber;
                  break;
                case 'pausada':
                  estadoColor = Colors.deepOrange;
                  break;
                case 'terminada':
                  estadoColor = Colors.green;
                  break;
                default:
                  estadoColor = Colors.orange;
              }

              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo[100],
                    child: Icon(
                      actividad['tipo'] == 'levantamiento'
                          ? Icons.assignment
                          : actividad['tipo'] == 'mantenimiento'
                          ? Icons.build
                          : Icons.settings_input_component,
                      color: Colors.indigo,
                    ),
                  ),
                  title: Text(
                    actividad['titulo'] ??
                        '${actividad['tipo']?.toString().toUpperCase() ?? ''} - ${actividad['colaborador'] ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fecha != null)
                        Text(
                          DateFormat('dd/MM/yyyy – HH:mm').format(fecha),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        actividad['descripcion'] ?? '',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (direccionManual.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.home,
                                color: Colors.indigo,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  direccionManual,
                                  style: const TextStyle(color: Colors.indigo),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (ubicacion.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: GestureDetector(
                                  onTap: () async =>
                                      _abrirUbicacionEnMaps(context, ubicacion),
                                  child: const Text(
                                    'Ver ubicación',
                                    style: TextStyle(
                                      color: Colors.red,
                                      decoration: TextDecoration.underline,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info,
                              size: 18,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Estado: ${estado.isNotEmpty ? estado[0].toUpperCase() + estado.substring(1).replaceAll('_', ' ') : ''}',
                              style: TextStyle(
                                color: estadoColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (esColaboradorAsignado)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              if (estado == 'pendiente')
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.check),
                                  label: const Text('Aceptar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    await _cambiarEstado(docId, 'aceptada');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Actividad aceptada'),
                                      ),
                                    );
                                  },
                                ),
                              if (estado == 'aceptada')
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Iniciar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                  ),
                                  onPressed: () async {
                                    await _cambiarEstado(docId, 'en_proceso');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Actividad en proceso'),
                                      ),
                                    );
                                  },
                                ),
                              if (estado == 'en_proceso') ...[
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.pause),
                                  label: const Text('Pausar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                  ),
                                  onPressed: () async {
                                    await _cambiarEstado(docId, 'pausada');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Actividad pausada'),
                                      ),
                                    );
                                  },
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.done_all),
                                  label: const Text('Terminar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () async {
                                    await _cambiarEstado(docId, 'terminada');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Actividad terminada'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              if (estado == 'pausada')
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Reanudar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                  ),
                                  onPressed: () async {
                                    await _cambiarEstado(docId, 'en_proceso');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Actividad reanudada'),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
