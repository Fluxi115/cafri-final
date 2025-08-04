// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registeruser_screen.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String rol;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.rol,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      rol: data['rol'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'rol': rol};
  }

  UserModel copyWith({String? name, String? email, String? rol}) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      rol: rol ?? this.rol,
    );
  }
}

class UserService {
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  Future<List<UserModel>> getAllUsers() async {
    final querySnapshot = await usersCollection.get();
    return querySnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  Future<void> addUser(UserModel user) async {
    await usersCollection.add(user.toMap());
  }

  Future<void> updateUser(UserModel user) async {
    await usersCollection.doc(user.id).update(user.toMap());
  }

  Future<void> deleteUser(String id) async {
    await usersCollection.doc(id).delete();
  }
}

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = UserService().getAllUsers();
    });
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este usuario?',
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
      await UserService().deleteUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario eliminado'),
          backgroundColor: Colors.red,
        ),
      );
      _refreshUsers();
    }
  }

  void _editUser(UserModel user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditUserScreen(user: user)),
    );
    _refreshUsers();
  }

  void _addUser() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisteruserScreen()),
    );
    _refreshUsers();
  }

  Widget _buildRoleChip(String rol) {
    return Chip(
      label: Text(
        rol[0].toUpperCase() + rol.substring(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: rol == 'administrador' ? Colors.indigo : Colors.green,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      backgroundColor: Colors.indigo[50],
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay usuarios registrados.',
                style: TextStyle(fontSize: 22),
              ),
            );
          }
          final users = snapshot.data!;
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
              child: Card(
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: isWide ? 48 : 24,
                        dataRowMinHeight: isWide ? 70 : 60,
                        dataRowMaxHeight: isWide ? 90 : 70,
                        headingRowColor:
                            WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) => Colors.indigo[100],
                            ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Nombre',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Correo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Rol',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Acciones',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                        rows: users.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    user.email,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(_buildRoleChip(user.rol)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Tooltip(
                                      message: 'Editar',
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.indigo,
                                          size: 28,
                                        ),
                                        onPressed: () => _editUser(user),
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Eliminar',
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 28,
                                        ),
                                        onPressed: () => _deleteUser(user.id),
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
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUser,
        icon: const Icon(Icons.person_add, size: 28),
        label: const Text('Nuevo usuario', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.indigo,
        elevation: 6,
      ),
    );
  }
}

class EditUserScreen extends StatefulWidget {
  final UserModel user;
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late String _selectedRol;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedRol = widget.user.rol;
  }

  void _updateUser() async {
    setState(() {
      _isLoading = true;
    });

    final updatedUser = widget.user.copyWith(
      name: _nameController.text,
      email: _emailController.text,
      rol: _selectedRol,
    );
    await UserService().updateUser(updatedUser);

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usuario actualizado'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar usuario'),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 12,
              color: Colors.white.withAlpha(240),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Correo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: false, // No permitir editar el correo
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRol,
                      decoration: InputDecoration(
                        labelText: 'Rol',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRol = newValue!;
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'administrador',
                          child: Text(
                            'Administrador',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'colaborador',
                          child: Text(
                            'Colaborador',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _updateUser,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.indigo,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: const Text(
                                'Guardar cambios',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
