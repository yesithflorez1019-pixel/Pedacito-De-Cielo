// lib/registrar_pedido.dart - VERSIÓN FINAL CON AUTOCOMPLETADO NATIVO Y CORRECCIONES

import 'package:flutter/material.dart';
import 'package:postres_app/cliente.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/detalle_pedido.dart';
import 'package:postres_app/formato.dart';
import 'package:postres_app/pedido.dart';
import 'package:postres_app/producto.dart';
import 'package:postres_app/util/app_colors.dart';
import 'package:postres_app/widgets/acrylic_card.dart';

class RegistrarPedidoPage extends StatefulWidget {
  final Pedido? pedidoEditar;
  final int tandaId;

  const RegistrarPedidoPage({
    super.key,
    required this.tandaId,
    this.pedidoEditar,
  });

  @override
  State<RegistrarPedidoPage> createState() => _RegistrarPedidoPageState();
}

class _RegistrarPedidoPageState extends State<RegistrarPedidoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController pagoParcialController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> productosFiltrados = [];
  List<DetallePedido> detalles = [];
  bool entregado = false;
  bool pagado = false;

  Map<int, int> _stockDisponible = {};
  Map<int, int> _cantidadesEnPedido = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    searchController.addListener(filtrarProductos);
    _loadData();
    pagoParcialController.addListener(() => setState(() {}));

  }
  
  @override
  void dispose() {
    clienteController.dispose();
    direccionController.dispose();
    telefonoController.dispose();
    pagoParcialController.dispose();
    searchController.dispose();
    super.dispose();
  }

  
  Future<void> _loadData() async {
   
    if (widget.pedidoEditar != null) {
      final pedido = widget.pedidoEditar!;
      clienteController.text = pedido.cliente;
      direccionController.text = pedido.direccion;
      telefonoController.text = pedido.telefono ?? ''; 
      pagoParcialController.text = pedido.pagoParcial.toStringAsFixed(0);
      entregado = pedido.entregado;
      pagado = pedido.pagado;
      detalles = List.from(pedido.detalles);
      
      for (var detalle in pedido.detalles) {
        _cantidadesEnPedido[detalle.producto.id!] = detalle.cantidad;
      }
    }

    
    final productosDeTanda = await AppDatabase.obtenerProductosDeTanda(widget.tandaId);

   
    if (mounted) {
      setState(() {
        productos = productosDeTanda.map((map) {
          final productoId = map['productoId'] as int;
          final stockTotal = map['stock'] as int;
          final stockEnPedido = _cantidadesEnPedido[productoId] ?? 0;
          _stockDisponible[productoId] = stockTotal + stockEnPedido;
          return {
            'producto': Producto(
              id: productoId,
              nombre: map['nombre'] as String,
              precio: map['precio'] as double,
            ),
            'stock': stockTotal + stockEnPedido,
          };
        }).toList();
        productosFiltrados = List.from(productos);
        _isLoading = false;
      });
    }
  }

