// lib/database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'producto.dart';
import 'pedido.dart';
import 'detalle_pedido.dart';
import 'gasto.dart';
import 'tanda.dart';
import 'insumo.dart';
import 'finanzas/cuenta.dart';
import 'finanzas/transaccion.dart';



class AppDatabase {

  static Database? _database;

  static Future<Database> _getDatabase() async {

    if (_database != null && _database!.isOpen) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'postres.db');


    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _crearTablas(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _crearTablas(db);
      },
    );
    return _database!;
  }

  static Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
  static Future<void> _crearTablas(Database db) async {

    await db.execute('''
  CREATE TABLE IF NOT EXISTS cuentas(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    balance REAL NOT NULL
  )
''');

await db.execute('''
  CREATE TABLE IF NOT EXISTS transacciones(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    monto REAL NOT NULL,
    tipo TEXT NOT NULL,
    categoria TEXT NOT NULL,
    descripcion TEXT,
    fecha TEXT NOT NULL,
    cuentaId INTEGER,
    FOREIGN KEY (cuentaId) REFERENCES cuentas(id) ON DELETE CASCADE
  )
''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS facturas(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      productoId INTEGER NOT NULL,
      nombre TEXT NOT NULL,
      path TEXT NOT NULL
    )
  ''');



    await db.execute('''       
        CREATE TABLE producto_insumo (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          producto_id INTEGER NOT NULL,
          insumo_id INTEGER NOT NULL,
          cantidad REAL NOT NULL,
          FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
          FOREIGN KEY (insumo_id) REFERENCES insumos(id) ON DELETE CASCADE
        )
      ''');

    
    await db.execute('''
        CREATE TABLE insumos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          unidad TEXT,
          precio REAL
        )
        ''');




await db.execute('''
  CREATE TABLE IF NOT EXISTS productos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT,
    precio REAL,
    rendimiento_tanda INTEGER NOT NULL DEFAULT 1
  );
''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tandas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pedidos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tandaId INTEGER,
        cliente TEXT,
        direccion TEXT,
        entregado INTEGER,
        pagado INTEGER,
        pagoParcial REAL,
        fecha TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS detalles_pedido (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pedidoId INTEGER,
        productoId INTEGER,
        cantidad INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tandaId INTEGER,
        descripcion TEXT,
        monto REAL,
        fecha TEXT
      );
    ''');

   await db.execute('''
  CREATE TABLE IF NOT EXISTS productos_tanda (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tandaId INTEGER,
    productoId INTEGER,
    stock INTEGER NOT NULL DEFAULT 0,
    costo_produccion_unitario REAL NOT NULL DEFAULT 0.0
  );
''');
  }

 // ================== PRODUCTOS ==================
static Future<int> insertarProducto(Producto producto) async {
  final db = await _getDatabase();
  return await db.insert('productos', producto.toMap());
}

static Future<void> actualizarProducto(Producto producto) async {
  final db = await _getDatabase();
  await db.update(
    'productos',
    producto.toMap(),
    where: 'id = ?',
    whereArgs: [producto.id!],
  );
}
static Future<void> eliminarProductoPorId(int id) async {
  final db = await _getDatabase();
  await db.delete('productos', where: 'id = ?', whereArgs: [id]);
}

// ================== OBTENER PRODUCTOS ==================
static Future<List<Producto>> obtenerProductos({int? tandaId}) async {
  final db = await _getDatabase();
  List<Map<String, dynamic>> rows;

  if (tandaId != null) {
    rows = await db.rawQuery('''
      SELECT p.*
      FROM productos p
      INNER JOIN productos_tanda pt ON pt.productoId = p.id
      WHERE pt.tandaId = ?
      ORDER BY p.nombre ASC
    ''', [tandaId]);
  } else {
    rows = await db.query('productos', orderBy: 'nombre ASC');
  }

  return rows.map((m) => Producto.fromMap(m)).toList();
}


  // ================== PEDIDOS ==================
  static Future<int> insertarPedidoConDetalles(Pedido pedido) async {
    final db = await _getDatabase();
    final pedidoId = await db.insert('pedidos', {
      'tandaId': pedido.tandaId,
      'cliente': pedido.cliente,
      'direccion': pedido.direccion,
      'entregado': pedido.entregado ? 1 : 0,
      'pagado': pedido.pagado ? 1 : 0,
      'pagoParcial': pedido.pagoParcial,
      'fecha': pedido.fecha.toIso8601String(),
    });

    for (final detalle in pedido.detalles) {
      await db.insert('detalles_pedido', {
        'pedidoId': pedidoId,
        'productoId': detalle.producto.id!,
        'cantidad': detalle.cantidad,
      });

      final stockActual =
          await obtenerStockProducto(pedido.tandaId, detalle.producto.id!);
      final nuevoStock = stockActual - detalle.cantidad;
      await actualizarStockProducto(
          pedido.tandaId, detalle.producto.id!, nuevoStock);
    }

    return pedidoId;
  }

