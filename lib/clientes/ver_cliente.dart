// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cafri/clientes/crear_cliente.dart';
import 'package:cafri/clientes/actualizar_cliente.dart';

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
    String codigo,
    String nombre,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "$codigo - $nombre"? Esta acción no se puede deshacer.',
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
          SnackBar(
            content: Text(
              'Cliente "$codigo - $nombre" eliminado exitosamente.',
            ),
          ),
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Clientes')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText:
                        'Buscar por código, nombre, ID, correo o teléfono',
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
                      final data = cliente.data() as Map<String, dynamic>;
                      final codigo = data.containsKey('codigo')
                          ? (data['codigo'] ?? '').toString().toLowerCase()
                          : '';
                      final nombre = data.containsKey('nombre')
                          ? (data['nombre'] ?? '').toString().toLowerCase()
                          : '';
                      final correo = data.containsKey('correo')
                          ? (data['correo'] ?? '').toString().toLowerCase()
                          : '';
                      final telefono = data.containsKey('telefono')
                          ? (data['telefono'] ?? '').toString().toLowerCase()
                          : '';
                      final id = cliente.id.toLowerCase();
                      if (_search.isEmpty) return true;
                      return codigo.contains(_search) ||
                          nombre.contains(_search) ||
                          correo.contains(_search) ||
                          telefono.contains(_search) ||
                          id.contains(_search);
                    }).toList();

                    if (clientes.isEmpty) {
                      return const Center(
                        child: Text('No hay resultados para la búsqueda.'),
                      );
                    }

                    // Cambios aquí: scroll vertical + scroll horizontal
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          headingRowColor: WidgetStateProperty.all(
                            theme.colorScheme.primary.withAlpha(30),
                          ),
                          columns: const [
                            DataColumn(label: Text('Código')),
                            DataColumn(label: Text('Nombre')),
                            DataColumn(label: Text('Ciudad')),
                            DataColumn(label: Text('Teléfono')),
                            DataColumn(label: Text('Correo')),
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: clientes.map((cliente) {
                            final data = cliente.data() as Map<String, dynamic>;
                            final codigo = data.containsKey('codigo')
                                ? data['codigo'] ?? ''
                                : '';
                            final nombre = data.containsKey('nombre')
                                ? data['nombre'] ?? ''
                                : '';
                            final ciudad = data.containsKey('ciudad')
                                ? data['ciudad'] ?? ''
                                : '';
                            final telefono = data.containsKey('telefono')
                                ? data['telefono'] ?? ''
                                : '';
                            final correo = data.containsKey('correo')
                                ? data['correo'] ?? ''
                                : '';
                            final id = cliente.id;

                            return DataRow(
                              cells: [
                                DataCell(Text(codigo)),
                                DataCell(Text(nombre)),
                                DataCell(Text(ciudad)),
                                DataCell(Text(telefono)),
                                DataCell(Text(correo)),
                                DataCell(
                                  Tooltip(
                                    message: id,
                                    child: Text(
                                      id.length > 8
                                          ? '${id.substring(0, 8)}...'
                                          : id,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        tooltip: 'Editar cliente',
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ClienteEditarScreen(
                                                    clienteId: cliente.id,
                                                    clienteData: data,
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
                                        tooltip: 'Eliminar cliente',
                                        onPressed: () => _borrarCliente(
                                          context,
                                          cliente.id,
                                          codigo,
                                          nombre,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClienteCreateScreen()),
          );
        },
        tooltip: 'Registrar nuevo cliente',
        child: const Icon(Icons.add),
      ),
    );
  }
}
