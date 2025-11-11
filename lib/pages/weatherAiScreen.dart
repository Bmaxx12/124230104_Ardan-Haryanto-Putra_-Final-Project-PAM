import 'package:flutter/material.dart';
import 'package:finalproject/service/apiService.dart';
import 'package:finalproject/pages/weatherScreen.dart';


class WeatherAiPage extends StatefulWidget {
  final Map<String, dynamic> weatherData;
  final String cityName;

  const WeatherAiPage({
    super.key,
    required this.weatherData,
    required this.cityName,
  });

  @override
  State<WeatherAiPage> createState() => _WeatherAiPageState();
}

class _WeatherAiPageState extends State<WeatherAiPage> {
  final GeminiAIService _aiService = GeminiAIService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> messages = [];
  bool isLoading = false;
  bool showSuggestions = true;

  final List<String> suggestionQuestions = [
    "Apa saran aktivitas untuk cuaca ini?",
    "Pakaian apa yang cocok untuk hari ini?",
    "Apakah aman untuk olahraga outdoor?",
    "Bagaimana prediksi cuaca hari ini?",
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialRecommendation();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialRecommendation() async {
    setState(() {
      messages.add(ChatMessage(
        text: "Halo! 👋 Saya Weather AI Assistant. Saya siap membantu Anda dengan informasi cuaca di ${widget.cityName}.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
      isLoading = true;
    });

    try {
      final recommendation = await _aiService.getWeatherRecommendation(widget.weatherData);
      
      setState(() {
        messages.add(ChatMessage(
          text: recommendation,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        isLoading = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        messages.add(ChatMessage(
          text: "Maaf, terjadi kesalahan saat memuat rekomendasi awal.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String question) async {
    if (question.trim().isEmpty) return;

    setState(() {
      showSuggestions = false;
      messages.add(ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      isLoading = true;
    });

    _questionController.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.getWeatherInsight(question, widget.weatherData);
      
      setState(() {
        messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        isLoading = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        messages.add(ChatMessage(
          text: "Maaf, saya tidak dapat menjawab pertanyaan Anda saat ini. Silakan coba lagi.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
  backgroundColor: Colors.black45,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WeaterScreen()),
      );
    },
  ),
  title: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 12),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Powered by Gemini',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ],
  ),
),

      body: Column(
        children: [
          // Weather Info Card
          Container(
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade900.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.weatherData['current']?['condition']?['icon'] != null)
                  Image.network(
                    "https:${widget.weatherData['current']['condition']['icon']}",
                    width: 60,
                    height: 60,
                  ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cityName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${widget.weatherData['current']?['temp_c']}°C • ${widget.weatherData['current']?['condition']?['text']}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: messages[index]);
              },
            ),
          ),

          // Suggestion Chips
          if (showSuggestions && messages.length <= 2)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: suggestionQuestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        suggestionQuestions[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.blue.shade900,
                      side: BorderSide(color: Colors.blue.shade700),
                      onPressed: () => _sendMessage(suggestionQuestions[index]),
                    ),
                  );
                },
              ),
            ),

          // Loading Indicator
          if (isLoading)
            Container(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue.shade400,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'AI sedang berpikir...',
                          style: TextStyle(
                            color: Colors.blue.shade200,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input Field
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black87,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Tanya tentang cuaca...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white38,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade900],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () => _sendMessage(_questionController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.blue.shade800
                    : Colors.white10,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 5),
                  bottomRight: Radius.circular(message.isUser ? 5 : 20),
                ),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}