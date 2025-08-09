import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HistorialCotizacionesScreen extends StatefulWidget {
  const HistorialCotizacionesScreen({super.key});

  @override
  State<HistorialCotizacionesScreen> createState() =>
      _HistorialCotizacionesScreenState();
}

class _HistorialCotizacionesScreenState
    extends State<HistorialCotizacionesScreen> {
  String _busquedaFolio = "";
  String _busquedaCliente = "";
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  Widget build(BuildContext context) {
    Query cotizacionesQuery = FirebaseFirestore.instance.collection(
      'cotizaciones',
    );

    if (_busquedaFolio.isNotEmpty) {
      cotizacionesQuery = cotizacionesQuery.where(
        'folio',
        isEqualTo: _busquedaFolio,
      );
    }
    if (_busquedaCliente.isNotEmpty) {
      cotizacionesQuery = cotizacionesQuery.where(
        'cliente.nombre',
        isEqualTo: _busquedaCliente,
      );
    }
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
    cotizacionesQuery = cotizacionesQuery.orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Cotizaciones')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Buscar por folio',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _busquedaFolio = value.trim();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Buscar por cliente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _busquedaCliente = value.trim();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
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
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: cotizacionesQuery.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No hay cotizaciones encontradas.'),
                  );
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text('Folio: ${data['folio']}'),
                        subtitle: Text(
                          'Cliente: ${data['cliente']['nombre'] ?? ''}\nFecha: ${data['fecha'] ?? ''}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          tooltip: 'Generar/Descargar PDF',
                          onPressed: () async {
                            await _generarYMostrarPDF(data);
                          },
                        ),
                        onTap: () {
                          // Aquí puedes mostrar detalles completos si lo deseas
                        },
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
          return pw.Text(
            'Aquí va tu PDF de cotización',
          ); // ... igual que antes ...
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
