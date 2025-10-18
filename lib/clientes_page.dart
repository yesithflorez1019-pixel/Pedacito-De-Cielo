// lib/clientes_page.dart (Versión Súper Mejorada)

import 'package:flutter/material.dart';
import 'package:postres_app/cliente.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/registrar_cliente_page.dart';
import 'package:postres_app/util/app_colors.dart';
import 'package:postres_app/widgets/acrylic_card.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum OrdenClientes { AZ, ZA, Recientes }

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  List<Cliente> _todosLosClientes = [];
  List<Cliente> _clientesFiltrados = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  OrdenClientes _ordenActual = OrdenClientes.Recientes;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
    _searchController.addListener(_filtrarClientes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    setState(() => _isLoading = true);
    final clientes = await AppDatabase.obtenerClientes();
    setState(() {
      _todosLosClientes = clientes;
      _ordenarYFiltrar();
      _isLoading = false;
    });
  }

  void _ordenarYFiltrar() {
    // 1. Ordenamos la lista completa
    switch (_ordenActual) {
      case OrdenClientes.AZ:
        _todosLosClientes.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        break;
      case OrdenClientes.ZA:
        _todosLosClientes.sort((a, b) => b.nombre.toLowerCase().compareTo(a.nombre.toLowerCase()));
        break;
      case OrdenClientes.Recientes:
        _todosLosClientes.sort((a, b) => b.id!.compareTo(a.id!)); // Asumiendo que el ID más alto es el más reciente
        break;
    }
    // 2. Aplicamos el filtro de búsqueda
    _filtrarClientes();
  }

  void _filtrarClientes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _clientesFiltrados = _todosLosClientes.where((cliente) {
        final nombre = cliente.nombre.toLowerCase();
        return nombre.contains(query);
      }).toList();
    });
  }
  
  void _cambiarOrden() {
    setState(() {
      if (_ordenActual == OrdenClientes.Recientes) {
        _ordenActual = OrdenClientes.AZ;
      } else if (_ordenActual == OrdenClientes.AZ) {
        _ordenActual = OrdenClientes.ZA;
      } else {
        _ordenActual = OrdenClientes.Recientes;
      }
      _ordenarYFiltrar();
    });
  }

  void _navegarARegistro([Cliente? cliente]) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => RegistrarClientePage(cliente: cliente)),
    );
    if (resultado == true) {
      _cargarClientes();
    }
  }

  Future<void> _eliminarCliente(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar a ${cliente.nombre}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true) {
      await AppDatabase.eliminarCliente(cliente.id!);
      _cargarClientes();
    }
  }

  // Nueva función para lanzar URLs (llamadas, WhatsApp)
  Future<void> _lanzarUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la aplicación para $url')),
      );
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
          gradient: LinearGradient(colors: [kColorBackground1, kColorBackground2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kColorPrimary))
                  : _clientesFiltrados.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _cargarClientes,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: _clientesFiltrados.length,
                            itemBuilder: (context, index) => _buildClienteCard(_clientesFiltrados[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    IconData ordenIcon;
    String ordenTooltip;
    switch (_ordenActual) {
      case OrdenClientes.AZ:
        ordenIcon = Icons.sort_by_alpha;
        ordenTooltip = 'Ordenado A-Z';
        break;
      case OrdenClientes.ZA:
        ordenIcon = Icons.sort_by_alpha; // El ícono puede ser el mismo, o puedes buscar otro
        ordenTooltip = 'Ordenado Z-A';
        break;
      case OrdenClientes.Recientes:
        ordenIcon = Icons.new_releases;
        ordenTooltip = 'Más recientes';
        break;
    }
    
    return Container(
      // ... (El estilo de tu header se mantiene, solo añadimos el botón de ordenar)
       padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 16),
       decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kColorHeader1, kColorHeader2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(child: Text("Mis Clientes", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Tooltip(
            message: ordenTooltip,
            child: IconButton(
              icon: Icon(ordenIcon, color: Colors.white),
              onPressed: _cambiarOrden,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar cliente...',
          prefixIcon: const Icon(Icons.search, color: kColorPrimary),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
            : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_searchController.text.isNotEmpty ? Icons.search_off : Icons.people_outline, size: 80, color: kColorPrimary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(_searchController.text.isNotEmpty ? 'Sin resultados' : 'Aún no hay clientes', style: const TextStyle(fontSize: 24, color: kColorTextDark)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              _searchController.text.isNotEmpty ? 'No se encontraron clientes con ese nombre.' : '¡Toca el botón "+" para agregar tu primer cliente!',
              textAlign: TextAlign.center,
              style: TextStyle(color: kColorTextDark.withOpacity(0.7), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard(Cliente cliente) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AcrylicCard(
        child: Column(
          children: [
            ListTile(
              onTap: () => _navegarARegistro(cliente),
              leading: CircleAvatar(backgroundColor: kColorPrimary.withOpacity(0.2), child: Text(cliente.nombre.substring(0,1), style: const TextStyle(color: kColorPrimary, fontWeight: FontWeight.bold))),
              title: Text(cliente.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cliente.direccion?.isNotEmpty ?? false) Text(cliente.direccion!),
                  if (cliente.telefono?.isNotEmpty ?? false) Text(cliente.telefono!, style: const TextStyle(color: kColorTextDark)),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: kColorTextDark),
                onPressed: () => _navegarARegistro(cliente),
              ),
            ),
            // La nueva fila de acciones rápidas
            if (cliente.telefono?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    label: const Text('Llamar', style: TextStyle(color: Colors.green)),
                    onPressed: () => _lanzarUrl('tel:${cliente.telefono!}'),
                  ),
                  TextButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                    label: const Text('WhatsApp', style: TextStyle(color: Colors.teal)),
                    onPressed: () => _lanzarUrl('https://wa.me/57${cliente.telefono!}'), // Asume prefijo de Colombia
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _eliminarCliente(cliente),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}