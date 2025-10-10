
import 'package:flutter/material.dart';
import 'producto.dart';
import 'database.dart';
import 'formato.dart'; 
import 'package:flutter/services.dart';
import 'util/app_colors.dart';
import 'package:postres_app/widgets/acrylic_card.dart';


class AgregarProductoPage extends StatefulWidget {
  final Producto? productoExistente;
  const AgregarProductoPage({super.key, this.productoExistente});

  @override
  State<AgregarProductoPage> createState() => _AgregarProductoPageState();
}

class _AgregarProductoPageState extends State<AgregarProductoPage> {
  final nombreCtrl = TextEditingController();
  final precioCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.productoExistente != null) {
      nombreCtrl.text = widget.productoExistente!.nombre;
      precioCtrl.text =
          widget.productoExistente!.precio.toInt().aPesos(conSimbolo: false);
    }
  }

  Future<void> guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = nombreCtrl.text.trim();
    final precio = double.tryParse(precioCtrl.text.replaceAll('.', '')) ?? 0.0;

    if (nombre.isEmpty || precio <= 0) return;

    if (widget.productoExistente != null) {
      final confirmacion = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: kColorBackground1,
          title: const Text(
            '¡Cuidado!',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: kColorPrimary),
          ),
          content: const Text(
            'Actualizar este producto afectará los pedidos existentes.\n¿Seguro que quieres continuar?',
            style: TextStyle(color: kColorTextDark, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kColorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );

      if (confirmacion != true) return;
    }


    final producto = Producto(
      id: widget.productoExistente?.id,
      nombre: nombre,
      precio: precio,
      rendimientoTanda: widget.productoExistente?.rendimientoTanda ?? 1,
    );

    if (widget.productoExistente == null) {
      await AppDatabase.insertarProducto(producto);
    } else {
      await AppDatabase.actualizarProducto(producto);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.productoExistente != null;
    return Scaffold(
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
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kColorHeader1, kColorHeader2],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                  ]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        editando ? 'Editar Producto' : 'Nuevo Producto',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  AcrylicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Icon(editando ? Icons.edit_note : Icons.add_business_outlined, size: 60, color: kColorPrimary),
                            const SizedBox(height: 16),
                            Text(
                              'Información del producto',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: kColorTextDark),
                              textAlign: TextAlign.center,
                            ),
                             Text(
                              'Dale un nombre y precio a tu creación',
                              style: TextStyle(color: kColorTextDark.withOpacity(0.7)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: nombreCtrl,
                              decoration: const InputDecoration(labelText: 'Nombre del producto', prefixIcon: Icon(Icons.cake_outlined, color: kColorPrimary)),
                              validator: (v) => v!.isEmpty ? 'El nombre es requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: precioCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(labelText: 'Precio', prefixIcon: Icon(Icons.attach_money, color: kColorPrimary)),
                               validator: (v) => v!.isEmpty ? 'El precio es requerido' : null,
                              onChanged: (value) {
                                final cleaned = value.replaceAll('.', '');
                                if (cleaned.isEmpty) return;
                                final numero = int.tryParse(cleaned);
                                if (numero == null) return;
                                final formatted = numero.aPesos(conSimbolo: false);
                                if (formatted != value) {
                                  precioCtrl.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(offset: formatted.length),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: guardar,
                                icon: Icon(editando ? Icons.sync_alt : Icons.save_outlined),
                                label: Text(editando ? 'Actualizar Producto' : 'Guardar Producto'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kColorPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

