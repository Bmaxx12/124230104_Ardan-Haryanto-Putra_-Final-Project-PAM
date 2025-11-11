import 'package:flutter/material.dart';
import 'package:finalproject/app/registerController.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final RegisterController _controller = RegisterController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView( // TAMBAHAN: Agar bisa scroll jika keyboard muncul
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Header Text ---
                const Center(
                  child: Text(
                    "Create Account\nJoin Us Today!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // --- Illustration Image ---
                Image.asset(
                  "assets/images/cloudy.png", 
                  height: 180, // Dikurangi sedikit agar muat dengan field baru
                ),
                const SizedBox(height: 40),

                // --- Username Field ---
                CustomTextfield(
                  controller: _controller.userController,
                  textInputType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  hint: 'Username',
                ),
                const SizedBox(height: 16),

                // --- Password Field ---
                ValueListenableBuilder<bool>(
                  valueListenable: _controller.isObscureNotifier,
                  builder: (context, isObscure, child) {
                    return CustomTextfield(
                      controller: _controller.passwordController,
                      textInputType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.next, // UBAH: dari done ke next
                      hint: 'Password',
                      isObscure: isObscure,
                      hasSuffix: true,
                      onPressed: _controller.togglePasswordVisibility,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // --- KONFIRMASI PASSWORD FIELD (BARU) ---
                ValueListenableBuilder<bool>(
                  valueListenable: _controller.isObscureConfirmNotifier,
                  builder: (context, isObscureConfirm, child) {
                    return CustomTextfield(
                      controller: _controller.confirmPasswordController,
                      textInputType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      hint: 'Konfirmasi Password',
                      isObscure: isObscureConfirm,
                      hasSuffix: true,
                      onPressed: _controller.toggleConfirmPasswordVisibility,
                    );
                  },
                ),
                const SizedBox(height: 30),

                // --- Register Button ---
                ElevatedButton(
                  onPressed: () => _controller.register(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20), // UBAH: dari Spacer() ke SizedBox fixed height

                // --- Login Link ---
                Center(
                  child: GestureDetector(
                    onTap: () => _controller.goToLogin(context),
                    child: RichText(
                      text: const TextSpan(
                        text: "Sudah punya akun? ",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                        children: [
                          TextSpan(
                            text: "Login!",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- CUSTOM TEXTFIELD ----------------
class CustomTextfield extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType textInputType;
  final TextInputAction textInputAction;
  final String hint;
  final bool isObscure;
  final bool hasSuffix;
  final VoidCallback? onPressed;

  const CustomTextfield({
    required this.controller,
    required this.textInputType,
    required this.textInputAction,
    required this.hint,
    this.isObscure = false,
    this.hasSuffix = false,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: textInputType,
      textInputAction: textInputAction,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        suffixIcon: hasSuffix
            ? IconButton(
                onPressed: onPressed,
                icon: Icon(
                  isObscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
        ),
      ),
    );
  }
}