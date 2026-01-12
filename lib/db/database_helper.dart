import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smartpack.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        destination TEXT,
        startDate TEXT,
        endDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tripId INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Umum',
        qty INTEGER NOT NULL DEFAULT 1,
        isChecked INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (tripId) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    // akun default (untuk login)
    await db.insert('users', {'username': 'admin', 'password': '1234'});
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // cek dulu kolom category sudah ada atau belum (biar aman)
      final cols = await db.rawQuery("PRAGMA table_info(items)");
      final hasCategory = cols.any((c) => c['name'] == 'category');

      if (!hasCategory) {
        await db.execute(
          "ALTER TABLE items ADD COLUMN category TEXT NOT NULL DEFAULT 'Umum'",
        );
      }
    }
  }

  // ===== AUTH =====
  Future<bool> login(String username, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ===== TRIP CRUD =====
  Future<int> insertTrip(Map<String, dynamic> data) async {
    final db = await instance.database;
    return db.insert('trips', data);
  }

  Future<List<Map<String, dynamic>>> getTrips() async {
    final db = await instance.database;
    return db.query('trips', orderBy: 'id DESC');
  }

  Future<int> deleteTrip(int id) async {
    final db = await instance.database;
    return db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  // ===== ITEM CRUD (Checklist) =====
  Future<int> insertItem(Map<String, dynamic> data) async {
    final db = await instance.database;
    return db.insert('items', data);
  }

  // insert banyak item sekaligus (untuk template)
  Future<void> insertItemsBatch(List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert('items', item);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getItemsByTrip(int tripId) async {
    final db = await instance.database;
    return db.query(
      'items',
      where: 'tripId = ?',
      whereArgs: [tripId],
      orderBy: 'id DESC',
    );
  }

  Future<int> updateItemChecked(int id, int isChecked) async {
    final db = await instance.database;
    return db.update(
      'items',
      {'isChecked': isChecked},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // update item (untuk edit)
  Future<int> updateItem(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return db.update(
      'items',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}
