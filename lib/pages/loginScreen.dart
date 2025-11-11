import 'package:flutter/material.dart';
import 'package:finalproject/app/loginController.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController _controller = LoginController();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    await _controller.initDatabase();
    await _controller.loadSavedCredentials(); // TAMBAHAN: Load saved credentials
    _controller.checkSession(context);
  }

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
        child: SingleChildScrollView( // TAMBAHAN: Agar bisa scroll
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Header Text ---
                const Center(
                  child: Text(
                    "Welcome Back\nLogin to Continue",
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
                  height: 180, // Dikurangi sedikit
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
                      textInputAction: TextInputAction.done,
                      hint: 'Password',
                      isObscure: isObscure,
                      hasSuffix: true,
                      onPressed: _controller.togglePasswordVisibility,
                    );
                  },
                ),
                const SizedBox(height: 8),

                // --- CHECKBOX INGAT SAYA (BARU) ---
                ValueListenableBuilder<bool>(
                  valueListenable: _controller.rememberMeNotifier,
                  builder: (context, rememberMe, child) {
                    return Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: _controller.toggleRememberMe,
                          activeColor: Colors.orangeAccent,
                          checkColor: Colors.white,
                        ),
                        GestureDetector(
                          onTap: () {
                            _controller.toggleRememberMe(!rememberMe);
                          },
                          child: const Text(
                            'Ingat Saya',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // --- Login Button ---
                ValueListenableBuilder<bool>(
                  valueListenable: _controller.isLoadingNotifier,
                  builder: (context, isLoading, child) {
                    return ElevatedButton(
                      onPressed: isLoading ? null : () => _controller.login(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        disabledBackgroundColor: Colors.orangeAccent.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Log In",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    );
                  },
                ),

                const SizedBox(height: 20), // UBAH: dari Spacer() ke SizedBox

                // --- Register Link ---
                Center(
                  child: GestureDetector(
                    onTap: () => _controller.goToRegister(context),
                    child: RichText(
                      text: const TextSpan(
                        text: "Belum punya akun? ",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                        children: [
                          TextSpan(
                            text: "Register!",
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