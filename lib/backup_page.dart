import 'package:flutter/material.dart';
import 'package:postres_app/util/app_colors.dart';
import 'package:postres_app/database.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:typed_data';
import 'package:postres_app/widgets/acrylic_card.dart';
const backupTaskName = "autoBackupTask";

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  String _lastBackupDate = "Nunca";
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isAutomaticBackupEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBackupSettings();
  }

  Future<void> _loadBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isAutomaticBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;
    });
    _loadLastBackupInfo();
  }

  Future<void> _toggleAutomaticBackup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAutomaticBackupEnabled = value;
    });
    
    await prefs.setBool('auto_backup_enabled', value);

    if (value) {
      await Workmanager().registerPeriodicTask(
        backupTaskName,
        "backupTask",
        frequency: const Duration(hours: 6),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copia automática activada.'), backgroundColor: Colors.green),
        );
       }
    } else {
      await Workmanager().cancelByUniqueName(backupTaskName);
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copia automática desactivada.'), backgroundColor: kColorPrimary),
        );
       }
    }
  }

  Future<void> _loadLastBackupInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final metadata = await FirebaseStorage.instance
          .ref('backups/${user.uid}/backup.zip')
          .getMetadata();
      if (metadata.timeCreated != null) {
        final formattedDate = DateFormat('dd MMM yyyy, hh:mm a', 'es_CO').format(metadata.timeCreated!);
        if(mounted) {
          setState(() {
            _lastBackupDate = formattedDate;
          });
        }
      }
    } catch (e) {
      if(mounted) setState(() => _lastBackupDate = "Nunca");
      print("No se encontró backup previo: $e");
    }
  }
  
  Future<void> _createManualBackup() async {
    if (!mounted) return;
    setState(() => _isBackingUp = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No has iniciado sesión.')));
      setState(() => _isBackingUp = false);
      return;
    }

    try {
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

      await _loadLastBackupInfo();

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ¡Copia de seguridad creada con éxito!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al crear la copia: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreFromBackup() async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: kColorBackground1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Restaurar Datos?', style: TextStyle(color: kColorPrimary)),
        content: const Text('Esto reemplazará todos los datos locales. ¿Estás seguro?', style: TextStyle(color: kColorTextDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kColorPrimary, foregroundColor: Colors.white),
            child: const Text('Sí, Restaurar'),
          )
        ],
      ),
    );

    if (confirmado != true) return;

    if (!mounted) return;
    setState(() => _isRestoring = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isRestoring = false);
      return;
    }

    try {
      final storageRef = FirebaseStorage.instance.ref('backups/${user.uid}/backup.zip');
      final Uint8List? zipBytes = await storageRef.getData();

      if (zipBytes == null) {
        throw Exception("El archivo de la copia de seguridad está vacío o no se pudo descargar.");
      }
      
      final archive = ZipDecoder().decodeBytes(zipBytes);
      
      await AppDatabase.closeDatabase();
      final appDir = await getApplicationDocumentsDirectory();

      for (final file in archive) {
        final filename = file.name;
        final data = file.content as List<int>;
        
        if (filename == 'postres.db') {
          final dbPath = await AppDatabase.getDatabasePath();
          await File(dbPath).writeAsBytes(data);
        } else {
          final restoredFile = File('${appDir.path}/$filename');
          await restoredFile.writeAsBytes(data);
        }
      
      }
      
      await AppDatabase.asegurarTablaClientes();
    
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sync_completed_${user.uid}', true);

      if(mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            backgroundColor: kColorBackground1,
            title: const Text('Restauración Completa', style: TextStyle(color: Colors.green)),
            content: const Text('Datos restaurados. Reinicia la app para ver los cambios.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              )
            ],
          )
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Error: No se encontró una copia de seguridad.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isRestoring = false);
      }
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
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
              ),
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
                        'Copia de Seguridad',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildManualBackupCard(),
                  const SizedBox(height: 24),
                  _buildAutomaticBackupCard(),
                  const SizedBox(height: 24),
                  _buildRestoreCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return AcrylicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, color: kColorPrimary, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Tu información segura',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kColorTextDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Guarda una copia de todos tus datos en tu cuenta de Google. Podrás restaurarla si cambias de teléfono o reinstalas la app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kColorTextDark.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualBackupCard() {
    return AcrylicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Última copia: $_lastBackupDate', textAlign: TextAlign.center, style: const TextStyle(color: kColorTextDark)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isBackingUp ? null : _createManualBackup,
              icon: _isBackingUp 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.backup_outlined),
              label: Text(_isBackingUp ? 'Guardando...' : 'Crear copia de seguridad ahora'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomaticBackupCard() {
    return AcrylicCard(
      child: SwitchListTile(
        title: const Text('Copia de seguridad automática', style: TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark)),
        subtitle: Text('Se guardará una copia cada 6 horas con internet.', style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
        value: _isAutomaticBackupEnabled,
        onChanged: _toggleAutomaticBackup,
        activeThumbColor: kColorPrimary,
        secondary: const Icon(Icons.sync_outlined, color: kColorPrimary),
      ),
    );
  }

  Widget _buildRestoreCard() {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.red.shade100)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Restaurar desde la nube', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            Text('Atención: Esto reemplazará todos los datos locales con la última copia guardada en la nube.', style: TextStyle(color: Colors.red.shade900)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isRestoring ? null : _restoreFromBackup,
              icon: _isRestoring 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) 
                  : const Icon(Icons.cloud_download_outlined),
              label: Text(_isRestoring ? 'Restaurando...' : 'Restaurar datos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

