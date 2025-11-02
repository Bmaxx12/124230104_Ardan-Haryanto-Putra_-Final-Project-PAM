import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finalproject/service/dbHelper.dart';
import 'package:finalproject/pages/loginScreen.dart';
import 'package:finalproject/pages/weatherScreen.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final picker = ImagePicker();

  final nama = "Ardan Haryanto Putra";
  final nim = "124230104";
  final hobi = "Futsal, Pelajaran pak bagus";
  final motto = "satu dua biji nangka, tidak lupa jangan beli apel";

  // Database Helper
  final dbHelper = DatabaseHelper();
  List<PesanKesan> listPesan = [];

  final _namaController = TextEditingController();
  final _pesanController = TextEditingController();
  final _kesanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getAllPesan();
  }



  // CRUD
  Future<void> getAllPesan() async {
    final data = await dbHelper.getAllPesan();
    setState(() {
      listPesan = data;
    });
  }

  Future<void> addPesan() async {
    if (_namaController.text.isEmpty ||
        _pesanController.text.isEmpty ||
        _kesanController.text.isEmpty) return;

    final pesan = PesanKesan(
      nama: _namaController.text,
      pesan: _pesanController.text,
      kesan: _kesanController.text,
    );
    await dbHelper.insertPesan(pesan);
    _namaController.clear();
    _pesanController.clear();
    _kesanController.clear();
    getAllPesan();
  }

  Future<void> deletePesan(int id) async {
    await dbHelper.deletePesan(id);
    getAllPesan();
  }

  // ==== LOGOUT ====
 Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Konfirmasi Logout"),
      content: const Text("Apakah Anda yakin ingin keluar?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context); // Tutup dialog
            await prefs.remove('username'); // 🔥 hapus session
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: const Text(
            "Logout",
            style: TextStyle(color: Colors.redAccent),
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
        title: const Text("Profil & Pesan Kesan"),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,
        leading: IconButton(
  icon: const Icon(Icons.arrow_back, color: Colors.white),
  onPressed: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => WeaterScreen()), // arahkan ke WeatherScreen
    );
  },
),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // FOTO PROFIL
           // FOTO PROFIL STATIS
Center(
  child: CircleAvatar(
    radius: 60,
    backgroundColor: Colors.orangeAccent,
    backgroundImage: const AssetImage('assets/images/profile.jpg'),
  ),
),

            const SizedBox(height: 20),

            // INFO PROFILE
            Text(
              nama,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("NIM: $nim", style: const TextStyle(color: Colors.white70)),
            Text("Hobi: $hobi", style: const TextStyle(color: Colors.white70)),
            Text("Motto: $motto", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),

            const Divider(color: Colors.white24, thickness: 1),
            const SizedBox(height: 10),
            const Text(
              "Form Pesan & Kesan",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // FORM
            TextField(
              controller: _namaController,
              decoration: inputDecoration("Nama"),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pesanController,
              decoration: inputDecoration("Pesan"),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _kesanController,
              decoration: inputDecoration("Kesan"),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: addPesan,
              icon: const Icon(Icons.send),
              label: const Text("Kirim"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Daftar Pesan & Kesan",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // LIST PESAN
            ListView.builder(
              itemCount: listPesan.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = listPesan[index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(
                      item.nama,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Pesan: ${item.pesan}",
                            style: const TextStyle(color: Colors.white70)),
                        Text("Kesan: ${item.kesan}",
                            style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => deletePesan(item.id!),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
      ),
    );
  }
}
