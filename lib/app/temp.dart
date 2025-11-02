import 'package:flutter/material.dart';
import 'package:finalproject/pages/weatherScreen.dart';
import 'package:finalproject/service/apiService.dart';

class PlanProPage extends StatefulWidget {
  const PlanProPage({super.key});

  @override
  State<PlanProPage> createState() => _PlanProPageState();
}

class _PlanProPageState extends State<PlanProPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int selectedPlanIndex = 1; // Default: Pro Plan
  
  // Currency Selection
  String selectedCurrency = 'USD';
  final CurrencyService currencyService = CurrencyService();
  
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  // Fungsi untuk mengkonversi harga menggunakan API service
  Future<String> _getConvertedPrice(double usdPrice, String targetCurrency) async {
    if (targetCurrency == 'USD') {
      return '\$${usdPrice.toStringAsFixed(2)}';
    }

    try {
      final result = await currencyService.convertCurrency('USD', targetCurrency, usdPrice);
      
      // Debug: Print response untuk melihat struktur data
      print('🔍 API Response: $result');
      
      // Perbaikan: Cek struktur data yang sebenarnya dari API
      final convertedAmount = result['converted_amount'] ?? 
                             result['result'] ?? 
                             result['amount'] ?? 
                             usdPrice;
      
      // Pastikan convertedAmount adalah double
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
      
      final symbol = _getCurrencySymbol(targetCurrency);
      
      // Format berdasarkan currency
      if (targetCurrency == 'IDR' || targetCurrency == 'JPY') {
        // Untuk IDR dan JPY, tanpa desimal dan dengan separator
        String formatted = finalAmount.toStringAsFixed(0);
        return symbol + _addThousandSeparator(formatted);
      } else {
        // Untuk currency lain, dengan 2 desimal
        return symbol + finalAmount.toStringAsFixed(2);
      }
    } catch (e) {
      print('❌ Error converting currency: $e');
      // Fallback ke USD jika konversi gagal
      return '\$${usdPrice.toStringAsFixed(2)}';
    }
  }
  
  String _addThousandSeparator(String number) {
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

  String _getCurrencySymbol(String currencyCode) {
    return availableCurrencies.firstWhere(
      (c) => c['code'] == currencyCode,
      orElse: () => {'symbol': '\$'},
    )['symbol']!;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => WeaterScreen()),
                );
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepPurple.shade900,
                      Colors.orange.shade800,
                      Colors.pink.shade700,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.workspace_premium,
                        size: 60,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upgrade ke Pro',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nikmati pengalaman cuaca premium',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    ...List.generate(plansUSD.length, (index) {
                      return _buildPlanCard(plansUSD[index], index);
                    }),
                    const SizedBox(height: 32),
                    _buildSubscribeButton(),
                    const SizedBox(height: 24),
                    _buildFeaturesComparison(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, int index) {
    final isSelected = selectedPlanIndex == index;
    final color = plan['color'] as Color;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlanIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.3),
                    color.withOpacity(0.1),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          plan['icon'] as IconData,
                          color: color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan['name'] as String,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    plan['price'] == 0.0 
                                        ? 'Gratis' 
                                        : plan['priceText'] as String,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if ((plan['duration'] as String) != 'Selamanya')
                                  Text(
                                    plan['duration'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),
                  ...List.generate(
                    (plan['features'] as List<String>).length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              plan['features'][i] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (plan['badge'] != null)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    plan['badge'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton() {
    final selectedPlan = plansUSD[selectedPlanIndex];
    final color = selectedPlan['color'] as Color;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          _showSubscribeDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          selectedPlanIndex == 0 
              ? 'Gunakan Gratis' 
              : 'Berlangganan ${selectedPlan['name']}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesComparison() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orangeAccent, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Mengapa Upgrade?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildComparisonItem(
            Icons.schedule,
            'Akurasi Tinggi',
            'Data cuaca realtime dari berbagai sumber terpercaya',
          ),
          _buildComparisonItem(
            Icons.notifications_active,
            'Alert Cuaca',
            'Notifikasi otomatis untuk cuaca ekstrem',
          ),
          _buildComparisonItem(
            Icons.analytics,
            'Analisis Mendalam',
            'Laporan cuaca detail dengan grafik interaktif',
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.orangeAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscribeDialog() {
    final selectedPlan = plansUSD[selectedPlanIndex];
    final double usdPrice = selectedPlan['price'] as double;
    final color = selectedPlan['color'] as Color;
    
    if (selectedPlanIndex == 0) {
      _showFreePlanDialog(selectedPlan, color);
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => CurrencyConverterDialog(
        selectedPlan: selectedPlan,
        usdPrice: usdPrice,
        color: color,
        availableCurrencies: availableCurrencies,
        currencyService: currencyService,
        getCurrencySymbol: _getCurrencySymbol,
        addThousandSeparator: _addThousandSeparator,
        getConvertedPrice: _getConvertedPrice, // Tambahkan ini
      ),
    );
  }

  void _showFreePlanDialog(Map<String, dynamic> plan, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              color: color,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Selamat Menggunakan!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Anda menggunakan plan Basic secara gratis',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrencyConverterDialog extends StatefulWidget {
  final Map<String, dynamic> selectedPlan;
  final double usdPrice;
  final Color color;
  final List<Map<String, String>> availableCurrencies;
  final CurrencyService currencyService;
  final String Function(String) getCurrencySymbol;
  final String Function(String) addThousandSeparator;
  final Future<String> Function(double, String) getConvertedPrice; // Tambahkan ini

  const CurrencyConverterDialog({
    Key? key,
    required this.selectedPlan,
    required this.usdPrice,
    required this.color,
    required this.availableCurrencies,
    required this.currencyService,
    required this.getCurrencySymbol,
    required this.addThousandSeparator,
    required this.getConvertedPrice, // Tambahkan ini
  }) : super(key: key);

  @override
  State<CurrencyConverterDialog> createState() => _CurrencyConverterDialogState();
}

class _CurrencyConverterDialogState extends State<CurrencyConverterDialog> {
  String selectedCurrency = 'USD';
  String convertedPrice = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _convertPrice();
  }

  Future<void> _convertPrice() async {
    if (selectedCurrency == 'USD') {
      setState(() {
        convertedPrice = '\$${widget.usdPrice.toStringAsFixed(2)}';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Gunakan fungsi getConvertedPrice yang sudah diperbaiki
      final result = await widget.getConvertedPrice(widget.usdPrice, selectedCurrency);
      
      setState(() {
        convertedPrice = result;
        isLoading = false;
      });
      
      print('✅ Converted price: $convertedPrice');
    } catch (e) {
      print('❌ Error converting currency: $e');
      setState(() {
        convertedPrice = '\$${widget.usdPrice.toStringAsFixed(2)}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade800,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.currency_exchange,
                    color: widget.color,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Konfirmasi Langganan',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.selectedPlan['name']} Plan',
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payments,
                            color: Colors.orangeAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Pilih Mata Uang Pembayaran',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.color.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCurrency,
                            isExpanded: true,
                            dropdownColor: Colors.grey.shade900,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: widget.color,
                            ),
                            items: widget.availableCurrencies.map((currency) {
                              return DropdownMenuItem<String>(
                                value: currency['code'],
                                child: Row(
                                  children: [
                                    Text(
                                      currency['symbol']!,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: widget.color,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      currency['code']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        currency['name']!,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedCurrency = newValue;
                                });
                                _convertPrice();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.color.withOpacity(0.2),
                              widget.color.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (isLoading)
                              SizedBox(
                                height: 32,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                                  ),
                                ),
                              )
                            else
                              Text(
                                '$convertedPrice${widget.selectedPlan['duration']}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: widget.color,
                                ),
                              ),
                            if (selectedCurrency != 'USD' && !isLoading)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '≈ \$${widget.usdPrice.toStringAsFixed(2)} USD',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Berlangganan ${widget.selectedPlan['name']} berhasil!\nPembayaran: $convertedPrice${widget.selectedPlan['duration']}',
                              ),
                              backgroundColor: widget.color,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                        child: const Text(
                          'Konfirmasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}