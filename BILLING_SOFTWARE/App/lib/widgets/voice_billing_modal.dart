import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
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

  static Future<void> show(
    BuildContext context, {
    required Function(List<VoiceAiItem> matched, List<VoiceAiUnmatched> unmatched) onAddToCart,
  }) {
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
  bool _isAddingToCart = false;
  VoiceAiResult? _result;
  String? _errorMessage;

  List<VoiceAiItem> _editableMatched = [];

  final List<String> _quickVoiceExamples = [
    '250g chini',
    '500g aata',
    '1.5 kg chawal',
    '500ml doodh',
    '2 packet biscuit',
    '1 kg dal',
  ];

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
        _errorMessage = 'No voice detected. Please hold or tap the mic and speak clearly.';
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
        _editableMatched = List.from(result.matched);
        if (result.rawText.isNotEmpty && result.rawText != liveText) {
          _textCtrl.text = result.rawText;
        }
        if (!result.success) {
          _errorMessage = result.errorMessage ?? 'Failed to process voice order';
        }
      });
    }
  }

  void _processAiOrder([String? customText]) async {
    final text = (customText ?? _textCtrl.text).trim();
    if (text.isEmpty) return;

    if (customText != null) {
      _textCtrl.text = customText;
    }

    final auth = context.read<AuthProvider>();
    final currentLocale = context.read<LocaleProvider>().locale;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final result = await _voiceService.processVoiceOrder(
      baseUrl: auth.baseUrl,
      apiKey: auth.apiKey,
      audioBase64: null,
      text: text,
      language: currentLocale,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _result = result;
        _editableMatched = List.from(result.matched);
        if (!result.success) {
          _errorMessage = result.errorMessage ?? 'Failed to process order';
        }
      });
    }
  }

  void _confirmAndAddToCart() {
    if (_isAddingToCart || _editableMatched.isEmpty) return;

    setState(() => _isAddingToCart = true);

    widget.onAddToCart(
      _editableMatched,
      _result?.unmatched ?? [],
    );

    Navigator.pop(context);
  }

  void _updateItemQuantity(int index, double delta) {
    setState(() {
      final current = _editableMatched[index];
      final newQty = math.max(0.05, (current.quantity + delta));
      final rounded = double.parse(newQty.toStringAsFixed(3));

      _editableMatched[index] = VoiceAiItem(
        id: current.id,
        name: current.name,
        price: current.price,
        unit: current.unit,
        stock: current.stock,
        category: current.category,
        quantity: rounded,
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _editableMatched.removeAt(index);
    });
  }

  double get _totalEstimatedAmount {
    double total = 0.0;
    for (final item in _editableMatched) {
      total += item.price * item.quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || AppColors.isDark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
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
                    color: isDark ? const Color(0xFF37475A) : const Color(0xFFD5CEBF),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.mic_rounded, color: AppColors.terracotta, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI VOICE CART',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Speak weights, units & items',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const LanguagePickerButton(),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2432) : const Color(0xFFF9F7F4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isListening
                        ? AppColors.terracotta
                        : (isDark ? const Color(0xFF2B3A4F) : const Color(0xFFE8E2D8)),
                    width: _isListening ? 1.5 : 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Spoken Order / Items Input',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_textCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _textCtrl.clear();
                                  _result = null;
                                  _editableMatched = [];
                                });
                              },
                              child: Text(
                                'Clear',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.terracotta,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
                            ? 'Listening... e.g. "250g chini 1 bottle pani"'
                            : 'Tap mic or type: e.g. 250g chini, 500ml doodh, 1.5kg chawal',
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
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickVoiceExamples.map((example) {
                  return ActionChip(
                    label: Text(example),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFD5CEBF) : const Color(0xFF4A443A),
                    ),
                    backgroundColor: isDark ? const Color(0xFF243042) : const Color(0xFFEBE6DC),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: _isProcessing ? null : () => _processAiOrder(example),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              if (_isProcessing)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2432) : const Color(0xFFF9F7F4),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2B3A4F) : const Color(0xFFE8E2D8),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.terracotta, strokeWidth: 2.8),
                      const SizedBox(height: 14),
                      Text(
                        'ANALYZING SPEECH & QUANTITIES...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppColors.terracotta,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Converting decimal weights into cart units',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_result != null && _editableMatched.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2432) : const Color(0xFFF9F7F4),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.forestMint.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppColors.forestMint, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${_editableMatched.length} ITEMS IDENTIFIED',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: AppColors.forestMint,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Est. ₹${_totalEstimatedAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._editableMatched.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final itemTotal = item.price * item.quantity;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF243042) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2B3A4F) : const Color(0xFFE8E2D8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${item.price.toStringAsFixed(0)} / ${item.unit}  •  ₹${itemTotal.toStringAsFixed(2)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    color: AppColors.textSecondary,
                                    onPressed: item.quantity <= 0.1
                                        ? () => _removeItem(index)
                                        : () => _updateItemQuantity(
                                              index,
                                              ['kg', 'l', 'ltr', 'liter'].contains(item.unit.toLowerCase()) ? -0.25 : -1.0,
                                            ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '${item.quantity} ${item.unit}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.terracotta,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    color: AppColors.forestMint,
                                    onPressed: () => _updateItemQuantity(
                                      index,
                                      ['kg', 'l', 'ltr', 'liter'].contains(item.unit.toLowerCase()) ? 0.25 : 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (_result!.unmatched.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Not In Inventory (${_result!.unmatched.length})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ..._result!.unmatched.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${item.name} (${item.quantity} ${item.unit})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAddingToCart ? null : _confirmAndAddToCart,
                    icon: _isAddingToCart
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    label: Text(
                      _isAddingToCart
                          ? 'ADDING TO CART...'
                          : 'ADD ${_editableMatched.length} ITEMS TO BILL (₹${_totalEstimatedAmount.toStringAsFixed(0)})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestMint,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ] else ...[
                Center(
                  child: GestureDetector(
                    onTap: () {
                      if (_isListening) {
                        _stopVoiceAndProcess();
                      } else {
                        _startVoiceListening();
                      }
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
                                  width: 84,
                                  height: 84,
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
                                              isDark ? const Color(0xFF243042) : const Color(0xFFFFFFFF),
                                              isDark ? const Color(0xFF1B2432) : const Color(0xFFF9F7F4),
                                            ],
                                    ),
                                    border: Border.all(
                                      color: _isListening
                                          ? Colors.white.withValues(alpha: 0.4)
                                          : AppColors.terracotta.withValues(alpha: 0.5),
                                      width: _isListening ? 2.5 : 1.8,
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
                                      size: 36,
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
                        color: isDark ? const Color(0xFF1B2432) : const Color(0xFFF9F7F4),
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
                      'Hold or Tap Mic to Speak Order',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 16),
                if (_textCtrl.text.trim().isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _processAiOrder(),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        'PROCESS ORDER VIA AI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
