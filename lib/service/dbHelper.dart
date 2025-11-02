
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

// ==== MODEL ====
class PesanKesan {
  final int? id;
  final String nama;
  final String pesan;
  final String kesan;

  PesanKesan({
    this.id,
    required this.nama,
    required this.pesan,
    required this.kesan,
  });

  // Konversi dari Map (Database) ke Object
  factory PesanKesan.fromMap(Map<String, dynamic> map) {
    return PesanKesan(
      id: map['id'],
      nama: map['nama'],
      pesan: map['pesan'],
      kesan: map['kesan'],
    );
  }

  // Konversi dari Object ke Map (untuk insert/update)
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'nama': nama,
      'pesan': pesan,
      'kesan': kesan,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}

// ==== DATABASE HELPER ====
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper.internal();

  static Database? _db;

  Future<Database?> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  Future<Database> initDb() async {
    io.Directory docDirectory = await getApplicationDocumentsDirectory();
    String path = join(docDirectory.path, 'weather.db');
    var localDb = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    return localDb;
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pesankesan(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        pesan TEXT NOT NULL,
        kesan TEXT NOT NULL
      )
    ''');
  }

  // ===== CREATE =====
  Future<int> insertPesan(PesanKesan pesanKesan) async {
    var dbClient = await db;
    return await dbClient!.insert('pesankesan', pesanKesan.toMap());
  }

  // ===== READ =====
  Future<List<PesanKesan>> getAllPesan() async {
    var dbClient = await db;
    var result = await dbClient!.query('pesankesan', orderBy: 'id DESC');
    return result.map((e) => PesanKesan.fromMap(e)).toList();
  }

  // ===== UPDATE =====
  Future<int> updatePesan(PesanKesan pesanKesan) async {
    var dbClient = await db;
    return await dbClient!.update(
      'pesankesan',
      pesanKesan.toMap(),
      where: 'id = ?',
      whereArgs: [pesanKesan.id],
    );
  }

  // ===== DELETE =====
  Future<int> deletePesan(int id) async {
    var dbClient = await db;
    return await dbClient!.delete(
      'pesankesan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== DELETE ALL (optional) =====
  Future<int> deleteAllPesan() async {
    var dbClient = await db;
    return await dbClient!.delete('pesankesan');
  }

  // ===== COUNT DATA (optional) =====
  Future<int> getCount() async {
    var dbClient = await db;
    return Sqflite.firstIntValue(
          await dbClient!.rawQuery('SELECT COUNT(*) FROM pesankesan'),
        ) ??
        0;
  }
}

// ==== MODEL USER ==== //
class UserModel {
  final int? id;
  final String username;
  final String password; // disimpan dalam bentuk hash (sha256)

  UserModel({
    this.id,
    required this.username,
    required this.password,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      password: map['password'],
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'username': username,
      'password': password,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}

// ==== FITUR REGISTER & LOGIN USER ==== //
extension UserAuthExtension on DatabaseHelper {
  // Membuat tabel users jika belum ada
  Future<void> _createUserTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');
  }

  // Panggil fungsi ini saat pertama kali membuka database (opsional)
  Future<void> ensureUserTableExists() async {
    var dbClient = await db;
    await _createUserTable(dbClient!);
  }

  // REGISTER USER
  Future<int> registerUser(UserModel user) async {
    var dbClient = await db;
    await ensureUserTableExists();
    return await dbClient!.insert('users', user.toMap());
  }

  // LOGIN USER
  Future<UserModel?> loginUser(String username, String password) async {
    var dbClient = await db;
    await ensureUserTableExists();
    var result = await dbClient!.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }
}

