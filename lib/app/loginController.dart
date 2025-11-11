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
  
  // PERBAIKAN: Buat instance ValueNotifier yang proper
  final ValueNotifier<bool> isObscureNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> rememberMeNotifier = ValueNotifier<bool>(false);

  Future<void> initDatabase() async {
    await dbHelper.ensureUserTableExists();
  }

  String encryptPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Load saved credentials jika "Ingat Saya" aktif
  Future<void> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRememberMe = prefs.getBool('rememberMe') ?? false;
    
    if (savedRememberMe) {
      final savedUsername = prefs.getString('savedUsername') ?? '';
      final savedPassword = prefs.getString('savedPassword') ?? '';
      
      userController.text = savedUsername;
      passwordController.text = savedPassword;
      rememberMeNotifier.value = savedRememberMe;
    }
  }

  // Save session dengan opsi remember me
  Future<void> saveSession(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setBool('isLoggedIn', true);
    
    // Simpan credentials jika "Ingat Saya" aktif
    if (rememberMeNotifier.value) {
      await prefs.setString('savedUsername', username);
      await prefs.setString('savedPassword', password);
      await prefs.setBool('rememberMe', true);
    } else {
      // Hapus saved credentials jika tidak dicentang
      await prefs.remove('savedUsername');
      await prefs.remove('savedPassword');
      await prefs.setBool('rememberMe', false);
    }
  }

  Future<void> checkSession(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final username = prefs.getString('username');
    
    if (isLoggedIn && username != null) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WeaterScreen()),
        );
      }
    }
  }

  // Login dengan save password asli untuk remember me
  Future<void> login(BuildContext context) async {
    String username = userController.text.trim();
    String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Username dan Password tidak boleh kosong"),
          backgroundColor: Colors.red[800],
        ),
      );
      return;
    }

    isLoadingNotifier.value = true;

    try {
      String hashedPassword = encryptPassword(password);

      UserModel? user = await dbHelper.loginUser(username, hashedPassword);

      isLoadingNotifier.value = false;

      if (user != null) {
        // Simpan session dan credentials
        await saveSession(username, password);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Login Berhasil, Selamat Datang ${user.username}"),
              backgroundColor: Colors.green[700],
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WeaterScreen()),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("❌ Login gagal, username atau password salah"),
              backgroundColor: Colors.red[800],
            ),
          );
        }
      }
    } catch (e) {
      isLoadingNotifier.value = false;
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: ${e.toString()}"),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    }
  }

  void goToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  // PERBAIKAN: Toggle password visibility
  void togglePasswordVisibility() {
    isObscureNotifier.value = !isObscureNotifier.value;
  }

  // PERBAIKAN: Toggle remember me
  void toggleRememberMe(bool? value) {
    rememberMeNotifier.value = value ?? false;
  }

  void dispose() {
    userController.dispose();
    passwordController.dispose();
    isObscureNotifier.dispose();
    isLoadingNotifier.dispose();
    rememberMeNotifier.dispose();
  }
}