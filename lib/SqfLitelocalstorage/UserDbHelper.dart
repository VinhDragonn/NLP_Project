import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class UserDbHelper {
  static final UserDbHelper _instance = UserDbHelper._internal();
  factory UserDbHelper() => _instance;
  UserDbHelper._internal();

  static Database? _db;
  static const String dbName = 'userdb.db';
  static const String tableUser = 'user';
  static const String columnId = 'id';
  static const String columnEmail = 'email';
  static const String columnPassword = 'password';

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, dbName);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUser (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnEmail TEXT NOT NULL UNIQUE,
        $columnPassword TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertUser(String email, String password) async {
    final dbClient = await db;
    return await dbClient.insert(tableUser, {
      columnEmail: email,
      columnPassword: password,
    });
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient.query(
      tableUser,
      where: '$columnEmail = ? AND $columnPassword = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient.query(
      tableUser,
      where: '$columnEmail = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}