static Future<void> actualizarPedidoConDetalles(Pedido pedido) async {
  final db = await _getDatabase();

  await db.transaction((txn) async {
    final oldDetailsMaps = await txn.query('detalles_pedido', where: 'pedidoId = ?', whereArgs: [pedido.id!]);

    for (var oldDetailMap in oldDetailsMaps) {
      final productoId = oldDetailMap['productoId'] as int;
      final cantidad = oldDetailMap['cantidad'] as int;

      final currentStockMap = await txn.query(
        'productos_tanda',
        columns: ['stock'],
        where: 'tandaId = ? AND productoId = ?',
        whereArgs: [pedido.tandaId, productoId],
      );
      final currentStock = currentStockMap.isNotEmpty ? currentStockMap.first['stock'] as int : 0;
      final newStock = currentStock + cantidad;

      await txn.update(
        'productos_tanda',
        {'stock': newStock},
        where: 'tandaId = ? AND productoId = ?',
        whereArgs: [pedido.tandaId, productoId],
      );
    }

    await txn.delete('detalles_pedido', where: 'pedidoId = ?', whereArgs: [pedido.id!]);

    for (final newDetail in pedido.detalles) {
      final productoId = newDetail.producto.id!;
      final cantidad = newDetail.cantidad;

      final currentStockMap = await txn.query(
        'productos_tanda',
        columns: ['stock'],
        where: 'tandaId = ? AND productoId = ?',
        whereArgs: [pedido.tandaId, productoId],
      );
      final currentStock = currentStockMap.isNotEmpty ? currentStockMap.first['stock'] as int : 0;
      final newStock = currentStock - cantidad;

      await txn.update(
        'productos_tanda',
        {'stock': newStock},
        where: 'tandaId = ? AND productoId = ?',
        whereArgs: [pedido.tandaId, productoId],
      );
      
      await txn.insert('detalles_pedido', {
        'pedidoId': pedido.id!,
        'productoId': productoId,
        'cantidad': cantidad,
      });
    }

    await txn.update(
      'pedidos',
      {
        'tandaId': pedido.tandaId,
        'cliente': pedido.cliente,
        'direccion': pedido.direccion,
        'entregado': pedido.entregado ? 1 : 0,
        'pagado': pedido.pagado ? 1 : 0,
        'pagoParcial': pedido.pagoParcial,
      },
      where: 'id = ?',
      whereArgs: [pedido.id!],
    );
  });
}

