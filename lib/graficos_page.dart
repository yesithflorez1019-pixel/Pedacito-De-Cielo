// lib/graficos_page.dart
import 'package:flutter/material.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/util/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:postres_app/widgets/acrylic_card.dart';
import 'dart:math';

class GraficosPage extends StatefulWidget {
  const GraficosPage({super.key});

  @override
  State<GraficosPage> createState() => _GraficosPageState();
}

class _GraficosPageState extends State<GraficosPage> {
  List<Map<String, dynamic>> _gananciaProductos = [];
  List<Map<String, dynamic>> _topClientes = [];
  List<Map<String, dynamic>> _ventasPorDia = [];
  List<Map<String, dynamic>> _gananciaTandas = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final gananciaData = await AppDatabase.obtenerGananciaPorProducto();
    final clientesData = await AppDatabase.obtenerTopClientes();
    final ventasDiaData = await AppDatabase.obtenerVentasPorDiaSemana();
    final gananciaTandaData = await AppDatabase.obtenerGananciaPorTanda();
    
    if(mounted) {
      setState(() {
        _gananciaProductos = gananciaData;
        _topClientes = clientesData;
        _ventasPorDia = ventasDiaData;
        _gananciaTandas = gananciaTandaData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Análisis de Negocio',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _cargarDatos,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kColorPrimary))
                  : RefreshIndicator(
                      onRefresh: _cargarDatos,
                      color: kColorPrimary,
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          _buildSectionTitle('Ventas por Día de la Semana'),
                          _buildVentasPorDiaChart(),
                          _buildSectionTitle('Rentabilidad de Últimas Tandas'),
                          _buildGananciaTandasChart(),
                          _buildSectionTitle('Productos Estrella (Top 5 por Ganancia)'),
                          _buildGananciaProductosChart(),
                          _buildSectionTitle('Clientes VIP (Top 5 por Compra)'),
                          _buildTopClientesList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 24.0),
      child: Text(title, style: const TextStyle(color: kColorPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildVentasPorDiaChart() {
    if (_ventasPorDia.isEmpty || _ventasPorDia.every((e) => (e['total_ingresos'] as num) == 0)) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No hay datos de ventas para mostrar.', style: TextStyle(color: kColorTextDark)),
      ));
    }
    
    final dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final barGroups = List.generate(7, (i) {
      final ventaDia = _ventasPorDia.firstWhere((d) => d['dia_semana'] == i, orElse: () => {'total_ingresos': 0.0});
      return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (ventaDia['total_ingresos'] as num).toDouble(),
              color: kColorPrimary,
              width: 20,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _getMaxValue(_ventasPorDia, 'total_ingresos') * 1.1,
                color: Colors.white.withOpacity(0.2),
              ),
            )
          ]
      );
    });

    final maxY = _getMaxValue(_ventasPorDia, 'total_ingresos') * 1.1;

    return SizedBox(
      height: 250,
      child: AcrylicCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(dias[value.toInt()], style: const TextStyle(fontSize: 10, color: kColorTextDark)), 
                    reservedSize: 30
                  )
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      final formatter = NumberFormat.compactCurrency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
                      return Text(formatter.format(value), style: const TextStyle(fontSize: 10, color: kColorTextDark));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.white.withOpacity(0.2), strokeWidth: 1);
                }
              ),
              maxY: maxY,
            )
          ),
        ),
      ),
    );
  }

  Widget _buildGananciaTandasChart() {

     if (_gananciaTandas.isEmpty || _gananciaTandas.every((e) => ((e['utilidad_neta'] as num?) ?? 0) == 0)) {
       return const Center(child: Padding(
         padding: EdgeInsets.all(16.0),
         child: Text('No hay datos de tandas para mostrar.', style: TextStyle(color: kColorTextDark)),
       ));
     }
     
     final maxY = _getMaxValue(_gananciaTandas, 'utilidad_neta', absolute: true) * 1.2;
     final minY = -maxY; 

     return SizedBox(
       height: 250,
       child: AcrylicCard(
         child: Padding(
           padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
           child: BarChart(
             BarChartData(
                barGroups: _gananciaTandas.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tanda = entry.value;
                  final utilidad = (tanda['utilidad_neta'] as num?)?.toDouble() ?? 0.0;
                  return BarChartGroupData(
                    x: index, 
                    barRods: [
                      BarChartRodData(
                        toY: utilidad, 
                        color: utilidad >= 0 ? Colors.teal : Colors.redAccent, 
                        width: 22, 
                        borderRadius: BorderRadius.circular(4),
                      )
                    ]
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, 
                      getTitlesWidget: (value, meta) {
                        String text = _gananciaTandas[value.toInt()]['nombre'];
                        if (text.length > 8) text = '${text.substring(0, 7)}...';
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4.0,
                          child: Text(text, style: const TextStyle(fontSize: 10, color: kColorTextDark)),
                        );
                      }, 
                      reservedSize: 40
                    )
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        final formatter = NumberFormat.compactCurrency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
                        return Text(formatter.format(value), style: const TextStyle(fontSize: 10, color: kColorTextDark));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: value == 0 ? kColorTextDark.withOpacity(0.5) : Colors.white.withOpacity(0.2), strokeWidth: 1);
                  }
                ),
                maxY: maxY,
                minY: minY,
             ),
           ),
         ),
       ),
     );
  }

  Widget _buildGananciaProductosChart() {
    if (_gananciaProductos.isEmpty || _gananciaProductos.every((e) => (e['ganancia_neta'] as num) == 0)) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No hay datos de productos para mostrar.', style: TextStyle(color: kColorTextDark)),
      ));
    }
    
    final formatter = NumberFormat.compactCurrency(locale: 'es_CO', symbol: '\$');
    final List<Color> pieColors = [
      kColorPrimary, Colors.teal.shade400, Colors.orange.shade400, Colors.lightBlue.shade400, Colors.purple.shade400,
    ];

    return SizedBox(
      height: 250, 
      child: AcrylicCard(
        child: Padding(
          padding: const EdgeInsets.all(16), 
          child: PieChart(
            PieChartData(
              sections: _gananciaProductos.asMap().entries.map((entry) {
                final index = entry.key;
                final producto = entry.value;
                final ganancia = (producto['ganancia_neta'] as num).toDouble();
                final String titleText = '${producto['nombre']}\n${formatter.format(ganancia)}';
                
                return PieChartSectionData(
                  color: pieColors[index % pieColors.length],
                  value: ganancia,
                  title: titleText,
                  radius: 80,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 2)]),
                  titlePositionPercentageOffset: 0.55,
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          )
        )
      )
    );
  }

  Widget _buildTopClientesList() {
    if (_topClientes.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No hay datos de clientes aún.', style: TextStyle(color: kColorTextDark)),
      ));
    }
    
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return AcrylicCard(child: Column(
      children: _topClientes.asMap().entries.map((entry) {
        final index = entry.key;
        final cliente = entry.value;
        final medals = ['🥇', '🥈', '🥉', '4.', '5.'];
        return ListTile(
          leading: Text(medals[index], style: const TextStyle(fontSize: 24)),
          title: Text(cliente['cliente'], style: const TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark)),
          trailing: Text(formatter.format(cliente['total_gastado']), style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16)),
        );
      }).toList(),
    ));
  }

  double _getMaxValue(List<Map<String, dynamic>> data, String key, {bool absolute = false}) {
    if (data.isEmpty) return 0;
    double maxVal = 0;
    for (var item in data) {
      final value = (item[key] as num?)?.toDouble() ?? 0.0;
      if (absolute) {
        maxVal = max(maxVal, value.abs());
      } else {
        maxVal = max(maxVal, value);
      }
    }
    return maxVal == 0 ? 1 : maxVal;
  }
}

