import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance =
      DatabaseHelper._internal();
  static Database? _database;


  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();

    return _database!;
  }
  Future<Database> _initDatabase() async {
    final databaseDirectory = await getDatabasesPath();
    final databasePath = join(
      databaseDirectory,
      'contact_manager.db'
    );

    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE contacts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL DEFAULT '',
    isFavorite INTEGER NOT NULL DEFAULT 0
  )

        ''');
      },
    );
  }

  Future<int> insertContact(
      Map<String,dynamic> contact,
      ) async {
    final db = await database;
    return db.insert('contacts', contact);
  }
  Future<List<Map<String, dynamic>>> getContacts({
    String search = '',
    bool favoritesOnly = false,
}) async {
    final db = await database;

    final conditions = <String>[];
    final arguments = <dynamic>[];

    if (search.trim().isNotEmpty){
      conditions.add('name LIKE ?');
      arguments.add('%${search.trim()}%');

    }
    if(favoritesOnly){
      conditions.add('isFavorite = ?');
      arguments.add(1);
    }

    return db.query(
      'contacts',
      where: conditions.isEmpty
          ? null
          : conditions.join(' AND '),
      whereArgs: arguments.isEmpty ? null : arguments,
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  Future<int> updateContact (
      int id,
      Map<String, dynamic> contact,
      ) async {
    final db = await database;

    return db.update(
      'contacts',
      contact,
      where: 'id = ?',
      whereArgs: [id],

    );
  }
  Future<int> deleteContact(int id) async {
    final db = await database;

    return db.delete(
         'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<int> toggleFavorite(
      int id,
      bool isFavorite,
      ) async {
    final db = await database;

    return db.update(
      'contacts',
      { 'isFavorite': isFavorite ? 1 : 0 },
      where: 'id = ?',
      whereArgs: [id],

    );
  }
}