static Future<List<Pedido>> obtenerPedidos({int? tandaId}) async {
  final db = await _getDatabase();

 
  final rows = await db.rawQuery('''
    SELECT
      p.id,
      p.tandaId,
      p.cliente,
      p.direccion,
      p.entregado,
      p.pagado,
      p.pagoParcial,
      p.fecha,
      t.nombre as nombreTanda 
    FROM pedidos p
    LEFT JOIN tandas t ON p.tandaId = t.id
    ${tandaId != null ? 'WHERE p.tandaId = ?' : ''}
    ORDER BY p.id DESC
  ''', tandaId != null ? [tandaId] : null);

  List<Pedido> pedidos = [];
  for (final pedidoMap in rows) {
    final pedidoId = pedidoMap['id'] as int;
    final detallesMap =
        await db.query('detalles_pedido', where: 'pedidoId = ?', whereArgs: [pedidoId]);

    final detalles = <DetallePedido>[];
    for (final d in detallesMap) {
      final prodResult = await db.query('productos', where: 'id = ?', whereArgs: [d['productoId']]);
      
      if (prodResult.isNotEmpty) {
        final prodMap = prodResult.first;
        detalles.add(DetallePedido(
          producto: Producto.fromMap(prodMap),
          cantidad: (d['cantidad'] as num).toInt(),
        ));
      } else {
      
        print('Aviso: Producto con id ${d['productoId']} no encontrado para el pedido $pedidoId.');
      }
    }

    pedidos.add(Pedido(
      id: pedidoId,
      tandaId: (pedidoMap['tandaId'] as int?) ?? 0,
      cliente: pedidoMap['cliente'] as String,
      direccion: pedidoMap['direccion'] as String,
      entregado: ((pedidoMap['entregado'] ?? 0) as int) == 1,
      pagado: ((pedidoMap['pagado'] ?? 0) as int) == 1,
      pagoParcial: (pedidoMap['pagoParcial'] as num?)?.toDouble() ?? 0.0,
      detalles: detalles,
      fecha: DateTime.parse(pedidoMap['fecha'] as String),
     
      nombreTanda: pedidoMap['nombreTanda'] as String?,
    ));
  }
  return pedidos;
}


  static Future<void> insertarPedido(int tandaId, List<DetallePedido> detalles) async {
  final db = await _getDatabase();

  final pedidoId = await db.insert(
    'pedidos',
    {
      'tanda_id': tandaId,
      'fecha': DateTime.now().toIso8601String(),
    },
  );

  for (var detalle in detalles) {
    await db.insert(
      'detalles_pedido',
      {
        'pedido_id': pedidoId,
        'producto_id': detalle.producto.id,
        'cantidad': detalle.cantidad,
      },
    );
  }
}

  static Future<void> eliminarPedidoPorId(int id) async {
    final db = await _getDatabase();

    final detalles = await db.query('detalles_pedido', where: 'pedidoId = ?', whereArgs: [id]);
    if (detalles.isNotEmpty) {
      final pedido = await db.query('pedidos', where: 'id = ?', whereArgs: [id]);
      final tandaId = pedido.first['tandaId'] as int;
      for (final d in detalles) {
        final productoId = d['productoId'] as int;
        final cantidad = d['cantidad'] as int;
        final stockActual = await obtenerStockProducto(tandaId, productoId);
        await actualizarStockProducto(tandaId, productoId, stockActual + cantidad);
      }
    }

    await db.delete('detalles_pedido', where: 'pedidoId = ?', whereArgs: [id]);
    await db.delete('pedidos', where: 'id = ?', whereArgs: [id]);
  }

  // ================== GASTOS ==================
  static Future<int> insertarGasto(Gasto gasto) async {
    final db = await _getDatabase();
    return await db.insert('gastos', {
      'tandaId': gasto.tandaId!,
      'descripcion': gasto.descripcion,
      'monto': gasto.monto,
      'fecha': gasto.fecha.toIso8601String(),
    });
  }
  
  
  static Future<void> eliminarGastoPorId(int id) async {
    final db = await _getDatabase();
    await db.delete('gastos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> actualizarGasto(Gasto gasto) async {
    final db = await _getDatabase();
    await db.update(
      'gastos',
      gasto.toMap(),
      where: 'id = ?',
      whereArgs: [gasto.id!],
    );
  }

  static Future<List<Gasto>> obtenerGastos({int? tandaId}) async {
    final db = await _getDatabase();
    final rows = await db.query(
      'gastos',
      where: tandaId != null ? 'tandaId = ?' : null,
      whereArgs: tandaId != null ? [tandaId] : null,
      orderBy: 'fecha DESC',
    );
    return rows.map((m) => Gasto.fromMap(m)).toList();
  }

  // ================== TANDAS ==================
  static Future<int> insertarTanda(Tanda tanda) async {
    final db = await _getDatabase();
    return await db.insert('tandas', {'nombre': tanda.nombre});
  }

static Future<void> addProductosToTanda(int tandaId, Map<int, int> productosConStock) async {
  final db = await _getDatabase();
  await db.transaction((txn) async {
    for (var entry in productosConStock.entries) {
      final productoId = entry.key;
      final stock = entry.value;
      
      final productoMap = (await txn.query('productos', where: 'id = ?', whereArgs: [productoId])).first;
      final producto = Producto.fromMap(productoMap);
      
      final costoCalculado = await _calcularCostoUnitario(txn, producto);
      
      await txn.insert(
        'productos_tanda',
        {
          'tandaId': tandaId,
          'productoId': productoId,
          'stock': stock,
          'costo_produccion_unitario': costoCalculado,
        },
      );
    }
  });
}


static Future<double> _calcularCostoUnitario(dynamic txn, Producto producto) async {
  final insumos = await txn.rawQuery('''
    SELECT i.precio, pi.cantidad
    FROM producto_insumo pi
    JOIN insumos i ON i.id = pi.insumo_id
    WHERE pi.producto_id = ?
  ''', [producto.id]);

  double costoTotalTanda = 0;
  for (var insumo in insumos) {
    final precio = (insumo['precio'] as num?)?.toDouble() ?? 0.0;
    final cantidad = (insumo['cantidad'] as num?)?.toDouble() ?? 0.0;
    costoTotalTanda += precio * cantidad;
  }

  final rendimiento = producto.rendimientoTanda > 0 ? producto.rendimientoTanda : 1;
  return costoTotalTanda / rendimiento;
}

  static Future<void> actualizarTanda(Tanda tanda) async {
    final db = await _getDatabase();
    await db.update(
      'tandas',
      {'nombre': tanda.nombre},
      where: 'id = ?',
      whereArgs: [tanda.id!],
    );
  }

  static Future<void> eliminarTanda(int id) async {
    final db = await _getDatabase();
    final pedidos = await db.query('pedidos', where: 'tandaId = ?', whereArgs: [id]);
    for (final p in pedidos) {
      await eliminarPedidoPorId(p['id'] as int);
    }
    await db.delete('gastos', where: 'tandaId = ?', whereArgs: [id]);
    await db.delete('tandas', where: 'id = ?', whereArgs: [id]);
    await db.delete('productos_tanda', where: 'tandaId = ?', whereArgs: [id]);
  }

  // ================== PRODUCTOS_TANDA ==================
  static Future<int> asignarProductoATanda(int tandaId, int productoId, {int stock = 0}) async {
    final db = await _getDatabase();
    return await db.insert(
      'productos_tanda',
      {
        'tandaId': tandaId,
        'productoId': productoId,
        'stock': stock,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> limpiarProductosDeTanda(int tandaId) async {
    final db = await _getDatabase();
    await db.delete('productos_tanda', where: 'tandaId = ?', whereArgs: [tandaId]);
  }

  static Future<List<Map<String, dynamic>>> obtenerProductosDeTanda(int tandaId) async {
    final db = await _getDatabase();
    final rows = await db.rawQuery('''
      SELECT pt.id, pt.stock, p.id as productoId, p.nombre, p.precio
      FROM productos_tanda pt
      INNER JOIN productos p ON p.id = pt.productoId
      WHERE pt.tandaId = ?
    ''', [tandaId]);
    return rows;
  }

  static Future<int> obtenerStockProducto(int tandaId, int productoId) async {
    final db = await _getDatabase();
    final result = await db.query(
      'productos_tanda',
      columns: ['stock'],
      where: 'tandaId = ? AND productoId = ?',
      whereArgs: [tandaId, productoId],
    );

    if (result.isNotEmpty) {
      return result.first['stock'] as int;
    }
    return 0;
  }

  static Future<void> actualizarStockProducto(int tandaId, int productoId, int nuevoStock) async {
    final db = await _getDatabase();
    await db.update(
      'productos_tanda',
      {'stock': nuevoStock},
      where: 'tandaId = ? AND productoId = ?',
      whereArgs: [tandaId, productoId],
    );
  }

  // ================== INFORMES ==================
  static Future<List<Map<String, dynamic>>> obtenerIngresosAgrupadosPorTanda(int tandaId) async {
    final db = await _getDatabase();
    final result = await db.rawQuery('''
      SELECT p.id AS pedidoId, SUM(dp.cantidad * pr.precio) AS ingreso
      FROM pedidos p
      INNER JOIN detalles_pedido dp ON p.id = dp.pedidoId
      INNER JOIN productos pr ON dp.productoId = pr.id
      WHERE p.tandaId = ?
      GROUP BY p.id
    ''', [tandaId]);
    return result;
  }
  static Future<List<Map<String, dynamic>>> obtenerIngresosPorProducto(int tandaId) async {
  final db = await _getDatabase();

  final result = await db.rawQuery('''
    SELECT pr.id AS productoId, pr.nombre AS producto, pr.precio,
           SUM(dp.cantidad) AS cantidadTotal,
           SUM(dp.cantidad * pr.precio) AS ingresoTotal
    FROM pedidos p
    INNER JOIN detalles_pedido dp ON p.id = dp.pedidoId
    INNER JOIN productos pr ON dp.productoId = pr.id
    WHERE p.tandaId = ?
    GROUP BY pr.id
  ''', [tandaId]);

  return result;
}

  static Future<double> obtenerTotalPagosParcialesPorTanda(int tandaId) async {
  final db = await _getDatabase();
  final result = await db.rawQuery('''
    SELECT SUM(pagoParcial) AS totalPagos
    FROM pedidos
    WHERE tandaId = ?
  ''', [tandaId]);

  if (result.isNotEmpty && result.first['totalPagos'] != null) {
    return (result.first['totalPagos'] as num).toDouble();
  }
  return 0.0;
}

  static Future<double> obtenerTotalIngresosPorTanda(int tandaId) async {
    final db = await _getDatabase();
    final result = await db.rawQuery('''
      SELECT SUM(dp.cantidad * pr.precio) AS totalIngresos
      FROM pedidos p
      INNER JOIN detalles_pedido dp ON p.id = dp.pedidoId
      INNER JOIN productos pr ON dp.productoId = pr.id
      WHERE p.tandaId = ?
    ''', [tandaId]);

    if (result.isNotEmpty && result.first['totalIngresos'] != null) {
      return (result.first['totalIngresos'] as num).toDouble();
    }
    return 0.0;
  }

  static Future<List<Gasto>> obtenerGastosPorTanda(int tandaId) async {
    final db = await _getDatabase();
    final rows = await db.query(
      'gastos',
      where: 'tandaId = ?',
      whereArgs: [tandaId],
      orderBy: 'fecha DESC',
    );
    return rows.map((m) => Gasto.fromMap(m)).toList();
  }

  static Future<double> obtenerTotalGastosPorTanda(int tandaId) async {
    final db = await _getDatabase();
    final result = await db.rawQuery('''
      SELECT SUM(monto) AS totalGastos
      FROM gastos
      WHERE tandaId = ?
    ''', [tandaId]);

    if (result.isNotEmpty && result.first['totalGastos'] != null) {
      return (result.first['totalGastos'] as num).toDouble();
    }
    return 0.0;
  }

  // --- NUEVAS FUNCIONES PARA REPORTES GENERALES ---

  static Future<double> obtenerTotalPagosParcialesGeneral() async {
    final db = await _getDatabase();
    final result = await db.rawQuery('SELECT SUM(pagoParcial) AS total FROM pedidos');
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  static Future<double> obtenerTotalGastosGeneral() async {
    final db = await _getDatabase();
    final result = await db.rawQuery('SELECT SUM(monto) AS total FROM gastos');
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  static Future<List<Map<String, dynamic>>> obtenerProductosMasVendidosGeneral() async {
    final db = await _getDatabase();
    return await db.rawQuery('''
      SELECT pr.nombre AS producto, SUM(dp.cantidad) AS cantidadTotal
      FROM detalles_pedido dp
      JOIN productos pr ON dp.productoId = pr.id
      GROUP BY pr.id
      ORDER BY cantidadTotal DESC
    ''');
  }


  // ================== CLIENTES DEUDORES ==================
  static Future<List<String>> obtenerClientesDeudores() async {
    final db = await _getDatabase();
    final result = await db.rawQuery('''
      SELECT DISTINCT cliente
      FROM pedidos
      WHERE pagado = 0
    ''');
    return result.map((row) => row['cliente'] as String).toList();
  }

  static Future<List<Pedido>> obtenerPedidosNoPagadosPorCliente(String cliente) async {
  final db = await _getDatabase();
  final pedidosMap = await db.query(
    'pedidos',
    where: 'cliente = ? AND pagado = 0',
    whereArgs: [cliente],
    orderBy: 'id DESC',
  );

  List<Pedido> pedidos = [];
  for (final pedidoMap in pedidosMap) {
    final pedidoId = pedidoMap['id'] as int;
    final detallesMap = await db.query('detalles_pedido', where: 'pedidoId = ?', whereArgs: [pedidoId]);

    final detalles = <DetallePedido>[];
    for (final d in detallesMap) {
      final prodMap = (await db.query('productos', where: 'id = ?', whereArgs: [d['productoId']])).first;
      detalles.add(DetallePedido(
        producto: Producto.fromMap(prodMap),
        cantidad: (d['cantidad'] as num).toInt(),
      ));
    }

    String nombreTanda = '';
    if (pedidoMap['tandaId'] != null) {
      final tandaMap = (await db.query(
        'tandas',
        where: 'id = ?',
        whereArgs: [pedidoMap['tandaId'] as int],
      )).first;
      nombreTanda = tandaMap['nombre'] as String;
    }

    pedidos.add(Pedido(
      id: pedidoId,
      tandaId: (pedidoMap['tandaId'] as int?) ?? 0,
      cliente: pedidoMap['cliente'] as String,
      direccion: pedidoMap['direccion'] as String,
      entregado: ((pedidoMap['entregado'] ?? 0) as int) == 1,
      pagado: ((pedidoMap['pagado'] ?? 0) as int) == 1,
      pagoParcial: (pedidoMap['pagoParcial'] as num?)?.toDouble() ?? 0.0,
      detalles: detalles,
      nombreTanda: nombreTanda,
      fecha: DateTime.parse(pedidoMap['fecha'] as String),
    ));
  }

  return pedidos;
}




static Future<void> liquidarCliente(String cliente) async {
  final db = await _getDatabase();
  

  final nombreNormalizado = cliente.toLowerCase().trim();


  final pedidos = await db.query(
    'pedidos',
    where: 'TRIM(LOWER(cliente)) = ? AND pagado = 0',
    whereArgs: [nombreNormalizado],
  );

  if (pedidos.isEmpty) {

    print("No se encontraron pedidos para liquidar para el cliente: $cliente (esto es normal si ya no debe nada).");
    return;
  }


  for (final pedido in pedidos) {
    final pedidoId = pedido['id'] as int;


    final detalles = await db.query('detalles_pedido', where: 'pedidoId = ?', whereArgs: [pedidoId]);
    double totalDelPedido = 0.0;
    for (final d in detalles) {
      final productoId = d['productoId'] as int;
      final cantidad = d['cantidad'] as int;
      final productoData = await db.query('productos', where: 'id = ?', whereArgs: [productoId]);
      if (productoData.isNotEmpty) {
        final precio = (productoData.first['precio'] as num).toDouble();
        totalDelPedido += precio * cantidad;
      }
    }


    await db.update(
      'pedidos',
      {
        'pagado': 1,
        'pagoParcial': totalDelPedido,
      },
      where: 'id = ?',
      whereArgs: [pedidoId],
    );
  }


  print("Pedidos liquidados para '$cliente': ${pedidos.length}");
}



  static Future<List<Map<String, dynamic>>> obtenerTandasConConteo() async {
    final db = await _getDatabase();
    final result = await db.rawQuery('''
      SELECT t.id, t.nombre,
             (SELECT COUNT(*) FROM pedidos p WHERE p.tandaId = t.id) AS pedidosCount
      FROM tandas t
      ORDER BY t.id DESC
    ''');
    return result;
  }

// ================== INSUMOS ==================
static Future<int> insertarInsumo(Insumo insumo) async {
  final db = await _getDatabase();
  return await db.insert('insumos', insumo.toMap());
}

static Future<void> eliminarInsumo(int id) async {
  final db = await _getDatabase();

  await db.delete('insumos', where: 'id = ?', whereArgs: [id]);
}

static Future<void> actualizarInsumo(Insumo insumo) async {
  final db = await _getDatabase();
  await db.update(
    'insumos',
    insumo.toMap(),
    where: 'id = ?',
    whereArgs: [insumo.id],
  );
}

static Future<List<Insumo>> getInsumos() async {
  final db = await _getDatabase();
  final List<Map<String, dynamic>> maps = await db.query('insumos', orderBy: 'nombre ASC');
  return maps.map((map) => Insumo.fromMap(map)).toList();
}
static Future<int> addInsumoToProducto(int productoId, int insumoId, double cantidad) async {
  final db = await _getDatabase();
  return await db.insert('producto_insumo', {
    'producto_id': productoId,
    'insumo_id': insumoId,
    'cantidad': cantidad,
  });
}

static Future<List<Map<String, dynamic>>> obtenerInsumosDeProducto(int productoId) async {
  final db = await _getDatabase();

  return await db.rawQuery('''
    SELECT 
      i.id, 
      i.nombre, 
      i.unidad,
      i.precio,
      pi.cantidad
    FROM producto_insumo pi
    JOIN insumos i ON pi.insumo_id = i.id
    WHERE pi.producto_id = ?
  ''', [productoId]);
}
static Future<int> eliminarProductoInsumo(int productoId, int insumoId) async {
  final db = await _getDatabase();
  return await db.delete(
    'producto_insumo',
    where: 'producto_id = ? AND insumo_id = ?',
    whereArgs: [productoId, insumoId],
  );
}

static Future<int> actualizarCantidadInsumo(int productoId, int insumoId, double nuevaCantidad) async {
  final db = await _getDatabase();
  return await db.update(
    'producto_insumo',
    {'cantidad': nuevaCantidad},
    where: 'producto_id = ? AND insumo_id = ?',
    whereArgs: [productoId, insumoId],
  );
}

static Future<int> insertarFactura(int productoId, String nombre, String path) async {
  final db = await _getDatabase();
  return await db.insert('facturas', {
    'productoId': productoId,
    'nombre': nombre,
    'path': path,
  });
}


static Future<List<Map<String, dynamic>>> obtenerFacturasDeProducto(int productoId) async {
  final db = await _getDatabase();
  return await db.query(
    'facturas',
    where: 'productoId = ?',
    whereArgs: [productoId],
  );
}

static Future<int> eliminarFactura(int id) async {
  final db = await _getDatabase();
  return await db.delete(
    'facturas',
    where: 'id = ?',
    whereArgs: [id],
  );
}

static Future<int> actualizarNombreFactura(int id, String nuevoNombre) async {
  final db = await _getDatabase();
  return await db.update(
    'facturas',
    {'nombre': nuevoNombre},
    where: 'id = ?',
    whereArgs: [id],
  );
}

static Future<List<Map<String, dynamic>>> obtenerProductosConCosto() async {
  final db = await _getDatabase();
  final result = await db.rawQuery('''
    SELECT
      p.id,
      p.nombre,
      p.precio,
      p.rendimiento_tanda,
      (SELECT SUM(i.precio * pi.cantidad) / CASE WHEN p.rendimiento_tanda > 0 THEN p.rendimiento_tanda ELSE 1 END
       FROM producto_insumo pi
       JOIN insumos i ON i.id = pi.insumo_id
       WHERE pi.producto_id = p.id) as costo
    FROM productos p
    ORDER BY p.nombre ASC;
  ''');
  return result;
}

static Future<void> actualizarProductosDeTanda(int tandaId, Map<int, int> productosConStock) async {
  final db = await _getDatabase();
  await db.transaction((txn) async {
    await txn.delete('productos_tanda', where: 'tandaId = ?', whereArgs: [tandaId]);

    for (var entry in productosConStock.entries) {
      final productoId = entry.key;
      final stock = entry.value;
      
      final productoMap = (await txn.query('productos', where: 'id = ?', whereArgs: [productoId])).first;
      final producto = Producto.fromMap(productoMap);
      
      final costoCalculado = await _calcularCostoUnitario(txn, producto);
      
      await txn.insert(
        'productos_tanda',
        {
          'tandaId': tandaId,
          'productoId': productoId,
          'stock': stock,
          'costo_produccion_unitario': costoCalculado,
        },
      );
    }
  });
}



// ================== FINANZAS: CUENTAS ==================
static Future<int> insertarCuenta(Cuenta cuenta) async {
  final db = await _getDatabase();
  return await db.insert('cuentas', cuenta.toMap());
}

static Future<List<Cuenta>> obtenerCuentas() async {
  final db = await _getDatabase();
  final List<Map<String, dynamic>> maps = await db.query('cuentas');
  return List.generate(maps.length, (i) {
    return Cuenta.fromMap(maps[i]);
  });
}

static Future<void> actualizarBalanceCuenta(int cuentaId, double nuevoBalance) async {
  final db = await _getDatabase();
  await db.update(
    'cuentas',
    {'balance': nuevoBalance},
    where: 'id = ?',
    whereArgs: [cuentaId],
  );
}

static Future<void> eliminarCuenta(int id) async {
  final db = await _getDatabase();
  await db.delete('cuentas', where: 'id = ?', whereArgs: [id]);
}

// ================== FINANZAS: TRANSACCIONES ==================
static Future<int> insertarTransaccion(Transaccion transaccion) async {
  final db = await _getDatabase();
  return await db.transaction((txn) async {
    final transaccionId = await txn.insert('transacciones', transaccion.toMap());

    final cuentaMap = await txn.query('cuentas', where: 'id = ?', whereArgs: [transaccion.cuentaId]);
    final cuenta = Cuenta.fromMap(cuentaMap.first);
    
    final nuevoBalance = transaccion.tipo == 'ingreso'
        ? cuenta.balance + transaccion.monto
        : cuenta.balance - transaccion.monto;

    await txn.update(
      'cuentas',
      {'balance': nuevoBalance},
      where: 'id = ?',
      whereArgs: [transaccion.cuentaId],
    );

    return transaccionId;
  });
}

static Future<List<Transaccion>> obtenerTransaccionesPorCuenta(int cuentaId) async {
  final db = await _getDatabase();
  final List<Map<String, dynamic>> maps = await db.query(
    'transacciones',
    where: 'cuentaId = ?',
    whereArgs: [cuentaId],
    orderBy: 'fecha DESC',
  );
  return List.generate(maps.length, (i) {
    return Transaccion.fromMap(maps[i]);
  });
}

static Future<void> eliminarTransaccion(int id) async {
  final db = await _getDatabase();
  await db.transaction((txn) async {
    final transaccionMap = await txn.query('transacciones', where: 'id = ?', whereArgs: [id]);
    final transaccion = Transaccion.fromMap(transaccionMap.first);
    
    final cuentaMap = await txn.query('cuentas', where: 'id = ?', whereArgs: [transaccion.cuentaId]);
    final cuenta = Cuenta.fromMap(cuentaMap.first);

    final nuevoBalance = transaccion.tipo == 'ingreso'
        ? cuenta.balance - transaccion.monto
        : cuenta.balance + transaccion.monto;

    await txn.update(
      'cuentas',
      {'balance': nuevoBalance},
      where: 'id = ?',
      whereArgs: [transaccion.cuentaId],
    );

    await txn.delete('transacciones', where: 'id = ?', whereArgs: [id]);
  });
}




static Future<void> limpiarTablasLocales() async {
  final db = await _getDatabase();
  await db.delete('detalles_pedido');
  await db.delete('pedidos');
  await db.delete('productos_tanda');
  await db.delete('tandas');
  await db.delete('producto_insumo');
  await db.delete('insumos');
  await db.delete('productos');

}



static Future<String> getDatabasePath() async {
  return join(await getDatabasesPath(), 'postres.db');
}


static Future<List<Map<String, dynamic>>> obtenerTodasLasFacturas() async {
  final db = await _getDatabase();
  return await db.query('facturas');
}


static Future<List<Map<String, dynamic>>> obtenerIngresosYGastosPorPeriodo({required String periodo}) async {
    final db = await _getDatabase();
    String groupBy;
    switch (periodo) {
      case 'mes':
        groupBy = "strftime('%Y-%m', fecha)";
        break;
      case 'ano':
        groupBy = "strftime('%Y', fecha)";
        break;
      default: // semana
        groupBy = "strftime('%Y-%W', fecha)";
        break;
    }

    final result = await db.rawQuery('''
      SELECT 
        STRFTIME('%Y-%m-%d', fecha) as fecha_grupo, 
        SUM(CASE WHEN tipo = 'ingreso' THEN monto ELSE 0 END) as total_ingresos,
        SUM(CASE WHEN tipo = 'gasto' THEN monto ELSE 0 END) as total_gastos
      FROM (
        SELECT pagoParcial as monto, 'ingreso' as tipo, STRFTIME('%Y-%m-%d %H:%M:%S', id / 1000, 'unixepoch') as fecha FROM pedidos WHERE pagado = 1
        UNION ALL
        SELECT monto, 'gasto' as tipo, fecha FROM gastos
      )
      GROUP BY $groupBy
      ORDER BY fecha_grupo ASC
    ''');
    return result;
  }

  static Future<List<Map<String, dynamic>>> obtenerGananciaPorProducto() async {
    final db = await _getDatabase();
    final result = await db.rawQuery('''
      SELECT 
        p.nombre,
        SUM(dp.cantidad * (p.precio - pt.costo_produccion_unitario)) as ganancia_neta
      FROM detalles_pedido dp
      JOIN productos p ON p.id = dp.productoId
      JOIN pedidos ped ON ped.id = dp.pedidoId
      JOIN productos_tanda pt ON pt.productoId = p.id AND pt.tandaId = ped.tandaId
      GROUP BY p.id
      ORDER BY ganancia_neta DESC
      LIMIT 5
    ''');
    return result;
  }

  static Future<List<Map<String, dynamic>>> obtenerTopClientes() async {
    final db = await _getDatabase();
    return await db.rawQuery('''
      SELECT 
        cliente, 
        SUM(pagoParcial) as total_gastado
      FROM pedidos
      GROUP BY cliente
      ORDER BY total_gastado DESC
      LIMIT 5
    ''');
  }

  static Future<List<Map<String, dynamic>>> obtenerVentasPorDiaSemana() async {
  final db = await _getDatabase();
  return await db.rawQuery('''
    SELECT 
      CAST(strftime('%w', id / 1000, 'unixepoch', 'localtime') AS INTEGER) as dia_semana, 
      SUM(pagoParcial) as total_ingresos
    FROM pedidos
    GROUP BY dia_semana
    ORDER BY dia_semana ASC
  ''');
}

  static Future<List<Map<String, dynamic>>> obtenerGananciaPorTanda() async {
    final db = await _getDatabase();
    return await db.rawQuery('''
      SELECT 
        t.nombre,
        (SELECT SUM(p.pagoParcial) FROM pedidos p WHERE p.tandaId = t.id) - 
        (SELECT SUM(g.monto) FROM gastos g WHERE g.tandaId = t.id) as utilidad_neta
      FROM tandas t
      ORDER BY t.id DESC
      LIMIT 5
    ''');
  }






static Future<double> obtenerIngresosDeHoy() async {
    final db = await _getDatabase();
    final result = await db.rawQuery('''
      SELECT SUM(pagoParcial) as total
      FROM pedidos
      WHERE DATE(fecha, 'localtime') = DATE('now', 'localtime')
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<int> obtenerPedidosPendientes() async {
    final db = await _getDatabase();
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM pedidos
      WHERE entregado = 0
    ''');
    return (result.first['count'] as int?) ?? 0;
  }


// funciones nuevas v9.0 para informe de deudores//

static Future<List<Producto>> obtenerTodosLosProductos() async {
  final db = await _getDatabase();
  final List<Map<String, dynamic>> maps = await db.query('productos', orderBy: 'nombre ASC');
  return List.generate(maps.length, (i) {
    return Producto.fromMap(maps[i]);
  });
}


//para verificar si la tanda ya tiene ese nombre

static Future<bool> existeTandaConNombre(String nombre) async {
  final db = await _getDatabase();
  final resultado = await db.query(
    'tandas',
    where: 'LOWER(nombre) = ?',
    whereArgs: [nombre.toLowerCase()],
    limit: 1,
  );
  return resultado.isNotEmpty;
}
}