import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:finalproject/pages/weatherScreen.dart';
import 'package:finalproject/pages/register.dart';
import 'package:finalproject/service/dbHelper.dart';

class LoginController {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper();
  
  bool isObscure = true;
  bool isLoading = false;

  ValueNotifier<bool> get isObscureNotifier => ValueNotifier(isObscure);
  ValueNotifier<bool> get isLoadingNotifier => ValueNotifier(isLoading);

  /// 🗄️ Inisialisasi database
  Future<void> initDatabase() async {
    await dbHelper.ensureUserTableExists();
  }

  /// 🔒 Fungsi untuk enkripsi password
  String encryptPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 💾 Simpan session
  Future<void> saveSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setBool('isLoggedIn', true);
  }

  /// 🔍 Cek session
  Future<void> checkSession(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final username = prefs.getString('username');
    
    if (isLoggedIn && username != null) {
      // Jika sudah login, langsung ke WeatherScreen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WeaterScreen()),
        );
      }
    }
  }

  /// 🚪 Login handler dengan database
  Future<void> login(BuildContext context) async {
    String username = userController.text.trim();
    String password = passwordController.text;

    // Validasi input
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Username dan Password tidak boleh kosong"),
          backgroundColor: Colors.red[800],
        ),
      );
      return;
    }

    _setLoading(true);

    try {
      // Hash password
      String hashedPassword = encryptPassword(password);
      
      // Cek ke database
      UserModel? user = await dbHelper.loginUser(username, hashedPassword);

      _setLoading(false);

      if (user != null) {
        // Login berhasil
        await saveSession(username);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Login Berhasil, Selamat Datang ${user.username}"),
              backgroundColor: Colors.green[700],
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WeaterScreen()),
          );
        }
      } else {
        // Login gagal
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Login gagal, username atau password salah"),
              backgroundColor: Colors.red[800],
            ),
          );
        }
      }
    } catch (e) {
      _setLoading(false);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    }
  }

  /// 📝 Navigate to Register
  void goToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  /// 👁️ Toggle password visibility
  void togglePasswordVisibility() {
    isObscure = !isObscure;
    isObscureNotifier.value = isObscure;
  }

  /// ⏳ Set loading state
  void _setLoading(bool value) {
    isLoading = value;
    isLoadingNotifier.value = isLoading;
  }

  /// 🧹 Cleanup resources
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    isObscureNotifier.dispose();
    isLoadingNotifier.dispose();
  }
}