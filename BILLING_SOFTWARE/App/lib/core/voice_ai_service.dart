import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
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
  final bool sarvamUsed;
  final String? sarvamModel;
  final String? sarvamError;
  final String? mistralRaw;
  final String? mistralError;
  final List<VoiceAiItem> matched;
  final List<VoiceAiUnmatched> unmatched;
  final String? errorMessage;

  VoiceAiResult({
    required this.success,
    required this.rawText,
    this.provider,
    this.sarvamUsed = false,
    this.sarvamModel,
    this.sarvamError,
    this.mistralRaw,
    this.mistralError,
    required this.matched,
    required this.unmatched,
    this.errorMessage,
  });
}

class VoiceAiService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isSpeechInitialized = false;
  bool _hasAudioPermission = false;
  String? _currentRecordingPath;

  bool get isListening => _speech.isListening;

  Future<bool> initRecorder() async {
    try {
      _hasAudioPermission = await _audioRecorder.hasPermission();
      return _hasAudioPermission;
    } catch (_) {
      return false;
    }
  }

  Future<bool> initSpeech() async {
    if (_isSpeechInitialized) return true;
    try {
      _isSpeechInitialized = await _speech.initialize(
        onError: (err) {},
        onStatus: (status) {},
      );
      return _isSpeechInitialized;
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

  Future<void> startRecording({
    required String languageCode,
    required Function(String liveText) onLiveText,
    required Function() onDone,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath = '${tempDir.path}/voice_order_${DateTime.now().millisecondsSinceEpoch}.m4a';

      if (!_hasAudioPermission) {
        _hasAudioPermission = await _audioRecorder.hasPermission();
      }

      if (_hasAudioPermission) {
        if (await _audioRecorder.isRecording()) {
          await _audioRecorder.stop();
        }
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _currentRecordingPath!,
        );
      }
    } catch (_) {
    }

    try {
      final speechReady = await initSpeech();
      if (speechReady) {
        final localeId = getLocaleForLanguage(languageCode);
        await _speech.listen(
          onResult: (result) {
            onLiveText(result.recognizedWords);
            if (result.finalResult) {
              onDone();
            }
          },
          listenOptions: stt.SpeechListenOptions(
            localeId: localeId,
            listenMode: stt.ListenMode.dictation,
            pauseFor: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {
    }

    try {
      final isRec = await _audioRecorder.isRecording();
      String? path;
      if (isRec) {
        path = await _audioRecorder.stop();
      } else {
        path = _currentRecordingPath;
      }

      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            return base64Encode(bytes);
          }
        }
      }
    } catch (_) {
    }
    return null;
  }

  Future<VoiceAiResult> processVoiceOrder({
    required String baseUrl,
    required String apiKey,
    String? audioBase64,
    required String text,
    required String language,
  }) async {
    try {
      String cleanBase = baseUrl.trim();
      while (cleanBase.endsWith('/')) {
        cleanBase = cleanBase.substring(0, cleanBase.length - 1);
      }
      if (cleanBase.endsWith('/api')) {
        cleanBase = cleanBase.substring(0, cleanBase.length - 4);
      }
      final uri = Uri.parse('$cleanBase/api/ai/voice-to-cart');

      final payload = <String, dynamic>{
        'language': language,
        'format': 'm4a',
      };

      if (audioBase64 != null && audioBase64.isNotEmpty) {
        payload['audio'] = audioBase64;
      }
      if (text.isNotEmpty) {
        payload['text'] = text;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final rawText = data['rawText']?.toString() ?? text;
        final provider = data['provider']?.toString();
        final sarvamUsed = data['sarvamUsed'] == true;
        final sarvamModel = data['sarvamModel']?.toString();
        final sarvamError = data['sarvamError']?.toString();
        final mistralRaw = data['mistralRaw']?.toString();
        final mistralError = data['mistralError']?.toString();
        final isSuccess = data['success'] == true;

        if (!isSuccess) {
          return VoiceAiResult(
            success: false,
            rawText: rawText,
            sarvamModel: sarvamModel,
            sarvamError: sarvamError,
            mistralRaw: mistralRaw,
            mistralError: mistralError,
            matched: [],
            unmatched: [],
            errorMessage: data['message']?.toString() ?? 'Failed to process voice order',
          );
        }

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
          sarvamUsed: sarvamUsed,
          sarvamModel: sarvamModel,
          sarvamError: sarvamError,
          mistralRaw: mistralRaw,
          mistralError: mistralError,
          matched: matched,
          unmatched: unmatched,
        );
      } else {
        String msg = 'Server communication error (${response.statusCode})';
        try {
          final errData = jsonDecode(response.body);
          if (errData['message'] != null) {
            msg = errData['message'].toString();
          } else if (errData['error'] != null) {
            msg = errData['error'].toString();
          }
        } catch (_) {}

        return VoiceAiResult(
          success: false,
          rawText: text,
          matched: [],
          unmatched: [],
          errorMessage: msg,
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
