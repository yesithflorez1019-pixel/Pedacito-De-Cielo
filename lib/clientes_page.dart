// lib/clientes_page.dart
import 'package:flutter/material.dart';
import 'package:postres_app/cliente.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/registrar_cliente_page.dart';
import 'package:postres_app/util/app_colors.dart';
import 'package:postres_app/widgets/acrylic_card.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  late Future<List<Cliente>> _clientesFuture;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  void _cargarClientes() {
    setState(() {
      _clientesFuture = AppDatabase.obtenerClientes();
    });
  }

  void _navegarARegistro([Cliente? cliente]) async {
    final bool? resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistrarClientePage(cliente: cliente)),
    );
    if (resultado == true) {
      _cargarClientes();
    }
  }

  Future<void> _eliminarCliente(Cliente cliente) async {
    final bool? confirmar = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Confirmar eliminación'),
              content: Text('¿Estás seguro de que quieres eliminar a ${cliente.nombre}?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
              ],
            ));

    if (confirmar == true) {
      await AppDatabase.eliminarCliente(cliente.id!);
      _cargarClientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarARegistro,
        backgroundColor: kColorPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kColorBackground1, kColorBackground2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FutureBuilder<List<Cliente>>(
                future: _clientesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kColorPrimary));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No hay clientes registrados.'));
                  }
                  final clientes = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: clientes.length,
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
                      return AcrylicCard(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(cliente.nombre),
                          subtitle: Text(cliente.direccion ?? 'Sin dirección'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: kColorTextDark),
                                onPressed: () => _navegarARegistro(cliente),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _eliminarCliente(cliente),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 16),
      decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kColorHeader1, kColorHeader2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              "Mis Clientes",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarClientes,
          ),
        ],
      ),
    );
  }
}