void _mostrarDialogoSumarAbono() {
  final abonoAdicionalController = TextEditingController();
  String? errorText; 


  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder( 
        builder: (context, setStateDialog) {
          return AlertDialog(

            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Sumar al Abono'),
            content: TextFormField(
              controller: abonoAdicionalController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Monto a agregar',
                prefixIcon: const Icon(Icons.add_shopping_cart, color: kColorPrimary),

                errorText: errorText, 
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final abonoActual = double.tryParse(pagoParcialController.text) ?? 0.0;
                  final abonoAdicional = double.tryParse(abonoAdicionalController.text) ?? 0.0;
                  

                  if (abonoActual + abonoAdicional > totalPedido) {
                    setStateDialog(() { 
                      errorText = 'El abono supera el total del pedido.';
                    });
                  } else {

                    final nuevoTotal = abonoActual + abonoAdicional;
                    setState(() { 
                      pagoParcialController.text = nuevoTotal.toStringAsFixed(0);
                    });
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      );
    },
  );
}

  void filtrarProductos() {
    final query = searchController.text.toLowerCase();
    setState(() {
      productosFiltrados = productos
          .where((p) => (p['producto'] as Producto).nombre.toLowerCase().contains(query))
          .toList();
    });
  }

  void agregarDetalle(Producto producto, int cantidad) {
    setState(() {
      final productoId = producto.id!;
      final cantidadActualEnPedido = _cantidadesEnPedido[productoId] ?? 0;
      final stockDisponibleReal = _stockDisponible[productoId] ?? 0;
      final stockRestante = stockDisponibleReal - cantidadActualEnPedido;

      if (cantidad > stockRestante) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No hay suficiente stock. Disponibles: $stockRestante'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      _cantidadesEnPedido[productoId] = cantidadActualEnPedido + cantidad;

      final index = detalles.indexWhere((d) => d.producto.id == productoId);
      if (index != -1) {
        detalles[index].cantidad += cantidad;
      } else {
        detalles.add(DetallePedido(producto: producto, cantidad: cantidad));
      }
    });
  }

  void quitarDetalle(DetallePedido detalle) {
    setState(() {
      final productoId = detalle.producto.id!;
      _cantidadesEnPedido.remove(productoId);
      detalles.remove(detalle);
    });
  }

  double get totalPedido => detalles.fold(0, (suma, det) => suma + det.subtotal);

  Future<void> guardarPedido() async {
    if (!_formKey.currentState!.validate()) return;
    if (detalles.isEmpty) {
      return;
    }

    final pago = pagado ? totalPedido : (double.tryParse(pagoParcialController.text) ?? 0.0);
    
    final pedido = Pedido(
      id: widget.pedidoEditar?.id,
      tandaId: widget.tandaId,
      cliente: clienteController.text.trim(),
      direccion: direccionController.text.trim(),
      telefono: telefonoController.text.trim(),
      entregado: entregado,
      pagado: pagado,
      pagoParcial: pago,
      detalles: detalles,
      fecha: widget.pedidoEditar?.fecha ?? DateTime.now(), 
    );

    if (widget.pedidoEditar != null) {
      await AppDatabase.actualizarPedidoConDetalles(pedido);
    } else {
      await AppDatabase.insertarPedidoConDetalles(pedido);
    }
    
    
    final clienteAGuardar = Cliente(
      nombre: clienteController.text.trim(),
      direccion: direccionController.text.trim(),
      telefono: telefonoController.text.trim()
    );
    await AppDatabase.insertarCliente(clienteAGuardar);


    if (mounted) Navigator.pop(context, true);
  }

  void mostrarDialogoCantidad(Producto producto) {
    final cantidadController = TextEditingController(text: '1');
    final stockInicial = _stockDisponible[producto.id!] ?? 0;
    final cantidadEnPedido = _cantidadesEnPedido[producto.id!] ?? 0;
    final stockDisponible = stockInicial - cantidadEnPedido;
    
    if (stockDisponible <= 0) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kColorBackground1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cantidad para ${producto.nombre}', style: const TextStyle(color: kColorPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Cantidad'),
            ),
            const SizedBox(height: 8),
            Text(
              'Stock disponible: $stockDisponible',
              style: TextStyle(
                color: stockDisponible > 0 ? Colors.teal.shade700 : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(child: Text('Cancelar', style: TextStyle(color: kColorTextDark.withOpacity(0.7))), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text('Agregar'),
            style: ElevatedButton.styleFrom(backgroundColor: kColorPrimary, foregroundColor: Colors.white),
            onPressed: () {
              final cantidad = int.tryParse(cantidadController.text) ?? 0;
              if (cantidad <= 0) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('La cantidad debe ser mayor a 0')),
                 );
                 return;
              }
              if (cantidad > stockDisponible) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cantidad no disponible. Solo quedan $stockDisponible')),
                );
              } else {
                agregarDetalle(producto, cantidad);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kColorBackground1, kColorBackground2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(child: CircularProgressIndicator(color: kColorPrimary)),
        ),
      );
    }

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
                        widget.pedidoEditar != null ? 'Editar Pedido' : 'Nuevo Pedido',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.save_outlined, color: Colors.white),
                      onPressed: guardarPedido,
                      tooltip: 'Guardar Pedido',
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildTotalCard(),
                    _buildSectionTitle('Datos del Cliente'),
                    _buildClienteCard(),
                    _buildSectionTitle('Estado y Pago'),
                    _buildPagoCard(),
                    _buildSectionTitle('Añadir Productos'),
                    _buildAddProductsSection(),
                    _buildSectionTitle('Resumen del Pedido'),
                    _buildResumenCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return AcrylicCard(
      child:Padding(
        padding: const EdgeInsets.all(16),
      child:Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total del Pedido', style: TextStyle(color: kColorTextDark.withOpacity(0.8), fontSize: 16)),
          Text(totalPedido.aPesos(), style: const TextStyle(color: kColorPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
    );
  }
  
  Widget _buildClienteCard() {
    return AcrylicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Autocomplete<Cliente>(
              key: Key(clienteController.text),
              initialValue: TextEditingValue(text: clienteController.text),
              displayStringForOption: (option) => option.nombre,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<Cliente>.empty();
                }
                clienteController.text = textEditingValue.text;
                return AppDatabase.buscarClientesPorNombre(textEditingValue.text);
              },
              onSelected: (Cliente selection) {
                clienteController.text = selection.nombre;
                direccionController.text = selection.direccion ?? '';
                telefonoController.text = selection.telefono ?? '';
                FocusScope.of(context).unfocus();
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Cliente',
                    prefixIcon: Icon(Icons.person_outline, color: kColorPrimary),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingresa el nombre del cliente' : null,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Cliente option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: ListTile(
                              title: Text(option.nombre),
                              subtitle: Text(option.telefono ?? 'Sin teléfono'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: direccionController,
              decoration: const InputDecoration(labelText: 'Dirección', prefixIcon: Icon(Icons.location_on_outlined, color: kColorPrimary)),
              validator: (v) => v!.isEmpty ? 'Ingresa la dirección' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono (WhatsApp)', prefixIcon: Icon(Icons.phone, color: kColorPrimary)),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagoCard() {
  // --- ✅ Lógica de cálculo en tiempo real ---
  final abono = double.tryParse(pagoParcialController.text) ?? 0.0;
  final faltante = (totalPedido - abono).clamp(0, totalPedido); // clamp() evita negativos

  return AcrylicCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // --- El nuevo campo "Faltante" ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ListTile(
              title: const Text('Faltante por Pagar:', style: TextStyle(color: kColorTextDark)),
              trailing: Text(
                faltante.aPesos(), // Usamos tu formateador de moneda
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kColorPrimary,
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: pagoParcialController,
                    keyboardType: TextInputType.number,
                    enabled: !pagado,
                    decoration: const InputDecoration(
                      labelText: 'Abono Parcial',
                      prefixIcon: Icon(Icons.attach_money_outlined, color: kColorPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _mostrarDialogoSumarAbono,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                    backgroundColor: kColorPrimary,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Pagado Completamente', style: TextStyle(color: kColorTextDark)),
            value: pagado,
            onChanged: (value) => setState(() {
              pagado = value;
              if (pagado) {
                pagoParcialController.text = totalPedido.toStringAsFixed(0);
              }
            }),
            activeColor: kColorPrimary,
          ),
          SwitchListTile(
            title: const Text('Entregado', style: TextStyle(color: kColorTextDark)),
            value: entregado,
            onChanged: (value) => setState(() => entregado = value),
            activeColor: kColorPrimary,
          ),
        ],
      ),
    ),
  );
}
  
  Widget _buildAddProductsSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextFormField(controller: searchController, decoration: const InputDecoration(labelText: 'Buscar producto...', prefixIcon: Icon(Icons.search, color: kColorPrimary))),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: productosFiltrados.length,
            itemBuilder: (context, index) {
              final pMap = productosFiltrados[index];
              final p = pMap['producto'] as Producto;
              final stockDisponible = (_stockDisponible[p.id!] ?? 0) - (_cantidadesEnPedido[p.id!] ?? 0);
              return _ProductSelectorCard(
                producto: p, 
                stock: stockDisponible, 
                onTap: () => mostrarDialogoCantidad(p)
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildResumenCard() {
    return AcrylicCard(
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: detalles.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Aún no has agregado productos.', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: detalles.length,
              itemBuilder: (_, index) {
                final detalle = detalles[index];
                return ListTile(
                  leading: const Icon(Icons.shopping_basket_outlined, color: kColorPrimary),
                  title: Text('${detalle.cantidad}x ${detalle.producto.nombre}', style: const TextStyle(color: kColorTextDark)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(detalle.subtotal.aPesos(), style: const TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => quitarDetalle(detalle),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kColorPrimary)),
    );
  }
}

class _ProductSelectorCard extends StatelessWidget {
  final Producto producto;
  final int stock;
  final VoidCallback onTap;

  const _ProductSelectorCard({required this.producto, required this.stock, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = stock > 0;
    return SizedBox(
      width: 130,
      child: Card(
        color: isAvailable ? Colors.white : Colors.grey.shade200,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: isAvailable ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(producto.nombre, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isAvailable ? kColorTextDark : Colors.grey.shade600)),
                const Spacer(),
                Text(producto.precio.aPesos(), style: TextStyle(color: isAvailable ? kColorTextDark.withOpacity(0.7) : Colors.grey.shade600)),
                Text('Stock: $stock', style: TextStyle(color: isAvailable ? Colors.teal : Colors.red, fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(Icons.add_shopping_cart_outlined, color: isAvailable ? kColorPrimary : Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}