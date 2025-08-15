// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cafri/administrador/cotizacion/cotizacion_editar.dart';

class HistorialCotizacionesScreen extends StatefulWidget {
  const HistorialCotizacionesScreen({super.key});

  @override
  State<HistorialCotizacionesScreen> createState() =>
      _HistorialCotizacionesScreenState();
}

class _HistorialCotizacionesScreenState
    extends State<HistorialCotizacionesScreen> {
  // DateTime? _fechaInicio;         // <-- Descomenta si quieres activar el filtro de fecha
  // DateTime? _fechaFin;

  @override
  Widget build(BuildContext context) {
    Query cotizacionesQuery = FirebaseFirestore.instance.collection(
      'cotizaciones',
    );

    // Filtro por fecha (Comenta o descomenta estas líneas según necesidad)
    /*
    if (_fechaInicio != null) {
      cotizacionesQuery = cotizacionesQuery.where(
        'fecha',
        isGreaterThanOrEqualTo: _fechaInicio!.toString().substring(0, 10),
      );
    }
    if (_fechaFin != null) {
      cotizacionesQuery = cotizacionesQuery.where(
        'fecha',
        isLessThanOrEqualTo: _fechaFin!.toString().substring(0, 10),
      );
    }
    */
    cotizacionesQuery = cotizacionesQuery.orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Cotizaciones')),
      body: Column(
        children: [
          // Filtros de fechas (coméntalo todo si no deseas mostrarlo)
          /*
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
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
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha inicio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        _fechaInicio == null
                            ? ''
                            : _fechaInicio!.toString().substring(0, 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
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
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha fin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        _fechaFin == null
                            ? ''
                            : _fechaFin!.toString().substring(0, 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          */
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: cotizacionesQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error en la consulta: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No hay cotizaciones encontradas.'),
                  );
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final total = data['total'] ?? 0.0;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('Folio: ${data['folio']}'),
                            subtitle: Text(
                              'Fecha: ${data['fecha'] ?? ''}\nCliente: ${data['cliente']['nombre'] ?? ''}',
                            ),
                            trailing: Text('\$${total.toStringAsFixed(2)}'),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // BOTÓN EDITAR
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Editar cotización',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CotizacionEditarScreen(
                                        cotizacionId: doc.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // BOTÓN ELIMINAR
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Eliminar cotización',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text(
                                        '¿Eliminar cotización?',
                                      ),
                                      content: const Text(
                                        '¿Seguro que quieres borrar esta cotización? Esta acción no se puede deshacer.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await doc.reference.delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Cotización eliminada'),
                                      ),
                                    );
                                  }
                                },
                              ),
                              // BOTÓN PDF
                              IconButton(
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                ),
                                tooltip: 'Descargar PDF',
                                onPressed: () async {
                                  await _generarYMostrarPDF(data);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generarYMostrarPDF(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Text('Aquí va tu PDF de cotización');
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
