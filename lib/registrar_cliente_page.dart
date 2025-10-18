// lib/registrar_cliente_page.dart (Versión Totalmente Rediseñada)

import 'package:flutter/material.dart';
import 'package:postres_app/cliente.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/util/app_colors.dart';
import 'package:postres_app/widgets/acrylic_card.dart';

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

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardarCliente() async {
    // Si el formulario es válido, procede a guardar.
    if (_formKey.currentState!.validate()) {
      final nuevoCliente = Cliente(
        id: widget.cliente?.id,
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
        telefono: _telefonoController.text.trim(),
      );

      if (widget.cliente == null) {
        await AppDatabase.insertarCliente(nuevoCliente);
      } else {
        await AppDatabase.actualizarCliente(nuevoCliente);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente ${widget.cliente == null ? 'guardado' : 'actualizado'} con éxito.')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos un body que no se desborde cuando aparece el teclado
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: AcrylicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextFormField(
                            controller: _nombreController,
                            label: 'Nombre Completo',
                            icon: Icons.person_outline,
                            validator: (value) => value!.trim().isEmpty ? 'El nombre es obligatorio' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildTextFormField(
                            controller: _direccionController,
                            label: 'Dirección (Opcional)',
                            icon: Icons.home_outlined,
                          ),
                          const SizedBox(height: 20),
                          _buildTextFormField(
                            controller: _telefonoController,
                            label: 'Teléfono (Opcional)',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _guardarCliente,
                            icon: const Icon(Icons.save_alt_outlined),
                            label: const Text('Guardar Cliente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kColorPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header personalizado para mantener la consistencia visual
  Widget _buildHeader() {
    return Container(
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
          Expanded(
            child: Text(
              widget.cliente == null ? 'Nuevo Cliente' : 'Editar Cliente',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // Dejamos un espacio en blanco para centrar el título
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // Widget reutilizable para los campos de texto estilizados
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kColorPrimary.withOpacity(0.8)),
        filled: true,
        fillColor: Colors.grey.shade200.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: kColorPrimary, width: 2),
        ),
      ),
    );
  }
}