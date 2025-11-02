import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:finalproject/service/dbHelper.dart';
import 'package:finalproject/pages/loginScreen.dart';

class RegisterController {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper();
  
  bool isObscure = true;

  ValueNotifier<bool> get isObscureNotifier => ValueNotifier(isObscure);

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

  /// 📋 Register handler
  Future<void> register(BuildContext context) async {
    String username = userController.text.trim();
    String password = passwordController.text.trim();

    // Validasi input
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username dan password tidak boleh kosong"),
          backgroundColor: Colors.red,
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
            content: const Text("Registrasi berhasil! Silakan login."),
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
            content: const Text("Username sudah terdaftar atau error."),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    }
  }

 
  void togglePasswordVisibility() {
    isObscure = !isObscure;
    isObscureNotifier.value = isObscure;
  }

  void dispose() {
    userController.dispose();
    passwordController.dispose();
    isObscureNotifier.dispose();
  }
}