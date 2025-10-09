// lib/registrar_cliente_page.dart
import 'package:flutter/material.dart';
import 'package:postres_app/cliente.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/util/app_colors.dart';

class RegistrarClientePage extends StatefulWidget {
  final Cliente? cliente;
  const RegistrarClientePage({super.key, this.cliente});

  @override
  State<RegistrarClientePage> createState() => _RegistrarClientePageState();
}

class _RegistrarClientePageState extends State<RegistrarClientePage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.cliente != null) {
      _nombreController.text = widget.cliente!.nombre;
      _direccionController.text = widget.cliente!.direccion ?? '';
      _telefonoController.text = widget.cliente!.telefono ?? '';
    }
  }

  Future<void> _guardarCliente() async {
    if (_formKey.currentState!.validate()) {
      final nuevoCliente = Cliente(
        id: widget.cliente?.id,
        nombre: _nombreController.text,
        direccion: _direccionController.text,
        telefono: _telefonoController.text,
      );

      if (widget.cliente == null) {
        await AppDatabase.insertarCliente(nuevoCliente);
      } else {
        await AppDatabase.actualizarCliente(nuevoCliente);
      }

      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cliente == null ? 'Nuevo Cliente' : 'Editar Cliente'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _guardarCliente)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre Completo'),
              validator: (value) => value!.isEmpty ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono (WhatsApp)'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}