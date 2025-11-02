import 'dart:convert';
import 'package:http/http.dart' as http;


const String apiKey = "4d8bf10a755243d0868174048253010";
// Hourly Forecast
class WeatherApiService {
  final String _baseUrl = "https://api.weatherapi.com/v1";
  Future<Map<String, dynamic>>getHourlyForecast(String location) async {
    final url = Uri.parse(
      "$_baseUrl/forecast.json?key=$apiKey&q=$location&days=7",
    );

    final res = await http.get(url);
    if (res.statusCode !=200) { 
      throw Exception("Failed to fetch data: ${res.body}");
    }
final data = json.decode(res.body);
if (data.containsKey('error')) {
  throw Exception(data['error']['message']??'Invalid Location');
}
return data;
  }
}

/// Service untuk memanggil API konversi dari backend Go.
class CurrencyService {
  final String baseUrl = "http://10.0.2.2:8080"; // untuk Android emulator

  Future<Map<String, dynamic>> convertCurrency(String from, String to, double amount) async {
    final url = Uri.parse('$baseUrl/convert?from=$from&to=$to&amount=$amount');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to convert currency');
    }
  }
}

