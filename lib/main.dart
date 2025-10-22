// lib/main.dart (Versión Totalmente Rediseñada)

// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:postres_app/util/app_colors.dart';
import 'package:postres_app/login_page.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/backup_page.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'dart:typed_data';
import 'package:postres_app/widgets/acrylic_card.dart';
import 'package:postres_app/util/settings_manager.dart';
import 'package:postres_app/ver_productos.dart';
import 'package:postres_app/control_tandas.dart';
import 'package:postres_app/informe_no_pagados.dart';
import 'package:postres_app/inventario_page.dart';
import 'package:postres_app/finanzas/home_finanzas.dart';
import 'package:postres_app/reportes_page.dart';
import 'package:postres_app/graficos_page.dart';
import 'package:postres_app/ajustes_page.dart';
import 'package:postres_app/clientes_page.dart';
import 'en_reparto_page.dart';
import 'formato.dart';

// La lógica de Workmanager se queda igual, no necesita cambios.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // ... tu código de backup automático ...
    return true;
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es_CO', null);
  await SettingsManager.cargarPreferencias();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  runApp(const PedacitoDeCielo());
}

class PedacitoDeCielo extends StatelessWidget {
  const PedacitoDeCielo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pedacito de Cielo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kColorPrimary, primary: kColorPrimary, surface: Colors.white, brightness: Brightness.light),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: kColorBackground1, body: Center(child: CircularProgressIndicator(color: kColorPrimary)));
        }
        if (snapshot.hasData) {
          return HomePage(user: snapshot.data!);
        }
        return const LoginPage();
      },
    );
  }
}

// --- PÁGINA PRINCIPAL REDISEÑADA ---
class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Lista de las páginas que se mostrarán en cada pestaña
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _DashboardScreen(user: widget.user), // 0: Inicio
      const ControlTandasPage(),            // 1: Pedidos
      const EnRepartoPage(),                // 2: Reparto
      const InformeNoPagadosPage(),         // 3: Deudas
      const _MoreScreen(),                  // 4: Más
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // IndexedStack mantiene el estado de cada página
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Reparto'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Deudas'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Más'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kColorPrimary,
        unselectedItemColor: Colors.grey.shade600,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Para que todos los items se vean siempre
        backgroundColor: Colors.white,
      ),
    );
  }
}


// --- NUEVO WIDGET: PANTALLA DE INICIO (DASHBOARD) ---
class _DashboardScreen extends StatefulWidget {
  final User user;
  const _DashboardScreen({required this.user});

@override
  State<_DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<_DashboardScreen> {
  // Nuevas variables para los datos del dashboard
  double _ingresosHoy = 0.0;
  int _pedidosPendientes = 0;
  double _ingresosSemana = 0.0;
  Map<String, dynamic>? _productoEstrella;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosDashboard();
  }

  // Función de carga actualizada para obtener los nuevos datos
  Future<void> _cargarDatosDashboard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    // Llamamos a todas las funciones de la base de datos en paralelo
    final responses = await Future.wait([
      AppDatabase.obtenerIngresosDeHoy(),
      AppDatabase.obtenerPedidosPendientes(),
      AppDatabase.obtenerIngresosSemana(),
      AppDatabase.obtenerProductoEstrellaMes(),
    ]);
    
