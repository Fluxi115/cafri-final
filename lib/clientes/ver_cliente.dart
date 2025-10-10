import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cafri/clientes/crear_cliente.dart';
import 'package:cafri/clientes/actualizar_cliente.dart';

// ignore_for_file: use_build_context_synchronously

class ClientesListarScreen extends StatefulWidget {
  const ClientesListarScreen({super.key});

  @override
  State<ClientesListarScreen> createState() => _ClientesListarScreenState();
}

class _ClientesListarScreenState extends State<ClientesListarScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _tipoFiltro = 'todos'; // 'todos' | 'persona' | 'empresa'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  bool _coincideBusquedaYFiltro(Map<String, dynamic> data, String id) {
    final s = _search;
    final tipo = (data['tipo'] ?? '').toString().toLowerCase();
    if (_tipoFiltro != 'todos' && tipo != _tipoFiltro) return false;

    if (s.isEmpty) return true;

    final codigo = (data['codigo'] ?? '').toString().toLowerCase();
    final nombre = (data['nombre'] ?? '').toString().toLowerCase();
    final correo = (data['correo'] ?? '').toString().toLowerCase();
    final telefono = (data['telefono'] ?? '').toString().toLowerCase();
    final razonSocial = (data['razon_social'] ?? '').toString().toLowerCase();
    final rfc = (data['rfc'] ?? '').toString().toLowerCase();
    final ciudad = (data['ciudad'] ?? '').toString().toLowerCase();

    return codigo.contains(s) ||
        nombre.contains(s) ||
        correo.contains(s) ||
        telefono.contains(s) ||
        razonSocial.contains(s) ||
        rfc.contains(s) ||
        ciudad.contains(s) ||
        tipo.contains(s) ||
        id.toLowerCase().contains(s);
  }

  Color _cardTintForTipo(BuildContext context, String tipo) {
    final scheme = Theme.of(context).colorScheme;
    if (tipo == 'empresa') {
      return scheme.primaryContainer.withValues(alpha: 0.2);
    }
    if (tipo == 'persona') {
      return scheme.secondaryContainer.withValues(alpha: 0.2);
    }
    // surfaceVariant deprecado -> surfaceContainerHighest
    return scheme.surfaceContainerHighest.withValues(alpha: 0.2);
  }

  Widget _chipTipo({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected = _tipoFiltro == value;
    return ChoiceChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      onSelected: (_) => setState(() => _tipoFiltro = value),
    );
  }

  PopupMenuButton<String> _accionesPopup({
    required String clienteId,
    required String codigo,
    required String nombre,
    required Map<String, dynamic> data,
  }) {
    return PopupMenuButton<String>(
      tooltip: 'Acciones',
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClienteEditarScreen(
                  clienteId: clienteId,
                  clienteData: data,
                ),
              ),
            );
            if (result == true) setState(() {});
            break;
          case 'delete':
            await _borrarCliente(context, clienteId, codigo, nombre);
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit, color: Colors.blue),
            title: Text('Editar'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Eliminar'),
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1100;

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Clientes')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // Barra de búsqueda + chips de filtro
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText:
                                'Buscar por código, nombre, correo, teléfono, razón social o RFC',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _search.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpiar',
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _search = '');
                                    },
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) => setState(
                            () => _search = value.trim().toLowerCase(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chipTipo(
                        value: 'todos',
                        label: 'Todos',
                        icon: Icons.all_inclusive,
                      ),
                      _chipTipo(
                        value: 'persona',
                        label: 'Persona',
                        icon: Icons.person_outline,
                      ),
                      _chipTipo(
                        value: 'empresa',
                        label: 'Empresa',
                        icon: Icons.apartment_outlined,
                      ),
                    ],
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
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar clientes: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _EmptyState(
                          onCreate: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ClienteCreateScreen(),
                              ),
                            );
                          },
                        );
                      }

                      final allDocs = snapshot.data!.docs;
                      final clientes = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _coincideBusquedaYFiltro(data, doc.id);
                      }).toList();

                      // Contador de resultados
                      final total = allDocs.length;
                      final count = clientes.length;

                      if (clientes.isEmpty) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Mostrando 0 de $total resultados',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _NoResults(),
                          ],
                        );
                      }

                      // Encabezado con contador
                      final header = Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Mostrando $count de $total resultados',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );

                      if (isMobile) {
                        return Column(
                          children: [
                            header,
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.all(8),
                                itemCount: clientes.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, idx) {
                                  final cliente = clientes[idx];
                                  final data =
                                      cliente.data() as Map<String, dynamic>;
                                  return _ClienteCard(
                                    tint: _cardTintForTipo(
                                      context,
                                      (data['tipo'] ?? '').toString(),
                                    ),
                                    data: data,
                                    clienteId: cliente.id,
                                    acciones: _accionesPopup(
                                      clienteId: cliente.id,
                                      codigo: (data['codigo'] ?? '').toString(),
                                      nombre: (data['nombre'] ?? '').toString(),
                                      data: data,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      } else if (isTablet) {
                        // Grid en tablet
                        final crossAxisCount = 2;
                        return Column(
                          children: [
                            header,
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.all(12),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 1.9,
                                    ),
                                itemCount: clientes.length,
                                itemBuilder: (context, idx) {
                                  final cliente = clientes[idx];
                                  final data =
                                      cliente.data() as Map<String, dynamic>;
                                  return _ClienteCard(
                                    tint: _cardTintForTipo(
                                      context,
                                      (data['tipo'] ?? '').toString(),
                                    ),
                                    data: data,
                                    clienteId: cliente.id,
                                    acciones: _accionesPopup(
                                      clienteId: cliente.id,
                                      codigo: (data['codigo'] ?? '').toString(),
                                      nombre: (data['nombre'] ?? '').toString(),
                                      data: data,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      } else {
                        // ----------- TABLA PARA ESCRITORIO -----------
                        return Column(
                          children: [
                            header,
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 24,
                                    // MaterialStateProperty deprecado -> WidgetStateProperty
                                    headingRowColor:
                                        WidgetStatePropertyAll<Color?>(
                                          theme.colorScheme.primary.withValues(
                                            alpha: 30 / 255,
                                          ),
                                        ),
                                    columns: const [
                                      DataColumn(label: Text('Código')),
                                      DataColumn(label: Text('Nombre')),
                                      DataColumn(label: Text('Tipo')),
                                      DataColumn(label: Text('Razón social')),
                                      DataColumn(label: Text('RFC')),
                                      DataColumn(label: Text('Ciudad')),
                                      DataColumn(label: Text('Teléfono')),
                                      DataColumn(label: Text('Correo')),
                                      DataColumn(label: Text('Acciones')),
                                    ],
                                    rows: clientes.map((cliente) {
                                      final data =
                                          cliente.data()
                                              as Map<String, dynamic>;
                                      final codigo = (data['codigo'] ?? '')
                                          .toString();
                                      final nombre = (data['nombre'] ?? '')
                                          .toString();
                                      final tipo = (data['tipo'] ?? '')
                                          .toString();
                                      final razonSocial =
                                          (data['razon_social'] ?? '')
                                              .toString();
                                      final rfc = (data['rfc'] ?? '')
                                          .toString();
                                      final ciudad = (data['ciudad'] ?? '')
                                          .toString();
                                      final telefono = (data['telefono'] ?? '')
                                          .toString();
                                      final correo = (data['correo'] ?? '')
                                          .toString();

                                      final tipoLabel = tipo.isNotEmpty
                                          ? (tipo == 'empresa'
                                                ? 'Empresa'
                                                : 'Persona')
                                          : '';

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(codigo)),
                                          DataCell(Text(nombre)),
                                          DataCell(Text(tipoLabel)),
                                          DataCell(Text(razonSocial)),
                                          DataCell(Text(rfc)),
                                          DataCell(Text(ciudad)),
                                          DataCell(Text(telefono)),
                                          DataCell(Text(correo)),
                                          DataCell(
                                            _accionesPopup(
                                              clienteId: cliente.id,
                                              codigo: codigo,
                                              nombre: nombre,
                                              data: data,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClienteCreateScreen()),
          );
        },
        tooltip: 'Registrar nuevo cliente',
        icon: const Icon(Icons.add),
        label: const Text('Nuevo cliente'),
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String clienteId;
  final Color tint;
  final Widget acciones;

  const _ClienteCard({
    required this.data,
    required this.clienteId,
    required this.tint,
    required this.acciones,
  });

  @override
  Widget build(BuildContext context) {
    final codigo = (data['codigo'] ?? '').toString();
    final nombre = (data['nombre'] ?? '').toString();
    final ciudad = (data['ciudad'] ?? '').toString();
    final telefono = (data['telefono'] ?? '').toString();
    final correo = (data['correo'] ?? '').toString();
    final razonSocial = (data['razon_social'] ?? '').toString();
    final rfc = (data['rfc'] ?? '').toString().toUpperCase();
    final tipo = (data['tipo'] ?? '').toString(); // persona | empresa

    final tipoLabel = tipo == 'empresa'
        ? 'Empresa'
        : (tipo == 'persona' ? 'Persona' : 'Desconocido');

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tint.withValues(alpha: 0.5), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [Colors.white, tint],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.6, 1],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + código/nombre + acciones
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                  foregroundColor: colorScheme.primary,
                  child: Text(
                    (nombre.isNotEmpty ? nombre[0] : '?').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$codigo - $nombre',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tipo == 'empresa'
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: tipo == 'empresa'
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                            ),
                            child: Text(
                              tipoLabel,
                              style: TextStyle(
                                color: tipo == 'empresa'
                                    ? Colors.blue[700]
                                    : Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // ID oculto: se retira el tooltip con el ID
                        ],
                      ),
                    ],
                  ),
                ),
                acciones,
              ],
            ),
            const SizedBox(height: 8),
            if (razonSocial.isNotEmpty)
              _infoRow(
                Icons.business_center_outlined,
                'Razón social: $razonSocial',
              ),
            if (rfc.isNotEmpty) _infoRow(Icons.badge_outlined, 'RFC: $rfc'),
            if (ciudad.isNotEmpty)
              _infoRow(Icons.location_city_outlined, 'Ciudad: $ciudad'),
            if (telefono.isNotEmpty)
              _infoRow(Icons.phone_outlined, 'Tel: $telefono'),
            if (correo.isNotEmpty)
              _infoRow(Icons.email_outlined, 'Correo: $correo'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[800], fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.contact_page_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay clientes registrados.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comienza creando tu primer cliente.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Registrar nuevo cliente'),
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No hay resultados para la búsqueda.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
