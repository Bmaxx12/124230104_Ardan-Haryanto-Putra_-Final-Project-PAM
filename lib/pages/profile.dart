import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finalproject/service/dbHelper.dart';
import 'package:finalproject/pages/loginScreen.dart';
import 'package:finalproject/pages/weatherScreen.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final picker = ImagePicker();

  // Data diri yang sekarang dinamis
  String nama = "";
  String nim = "";
  String hobi = "";
  String motto = "";
  String currentUsername = "";
  String? profileImagePath;

  // Mode edit
  bool isEditMode = false;

  // Database Helper
  final dbHelper = DatabaseHelper();

  // Controllers untuk edit profile
  final _editNamaController = TextEditingController();
  final _editNimController = TextEditingController();
  final _editHobiController = TextEditingController();
  final _editMottoController = TextEditingController();

  // Data Pesan & Kesan Statis
  final String pesanStatis = "Terima kasih atas pembelajaran yang sangat bermanfaat. "
      "Semoga ilmu yang diberikan dapat saya terapkan dengan baik di masa depan.";
  
  final String kesanStatis = "Pembelajaran sangat menyenangkan dan mudah dipahami. "
      "Suasana kelas yang kondusif membuat saya lebih termotivasi untuk belajar.";

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadProfileImage();
  }

  @override
  void dispose() {
    _editNamaController.dispose();
    _editNimController.dispose();
    _editHobiController.dispose();
    _editMottoController.dispose();
    super.dispose();
  }

  // Load profile image dari SharedPreferences
  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profile_image_$currentUsername');
    if (savedPath != null && File(savedPath).existsSync()) {
      setState(() {
        profileImagePath = savedPath;
      });
    }
  }

  // Pilih gambar dari device
  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_$currentUsername', pickedFile.path);
      setState(() {
        profileImagePath = pickedFile.path;
      });
    }
  }

  // Load data user dari SharedPreferences dan Database
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    currentUsername = prefs.getString('username') ?? '';

    if (currentUsername.isNotEmpty) {
      final profile = await dbHelper.getProfileByUsername(currentUsername);

      if (profile != null) {
        setState(() {
          nama = profile.nama;
          nim = profile.nim;
          hobi = profile.hobi;
          motto = profile.motto;
          _editNamaController.text = nama;
          _editNimController.text = nim;
          _editHobiController.text = hobi;
          _editMottoController.text = motto;
        });
      } else {
        setState(() {
          nama = "Belum diisi";
          nim = "Belum diisi";
          hobi = "Belum diisi";
          motto = "Belum diisi";
        });
      }
    }
  }

  // Toggle edit mode
  void toggleEditMode() {
    setState(() {
      if (isEditMode) {
        // Simpan data
        saveProfile();
      } else {
        // Masuk mode edit
        _editNamaController.text = nama == "Belum diisi" ? "" : nama;
        _editNimController.text = nim == "Belum diisi" ? "" : nim;
        _editHobiController.text = hobi == "Belum diisi" ? "" : hobi;
        _editMottoController.text = motto == "Belum diisi" ? "" : motto;
      }
      isEditMode = !isEditMode;
    });
  }

  // Simpan profile ke database
  Future<void> saveProfile() async {
    if (_editNamaController.text.isEmpty ||
        _editNimController.text.isEmpty ||
        _editHobiController.text.isEmpty ||
        _editMottoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua field harus diisi!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        isEditMode = true;
      });
      return;
    }

    final profile = UserProfile(
      username: currentUsername,
      nama: _editNamaController.text,
      nim: _editNimController.text,
      hobi: _editHobiController.text,
      motto: _editMottoController.text,
    );

    await dbHelper.insertOrUpdateProfile(profile);
    await loadUserData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profil berhasil disimpan!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ==== LOGOUT ====
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Konfirmasi Logout",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await prefs.remove('username');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ==== UI ====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        title: const Text("Profil & Pesan Kesan"),
        backgroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.orangeAccent, size: 20),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => WeaterScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.orangeAccent),
            onPressed: logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Profile Section dengan desain minimalis
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3), width: 1),
              ),
              child: Column(
                children: [
                  // Profile Picture
                  GestureDetector(
                    onTap: pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.orangeAccent, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[900],
                            backgroundImage: profileImagePath != null
                                ? FileImage(File(profileImagePath!))
                                : const AssetImage('assets/images/profile.jpg') as ImageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orangeAccent.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.black, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle Edit Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: isEditMode
                            ? [Colors.green, Colors.green.shade700]
                            : [Colors.orangeAccent, Colors.deepOrange],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: toggleEditMode,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isEditMode ? Icons.save_rounded : Icons.edit_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEditMode ? "Simpan Profil" : "Edit Profil",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Info
                  if (!isEditMode) ...[
                    _buildInfoRow(Icons.person_outline, "Nama", nama),
                    _buildInfoRow(Icons.badge_outlined, "NIM", nim),
                    _buildInfoRow(Icons.favorite_outline, "Hobi", hobi),
                    _buildInfoRow(Icons.format_quote, "Motto", motto),
                  ] else ...[
                    _buildEditField(Icons.person_outline, "Nama Lengkap", _editNamaController),
                    const SizedBox(height: 12),
                    _buildEditField(Icons.badge_outlined, "NIM", _editNimController),
                    const SizedBox(height: 12),
                    _buildEditField(Icons.favorite_outline, "Hobi", _editHobiController),
                    const SizedBox(height: 12),
                    _buildEditField(Icons.format_quote, "Motto", _editMottoController, maxLines: 2),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Section Title - Pesan & Kesan Statis
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Pesan & Kesan",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Container Pesan Statis
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pesan
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.message_outlined,
                          color: Colors.orangeAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pesan",
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pesanStatis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white10,
                  ),
                  const SizedBox(height: 20),

                  // Kesan
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.sentiment_satisfied_alt,
                          color: Colors.orangeAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Kesan",
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              kesanStatis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.orangeAccent, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(IconData icon, String hint, TextEditingController controller,
      {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.orangeAccent, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}