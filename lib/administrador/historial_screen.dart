import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistorialActividadesScreen extends StatefulWidget {
  const HistorialActividadesScreen({super.key});

  @override
  State<HistorialActividadesScreen> createState() =>
      _HistorialActividadesScreenState();
}

class _HistorialActividadesScreenState
    extends State<HistorialActividadesScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _colaboradorSeleccionado;
  String? _tipoSeleccionado;
  String? _estadoSeleccionado;

  List<String> _colaboradores = [];
  List<String> _tipos = [];
  final List<String> _estados = [
    'pendiente',
    'aceptada',
    'en_proceso',
    'pausada',
    'terminada',
  ];

  @override
  void initState() {
    super.initState();
    _cargarColaboradoresYTipos();
  }

  Future<void> _cargarColaboradoresYTipos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('actividades')
        .get();

    final colaboradoresSet = <String>{};
    final tiposSet = <String>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['colaborador'] != null &&
          data['colaborador'].toString().isNotEmpty) {
        colaboradoresSet.add(data['colaborador']);
      }
      if (data['tipo'] != null && data['tipo'].toString().isNotEmpty) {
        tiposSet.add(data['tipo']);
      }
    }
    setState(() {
      _colaboradores = colaboradoresSet.toList()..sort();
      _tipos = tiposSet.toList()..sort();
    });
  }

  bool _pasaFiltros(Map<String, dynamic> data) {
    final fecha = (data['fecha'] as Timestamp).toDate();
    if (_fechaInicio != null && fecha.isBefore(_fechaInicio!)) return false;
    if (_fechaFin != null && fecha.isAfter(_fechaFin!)) return false;
    if (_colaboradorSeleccionado != null &&
        _colaboradorSeleccionado!.isNotEmpty &&
        data['colaborador'] != _colaboradorSeleccionado) {
      return false;
    }
    if (_tipoSeleccionado != null &&
        _tipoSeleccionado!.isNotEmpty &&
        data['tipo'] != _tipoSeleccionado) {
      return false;
    }
    if (_estadoSeleccionado != null &&
        _estadoSeleccionado!.isNotEmpty &&
        data['estado'] != _estadoSeleccionado) {
      return false;
    }
    return true;
  }

  Widget _historialEstadosDesdeCampos(Map<String, dynamic> actividad) {
    final estados = [
      {'campo': 'hora_aceptada', 'label': 'Aceptada', 'color': Colors.blue},
      {
        'campo': 'hora_en_proceso',
        'label': 'En proceso',
        'color': Colors.amber,
      },
      {'campo': 'hora_pausada', 'label': 'Pausada', 'color': Colors.deepOrange},
      {'campo': 'hora_terminada', 'label': 'Terminada', 'color': Colors.green},
    ];

    final historial = <Widget>[];
    for (var est in estados) {
      final dato = actividad[est['campo']];
      if (dato != null) {
        final d = dato is Timestamp ? dato.toDate() : dato;
        historial.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Icon(Icons.history, size: 16, color: est['color'] as Color),
                const SizedBox(width: 6),
                Text(
                  '${est['label']}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: est['color'] as Color,
                  ),
                ),
                Text(DateFormat('dd/MM/yyyy – HH:mm').format(d)),
              ],
            ),
          ),
        );
      }
    }

    if (historial.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          'No hay historial de cambios de estado registrado.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12.0, bottom: 6.0),
          child: Text(
            'Historial de cambios de estado:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.indigo,
            ),
          ),
        ),
        ...historial,
      ],
    );
  }

  void _mostrarDetallesActividad(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de la actividad'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detalle('Colaborador', data['colaborador']),
              _detalle('Tipo', data['tipo']),
              _detalle('Descripción', data['descripcion']),
              _detalle(
                'Fecha',
                DateFormat(
                  'dd/MM/yyyy – HH:mm',
                ).format((data['fecha'] as Timestamp).toDate()),
              ),
              _detalle('Dirección', data['direccion_manual']),
              _detalle('Ubicación', data['ubicacion']),
              _detalle('Latitud', data['lat']?.toString()),
              _detalle('Longitud', data['lng']?.toString()),
              _detalle('Estado', _estadoLegible(data['estado'])),
              _detalle(
                'Creado',
                data['creado'] != null
                    ? DateFormat(
                        'dd/MM/yyyy – HH:mm',
                      ).format((data['creado'] as Timestamp).toDate())
                    : '',
              ),
              _historialEstadosDesdeCampos(data),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detalle(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'aceptada':
        return Colors.blue;
      case 'en_proceso':
        return Colors.amber;
      case 'pausada':
        return Colors.deepOrange;
      case 'terminada':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _estadoLegible(String? estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'aceptada':
        return 'Aceptada';
      case 'en_proceso':
        return 'En proceso';
      case 'pausada':
        return 'Pausada';
      case 'terminada':
        return 'Terminada';
      default:
        return estado ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Historial de actividades'),
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Card(
                  elevation: 6,
                  color: Colors.white.withAlpha(220),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _fechaInicio == null
                                ? 'Desde'
                                : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_fechaInicio!),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fechaInicio ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _fechaInicio = picked;
                              });
                            }
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _fechaFin == null
                                ? 'Hasta'
                                : DateFormat('dd/MM/yyyy').format(_fechaFin!),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fechaFin ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _fechaFin = picked;
                              });
                            }
                          },
                        ),
                        DropdownButton<String>(
                          value: _colaboradorSeleccionado,
                          hint: const Text('Colaborador'),
                          dropdownColor: Colors.white,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._colaboradores.map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _colaboradorSeleccionado = value;
                            });
                          },
                        ),
                        DropdownButton<String>(
                          value: _tipoSeleccionado,
                          hint: const Text('Tipo'),
                          dropdownColor: Colors.white,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._tipos.map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _tipoSeleccionado = value;
                            });
                          },
                        ),
                        DropdownButton<String>(
                          value: _estadoSeleccionado,
                          hint: const Text('Estado'),
                          dropdownColor: Colors.white,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._estados.map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(_estadoLegible(e)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _estadoSeleccionado = value;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Limpiar filtros',
                          onPressed: () {
                            setState(() {
                              _fechaInicio = null;
                              _fechaFin = null;
                              _colaboradorSeleccionado = null;
                              _tipoSeleccionado = null;
                              _estadoSeleccionado = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white70),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('actividades')
                      .orderBy('fecha', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay actividades registradas.',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      );
                    }

                    final actividadesPorColaborador =
                        <String, List<QueryDocumentSnapshot>>{};
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (_pasaFiltros(data)) {
                        final colaborador =
                            data['colaborador'] ?? 'Sin colaborador';
                        actividadesPorColaborador
                            .putIfAbsent(colaborador, () => [])
                            .add(doc);
                      }
                    }

                    if (actividadesPorColaborador.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay actividades que coincidan con los filtros.',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: actividadesPorColaborador.entries.map((entry) {
                        final colaborador = entry.key;
                        final actividades = entry.value;
                        actividades.sort((a, b) {
                          final fa = (a['fecha'] as Timestamp).toDate();
                          final fb = (b['fecha'] as Timestamp).toDate();
                          return fb.compareTo(fa);
                        });
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 4,
                                top: 12,
                              ),
                              child: Text(
                                colaborador,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ...actividades.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final fecha = (data['fecha'] as Timestamp)
                                  .toDate();
                              final estado = data['estado'] ?? '';
                              return Card(
                                elevation: 6,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                color: Colors.white.withAlpha(235),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _estadoColor(
                                      estado,
                                    ).withAlpha(60),
                                    child: Icon(
                                      data['tipo'] == 'levantamiento'
                                          ? Icons.assignment
                                          : data['tipo'] == 'mantenimiento'
                                          ? Icons.build
                                          : Icons.settings_input_component,
                                      color: _estadoColor(estado),
                                    ),
                                  ),
                                  title: Text(
                                    data['descripcion'] ?? 'Sin descripción',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy – HH:mm',
                                        ).format(fecha),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        'Estado: ${_estadoLegible(estado)}',
                                        style: TextStyle(
                                          color: _estadoColor(estado),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    data['tipo']?.toString().toUpperCase() ??
                                        '',
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () => _mostrarDetallesActividad(doc),
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
