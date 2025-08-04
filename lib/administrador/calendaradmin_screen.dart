// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geocoding/geocoding.dart';
import '../calendar/location_picker.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedTipo = 'levantamiento';
  String? _selectedColaborador;
  latlng.LatLng? _ubicacionLatLng;
  String? _ubicacionUrl;
  String? _direccionManual;

  final _descripcionController = TextEditingController();
  final _direccionController = TextEditingController();

  @override
  void dispose() {
    _descripcionController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getColaboradores() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('rol', isEqualTo: 'colaborador')
        .get();
    return snapshot.docs
        .map(
          (doc) => {'id': doc.id, 'name': doc['name'], 'email': doc['email']},
        )
        .toList();
  }

  Future<void> _guardarActividad({String? docId}) async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedColaborador == null ||
        _descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos obligatorios.'),
        ),
      );
      return;
    }

    final fecha = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final data = {
      'fecha': fecha,
      'tipo': _selectedTipo,
      'descripcion': _descripcionController.text.trim(),
      'colaborador': _selectedColaborador,
      'ubicacion': _ubicacionUrl ?? '',
      'lat': _ubicacionLatLng?.latitude,
      'lng': _ubicacionLatLng?.longitude,
      'direccion_manual': _direccionManual ?? '',
      'creado': FieldValue.serverTimestamp(),
    };

    if (docId == null) {
      data['estado'] = 'pendiente';
      await FirebaseFirestore.instance.collection('actividades').add(data);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Actividad guardada')));
    } else {
      await FirebaseFirestore.instance
          .collection('actividades')
          .doc(docId)
          .update(data);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Actividad actualizada')));
    }

    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _selectedTipo = 'levantamiento';
      _selectedColaborador = null;
      _descripcionController.clear();
      _direccionController.clear();
      _ubicacionLatLng = null;
      _ubicacionUrl = null;
      _direccionManual = null;
    });
  }

  void _cargarActividadParaEditar(
    Map<String, dynamic> actividad,
    String docId,
  ) {
    setState(() {
      final fecha = (actividad['fecha'] as Timestamp).toDate();
      _selectedDate = DateTime(fecha.year, fecha.month, fecha.day);
      _selectedTime = TimeOfDay(hour: fecha.hour, minute: fecha.minute);
      _selectedTipo = actividad['tipo'] ?? 'levantamiento';
      _selectedColaborador = actividad['colaborador'];
      _descripcionController.text = actividad['descripcion'] ?? '';
      _ubicacionUrl = actividad['ubicacion'];
      _direccionManual = actividad['direccion_manual'] ?? '';
      _direccionController.text = _direccionManual ?? '';
      if (actividad['lat'] != null && actividad['lng'] != null) {
        _ubicacionLatLng = latlng.LatLng(
          actividad['lat'] as double,
          actividad['lng'] as double,
        );
      } else {
        _ubicacionLatLng = null;
      }
    });
    _mostrarDialogoActividad(docId: docId);
  }

  void _mostrarDialogoActividad({String? docId}) async {
    final colaboradores = await _getColaboradores();

    if (docId == null) {
      _selectedDate ??= DateTime.now();
      _selectedTime ??= TimeOfDay.now();
    }

    showDialog(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setStateDialog) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE3E6F3), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            docId == null ? Icons.add_circle : Icons.edit,
                            color: Colors.indigo,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            docId == null
                                ? 'Nueva actividad'
                                : 'Editar actividad',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ListTile(
                        leading: const Icon(
                          Icons.calendar_today,
                          color: Colors.indigo,
                        ),
                        title: Text(
                          _selectedDate == null
                              ? 'Selecciona una fecha'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        ),
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? now,
                            firstDate: now,
                            lastDate: DateTime(now.year + 2),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Colors.indigo,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.indigo[900]!,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: Colors.grey[100],
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(
                          Icons.access_time,
                          color: Colors.indigo,
                        ),
                        title: Text(
                          _selectedTime == null
                              ? 'Selecciona una hora'
                              : _selectedTime!.format(context),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? TimeOfDay.now(),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Colors.indigo,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.indigo[900]!,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              _selectedTime = picked;
                            });
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: Colors.grey[100],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedTipo,
                        decoration: InputDecoration(
                          labelText: 'Tipo de trabajo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) {
                          setStateDialog(() {
                            _selectedTipo = value!;
                          });
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'levantamiento',
                            child: Text('Levantamiento'),
                          ),
                          DropdownMenuItem(
                            value: 'mantenimiento',
                            child: Text('Mantenimiento'),
                          ),
                          DropdownMenuItem(
                            value: 'instalacion',
                            child: Text('Instalación'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _direccionController,
                        decoration: InputDecoration(
                          labelText: 'Dirección (opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.search,
                              color: Colors.indigo,
                            ),
                            tooltip: 'Buscar dirección',
                            onPressed: () async {
                              if (_direccionController.text.trim().isEmpty) {
                                return;
                              }
                              try {
                                List<Location> locations =
                                    await locationFromAddress(
                                      _direccionController.text.trim(),
                                    );
                                if (locations.isNotEmpty) {
                                  final lat = locations.first.latitude;
                                  final lng = locations.first.longitude;
                                  setStateDialog(() {
                                    _ubicacionLatLng = latlng.LatLng(lat, lng);
                                    _ubicacionUrl =
                                        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                                    _direccionManual = _direccionController.text
                                        .trim();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Dirección encontrada y seleccionada',
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No se encontró la dirección',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al buscar dirección: $e',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        onChanged: (value) {
                          _direccionManual = value;
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedColaborador,
                        decoration: InputDecoration(
                          labelText: 'Colaborador',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) {
                          setStateDialog(() {
                            _selectedColaborador = value;
                          });
                        },
                        items: colaboradores
                            .map<DropdownMenuItem<String>>(
                              (col) => DropdownMenuItem<String>(
                                value: col['email'],
                                child: Text('${col['name']} (${col['email']})'),
                              ),
                            )
                            .toList(),
                        menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _ubicacionLatLng == null
                                ? const Text(
                                    'Sin ubicación seleccionada',
                                    style: TextStyle(fontSize: 16),
                                  )
                                : Text(
                                    'Ubicación: ${_ubicacionLatLng!.latitude.toStringAsFixed(5)}, ${_ubicacionLatLng!.longitude.toStringAsFixed(5)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LocationPicker(),
                                ),
                              );
                              if (result != null && result is latlng.LatLng) {
                                setStateDialog(() {
                                  _ubicacionLatLng = result;
                                  _ubicacionUrl =
                                      'https://www.google.com/maps/search/?api=1&query=${result.latitude},${result.longitude}';
                                  _direccionManual = '';
                                  _direccionController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (docId != null)
                            TextButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('actividades')
                                    .doc(docId)
                                    .delete();
                                Navigator.pop(context);
                                setState(() {});
                              },
                            ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: Icon(
                              docId == null ? Icons.save : Icons.edit,
                              color: Colors.white,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
                              await _guardarActividad(docId: docId);
                              Navigator.pop(context);
                              setState(() {});
                            },
                            label: Text(
                              docId == null ? 'Guardar' : 'Actualizar',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Calendario de actividades'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
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
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('actividades')
                .orderBy('fecha')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final actividades = snapshot.data!.docs;
              final actividadesFiltradas = actividades.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['estado'] != 'terminada';
              }).toList();

              if (actividadesFiltradas.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay actividades agendadas.',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: actividadesFiltradas.length,
                itemBuilder: (context, index) {
                  final actividad =
                      actividadesFiltradas[index].data()
                          as Map<String, dynamic>;
                  final docId = actividadesFiltradas[index].id;
                  final fecha = (actividad['fecha'] as Timestamp).toDate();
                  return Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    color: Colors.white.withAlpha(235),
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
                        '${actividad['tipo']?.toString().toUpperCase() ?? ''} - ${actividad['colaborador'] ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          if ((actividad['direccion_manual'] ?? '').isNotEmpty)
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
                                      actividad['direccion_manual'],
                                      style: const TextStyle(
                                        color: Colors.indigo,
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
                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(Uri.parse(url));
                                  }
                                },
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ver ubicación',
                                      style: TextStyle(
                                        color: Colors.red,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.indigo),
                        onPressed: () =>
                            _cargarActividadParaEditar(actividad, docId),
                      ),
                      onTap: () => _cargarActividadParaEditar(actividad, docId),
                      onLongPress: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar actividad'),
                            content: const Text(
                              '¿Seguro que deseas eliminar esta actividad?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('actividades')
                              .doc(docId)
                              .delete();
                          setState(() {});
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add),
        label: const Text('Nueva actividad'),
        onPressed: () {
          setState(() {
            _selectedDate = DateTime.now();
            _selectedTime = TimeOfDay.now();
            _selectedTipo = 'levantamiento';
            _selectedColaborador = null;
            _descripcionController.clear();
            _direccionController.clear();
            _ubicacionLatLng = null;
            _ubicacionUrl = null;
            _direccionManual = null;
          });
          _mostrarDialogoActividad();
        },
      ),
    );
  }
}
