import 'dart:async';

import 'package:finalproject/pages/profile.dart';
import 'package:finalproject/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finalproject/pages/konversiKurs.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finalproject/pages/weatherAiScreen.dart';

class WeaterScreen extends ConsumerStatefulWidget {
  const WeaterScreen({super.key});

  @override
  ConsumerState<WeaterScreen> createState() => _WeaterScreenState();
}

class _WeaterScreenState extends ConsumerState<WeaterScreen> {
  final _weatherService = WeatherApiService();
  String city = "Jakarta";
  String country = '';
  Map<String, dynamic> currentValue = {};
  List<dynamic> hourly = [];
  bool isLoading = false;
  bool isLoadingLocation = false;
  String username = '';

  // Untuk waktu & zona
  String selectedZone = 'WIB';
  late Timer _timer;
  late DateTime _currentTime;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Notifikasi
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Kontrol notifikasi
  bool _enableNotifications = true;
  DateTime? _lastNotificationTime;
  
  // Timer untuk delay notifikasi setelah kembali ke halaman
  Timer? _notificationDelayTimer;
  bool _allowNotification = false;
  static const int _notificationDelaySeconds = 5;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _startClock();
    _initializeNotifications();
    _fetchWeather();
    _loadUsername();
    
    // Set timer untuk mengizinkan notifikasi setelah 5 detik
    _startNotificationDelayTimer();
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    _notificationDelayTimer?.cancel();
    super.dispose();
  }

  // Load username dari SharedPreferences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Guest';
    });
  }

  // ========== FITUR GEOLOKASI BARU ==========
  
  /// Cek dan request permission lokasi
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah GPS aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 GPS tidak aktif. Silakan aktifkan GPS Anda.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    // Cek permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Izin lokasi ditolak'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Izin lokasi ditolak permanen. Aktifkan di Settings.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return false;
    }

    return true;
  }

  /// Dapatkan lokasi saat ini dan update cuaca
  Future<void> _getCurrentLocation() async {
    print('\n📍 === GETTING CURRENT LOCATION ===');
    
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // Cek permission dulu
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      // Dapatkan posisi
      print('🌍 Getting position...');
      Position position = await Geolocator.getCurrentPosition(
      );

      print('✅ Position obtained: ${position.latitude}, ${position.longitude}');

      // Reverse geocoding untuk mendapatkan nama kota
      print('🏙️ Getting city name...');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Prioritas: locality > subAdministrativeArea > administrativeArea
        String detectedCity = 
                             place.subAdministrativeArea ?? 
                             place.administrativeArea ?? 
                             'Unknown';

        print('✅ Detected city: $detectedCity');
        print('   Country: ${place.country}');
        print('   Admin Area: ${place.administrativeArea}');

        if (mounted) {
          setState(() {
            city = detectedCity;
            isLoadingLocation = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 Lokasi terdeteksi: $detectedCity'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green.shade700,
            ),
          );

          // Fetch weather untuk lokasi baru
          _fetchWeather();
        }
      } else {
        throw Exception('Tidak dapat menemukan nama kota');
      }

    } catch (e) {
      print('❌ Error getting location: $e');
      
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });

        String errorMessage = '❌ Gagal mendapatkan lokasi';
        
        if (e.toString().contains('timeout')) {
          errorMessage = '⏱️ Timeout: Pastikan GPS aktif dan sinyal baik';
        } else if (e.toString().contains('permission')) {
          errorMessage = '🔒 Izinkan akses lokasi untuk fitur ini';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
    
    print('=== END GETTING LOCATION ===\n');
  }

  // ========== END FITUR GEOLOKASI ==========

  // Timer untuk delay notifikasi
  void _startNotificationDelayTimer() {
    print('⏳ Starting notification delay timer ($_notificationDelaySeconds seconds)...');
    _allowNotification = false;
    
    _notificationDelayTimer?.cancel();
    _notificationDelayTimer = Timer(
      Duration(seconds: _notificationDelaySeconds),
      () {
        if (mounted) {
          setState(() {
            _allowNotification = true;
          });
          print('✅ Notification timer completed. Notifications now allowed.');
          
          if (currentValue.isNotEmpty) {
            _checkWeatherAndNotify();
          }
        }
      },
    );
  }

  // Inisialisasi notifikasi
  Future<void> _initializeNotifications() async {
    print('🔔 Initializing notifications...');
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📬 Notification tapped: ${response.payload}');
      },
    );
    
    print('✅ Notifications initialized: $initialized');
    
    await _requestNotificationPermission();
  }

  // Request permission
  Future<void> _requestNotificationPermission() async {
    print('🔐 Requesting notification permission...');
    
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation
          .requestNotificationsPermission();
      print('🔐 Permission granted: $granted');
      
      if (granted == false) {
        print('⚠️ Notification permission denied!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Izinkan notifikasi di Settings untuk mendapat alert cuaca'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      print('⚠️ Android implementation is null');
    }
  }

  // Tampilkan notifikasi
  Future<void> _showNotification(String title, String body) async {
    print('\n🔔 === SHOWING NOTIFICATION ===');
    print('Title: $title');
    print('Body: $body');
    
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final bool? enabled = await androidImplementation.areNotificationsEnabled();
      print('Notifications Enabled in System: $enabled');
      
      if (enabled == false) {
        print('❌ Notifications are disabled in system settings!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Notifikasi dinonaktifkan. Aktifkan di Settings!'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'weather_channel_id',
      'Weather Alerts',
      channelDescription: 'Notifications for weather updates and alerts',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      showWhen: true,
      ticker: 'Weather Update',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    try {
      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('Notification ID: $notificationId');
      
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
      );
      
      print('✅ Notification sent successfully!');
      print('=== END NOTIFICATION ===\n');
    } catch (e) {
      print('❌ Error sending notification: $e');
      print('Error details: ${e.toString()}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  Future<void> _fetchWeather() async {
    print('\n🌍 Fetching weather for: $city');
    setState(() => isLoading = true);

    try {
      final forecast = await _weatherService.getHourlyForecast(city);

      setState(() {
        currentValue = forecast['current'] ?? {};
        country = forecast['location']?['country'] ?? '';
        hourly = forecast['forecast']?['forecastday']?[0]?['hour'] ?? [];
        isLoading = false;
      });

      print('✅ Weather data fetched successfully');
      print('📍 Location: $city, $country');
      print('🌡️ Temperature: ${currentValue['temp_c']}°C');
      
      if (_allowNotification) {
        _checkWeatherAndNotify();
      } else {
        print('⏳ Notification delayed. Timer still running.');
      }
    } catch (e) {
      print('❌ Error fetching weather: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('City not found or invalid')),
        );
      }
      setState(() {
        isLoading = false;
        currentValue = {};
        hourly = [];
      });
    }
  }

  // Cek kondisi & tampilkan notifikasi otomatis
  void _checkWeatherAndNotify() {
    print('\n🔍 === CHECK WEATHER AND NOTIFY ===');
    print('Current Value Empty: ${currentValue.isEmpty}');
    print('Notifications Enabled: $_enableNotifications');
    print('Allow Notification (Timer): $_allowNotification');
    
    if (currentValue.isEmpty || !_enableNotifications || !_allowNotification) {
      print('❌ Skipped: ${currentValue.isEmpty ? "No data" : !_enableNotifications ? "Notifications disabled" : "Timer not completed"}');
      return;
    }

    if (_lastNotificationTime != null) {
      final difference = DateTime.now().difference(_lastNotificationTime!);
      if (difference.inMinutes < 2) {
        print('⏳ Cooldown active. Time since last: ${difference.inSeconds}s');
        return;
      }
    }

    double? temp = currentValue['temp_c']?.toDouble();
    String condition =
        (currentValue['condition']?['text'] ?? '').toString().toLowerCase();

    print('🌡️ Temperature: $temp°C');
    print('☁️ Condition: $condition');

    bool notificationSent = false;

    if (temp != null) {
      if (temp > 35) {
        print('🔥 HOT WEATHER DETECTED');
        _showNotification(
          "Cuaca Panas 🔥",
          "Suhu di $city mencapai ${temp.toStringAsFixed(1)}°C, tetap terhidrasi ya!",
        );
        notificationSent = true;
      } else if (temp < 20) {
        print('❄️ COLD WEATHER DETECTED');
        _showNotification(
          "Cuaca Dingin ❄️",
          "Suhu di $city cukup rendah (${temp.toStringAsFixed(1)}°C), jangan lupa jaket!",
        );
        notificationSent = true;
      }
    }

    if (!notificationSent &&
        (condition.contains("rain") ||
            condition.contains("storm") ||
            condition.contains("cloud"))) {
      print('🌧️ SPECIAL WEATHER CONDITION DETECTED');
      _showNotification(
        "Perkiraan Cuaca 🌦️",
        "Saat ini di $city sedang ${currentValue['condition']?['text']}. Persiapkan payungmu!",
      );
      notificationSent = true;
    }

    if (notificationSent) {
      _lastNotificationTime = DateTime.now();
      print('✅ Notification sent and timestamp updated');
    } else {
      print('ℹ️ No notification conditions met (temp: $temp°C)');
    }
    
    print('=== END CHECK ===\n');
  }

  String formatTimeWithZone(DateTime time) {
    int offset = 7;
    if (selectedZone == 'WITA') offset = 8;
    if (selectedZone == 'WIT') offset = 9;
    if (selectedZone == 'London') offset = 0;
    if (selectedZone == 'Paris') offset = 1;

    DateTime adjustedTime = time.toUtc().add(Duration(hours: offset));
    return DateFormat('HH:mm').format(adjustedTime);
  }

  String formateTime(String timeString) {
    DateTime time = DateTime.parse(timeString);
    return DateFormat.j().format(time);
  }

  @override
  Widget build(BuildContext context) {
    String iconPath = currentValue['condition']?['icon'] ?? '';
    String imageUrl = iconPath.isNotEmpty ? "https:$iconPath" : "";

    Widget imageWidgets = imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            height: 200,
            width: 200,
            fit: BoxFit.cover,
          )
        : const SizedBox();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      drawer: Drawer(
  backgroundColor: Colors.black87,
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      // ===== DRAWER HEADER =====
     Container(
  padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0x73000000), Color.fromARGB(255, 255, 154, 22)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min, // biar tinggi pas isi aja
    children: [
      Text(
        'Welcome, $username!',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Ini aplikasi forecasting cuaca!',
        style: TextStyle(color: Colors.white60, fontSize: 13),
      ),
      const SizedBox(height: 6),
      Container(
        height: 1,
        color: Colors.white30, // garis pemisah halus
      ),
    ],
  ),
),

      
      // ===== WEATHER AI MENU - FIXED =====
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color.fromARGB(255, 255, 178, 25), Color.fromARGB(255, 255, 137, 19)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D1565C0),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: const Text(
            'Weather AI',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: const Text(
            'Tanya AI tentang cuaca',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white70,
            size: 16,
          ),
          onTap: () {
            print('\n🤖 === WEATHER AI CLICKED ===');
            print('Current Value: $currentValue');
            print('City: $city');
            print('Country: $country');
            
            // Validasi data cuaca
            if (currentValue.isEmpty) {
              print('❌ Weather data is empty!');
              Navigator.pop(context); // Tutup drawer dulu
              
              // Delay untuk menunggu drawer tertutup
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Data cuaca belum tersedia. Cari kota terlebih dahulu!'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              });
              return;
            }
            
            // Validasi data yang diperlukan
            if (currentValue['temp_c'] == null || 
                currentValue['condition'] == null) {
              print('❌ Incomplete weather data!');
              Navigator.pop(context); // Tutup drawer dulu
              
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Data cuaca tidak lengkap. Coba refresh data!'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              });
              return;
            }
            
            print('✅ Weather data validated. Preparing navigation...');
            
            // Buat weather data yang aman
            final weatherDataForAI = {
              'current': {
                'temp_c': currentValue['temp_c'] ?? 0,
                'condition': {
                  'text': currentValue['condition']?['text'] ?? 'Unknown',
                  'icon': currentValue['condition']?['icon'] ?? '',
                },
                'humidity': currentValue['humidity'] ?? 0,
                'wind_kph': currentValue['wind_kph'] ?? 0,
                'feelslike_c': currentValue['feelslike_c'] ?? 0,
              },
              'location': {
                'name': city,
                'country': country.isNotEmpty ? country : 'Unknown',
              },
            };
            
            print('📊 Weather data prepared: $weatherDataForAI');
            
            // KUNCI: Tutup drawer DULU
            Navigator.pop(context);
            
            // LALU navigate dengan delay untuk memastikan drawer tertutup
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                try {
                  print('🚀 Navigating to Weather AI page...');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WeatherAiPage(
                        weatherData: weatherDataForAI,
                        cityName: city,
                      ),
                    ),
                  ).then((value) {
                    print('🔙 Returned from AI page');
                  }).catchError((error) {
                    print('❌ Navigation error: $error');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error: $error'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  });
                } catch (e) {
                  print('❌ Exception during navigation: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error membuka AI: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              }
            });
            
            print('=== END WEATHER AI CLICK ===\n');
          },
        ),
      ),
      
      const SizedBox(height: 5),
      
      // ===== PROFILE MENU - FIXED =====
      ListTile(
        leading: const Icon(Icons.person, color: Colors.white70),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        onTap: () {
          print('👤 Profile clicked');
          
          // Tutup drawer dulu
          Navigator.pop(context);
          
          // Lalu navigate dengan delay
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              try {
                print('🚀 Navigating to Profile page...');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              } catch (e) {
                print('❌ Profile navigation error: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            }
          });
        },
      ),
      
      // ===== UPGRADE PRO MENU - FIXED =====
      ListTile(
        leading: const Icon(Icons.money, color: Colors.white70),
        title: const Text(
          'Upgrade Pro',
          style: TextStyle(color: Colors.white),
        ),
        onTap: () {
          print('💎 Upgrade Pro clicked');
          
          // Tutup drawer dulu
          Navigator.pop(context);
          
          // Lalu navigate dengan delay
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              try {
                print('🚀 Navigating to PlanPro page...');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PlanProPage()),
                );
              } catch (e) {
                print('❌ PlanPro navigation error: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            }
          });
        },
      ),
      
      const Divider(color: Colors.white30, thickness: 1),
      
      // ===== INFO FOOTER =====
      const Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud, color: Colors.blue, size: 16),
                SizedBox(width: 5),
                Text(
                  'Weather App v1.0',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Text(
              'Powered by Gemini AI',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
      appBar: AppBar(
        backgroundColor: Colors.black45,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: TextField(
                  onSubmitted: (value) {
                    if (value.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a city')),
                      );
                      return;
                    }
                    setState(() {
                      city = value.trim();
                    });
                    _fetchWeather();
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search City",
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.black26,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 15),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // ========== TOMBOL GEOLOKASI BARU ==========
            IconButton(
              onPressed: isLoadingLocation ? null : _getCurrentLocation,
              icon: isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location),
              color: Colors.white,
              tooltip: 'Gunakan Lokasi Saat Ini',
            ),
            // ========== END TOMBOL GEOLOKASI ==========
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatTimeWithZone(_currentTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                DropdownButton<String>(
                  value: selectedZone,
                  dropdownColor: Colors.black87,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: 'WIB',
                      child: Text('WIB'),
                    ),
                    DropdownMenuItem(
                      value: 'WITA',
                      child: Text('WITA'),
                    ),
                    DropdownMenuItem(
                      value: 'WIT',
                      child: Text('WIT'),
                    ),
                     DropdownMenuItem(
                      value: 'London',
                      child: Text('London'),
                    ),
                     DropdownMenuItem(
                      value: 'Paris',
                      child: Text('Paris'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedZone = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (currentValue.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "$city${country.isNotEmpty ? '-$country' : ''}",
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        "${currentValue['temp_c']}°C",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${currentValue['condition']?['text'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white30,
                        ),
                      ),
                      imageWidgets,
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Container(
                          height: 100,
                          width: double.maxFinite,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.white10,
                                offset: Offset(2, 2),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    "https://cdn-icons-png.flaticon.com/256/4148/4148460.png",
                                    width: 30,
                                    height: 30,
                                  ),
                                  Text(
                                    "${currentValue['humidity']}%",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    "Humidity",
                                    style: TextStyle(color: Colors.white),
                                  )
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    "https://cdn-icons-png.flaticon.com/512/5918/5918654.png",
                                    width: 30,
                                    height: 30,
                                  ),
                                  Text(
                                    "${currentValue['wind_kph']} kph",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    "Wind",
                                    style: TextStyle(color: Colors.white),
                                  )
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    "https://cdn-icons-png.flaticon.com/512/6281/6281340.png",
                                    width: 30,
                                    height: 30,
                                  ),
                                  Text(
                                    "${hourly.isNotEmpty ? hourly.map((h) => h['temp_c']).reduce((a, b) => a > b ? a : b) : "N/A"}°",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    "Max Temp",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        height: 250,
                        width: double.maxFinite,
                        decoration: const BoxDecoration(
                          border:
                              Border(top: BorderSide(color: Colors.white30)),
                          borderRadius: BorderRadiusDirectional.vertical(
                              top: Radius.circular(40)),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Center(
                                child: Text(
                                  "Today Forecast",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white30),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 150,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: hourly.length,
                                itemBuilder: (context, index) {
                                  final hour = hourly[index];
                                  final now = DateTime.now();
                                  final hourTime = DateTime.parse(hour['time']);
                                  final isCurrentHour = now.hour == hourTime.hour &&
                                      now.day == hourTime.day;

                                  return Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Container(
                                      width: 80,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isCurrentHour
                                            ? Colors.orange
                                            : Colors.black38,
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isCurrentHour
                                                ? "Now"
                                                : formateTime(hour['time']),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Image.network(
                                            "https:${hour['condition']?['icon']}",
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "${hour['temp_c']}°C",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}