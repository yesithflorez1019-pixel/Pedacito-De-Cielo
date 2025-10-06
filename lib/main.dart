import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:postres_app/util/app_colors.dart';
import 'package:postres_app/login_page.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/backup_page.dart';
import 'dart:ui';
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
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await AppDatabase.closeDatabase();
      final dbPath = await AppDatabase.getDatabasePath();
      final dbFile = File(dbPath);
      final facturas = await AppDatabase.obtenerTodasLasFacturas();
      
      final archive = Archive();
      if (await dbFile.exists()) {
        final bytes = await dbFile.readAsBytes();
        archive.addFile(ArchiveFile(p.basename(dbFile.path), bytes.length, bytes));
      }

      for (var factura in facturas) {
          final facturaFile = File(factura['path']);
          if (await facturaFile.exists()) {
              final bytes = await facturaFile.readAsBytes();
              archive.addFile(ArchiveFile(p.basename(facturaFile.path), bytes.length, bytes));
          }
      }

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      
      final storageRef = FirebaseStorage.instance.ref('backups/${user.uid}/backup.zip');
      await storageRef.putData(Uint8List.fromList(zipData));

      debugPrint("✅ Copia de seguridad automática (ZIP) completada.");
      return true;
    } catch (e) {
      debugPrint("❌ Error en copia de seguridad automática (ZIP): $e");
      return false;
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es_CO', null);

  await SettingsManager.cargarPreferencias(); 

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: kColorPrimary,
          primary: kColorPrimary,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
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

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _ingresosHoy = 0.0;
  int _pedidosPendientes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosDashboard();
  }

  Future<void> _cargarDatosDashboard() async {
    if(!mounted) return;
    setState(() => _isLoading = true);
    
    final ingresos = await AppDatabase.obtenerIngresosDeHoy();
    final pendientes = await AppDatabase.obtenerPedidosPendientes();
    
    if (mounted) {
      setState(() {
        _ingresosHoy = ingresos;
        _pedidosPendientes = pendientes;
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final options = <_MenuOption>[
      _MenuOption(icon: Icons.cake_outlined, label: 'Productos', color: kColorPrimary, onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const VerProductosPage()))),
      _MenuOption(icon: Icons.list_alt_outlined, label: 'Tandas y Pedidos', color: const Color(0xFFD4A3C4), onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ControlTandasPage()))),
      _MenuOption(icon: Icons.payment_outlined, label: 'Informe de Deudas', color: const Color(0xFFFFA07A), onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const InformeNoPagadosPage()))),
      _MenuOption(icon: Icons.inventory_2_outlined, label: 'Inventario', color: const Color(0xFFA8D1E7), onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const InventarioPage()))),
      _MenuOption(icon: Icons.attach_money, label: 'Finanzas Personales', color: const Color(0xFFFFBFC5), onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const HomeFinanzasPage()))),
      _MenuOption(icon: Icons.bar_chart, label: 'Panel de Reportes', color: const Color(0xFFB0C4DE), onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ReportesPage()))),
      _MenuOption(icon: Icons.analytics_outlined, label: 'Análisis y Gráficos', color: const Color(0xFF9370DB), onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const GraficosPage()))),
      _MenuOption(icon: Icons.cloud_upload_outlined, label: 'Copia de Seguridad', color: const Color(0xFF6E7B8B), onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const BackupPage()))),
      _MenuOption(icon: Icons.settings_outlined, label: 'Ajustes', color: const Color(0xFF808080), onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AjustesPage()))),
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _cargarDatosDashboard,
        color: kColorPrimary,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kColorBackground1, kColorBackground2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                height: 250,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kColorHeader1, kColorHeader2],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(
                                '¡Hola, ${widget.user.displayName ?? ''}!',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                               const Text(
                                'Recuerda siempre sonreir, a tu novio le encanta verde sonreir.💙',
                                style: TextStyle(fontSize: 16, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _isLoading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 32.0),
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    )
                  : Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                    child: Row(
                      children: [
                        Expanded(child: _buildKpiCard('Ingresos de Hoy', NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(_ingresosHoy), Icons.monetization_on_outlined, Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildKpiCard('Pedidos Pendientes', _pedidosPendientes.toString(), Icons.local_shipping_outlined, Colors.orange)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final opt = options[index];
                        return _buildMenuButton(opt);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

Widget _buildMenuButton(_MenuOption opt) {
  return AcrylicCard(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => opt.onTap(context),
      child: Center( 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: opt.color.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(opt.icon, size: 40, color: opt.color),
            ),
            const SizedBox(height: 12),
            Text(
              opt.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kColorTextDark,
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _MenuOption {
  final IconData icon;
  final String label;
  final Color color;
  final void Function(BuildContext) onTap;
  _MenuOption({required this.icon, required this.label, required this.onTap, required this.color});
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

