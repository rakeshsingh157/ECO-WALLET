import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

class _VoiceBillingModalState extends State<VoiceBillingModal> with TickerProviderStateMixin {
  final VoiceAiService _voiceService = VoiceAiService();
  final TextEditingController _textCtrl = TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _coreScaleAnimation;

  Timer? _recordTimer;
  int _recordDuration = 0;
  bool _isListening = false;
  bool _isProcessing = false;
  VoiceAiResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _voiceService.initRecorder();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _coreScaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _voiceService.stopRecording();
    _pulseController.dispose();
    _waveController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
              const SizedBox(height: 16),

              if (_isProcessing)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.terracotta, strokeWidth: 3),
                      const SizedBox(height: 14),
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
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isListening) ...[
                            AnimatedBuilder(
                              animation: _waveController,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: const Size(140, 140),
                                  painter: _VoiceWaveRipplesPainter(
                                    progress: _waveController.value,
                                    color: AppColors.terracotta,
                                  ),
                                );
                              },
                            ),
                          ],
                          AnimatedBuilder(
                            animation: _coreScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isListening ? _coreScaleAnimation.value : 1.0,
                                child: Container(
                                  width: 82,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _isListening
                                          ? [
                                              AppColors.terracotta,
                                              const Color(0xFFD34724),
                                            ]
                                          : [
                                              AppColors.canvas,
                                              AppColors.surface,
                                            ],
                                    ),
                                    border: Border.all(
                                      color: _isListening
                                          ? Colors.white.withValues(alpha: 0.35)
                                          : AppColors.terracotta.withValues(alpha: 0.4),
                                      width: _isListening ? 2 : 1.5,
                                    ),
                                    boxShadow: _isListening
                                        ? [
                                            BoxShadow(
                                              color: AppColors.terracotta.withValues(alpha: 0.45),
                                              blurRadius: 28,
                                              spreadRadius: 6,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                      color: _isListening ? Colors.white : AppColors.terracotta,
                                      size: 34,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                if (_isListening)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.terracotta,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recording ${(_recordDuration ~/ 60).toString().padLeft(1, '0')}:${(_recordDuration % 60).toString().padLeft(2, '0')}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.terracotta,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _VoiceVisualizerBars(animation: _pulseController, color: AppColors.terracotta),
                        ],
                      ),
                    ),
                  )
                else
                  Center(
                    child: Text(
                      context.tr('tap_and_hold_to_speak'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
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

class _VoiceWaveRipplesPainter extends CustomPainter {
  final double progress;
  final Color color;

  _VoiceWaveRipplesPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const minRadius = 42.0;
    const maxRadius = 68.0;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i * 0.33)) % 1.0;
      final radius = minRadius + (maxRadius - minRadius) * ringProgress;
      final opacity = (1.0 - ringProgress).clamp(0.0, 1.0) * 0.45;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - ringProgress * 0.4);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWaveRipplesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _VoiceVisualizerBars extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const _VoiceVisualizerBars({
    required this.animation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final val = animation.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBar(6.0 + (math.sin(val * math.pi) * 8.0).abs()),
            const SizedBox(width: 3),
            _buildBar(8.0 + (math.sin((val + 0.3) * math.pi) * 10.0).abs()),
            const SizedBox(width: 3),
            _buildBar(10.0 + (math.sin((val + 0.6) * math.pi) * 12.0).abs()),
            const SizedBox(width: 3),
            _buildBar(8.0 + (math.sin((val + 0.9) * math.pi) * 9.0).abs()),
            const SizedBox(width: 3),
            _buildBar(5.0 + (math.sin((val + 1.2) * math.pi) * 7.0).abs()),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 3,
      height: height.clamp(4.0, 20.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
