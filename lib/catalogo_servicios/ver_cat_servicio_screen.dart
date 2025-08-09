// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cafri/catalogo_servicios/agregar_cat_servicio_screen.dart';
import 'package:cafri/catalogo_servicios/actualizar_cat_servicio_screen.dart';

class ListarServiciosScreen extends StatefulWidget {
  const ListarServiciosScreen({super.key});

  @override
  State<ListarServiciosScreen> createState() => _ListarServiciosScreenState();
}

class _ListarServiciosScreenState extends State<ListarServiciosScreen> {
  String _search = '';

  Future<void> _borrarServicio(
    BuildContext context,
    String servicioId,
    String concepto,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "$concepto"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('servicios')
            .doc(servicioId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Servicio "$concepto" eliminado exitosamente.'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar servicio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(
        (0.15 * 255).toInt(),
      ),
      appBar: AppBar(
        title: const Text('Catálogo de Servicios'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar por código, concepto o precio',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _search = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('servicios')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No hay servicios registrados.'),
                      );
                    }
                    final servicios = snapshot.data!.docs.where((servicio) {
                      final codigo = (servicio['codigo'] ?? '')
                          .toString()
                          .toLowerCase();
                      final concepto = (servicio['concepto'] ?? '')
                          .toString()
                          .toLowerCase();
                      final precio = (servicio['precioMenudeo'] ?? '')
                          .toString()
                          .toLowerCase();
                      final id = servicio.id.toLowerCase();
                      if (_search.isEmpty) return true;
                      return codigo.contains(_search) ||
                          concepto.contains(_search) ||
                          precio.contains(_search) ||
                          id.contains(_search);
                    }).toList();

                    if (servicios.isEmpty) {
                      return const Center(
                        child: Text('No hay resultados para la búsqueda.'),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        headingRowColor: WidgetStateProperty.all(
                          theme.colorScheme.primary.withAlpha(20),
                        ),
                        columns: const [
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Concepto')),
                          DataColumn(label: Text('Precio')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: servicios.map((servicio) {
                          final codigo = servicio['codigo'] ?? '';
                          final concepto = servicio['concepto'] ?? '';
                          final precio = servicio['precioMenudeo'] ?? 0.0;
                          final id = servicio.id;

                          return DataRow(
                            cells: [
                              DataCell(Text(codigo)),
                              DataCell(Text(concepto)),
                              DataCell(Text('\$${precio.toStringAsFixed(2)}')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Editar servicio',
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ServicioEditarScreen(
                                                  servicioId: id,
                                                  servicioData:
                                                      servicio.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >,
                                                ),
                                          ),
                                        );
                                        if (result == true) {
                                          setState(() {});
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Eliminar servicio',
                                      onPressed: () => _borrarServicio(
                                        context,
                                        id,
                                        concepto,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ServicioCreateScreen()),
          );
        },
        tooltip: 'Agregar Servicio',
        icon: const Icon(Icons.add),
        label: const Text('Agregar Servicio'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
