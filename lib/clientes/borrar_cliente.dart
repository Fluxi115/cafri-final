// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientesListarScreen extends StatefulWidget {
  const ClientesListarScreen({super.key});

  @override
  State<ClientesListarScreen> createState() => _ClientesListarScreenState();
}

class _ClientesListarScreenState extends State<ClientesListarScreen> {
  String _search = '';

  Future<void> _borrarCliente(
    BuildContext context,
    String clienteId,
    String nombre,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "$nombre"? Esta acción no se puede deshacer.',
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
            .collection('clientes')
            .doc(clienteId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente "$nombre" eliminado exitosamente.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar cliente: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Clientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por nombre, ID, correo o teléfono',
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
                  .collection('clientes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay clientes registrados.'),
                  );
                }
                final clientes = snapshot.data!.docs.where((cliente) {
                  final nombre = (cliente['nombre'] ?? '')
                      .toString()
                      .toLowerCase();
                  final correo = (cliente['correo'] ?? '')
                      .toString()
                      .toLowerCase();
                  final telefono = (cliente['telefono'] ?? '')
                      .toString()
                      .toLowerCase();
                  final id = cliente.id.toLowerCase();
                  if (_search.isEmpty) return true;
                  return nombre.contains(_search) ||
                      correo.contains(_search) ||
                      telefono.contains(_search) ||
                      id.contains(_search);
                }).toList();

                if (clientes.isEmpty) {
                  return const Center(
                    child: Text('No hay resultados para la búsqueda.'),
                  );
                }

                return ListView.separated(
                  itemCount: clientes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(cliente['nombre'][0])),
                      title: Text(cliente['nombre']),
                      subtitle: Text(
                        'Ciudad: ${cliente['ciudad']}\nTel: ${cliente['telefono']}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ID:\n${cliente.id}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar cliente',
                            onPressed: () => _borrarCliente(
                              context,
                              cliente.id,
                              cliente['nombre'],
                            ),
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
          Navigator.pushNamed(context, '/clientes/crear');
        },
        tooltip: 'Registrar nuevo cliente',
        child: const Icon(Icons.add),
      ),
    );
  }
}
