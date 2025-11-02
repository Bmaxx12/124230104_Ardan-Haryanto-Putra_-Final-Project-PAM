import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Inisialisasi notifikasi
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Request permission untuk Android 13+ dan iOS
  Future<bool> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  // Handler ketika notifikasi di-tap
  void _onNotificationTapped(NotificationResponse response) {
    // Bisa ditambahkan logika navigasi atau aksi lain
    print('Notification tapped: ${response.payload}');
  }

  // Tampilkan notifikasi sederhana
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('🔔 Attempting to show notification:');
    print('   ID: $id');
    print('   Title: $title');
    print('   Body: $body');
    
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'weather_channel_id',
        'Weather Alerts',
        channelDescription: 'Notifications for weather updates and alerts',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      print('✅ Notification sent successfully!');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  // Notifikasi untuk cuaca panas
  Future<void> showHotWeatherAlert(String city, double temp) async {
    await showNotification(
      id: 1,
      title: "Cuaca Panas 🔥",
      body:
          "Suhu di $city mencapai ${temp.toStringAsFixed(1)}°C, tetap terhidrasi ya!",
      payload: 'hot_weather',
    );
  }

  // Notifikasi untuk cuaca dingin
  Future<void> showColdWeatherAlert(String city, double temp) async {
    await showNotification(
      id: 2,
      title: "Cuaca Dingin ❄️",
      body:
          "Suhu di $city cukup rendah (${temp.toStringAsFixed(1)}°C), jangan lupa jaket!",
      payload: 'cold_weather',
    );
  }

  // Notifikasi untuk kondisi cuaca khusus (hujan, badai, dll)
  Future<void> showWeatherConditionAlert(
      String city, String condition) async {
    String emoji = '🌦️';
    String message = "Persiapkan payungmu!";

    if (condition.toLowerCase().contains('rain')) {
      emoji = '🌧️';
      message = "Persiapkan payungmu!";
    } else if (condition.toLowerCase().contains('storm')) {
      emoji = '⛈️';
      message = "Hati-hati di luar!";
    } else if (condition.toLowerCase().contains('cloud')) {
      emoji = '☁️';
      message = "Langit tampak mendung.";
    }

    await showNotification(
      id: 3,
      title: "Perkiraan Cuaca $emoji",
      body: "Saat ini di $city sedang $condition. $message",
      payload: 'weather_condition',
    );
  }

  // Batalkan notifikasi tertentu
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Batalkan semua notifikasi
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // Cek apakah notifikasi diizinkan
  Future<bool> areNotificationsEnabled() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }

    return true;
  }
}