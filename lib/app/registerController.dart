import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:finalproject/service/dbHelper.dart';
import 'package:finalproject/pages/loginScreen.dart';

class RegisterController {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper();
  
  // PERBAIKAN: Buat instance ValueNotifier yang proper
  final ValueNotifier<bool> isObscureNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isObscureConfirmNotifier = ValueNotifier<bool>(true);

  String encryptPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  void goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  /// 📋 Register handler dengan validasi konfirmasi password
  Future<void> register(BuildContext context) async {
    String username = userController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    // Validasi input kosong
    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua field harus diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi password minimal 6 karakter
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password minimal 6 karakter"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // VALIDASI: Cek apakah password dan confirm password sama
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password dan Konfirmasi Password tidak cocok!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      var user = UserModel(
        username: username,
        password: encryptPassword(password),
      );
      await dbHelper.registerUser(user);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✅ Registrasi berhasil! Silakan login."),
            backgroundColor: Colors.green[700],
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("❌ Username sudah terdaftar atau error."),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    }
  }

  // PERBAIKAN: Toggle visibility untuk password
  void togglePasswordVisibility() {
    isObscureNotifier.value = !isObscureNotifier.value;
  }

  // PERBAIKAN: Toggle visibility untuk confirm password
  void toggleConfirmPasswordVisibility() {
    isObscureConfirmNotifier.value = !isObscureConfirmNotifier.value;
  }

  void dispose() {
    userController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    isObscureNotifier.dispose();
    isObscureConfirmNotifier.dispose();
  }
}