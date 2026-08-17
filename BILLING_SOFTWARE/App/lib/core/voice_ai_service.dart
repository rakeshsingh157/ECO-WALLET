import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceAiItem {
  final String id;
  final String name;
  final double price;
  final String unit;
  final int stock;
  final String category;
  final double quantity;

  VoiceAiItem({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.stock,
    required this.category,
    required this.quantity,
  });

  factory VoiceAiItem.fromJson(Map<String, dynamic> json) {
    return VoiceAiItem(
      id: json['id']?.toString() ?? json['product_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? 'pcs',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString() ?? 'General',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class VoiceAiUnmatched {
  final String name;
  final double quantity;
  final String unit;
  final String reason;

  VoiceAiUnmatched({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.reason,
  });

  factory VoiceAiUnmatched.fromJson(Map<String, dynamic> json) {
    return VoiceAiUnmatched(
      name: json['name']?.toString() ?? json['queryItem']?.toString() ?? 'Unknown',
      quantity: (json['quantity'] as num?)?.toDouble() ?? (json['requestedQty'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? json['requestedUnit']?.toString() ?? 'pcs',
      reason: json['reason']?.toString() ?? 'not_found',
    );
  }
}

class VoiceAiResult {
  final bool success;
  final String rawText;
  final String? provider;
  final List<VoiceAiItem> matched;
  final List<VoiceAiUnmatched> unmatched;
  final String? errorMessage;

  VoiceAiResult({
    required this.success,
    required this.rawText,
    this.provider,
    required this.matched,
    required this.unmatched,
    this.errorMessage,
  });
}

class VoiceAiService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isListening => _speech.isListening;

  Future<bool> initSpeech() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (err) {},
        onStatus: (status) {},
      );
      return _isInitialized;
    } catch (_) {
      return false;
    }
  }

  String getLocaleForLanguage(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'hi':
        return 'hi_IN';
      case 'mr':
        return 'mr_IN';
      case 'gu':
        return 'gu_IN';
      case 'ta':
        return 'ta_IN';
      case 'te':
        return 'te_IN';
      case 'en':
      default:
        return 'en_IN';
    }
  }

  Future<void> startListening({
    required String languageCode,
    required Function(String text) onResult,
    required Function() onDone,
  }) async {
    final available = await initSpeech();
    if (!available) return;

    final localeId = getLocaleForLanguage(languageCode);

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          onDone();
        }
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<VoiceAiResult> processVoiceOrder({
    required String baseUrl,
    required String apiKey,
    required String text,
    required String language,
  }) async {
    try {
      final sanitizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      final uri = Uri.parse('$sanitizedBase/api/ai/voice-to-cart');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'text': text,
          'language': language,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final rawText = data['rawText']?.toString() ?? text;
        final provider = data['provider']?.toString();

        final List<VoiceAiItem> matched = [];
        if (data['matched'] is List) {
          for (final item in data['matched']) {
            if (item is Map<String, dynamic>) {
              matched.add(VoiceAiItem.fromJson(item));
            }
          }
        }

        final List<VoiceAiUnmatched> unmatched = [];
        if (data['unmatched'] is List) {
          for (final item in data['unmatched']) {
            if (item is Map<String, dynamic>) {
              unmatched.add(VoiceAiUnmatched.fromJson(item));
            }
          }
        }

        return VoiceAiResult(
          success: true,
          rawText: rawText,
          provider: provider,
          matched: matched,
          unmatched: unmatched,
        );
      } else {
        return VoiceAiResult(
          success: false,
          rawText: text,
          matched: [],
          unmatched: [],
          errorMessage: 'Server returned ${response.statusCode}',
        );
      }
    } catch (e) {
      return VoiceAiResult(
        success: false,
        rawText: text,
        matched: [],
        unmatched: [],
        errorMessage: e.toString(),
      );
    }
  }
}
