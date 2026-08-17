import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/theme.dart';
import '../core/localization.dart';
import '../core/voice_ai_service.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import 'language_picker_button.dart';

class VoiceBillingModal extends StatefulWidget {
  final Function(List<VoiceAiItem> matched, List<VoiceAiUnmatched> unmatched) onAddToCart;

  const VoiceBillingModal({
    super.key,
    required this.onAddToCart,
  });

  static Future<void> show(BuildContext context, {required Function(List<VoiceAiItem> matched, List<VoiceAiUnmatched> unmatched) onAddToCart}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceBillingModal(onAddToCart: onAddToCart),
    );
  }

  @override
  State<VoiceBillingModal> createState() => _VoiceBillingModalState();
}

class _VoiceBillingModalState extends State<VoiceBillingModal> with SingleTickerProviderStateMixin {
  final VoiceAiService _voiceService = VoiceAiService();
  final TextEditingController _textCtrl = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  Timer? _recordTimer;
  int _recordDuration = 0;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isPlayingAudio = false;
  VoiceAiResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _voiceService.initRecorder();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _isPlayingAudio = false);
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioPlayer.dispose();
    _voiceService.stopRecording();
    _animController.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _startVoiceListening() async {
    setState(() {
      _isListening = true;
      _recordDuration = 0;
      _errorMessage = null;
    });

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && _isListening) {
        setState(() => _recordDuration++);
      }
    });

    await _voiceService.startRecording();
  }

  void _stopVoiceAndProcess() async {
    _recordTimer?.cancel();
    if (!_isListening && !_isProcessing) return;

    final auth = context.read<AuthProvider>();
    final currentLocale = context.read<LocaleProvider>().locale;

    final audioBase64 = await _voiceService.stopRecording();

    if (!mounted) return;

    final liveText = _textCtrl.text.trim();

    if ((audioBase64 == null || audioBase64.isEmpty) && liveText.isEmpty) {
      setState(() {
        _isListening = false;
        _isProcessing = false;
        _errorMessage = 'No voice detected. Please hold the button firmly while speaking.';
      });
      return;
    }

    setState(() {
      _isListening = false;
      _isProcessing = true;
      _errorMessage = null;
    });

    final result = await _voiceService.processVoiceOrder(
      baseUrl: auth.baseUrl,
      apiKey: auth.apiKey,
      audioBase64: audioBase64,
      text: liveText,
      language: currentLocale,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _result = result;
        if (result.rawText.isNotEmpty && result.rawText != liveText) {
          _textCtrl.text = result.rawText;
        }
        if (!result.success) {
          _errorMessage = result.errorMessage ?? 'Failed to process voice order';
        }
      });

      if (result.success && result.matched.isNotEmpty) {
        widget.onAddToCart(result.matched, result.unmatched);
      }
    }
  }

  void _processAiOrder() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final currentLocale = context.read<LocaleProvider>().locale;

    final audioBase64 = await _voiceService.stopRecording();

    if (!mounted) return;

    setState(() {
      _isListening = false;
      _isProcessing = true;
      _errorMessage = null;
    });

    final result = await _voiceService.processVoiceOrder(
      baseUrl: auth.baseUrl,
      apiKey: auth.apiKey,
      audioBase64: audioBase64,
      text: text,
      language: currentLocale,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _result = result;
        if (result.rawText.isNotEmpty && result.rawText != text) {
          _textCtrl.text = result.rawText;
        }
        if (!result.success) {
          _errorMessage = result.errorMessage ?? 'Failed to process voice order';
        }
      });

      if (result.success && result.matched.isNotEmpty) {
        widget.onAddToCart(result.matched, result.unmatched);
      }
    }
  }

  void _toggleAudioPlayback() async {
    final path = _voiceService.lastRecordedPath;
    if (path == null || !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No recorded audio file found on device',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isPlayingAudio) {
      await _audioPlayer.pause();
      setState(() => _isPlayingAudio = false);
    } else {
      setState(() => _isPlayingAudio = true);
      await _audioPlayer.play(DeviceFileSource(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final lastPath = _voiceService.lastRecordedPath;
    final hasAudioFile = lastPath != null && File(lastPath).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.mic_rounded, color: AppColors.terracotta, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('voice_billing_title'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const LanguagePickerButton(),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isListening ? AppColors.terracotta : AppColors.borderSubtle,
                    width: _isListening ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _textCtrl,
                      maxLines: 2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? context.tr('listening_hint')
                            : context.tr('speak_order_prompt'),
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _processAiOrder(),
                    ),
                    if (_textCtrl.text.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _textCtrl.clear();
                              _result = null;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              context.tr('clear_voice_text'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.terracotta,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Text(
                context.tr('try_speaking_example'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),

              if (hasAudioFile)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderStrong),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlayingAudio ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                          color: AppColors.terracotta,
                          size: 32,
                        ),
                        onPressed: _toggleAudioPlayback,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Recorded Voice Audio',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _isPlayingAudio ? 'Playing back recorded speech...' : 'Tap play to listen to what mic recorded',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isProcessing)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.terracotta, strokeWidth: 3),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('processing_voice_ai'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracotta,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderStrong),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Transcript (${_result!.provider ?? "AI"}):',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.terracotta,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _result!.rawText.isNotEmpty ? _result!.rawText : '(No transcript captured)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_result!.sarvamRaw != null && _result!.sarvamRaw!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Sarvam ASR Response:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.chaiGold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _result!.sarvamRaw!,
                          style: GoogleFonts.firaCode(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (_result!.mistralRaw != null && _result!.mistralRaw!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Mistral AI Raw Data:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forestMint,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _result!.mistralRaw!,
                          style: GoogleFonts.firaCode(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (_result!.matched.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.forestMint.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.forestMint.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppColors.forestMint, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${_result!.matched.length} ${context.tr('items_added_to_cart')}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forestMint,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._result!.matched.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.name} (${item.quantity} ${item.unit})',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                if (_result!.unmatched.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.terracotta, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('items_not_found_alert'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.terracotta,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ..._result!.unmatched.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.close_rounded, color: AppColors.error, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.name} (${item.quantity} ${item.unit})',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                  label: Text(context.tr('checkout')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                Center(
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr('tap_and_hold_to_speak'),
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onLongPressStart: (_) => _startVoiceListening(),
                    onLongPressEnd: (_) => _stopVoiceAndProcess(),
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isListening ? _scaleAnimation.value : 1.0,
                          child: Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening ? AppColors.terracotta : AppColors.terracotta.withValues(alpha: 0.12),
                              boxShadow: _isListening
                                  ? [
                                      BoxShadow(
                                        color: AppColors.terracotta.withValues(alpha: 0.5),
                                        blurRadius: 26,
                                        spreadRadius: 8,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                              color: _isListening ? Colors.white : AppColors.terracotta,
                              size: 36,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _isListening
                        ? 'Recording... ${(_recordDuration ~/ 60).toString().padLeft(1, '0')}:${(_recordDuration % 60).toString().padLeft(2, '0')}'
                        : context.tr('tap_and_hold_to_speak'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _isListening ? AppColors.terracotta : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
                if (_textCtrl.text.trim().isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _processAiOrder,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(context.tr('process_order_ai_btn')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
