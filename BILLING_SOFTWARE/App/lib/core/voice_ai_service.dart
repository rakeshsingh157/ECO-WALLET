import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceAiItem {
  final String id;
  final String name;
  final double price;
  final String unit;
  final double stock;
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
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
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
  final List<VoiceAiItem> matched;
  final List<VoiceAiUnmatched> unmatched;
  final String? errorMessage;

  VoiceAiResult({
    required this.success,
    required this.rawText,
    this.provider,
    this.sarvamUsed = false,
    required this.matched,
    required this.unmatched,
    this.errorMessage,
  });
}

class VoiceAiService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _hasAudioPermission = false;
  String? _currentRecordingPath;
  bool _isCurrentlyRecording = false;

  bool get isListening => _isCurrentlyRecording;
  String? get lastRecordedPath => _currentRecordingPath;

  Future<bool> initRecorder() async {
    try {
      _hasAudioPermission = await _audioRecorder.hasPermission();
      return _hasAudioPermission;
    } catch (_) {
      return false;
    }
  }

  Future<void> startRecording() async {
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
        _isCurrentlyRecording = true;
      }
    } catch (_) {
      _isCurrentlyRecording = false;
    }
  }

  Future<String?> stopRecording() async {
    _isCurrentlyRecording = false;
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
    String? merchantId,
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

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      };
      if (merchantId != null && merchantId.isNotEmpty) {
        headers['x-merchant-id'] = merchantId;
      }

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final rawText = data['rawText']?.toString() ?? text;
        final provider = data['provider']?.toString();
        final sarvamUsed = data['sarvamUsed'] == true;
        final isSuccess = data['success'] == true;

        if (!isSuccess) {
          return VoiceAiResult(
            success: false,
            rawText: rawText,
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
