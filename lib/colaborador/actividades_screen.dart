// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer; // Added for logging

class ColaboradorActividades extends StatelessWidget {
  final String userEmail;
  const ColaboradorActividades({super.key, required this.userEmail});

  Stream<QuerySnapshot> getActividadesColaborador(String email) {
    return FirebaseFirestore.instance
        .collection('actividades')
        .where('colaborador', isEqualTo: email)
        .where('estado', isNotEqualTo: 'terminada')
        .orderBy('estado')
        .orderBy('fecha')
        .snapshots();
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'aceptada':
        return Colors.blue;
      case 'en_proceso':
        return Colors.amber;
      case 'pausada':
        return Colors.deepOrange;
      case 'terminada':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'levantamiento':
        return Icons.assignment;
      case 'mantenimiento':
        return Icons.build;
      case 'instalacion':
        return Icons.settings_input_component;
      default:
        return Icons.work_outline;
    }
  }

  Future<void> _actualizarEstadoYHora(
    BuildContext context,
    String docId,
    String nuevoEstado,
    String subcampoHorario,
    String mensajeExito,
  ) async {
    if (subcampoHorario.isEmpty) {
      // Diagnóstico: revisar si subcampoHorario está siendo pasado vacío
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: subcampoHorario vacío')),
      );
      developer.log('subcampoHorario vacío', name: 'ColaboradorActividades');
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('actividades')
        .doc(docId);

    try {
      // Diagnóstico: lee antes de escribir
      final snapshot = await docRef.get();
      developer.log(
        "Documento antes de update: ${snapshot.data()}",
        name: 'ColaboradorActividades',
      );

      // Asegúrese de que el campo horarios es un objeto
      var data = snapshot.data();
      if (data != null &&
          data['horarios'] != null &&
          data['horarios'] is! Map) {
        // Si es cualquier cosa diferente a Map, lanza error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El campo horarios no es un objeto en Firestore (puede estar mal definido).',
            ),
          ),
        );
        developer.log(
          "El campo horarios no es un Map en Firestore. Valor encontrado: ${data['horarios'].runtimeType}",
          name: 'ColaboradorActividades',
        );
        return;
      }

      // 1. Actualizamos el estado general
      await docRef.update({'estado': nuevoEstado});

      // 2. Actualizamos o creamos el subcampo horario correspondiente
      // (Firestore debe crear horarios como {} si no existe y luego añadir el subcampo)
      await docRef.set({
        'horarios.$subcampoHorario': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Diagnóstico: lee después de escribir
      final updatedSnap = await docRef.get();
      developer.log(
        "Documento después de set horario: ${updatedSnap.data()}",
        name: 'ColaboradorActividades',
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeExito)));
    } catch (e) {
      // Diagnóstico: captura errores Firestore
      developer.log(
        'Firestore Write Error: $e',
        name: 'ColaboradorActividades',
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: StreamBuilder<QuerySnapshot>(
        stream: getActividadesColaborador(userEmail),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final actividades = snapshot.data?.docs ?? [];
          if (actividades.isEmpty) {
            return const Center(
              child: Text(
                'No tienes actividades asignadas.',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: actividades.length,
            itemBuilder: (context, index) {
              final actividad =
                  actividades[index].data() as Map<String, dynamic>;
              final docId = actividades[index].id;
              final fecha = (actividad['fecha'] as Timestamp).toDate();
              final estado = actividad['estado'] ?? 'pendiente';
              final esColaboradorAsignado =
                  actividad['colaborador'] == userEmail;
              final tipo = actividad['tipo'] ?? '';

              return Card(
                elevation: 10,
                margin: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white.withAlpha(235),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _estadoColor(estado).withAlpha(40),
                      child: Icon(
                        _iconoTipo(tipo),
                        color: _estadoColor(estado),
                      ),
                    ),
                    title: Text(
                      actividad['titulo'] ?? 'Actividad sin título',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.indigo,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.indigo[300],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} – ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if ((actividad['descripcion'] ?? '').isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.description,
                                color: Colors.blueGrey,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  actividad['descripcion'],
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if ((actividad['direccion_manual'] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.home,
                                  color: Colors.indigo,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    actividad['direccion_manual'],
                                    style: const TextStyle(
                                      color: Colors.indigo,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if ((actividad['ubicacion'] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: GestureDetector(
                              onTap: () async {
                                final url = actividad['ubicacion'];
                                await Clipboard.setData(
                                  ClipboardData(text: url),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ubicación copiada al portapapeles',
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Copiar ubicación',
                                    style: TextStyle(
                                      color: Colors.red,
                                      decoration: TextDecoration.underline,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info,
                                size: 16,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Estado: ${estado[0].toUpperCase()}${estado.substring(1).replaceAll('_', ' ')}',
                                style: TextStyle(
                                  color: _estadoColor(estado),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
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
                                      await _actualizarEstadoYHora(
                                        context,
                                        docId,
                                        'aceptada',
                                        'aceptada',
                                        'Actividad aceptada',
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
                                      await _actualizarEstadoYHora(
                                        context,
                                        docId,
                                        'en_proceso',
                                        'iniciada',
                                        'Actividad en proceso',
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
                                      await _actualizarEstadoYHora(
                                        context,
                                        docId,
                                        'pausada',
                                        'pausada',
                                        'Actividad pausada',
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
                                      await _actualizarEstadoYHora(
                                        context,
                                        docId,
                                        'terminada',
                                        'terminada',
                                        'Actividad terminada',
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
                                      await _actualizarEstadoYHora(
                                        context,
                                        docId,
                                        'en_proceso',
                                        'reanudada',
                                        'Actividad reanudada',
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
