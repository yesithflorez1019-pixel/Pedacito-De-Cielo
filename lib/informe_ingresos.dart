// lib/informe_ingresos.dart
import 'package:flutter/material.dart';
import 'database.dart';
import 'gasto.dart';
import 'formato.dart';
import 'package:intl/intl.dart';
import 'util/app_colors.dart';
import 'package:postres_app/widgets/acrylic_card.dart';


class InformeIngresosPage extends StatefulWidget {
  final int tandaId;
  final String nombreTanda;
  const InformeIngresosPage({
    super.key,
    required this.tandaId,
    required this.nombreTanda,
  });

  @override
  State<InformeIngresosPage> createState() => _InformeIngresosPageState();
}

class _InformeIngresosPageState extends State<InformeIngresosPage> {
  List<Map<String, dynamic>> ingresos = [];
  List<Gasto> gastos = [];
  double totalPagado = 0.0;
  double totalGastos = 0.0;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    ingresos = await AppDatabase.obtenerIngresosPorProducto(widget.tandaId);
    totalPagado = await AppDatabase.obtenerTotalPagosParcialesPorTanda(widget.tandaId);
    gastos = await AppDatabase.obtenerGastosPorTanda(widget.tandaId);
    totalGastos = await AppDatabase.obtenerTotalGastosPorTanda(widget.tandaId);
    if (mounted) setState(() {});
  }

  Future<void> agregarOEditarGasto({Gasto? gasto}) async {
    final bool esNuevo = gasto == null;
    final descCtrl = TextEditingController(text: esNuevo ? '' : gasto.descripcion);
    final montoCtrl = TextEditingController(text: esNuevo ? '' : gasto.monto.toString());

    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kColorBackground1.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(esNuevo ? 'Nuevo Gasto' : 'Editar Gasto', style: const TextStyle(color: kColorPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
            TextFormField(
                controller: montoCtrl,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: kColorTextDark.withOpacity(0.7)))),
          ElevatedButton(
            onPressed: () async {
              final monto = double.tryParse(montoCtrl.text) ?? 0.0;
              final desc = descCtrl.text.trim();
              if (monto > 0 && desc.isNotEmpty) {
                if (esNuevo) {
                  await AppDatabase.insertarGasto(Gasto(
                      tandaId: widget.tandaId,
                      descripcion: desc,
                      monto: monto,
                      fecha: DateTime.now()));
                } else {
                  await AppDatabase.actualizarGasto(Gasto(
                      id: gasto.id,
                      tandaId: gasto.tandaId,
                      descripcion: desc,
                      monto: monto,
                      fecha: gasto.fecha));
                }
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kColorPrimary, foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardado == true) {
      await cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => agregarOEditarGasto(),
          label: const Text('Nuevo Gasto'),
          icon: const Icon(Icons.add),
          backgroundColor: kColorPrimary,
          foregroundColor: Colors.white,
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, right: 16.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              widget.nombreTanda,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: cargar,
                          ),
                        ],
                      ),
                    ),
                    const TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorWeight: 2.5,
                      tabs: [
                        Tab(icon: Icon(Icons.cake_outlined), text: 'Ingresos'),
                        Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Gastos'),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    _buildResumenCard(),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildIngresosList(),
                          _buildGastosList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildResumenCard() {
  final utilidad = totalPagado - totalGastos;
  final bool esGanancia = utilidad >= 0;

  return AcrylicCard(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen Financiero',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: kColorTextDark)),
          const SizedBox(height: 16),
          _buildResumenRow(
            icon: Icons.arrow_downward,
            color: Colors.teal.shade400,
            label: 'Total Ingresos (Cobrado)',
            amount: totalPagado,
          ),
          const SizedBox(height: 8),
          _buildResumenRow(
            icon: Icons.arrow_upward,
            color: Colors.redAccent.shade200,
            label: 'Total Gastos',
            amount: totalGastos,
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Utilidad Final',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 20, color: kColorTextDark)),
              Text(
                utilidad.aPesos(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: esGanancia ? Colors.teal.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}

  Widget _buildResumenRow(
      {required IconData icon, required Color color, required String label, required double amount}) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          radius: 16,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kColorTextDark)),
        const Spacer(),
        Text(amount.aPesos(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kColorTextDark)),
      ],
    );
  }

  Widget _buildIngresosList() {
    if (ingresos.isEmpty) {
      return const Center(child: Text('No hay ingresos registrados.', style: TextStyle(color: kColorTextDark)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 90, left: 8, right: 8),
      itemCount: ingresos.length,
      itemBuilder: (_, i) {
        final r = ingresos[i];
        return AcrylicCard(
          child: ListTile(
            leading: const Icon(Icons.cake_outlined, color: kColorPrimary),
            title: Text(r['producto']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark)),
            subtitle: Text('Cantidad vendida: ${r['cantidadTotal']}',
                style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
            trailing: Text(
              (r['ingresoTotal'] as double? ?? 0.0).aPesos(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGastosList() {
    if (gastos.isEmpty) {
      return const Center(child: Text('No hay gastos registrados.', style: TextStyle(color: kColorTextDark)));
    }
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 90, left: 8, right: 8),
      itemCount: gastos.length,
      itemBuilder: (_, i) {
        final g = gastos[i];
        return AcrylicCard(
          child: ListTile(
            leading: const Icon(Icons.receipt_long_outlined, color: kColorPrimary),
            title: Text(g.descripcion,
                style: const TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark)),
            subtitle: Text(formatoFecha.format(g.fecha.toLocal()),
                style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  g.monto.aPesos(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: kColorTextDark, size: 20),
                  onPressed: () => agregarOEditarGasto(gasto: g),
                ),
                IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Eliminar gasto'),
                                  content: const Text('¿Deseas eliminar este gasto?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await AppDatabase.eliminarGastoPorId(g.id!);
                                await cargar(); // recarga la lista
                              }
                            },
                          ),
                
              ],
            ),
          ),
        );
      },
    );
  }
}

