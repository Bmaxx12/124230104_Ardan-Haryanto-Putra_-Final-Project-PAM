import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

// ==== MODEL USER PROFILE ==== //
class UserProfile {
  final int? id;
  final String username;
  final String nama;
  final String nim;
  final String hobi;
  final String motto;

  UserProfile({
    this.id,
    required this.username,
    required this.nama,
    required this.nim,
    required this.hobi,
    required this.motto,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      username: map['username'],
      nama: map['nama'],
      nim: map['nim'],
      hobi: map['hobi'],
      motto: map['motto'],
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'username': username,
      'nama': nama,
      'nim': nim,
      'hobi': hobi,
      'motto': motto,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}

// ==== MODEL USER ==== //
class UserModel {
  final int? id;
  final String username;
  final String password;
  final String subscriptionPlan; // Tambahan field baru

  UserModel({
    this.id,
    required this.username,
    required this.password,
    this.subscriptionPlan = 'Basic', // Default Basic
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      subscriptionPlan: map['subscription_plan'] ?? 'Basic',
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'username': username,
      'password': password,
      'subscription_plan': subscriptionPlan,
    };
    if (id != null) map['id'] = id;
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
    String path = join(docDirectory.path, 'weather_v2.db'); // Ganti nama DB biar fresh atau handle migration
    var localDb = await openDatabase(
      path,
      version: 4, // Naikkan versi ke 4
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return localDb;
  }

  void _onCreate(Database db, int version) async {
    // Tambahkan kolom subscription_plan
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        subscription_plan TEXT DEFAULT 'Basic' 
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        nama TEXT NOT NULL,
        nim TEXT NOT NULL,
        hobi TEXT NOT NULL,
        motto TEXT NOT NULL
      )
    ''');
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profiles(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          nama TEXT NOT NULL,
          nim TEXT NOT NULL,
          hobi TEXT NOT NULL,
          motto TEXT NOT NULL
        )
      ''');
    }
    
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS pesankesan');
    }

    // Migration ke versi 4: Tambah kolom subscription_plan jika belum ada
    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE users ADD COLUMN subscription_plan TEXT DEFAULT 'Basic'");
      } catch (e) {
        print("Error upgrading db: $e");
      }
    }
  }

  // ===== USER SUBSCRIPTION METHODS (BARU) =====
  
  // Update Plan User
  Future<void> updateUserPlan(String username, String newPlan) async {
    var dbClient = await db;
    await dbClient!.update(
      'users',
      {'subscription_plan': newPlan},
      where: 'username = ?',
      whereArgs: [username],
    );
    print("✅ Plan updated to $newPlan for user $username");
  }

  // Get User Plan
  Future<String> getUserPlan(String username) async {
    var dbClient = await db;
    var result = await dbClient!.query(
      'users',
      columns: ['subscription_plan'],
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      return result.first['subscription_plan'] as String? ?? 'Basic';
    }
    return 'Basic';
  }

  // ===== USER PROFILE METHODS =====
  Future<int> insertOrUpdateProfile(UserProfile profile) async {
    var dbClient = await db;
    var existing = await getProfileByUsername(profile.username);
    
    if (existing != null) {
      return await dbClient!.update(
        'user_profiles',
        profile.toMap(),
        where: 'username = ?',
        whereArgs: [profile.username],
      );
    } else {
      return await dbClient!.insert('user_profiles', profile.toMap());
    }
  }

  Future<UserProfile?> getProfileByUsername(String username) async {
    var dbClient = await db;
    var result = await dbClient!.query(
      'user_profiles',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      return UserProfile.fromMap(result.first);
    }
    return null;
  }
}

// ==== FITUR REGISTER & LOGIN USER ==== //
extension UserAuthExtension on DatabaseHelper {

  Future<void> _createUserTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        subscription_plan TEXT DEFAULT 'Basic'
      )
    ''');
  }

  Future<void> ensureUserTableExists() async {
    var dbClient = await db;
    // Cek apakah tabel ada, jika tidak create (logic simplified handled by onCreate/onUpgrade mostly)
  }

  // REGISTER USER
  Future<int> registerUser(UserModel user) async {
    var dbClient = await db;
    return await dbClient!.insert('users', user.toMap());
  }

  // LOGIN USER
  Future<UserModel?> loginUser(String username, String password) async {
    var dbClient = await db;
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