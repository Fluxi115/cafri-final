// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BorrarCatServicioScreen extends StatefulWidget {
  const BorrarCatServicioScreen({super.key});

  @override
  State<BorrarCatServicioScreen> createState() =>
      _BorrarCatServicioScreenState();
}

class _BorrarCatServicioScreenState extends State<BorrarCatServicioScreen> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de Servicios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por código, concepto o precio',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

                return ListView.separated(
                  itemCount: servicios.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final servicio = servicios[index];
                    final codigo = servicio['codigo'] ?? '';
                    final concepto = servicio['concepto'] ?? '';
                    final precio = servicio['precioMenudeo'] ?? 0.0;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(concepto.isNotEmpty ? concepto[0] : '?'),
                      ),
                      title: Text('$codigo - $concepto'),
                      subtitle: Text(
                        'Precio menudeo: \$${precio.toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ID:\n${servicio.id}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar servicio',
                            onPressed: () =>
                                _borrarServicio(context, servicio.id, concepto),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Aquí puedes navegar a una pantalla de detalle o edición si lo deseas
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/servicios/crear');
        },
        tooltip: 'Registrar nuevo servicio',
        child: const Icon(Icons.add),
      ),
    );
  }
}
