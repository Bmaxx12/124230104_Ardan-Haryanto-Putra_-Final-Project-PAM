import 'package:flutter/material.dart';
import 'package:finalproject/service/apiService.dart';
import 'package:finalproject/service/dbHelper.dart'; // Import DB Helper
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class ProPlanController {
  // State variables
  int selectedPlanIndex = 1; // Default: Pro Plan
  String selectedCurrency = 'USD';

  // Services
  final CurrencyService currencyService = CurrencyService();
  final DatabaseHelper dbHelper = DatabaseHelper(); // Instance DB Helper

  // Context untuk SnackBar
  BuildContext? context;

  // Callback untuk update UI
  Function()? onStateChanged;

  // Available Currencies
  final List<Map<String, String>> availableCurrencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'THB', 'name': 'Thai Baht', 'symbol': '฿'},
  ];

  // Plans Data
  final List<Map<String, dynamic>> plansUSD = [
    {
      'name': 'Basic',
      'price': 0.0,
      'priceText': 'Gratis',
      'duration': 'Selamanya',
      'color': Colors.blue,
      'features': [
        'Prakiraan cuaca 3 hari',
        'Update setiap 3 jam',
        'Lokasi terbatas (1)',
        'Iklan ditampilkan',
      ],
      'icon': Icons.wb_sunny_outlined,
    },
    {
      'name': 'Pro',
      'price': 4.99,
      'priceText': '\$4.99',
      'duration': '/bulan',
      'color': Colors.orangeAccent,
      'features': [
        'Prakiraan cuaca 14 hari',
        'Update realtime setiap jam',
        'Unlimited lokasi',
        'Tanpa iklan',
        'Lihat kurs mata uang pilihan',
        'Notifikasi cuaca ekstrem',
        'Widget premium',
      ],
      'icon': Icons.wb_sunny,
      'badge': 'POPULER',
    },
    {
      'name': 'Premium',
      'price': 9.99,
      'priceText': '\$9.99',
      'duration': '/bulan',
      'color': Colors.purple,
      'features': [
        'Semua fitur Pro',
        'Prakiraan cuaca 30 hari',
        'Radar cuaca interaktif',
        'Analisis cuaca AI',
        'API access',
        'Priority support',
        'Data historis',
      ],
      'icon': Icons.stars,
    },
  ];

  ProPlanController({this.context});

  void setContext(BuildContext ctx) {
    context = ctx;
  }

  void notifyListeners() {
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }

  // ========== PLAN SELECTION ==========

  void selectPlan(int index) {
    selectedPlanIndex = index;
    notifyListeners();
  }

  Map<String, dynamic> get selectedPlan => plansUSD[selectedPlanIndex];

  // ========== CURRENCY CONVERSION ==========

  Future<String> getConvertedPrice(
    double usdPrice,
    String targetCurrency,
  ) async {
    if (targetCurrency == 'USD') {
      return '\$${usdPrice.toStringAsFixed(2)}';
    }

    try {
      final result = await currencyService.convertCurrency(
        'USD',
        targetCurrency,
        usdPrice,
      );
      print('🔍 API Response: $result');

      final convertedAmount =
          result['converted_amount'] ??
          result['result'] ??
          result['amount'] ??
          usdPrice;

      double finalAmount;
      if (convertedAmount is int) {
        finalAmount = convertedAmount.toDouble();
      } else if (convertedAmount is double) {
        finalAmount = convertedAmount;
      } else if (convertedAmount is String) {
        finalAmount = double.tryParse(convertedAmount) ?? usdPrice;
      } else {
        finalAmount = usdPrice;
      }

      final symbol = getCurrencySymbol(targetCurrency);
      if (targetCurrency == 'IDR' || targetCurrency == 'JPY') {
        String formatted = finalAmount.toStringAsFixed(0);
        return symbol + addThousandSeparator(formatted);
      } else {
        return symbol + finalAmount.toStringAsFixed(2);
      }
    } catch (e) {
      print('❌ Error converting currency: $e');
      return '\$${usdPrice.toStringAsFixed(2)}';
    }
  }

  String addThousandSeparator(String number) {
    final parts = number.split('.');
    final integerPart = parts[0];
    final buffer = StringBuffer();

    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    if (parts.length > 1) {
      buffer.write('.');
      buffer.write(parts[1]);
    }

    return buffer.toString();
  }

  String getCurrencySymbol(String currencyCode) {
    return availableCurrencies.firstWhere(
      (c) => c['code'] == currencyCode,
      orElse: () => {'symbol': '\$'},
    )['symbol']!;
  }

  // ========== SUBSCRIPTION ACTIONS ==========

  void handleSubscription() {
    if (selectedPlanIndex == 0) {
      // Free plan logic if needed
    } else {
      // Pro/Premium logic handled by dialog
    }
  }

  // LOGIC UPDATE PLAN DI SINI
  Future<void> confirmSubscription(String convertedPrice) async {
    if (context == null || !context!.mounted) return;

    final plan = selectedPlan;
    final planName = plan['name'] as String;

    try {
      // 1. Ambil username yang sedang login
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      if (username != null) {
        // 2. Update status plan di database
        await dbHelper.updateUserPlan(username, planName);

        // 3. Tampilkan sukses
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text(
              'Berlangganan $planName berhasil!\nAkses fitur premium telah dibuka.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception("User session not found");
      }
    } catch (e) {
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text('Gagal mengupdate plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ========== GETTERS ==========

  bool isPlanSelected(int index) => selectedPlanIndex == index;

  Color getSelectedPlanColor() => selectedPlan['color'] as Color;

  String getSubscribeButtonText() {
    return selectedPlanIndex == 0
        ? 'Gunakan Gratis'
        : 'Berlangganan ${selectedPlan['name']}';
  }
}
