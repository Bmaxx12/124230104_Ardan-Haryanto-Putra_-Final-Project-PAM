import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiKey = "4d8bf10a755243d0868174048253010";
const String geminiApiKey = "AIzaSyDzscGsOwfxKsFKtt5t5wUJyhA2OYeWUvA";

// Hourly Forecast
class WeatherApiService {
  final String _baseUrl = "https://api.weatherapi.com/v1";
  
  Future<Map<String, dynamic>> getHourlyForecast(String location) async {
    final url = Uri.parse(
      "$_baseUrl/forecast.json?key=$apiKey&q=$location&days=7",
    );

    final res = await http.get(url);
    if (res.statusCode != 200) { 
      throw Exception("Failed to fetch data: ${res.body}");
    }
    
    final data = json.decode(res.body);
    if (data.containsKey('error')) {
      throw Exception(data['error']['message'] ?? 'Invalid Location');
    }
    return data;
  }
}

// Gemini AI Service
class GeminiAIService {
  // Gunakan model TANPA thinking mode - gemini-2.0-flash
  final String _baseUrl = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent";
  
  Future<String> getWeatherInsight(String prompt, Map<String, dynamic> weatherData) async {
    try {
      // Format data cuaca untuk konteks AI
      String weatherContext = """
Kamu adalah asisten cuaca yang membantu. Berikan jawaban dalam bahasa Indonesia yang informatif dan ramah.

Data Cuaca Saat Ini:
- Lokasi: ${weatherData['location']?['name']}, ${weatherData['location']?['country']}
- Suhu: ${weatherData['current']?['temp_c']}°C
- Kondisi: ${weatherData['current']?['condition']?['text']}
- Kelembaban: ${weatherData['current']?['humidity']}%
- Kecepatan Angin: ${weatherData['current']?['wind_kph']} kph
- Terasa Seperti: ${weatherData['current']?['feelslike_c']}°C
- Indeks UV: ${weatherData['current']?['uv']}

Pertanyaan User: $prompt

Berikan jawaban yang singkat, jelas, dan praktis.
""";

      final url = Uri.parse("$_baseUrl?key=$geminiApiKey");
      
      print('🔵 Mengirim request ke Gemini API...');
      print('URL: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "contents": [
            {
              "parts": [
                {
                  "text": weatherContext
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 1024,
            "topP": 0.95,
            "topK": 40
          },
          "safetySettings": [
            {
              "category": "HARM_CATEGORY_HARASSMENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            }
          ]
        }),
      );

      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Print full response untuk debugging
        print('📦 Full Response: ${json.encode(data)}');
        
        // Cek apakah ada error dalam response
        if (data.containsKey('error')) {
          print('❌ Error dari API: ${data['error']}');
          throw Exception('API Error: ${data['error']['message']}');
        }
        
        // Debug: Print struktur data lengkap
        print('🔍 Response Keys: ${data.keys.toList()}');
        
        // Extract text dari response
        try {
          if (data['candidates'] != null && data['candidates'] is List && data['candidates'].isNotEmpty) {
            print('🔍 Candidates length: ${data['candidates'].length}');
            
            final candidate = data['candidates'][0];
            print('🔍 Candidate keys: ${candidate.keys.toList()}');
            
            // Cek apakah candidate di-block karena safety atau max tokens
            if (candidate.containsKey('finishReason')) {
              print('🔍 Finish Reason: ${candidate['finishReason']}');
              
              if (candidate['finishReason'] == 'SAFETY') {
                return 'Maaf, respons diblokir karena alasan keamanan. Silakan ajukan pertanyaan dengan cara lain.';
              }
              
              if (candidate['finishReason'] == 'MAX_TOKENS') {
                print('⚠️ Response terpotong karena MAX_TOKENS');
                // Tetap coba extract text jika ada
              }
            }
            
            // Extract content
            if (candidate['content'] != null) {
              print('🔍 Content keys: ${candidate['content'].keys.toList()}');
              
              final content = candidate['content'];
              if (content['parts'] != null && content['parts'] is List && content['parts'].isNotEmpty) {
                print('🔍 Parts length: ${content['parts'].length}');
                
                final part = content['parts'][0];
                print('🔍 Part keys: ${part.keys.toList()}');
                
                if (part['text'] != null) {
                  final text = part['text'].toString();
                  print('✅ Berhasil extract text (${text.length} chars)');
                  print('📝 Preview: ${text.substring(0, text.length > 150 ? 150 : text.length)}...');
                  return text;
                } else {
                  print('❌ Part tidak memiliki key "text"');
                }
              } else {
                print('❌ Content tidak memiliki "parts" atau kosong');
              }
            } else {
              print('❌ Candidate tidak memiliki "content"');
            }
          } else {
            print('❌ Tidak ada candidates atau bukan List');
          }
          
          // Jika sampai sini, berarti gagal extract
          print('⚠️ Gagal extract text dari response');
          print('⚠️ Full data structure:');
          print(const JsonEncoder.withIndent('  ').convert(data));
          
          return 'Maaf, tidak dapat memproses respons AI. Silakan coba lagi atau hubungi developer.';
          
        } catch (e, stackTrace) {
          print('❌ Exception saat parsing: $e');
          print('❌ Stack trace: $stackTrace');
          return 'Error parsing response: $e';
        }
      } else if (response.statusCode == 400) {
        print('❌ Bad Request: ${response.body}');
        final errorData = json.decode(response.body);
        return 'Error 400: ${errorData['error']?['message'] ?? 'Request tidak valid'}';
      } else if (response.statusCode == 403) {
        print('❌ API Key Invalid atau Quota Habis');
        return 'API Key tidak valid atau quota Gemini API sudah habis. Silakan periksa API key Anda.';
      } else if (response.statusCode == 429) {
        print('❌ Rate Limit Exceeded');
        return 'Terlalu banyak request. Silakan tunggu beberapa saat.';
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in GeminiAIService: $e');
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('ClientException')) {
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      }
      
      return 'Maaf, terjadi kesalahan: ${e.toString()}. Silakan coba lagi.';
    }
  }
  
  Future<String> getWeatherRecommendation(Map<String, dynamic> weatherData) async {
    String prompt = """
Berikan rekomendasi praktis untuk cuaca hari ini dalam format:

🎯 Aktivitas yang Cocok:
[sebutkan 2-3 aktivitas]

👔 Rekomendasi Pakaian:
[jelaskan pakaian yang sesuai]

💡 Tips Kesehatan:
[berikan 1-2 tips kesehatan]

Jawab dalam bahasa Indonesia yang mudah dipahami dan ringkas.
""";
    
    return await getWeatherInsight(prompt, weatherData);
  }
}

class CurrencyService {
  final String baseUrl = "http://10.0.2.2:8080"; 

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