    if (mounted) {
      setState(() {
        _ingresosHoy = responses[0] as double;
        _pedidosPendientes = responses[1] as int;
        _ingresosSemana = responses[2] as double;
        _productoEstrella = responses[3] as Map<String, dynamic>?;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _cargarDatosDashboard,
        color: kColorPrimary,
        child: Stack(
          children: [
            Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [kColorBackground1, kColorBackground2], begin: Alignment.topLeft, end: Alignment.bottomRight))),
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(height: 250, decoration: const BoxDecoration(gradient: LinearGradient(colors: [kColorHeader1, kColorHeader2], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
            ),
            SafeArea(
              child: ListView( // Usamos ListView para que todo quepa sin importar el tamaño de la pantalla
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- SECCIÓN DE BIENVENIDA ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¡Hola, ${widget.user.displayName ?? ''}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text('Recuerda siempre sonreir, a tu novio le encanta verte sonreir.💙', style: TextStyle(fontSize: 16, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- KPIS PRINCIPALES ---
                  _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Row(
                        children: [
                          Expanded(child: _buildKpiCard('Ingresos de Hoy', _ingresosHoy.aPesos(), Icons.monetization_on_outlined, Colors.green)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildKpiCard('Pedidos Pendientes', _pedidosPendientes.toString(), Icons.local_shipping_outlined, Colors.orange)),
                        ],
                      ),
                  const SizedBox(height: 20),

                  // --- ✅ NUEVO: RESUMEN SEMANAL ---
                  if (!_isLoading) _buildResumenSemanalCard(),

                  // --- ✅ NUEVO: PRODUCTO ESTRELLA ---
                  if (!_isLoading && _productoEstrella != null) _buildProductoEstrellaCard(),

                  // --- ✅ NUEVO: ATAJOS RÁPIDOS ---
                  const SizedBox(height: 20),
                  _buildAtajosRapidos(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE AYUDA (NUEVOS Y MODIFICADOS) ---

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return AcrylicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kColorTextDark)),
            Text(title, style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenSemanalCard() {
    return AcrylicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.calendar_view_week_outlined, color: Colors.blue.shade700, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ingresos (últimos 7 días)', style: TextStyle(color: kColorTextDark.withOpacity(0.8))),
                  Text(_ingresosSemana.aPesos(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kColorTextDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoEstrellaCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: AcrylicCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.star_border_purple500_outlined, color: Colors.amber, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Producto Estrella del Mes', style: TextStyle(color: kColorTextDark.withOpacity(0.8))),
                    Text(_productoEstrella!['nombre'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kColorTextDark)),
                  ],
                ),
              ),
              Text('${_productoEstrella!['cantidad']}\nUNDS', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kColorPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtajosRapidos() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ControlTandasPage())),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Nuevo Pedido'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: kColorPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientesPage())),
            icon: const Icon(Icons.people_alt_outlined),
            label: const Text('Ver Clientes'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.white.withOpacity(0.8),
              foregroundColor: kColorPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
      ],
    );
  }
}



// --- NUEVO WIDGET: PANTALLA "MÁS" CON EL RESTO DE OPCIONES ---
class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    final options = <_MenuOption>[
      _MenuOption(icon: Icons.cake_outlined, label: 'Productos', page: const VerProductosPage()),
      _MenuOption(icon: Icons.people_outline, label: 'Clientes', page: const ClientesPage()),
      _MenuOption(icon: Icons.inventory_2_outlined, label: 'Inventario', page: const InventarioPage()),
      _MenuOption(icon: Icons.attach_money, label: 'Finanzas Personales', page: const HomeFinanzasPage()),
      _MenuOption(icon: Icons.bar_chart, label: 'Panel de Reportes', page: const ReportesPage()),
      _MenuOption(icon: Icons.analytics_outlined, label: 'Análisis y Gráficos', page: const GraficosPage()),
      _MenuOption(icon: Icons.cloud_upload_outlined, label: 'Copia de Seguridad', page: const BackupPage()),
      _MenuOption(icon: Icons.settings_outlined, label: 'Ajustes', page: const AjustesPage()),
      _MenuOption(icon: Icons.logout, label: 'Cerrar Sesión', onTap: () => FirebaseAuth.instance.signOut()),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [kColorBackground1, kColorBackground2], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(
          children: [
            _buildMoreHeader(context),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final opt = options[index];
                  return AcrylicCard(
                    child: ListTile(
                      leading: Icon(opt.icon, color: kColorPrimary),
                      title: Text(opt.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        if (opt.page != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => opt.page!));
                        } else if (opt.onTap != null) {
                          opt.onTap!();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kColorHeader1, kColorHeader2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
      child: const Center(
        child: Text("Más Opciones", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }
}


// Clases de ayuda
class _MenuOption {
  final IconData icon;
  final String label;
  final Widget? page;
  final VoidCallback? onTap;
  _MenuOption({required this.icon, required this.label, this.page, this.onTap});
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    var firstControlPoint = Offset(size.width * 0.25, size.height);
    var firstEndPoint = Offset(size.width * 0.5, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    var secondControlPoint = Offset(size.width * 0.75, size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}