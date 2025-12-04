import 'dart:async';
import 'dart:math' as math;

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
import 'package:finalproject/service/dbHelper.dart';
import 'package:flutter_compass/flutter_compass.dart';

class WeaterScreen extends ConsumerStatefulWidget {
  const WeaterScreen({super.key});

  @override
  ConsumerState<WeaterScreen> createState() => _WeaterScreenState();
}

class _WeaterScreenState extends ConsumerState<WeaterScreen> {
  final _weatherService = WeatherApiService();
  final DatabaseHelper dbHelper = DatabaseHelper();
  
  String city = "Jakarta";
  String country = '';
  Map<String, dynamic> currentValue = {};
  List<dynamic> hourly = [];
  bool isLoading = false;
  bool isLoadingLocation = false;
  String username = '';
  String userPlan = 'Basic'; 

  String selectedZone = 'WIB';
  late Timer _timer;
  late DateTime _currentTime;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  bool _enableNotifications = true;
  DateTime? _lastNotificationTime;
  
  Timer? _notificationDelayTimer;
  bool _allowNotification = false;
  static const int _notificationDelaySeconds = 5;

  // --- VARIABEL KOMPAS ---
  double? _heading = 0;
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _startClock();
    _initializeNotifications();
    _fetchWeather();
    _loadUserData();
    _startNotificationDelayTimer();
    _initCompass();
  }

  void _initCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          _heading = event.heading;
        });
      }
    });
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    _notificationDelayTimer?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }

  // Helper untuk mendapatkan teks arah mata angin
  String _getDirection(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    if (heading >= 292.5 && heading < 337.5) return 'NW';
    return 'N';
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('username') ?? 'Guest';
    
    String plan = 'Basic';
    if (user != 'Guest') {
      plan = await dbHelper.getUserPlan(user);
    }

    if (mounted) {
      setState(() {
        username = user;
        userPlan = plan;
      });
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

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

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        String detectedCity = 
                             place.subAdministrativeArea ?? 
                             place.administrativeArea ?? 
                             'Unknown';

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

          _fetchWeather();
        }
      } else {
        throw Exception('Tidak dapat menemukan nama kota');
      }

    } catch (e) {
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
  }

  void _startNotificationDelayTimer() {
    _allowNotification = false;
    
    _notificationDelayTimer?.cancel();
    _notificationDelayTimer = Timer(
      Duration(seconds: _notificationDelaySeconds),
      () {
        if (mounted) {
          setState(() {
            _allowNotification = true;
          });
          
          if (currentValue.isNotEmpty) {
            _checkWeatherAndNotify();
          }
        }
      },
    );
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
      },
    );
    
    await _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation
          .requestNotificationsPermission();
      
      if (granted == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Izinkan notifikasi di Settings untuk mendapat alert cuaca'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _showNotification(String title, String body) async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final bool? enabled = await androidImplementation.areNotificationsEnabled();
      
      if (enabled == false) {
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
      
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
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
    setState(() => isLoading = true);

    try {
      final forecast = await _weatherService.getHourlyForecast(city);

      setState(() {
        currentValue = forecast['current'] ?? {};
        country = forecast['location']?['country'] ?? '';
        hourly = forecast['forecast']?['forecastday']?[0]?['hour'] ?? [];
        isLoading = false;
      });

      if (_allowNotification) {
        _checkWeatherAndNotify();
      }
    } catch (e) {
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

  void _checkWeatherAndNotify() {
    if (currentValue.isEmpty || !_enableNotifications || !_allowNotification) {
      return;
    }

    if (_lastNotificationTime != null) {
      final difference = DateTime.now().difference(_lastNotificationTime!);
      if (difference.inMinutes < 2) {
        return;
      }
    }

    double? temp = currentValue['temp_c']?.toDouble();
    String condition =
        (currentValue['condition']?['text'] ?? '').toString().toLowerCase();

    bool notificationSent = false;

    if (temp != null) {
      if (temp > 35) {
        _showNotification(
          "Cuaca Panas 🔥",
          "Suhu di $city mencapai ${temp.toStringAsFixed(1)}°C, tetap terhidrasi ya!",
        );
        notificationSent = true;
      } else if (temp < 20) {
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
      _showNotification(
        "Perkiraan Cuaca 🌦️",
        "Saat ini di $city sedang ${currentValue['condition']?['text']}. Persiapkan payungmu!",
      );
      notificationSent = true;
    }

    if (notificationSent) {
      _lastNotificationTime = DateTime.now();
    }
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

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('💎 Fitur Premium', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Weather AI eksklusif untuk pengguna Premium. Upgrade sekarang untuk membuka akses!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PlanProPage()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Upgrade Premium', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                mainAxisSize: MainAxisSize.min,
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
                  Row(
                    children: [
                      Text(
                        'Plan: ',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: userPlan == 'Premium' 
                              ? Colors.purple
                              : userPlan == 'Pro' 
                                  ? Colors.orange 
                                  : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          userPlan,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 10,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 1,
                    color: Colors.white30,
                  ),
                ],
              ),
            ),
            
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
                  child: Icon(
                    userPlan == 'Premium' ? Icons.auto_awesome : Icons.lock,
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
                  if (userPlan != 'Premium') {
                    _showUpgradeDialog();
                    return;
                  }

                  if (currentValue.isEmpty) {
                    Navigator.pop(context);
                    
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
                  
                  if (currentValue['temp_c'] == null || 
                      currentValue['condition'] == null) {
                    Navigator.pop(context);
                    
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
                  
                  Navigator.pop(context);
                  
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      try {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WeatherAiPage(
                              weatherData: weatherDataForAI,
                              cityName: city,
                            ),
                          ),
                        ).then((value) {
                        }).catchError((error) {
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
                },
              ),
            ),
            
            const SizedBox(height: 5),
            
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white70),
              title: const Text(
                'Profile',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    try {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    } catch (e) {
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
            
            ListTile(
              leading: const Icon(Icons.money, color: Colors.white70),
              title: const Text(
                'Upgrade Pro',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    try {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const PlanProPage()),
                      );
                    } catch (e) {
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

            // ===== WIDGET KOMPAS (ROTATING CARD / KARTU BERPUTAR) =====
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.explore, color: Colors.orangeAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Compass",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. KARTU KOMPAS YANG BERPUTAR (N/S/E/W)
                          // Berputar berlawanan dengan arah heading HP (-heading)
                          Transform.rotate(
                            angle: ((_heading ?? 0) * (math.pi / 180) * -1),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
                                gradient: RadialGradient(
                                  colors: [Colors.black54, Colors.blueGrey.shade900],
                                ),
                              ),
                              child: Stack(
                                children: const [
                                  // Huruf N (Utara) - Selalu di "Atas" kartu
                                  Positioned(top: 8, left: 0, right: 0, child: Center(child: Text('N', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)))),
                                  // Huruf S (Selatan)
                                  Positioned(bottom: 8, left: 0, right: 0, child: Center(child: Text('S', style: TextStyle(color: Colors.white70)))),
                                  // Huruf E (Timur)
                                  Positioned(right: 8, top: 0, bottom: 0, child: Center(child: Text('E', style: TextStyle(color: Colors.white70)))),
                                  // Huruf W (Barat)
                                  Positioned(left: 8, top: 0, bottom: 0, child: Center(child: Text('W', style: TextStyle(color: Colors.white70)))),
                                ],
                              ),
                            ),
                          ),
                          
                          // 2. INDIKATOR PANAH DIAM (FIXED)
                          // Menunjuk ke arah hadap HP
                          const Icon(Icons.arrow_drop_up, color: Colors.orangeAccent, size: 50),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      _heading == null 
                          ? "Calibrating..." 
                          : "${_heading!.toStringAsFixed(0)}° ${_getDirection(_heading!)}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white30, thickness: 1),
            
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
        iconTheme: const IconThemeData(color: Colors.white),
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