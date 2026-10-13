import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._init();
  static Database? _database;

  LocalDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_product_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        name TEXT,
        slug TEXT,
        category_id INTEGER,
        brand_id INTEGER,
        unit_id INTEGER,
        sku TEXT,
        barcode TEXT,
        cost_price REAL,
        selling_price REAL,
        stock_quantity REAL,
        alert_quantity REAL,
        image TEXT,
        description TEXT,
        is_active INTEGER
      )
    ''');

    // ➕ តារាងសម្រាប់រក្សាទុកផលិតផលថ្មីៗដែលបង្កើតពេលដាច់អ៉ីនធឺណិត (Pending Queue)
    await db.execute('''
      CREATE TABLE pending_products (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        payload_json TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  // 📥 1. រក្សាទុក/អាប់ដេត Products ទាំងអស់ពី MySQL មក Caching ទុកក្នុង Local SQLite
  Future<void> saveProductsToLocal(List<Map<String, dynamic>> products) async {
    final db = await instance.database;
    Batch batch = db.batch();
    await db.delete('products');
    for (var prod in products) {
      batch.insert('products', {
        'id': prod['id'],
        'name': prod['name'],
        'slug': prod['slug'] ?? '',
        'category_id': prod['category_id'],
        'brand_id': prod['brand_id'],
        'unit_id': prod['unit_id'],
        'sku': prod['sku'] ?? '',
        'barcode': prod['barcode'],
        'cost_price': prod['cost_price'] ?? 0.0,
        'selling_price': prod['selling_price'] ?? 0.0,
        'stock_quantity': prod['stock_quantity'] ?? 0.0,
        'alert_quantity': prod['alert_quantity'],
        'image': prod['image'] ?? prod['image_url'],
        'description': prod['description'],
        'is_active': prod['is_active'] ?? 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // 🔍 2. ស្វែងរកផលិតផល ឬស្កេន Barcode ពេល Offline
  Future<List<Map<String, dynamic>>> searchLocalProducts(String query) async {
    final db = await instance.database;
    return await db.query(
      'products',
      where: 'name LIKE ? OR sku LIKE ? OR barcode = ?',
      whereArgs: ['%$query%', '%$query%', query],
    );
  }

  // 💾 3. រក្សាទុក Product ថ្មីក្នុងเครื่องពេលដាច់អ៉ីនធឺណិត
  Future<int> saveProductOffline(Map<String, dynamic> productData) async {
    final db = await instance.database;
    return await db.insert('pending_products', {
      'payload_json': jsonEncode(productData),
      'is_synced': 0,
    });
  }


  Future<List<Map<String, dynamic>>> getUnsyncedProducts() async {
    final db = await instance.database;
    return await db.query('pending_products', where: 'is_synced = ?', whereArgs: [0]);
  }


  Future<void> markProductAsSynced(int localId) async {
    final db = await instance.database;
    await db.update(
      'pending_products',
      {'is_synced': 1},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }
}