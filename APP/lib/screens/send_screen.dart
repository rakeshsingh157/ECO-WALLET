import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import 'success_screen.dart';
import 'scanner_screen.dart';
import '../providers/notification_provider.dart';
import 'notifications_screen.dart';

class SendScreen extends StatefulWidget {
  final String? prefillReceiverId;
  final String? prefillAmount;
  final String? prefillReceiverName;
  final String? prefillPaymentId;
  const SendScreen({super.key, this.prefillReceiverId, this.prefillAmount, this.prefillReceiverName, this.prefillPaymentId});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _recipientCtrl = TextEditingController();
  String _amount = '0';
  bool _sending = false;
  Map<String, dynamic>? _recipientInfo;

  @override
  void initState() {
    super.initState();
    if (widget.prefillAmount != null && widget.prefillAmount!.isNotEmpty) {
      _amount = widget.prefillAmount!;
    }
    if (widget.prefillReceiverName != null && widget.prefillReceiverName!.isNotEmpty) {
      _recipientInfo = {
        'name': widget.prefillReceiverName!,
        'user_id': widget.prefillReceiverId ?? '',
      };
    }
    if (widget.prefillReceiverId != null && widget.prefillReceiverId!.isNotEmpty) {
      _recipientCtrl.text = widget.prefillReceiverId!;
      _lookupRecipient();
    }
  }

  @override
  void dispose() {
    _recipientCtrl.dispose();
    super.dispose();
  }

  bool get _isReceiverLocked => widget.prefillReceiverId != null && widget.prefillReceiverId!.isNotEmpty;
  bool get _isAmountLocked => widget.prefillAmount != null && widget.prefillAmount!.isNotEmpty;

  Future<void> _lookupRecipient() async {
    if (_recipientCtrl.text.trim().length < 5) {
      if (mounted && widget.prefillReceiverName == null) setState(() => _recipientInfo = null);
      return;
    }
    final wallet = context.read<WalletProvider>();
    final info = await wallet.lookupUser(_recipientCtrl.text.trim());
    if (mounted && info != null) {
      setState(() => _recipientInfo = info);
    }
  }

  void _appendDigit(String digit) {
    FocusScope.of(context).unfocus(); // hide keyboard when typing amount
    if (_isAmountLocked) return;

    setState(() {
      if (_amount == '0' && digit != '.') {
        _amount = digit;
      } else if (digit == '.' && _amount.contains('.')) {
        return;
      } else if (_amount.contains('.') && _amount.split('.')[1].length >= 2) {
        return;
      } else {
        _amount += digit;
      }
    });
  }

  void _deleteDigit() {
    FocusScope.of(context).unfocus(); // hide keyboard when typing amount
    if (_isAmountLocked) return;

    setState(() {
      if (_amount.length <= 1) {
        _amount = '0';
      } else {
        _amount = _amount.substring(0, _amount.length - 1);
      }
    });
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (_sending) return;

    final amount = double.tryParse(_amount) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    if (_recipientCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter recipient ID')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (amount > auth.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. Your balance is ${NumberFormat('#,##0.00').format(auth.balance)} ECO'),
          backgroundColor: EcoColors.errorContainer,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? enteredPin;
    if (prefs.getBool('require_pin') == true) {
      enteredPin = await _showPinDialog();
      if (enteredPin == null || enteredPin.length != 6) return; // cancelled
    }

    setState(() => _sending = true);

    final wallet = context.read<WalletProvider>();
    final auth = context.read<AuthProvider>();
    
    // Generate simple idempotency key
    final idempotencyKey = '${DateTime.now().millisecondsSinceEpoch}_${auth.userId}';

    final res = await wallet.sendMoney(
      _recipientCtrl.text.trim(),
      amount,
      idempotencyKey: idempotencyKey,
      pin: enteredPin,
      paymentId: widget.prefillPaymentId,
    );

    setState(() => _sending = false);

    if (res['success'] == true) {
      auth.updateBalance((res['data']['new_balance'] ?? auth.balance).toDouble());
      if (mounted) {
        final data = Map<String, dynamic>.from(res['data'] ?? {});
        final displayName = widget.prefillReceiverName ?? _recipientInfo?['name'] ?? _recipientCtrl.text.trim();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuccessScreen(
              transactionData: data,
              fallbackReceiverName: displayName,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Transfer failed'),
            backgroundColor: EcoColors.errorContainer,
          ),
        );
      }
    }
  }

  Future<String?> _showPinDialog() async {
    String enteredPin = '';
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: EcoColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 24, left: 24, right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Enter Security PIN', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: EcoColors.primary)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < enteredPin.length ? EcoColors.primaryContainer : EcoColors.surfaceContainerHighest,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  // Simple numpad
                  _buildMiniNumpad((key) {
                    if (key == '⌫') {
                      if (enteredPin.isNotEmpty) setModalState(() => enteredPin = enteredPin.substring(0, enteredPin.length - 1));
                    } else if (enteredPin.length < 6) {
                      setModalState(() => enteredPin += key);
                      if (enteredPin.length == 6) {
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (ctx.mounted) Navigator.pop(ctx, enteredPin);
                        });
                      }
                    }
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildMiniNumpad(Function(String) onKey) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((k) {
              if (k.isEmpty) return const SizedBox(width: 64, height: 64);
              return GestureDetector(
                onTap: () => onKey(k),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: k == '⌫' 
                      ? const Icon(Icons.backspace_outlined, color: EcoColors.onSurfaceVariant) 
                      : Text(k, style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w600, color: EcoColors.onSurface)),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final formattedAmount = _amount == '0' ? '0.00' : _amount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EcoColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('ECO Wallet', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 3, color: EcoColors.primaryContainer)),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, notif, __) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: EcoColors.primaryContainer), 
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  }
                ),
                if (notif.unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: EcoColors.error),
                      child: Center(
                        child: Text(
                          '${notif.unreadCount}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Recipient section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RECIPIENT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: EcoColors.onSurfaceVariant)),
                      GestureDetector(
                        onTap: () {
                          // Our ScannerScreen pushes a replacement SendScreen when it finds an ECO user.
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ScannerScreen()),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_scanner, size: 16, color: EcoColors.primaryContainer),
                            const SizedBox(width: 4),
                            Text('SCAN QR', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: EcoColors.primaryContainer)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _recipientCtrl,
                    readOnly: _isReceiverLocked,
                    style: GoogleFonts.inter(
                      color: _isReceiverLocked ? EcoColors.onSurfaceVariant : EcoColors.onSurface,
                    ),
                    textInputAction: TextInputAction.done,
                    onEditingComplete: () {
                      FocusScope.of(context).unfocus();
                      _lookupRecipient();
                    },
                    decoration: InputDecoration(
                      hintText: 'User ID / Username',
                      suffixIcon: Icon(
                        _isReceiverLocked ? Icons.lock : Icons.person, 
                        color: EcoColors.onSurfaceVariant.withOpacity(0.3)
                      ),
                    ),
                    onChanged: (_) => _lookupRecipient(),
                  ),
                  if (_recipientInfo != null || _isReceiverLocked) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: EcoColors.primaryContainer.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: EcoColors.primaryContainer.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: EcoColors.primaryContainer.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_rounded, size: 20, color: EcoColors.primaryContainer),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PAYING TO',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: EcoColors.onSurfaceVariant),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _recipientInfo?['name'] ?? widget.prefillReceiverName ?? _recipientCtrl.text,
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: EcoColors.primaryContainer),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.verified_rounded, size: 18, color: EcoColors.primaryContainer),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Balance indicator
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: EcoColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet, size: 14, color: EcoColors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'BALANCE: ${NumberFormat('#,##0.##').format(auth.balance)} ECO',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: EcoColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Amount display
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₹', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: EcoColors.primaryContainer)),
                        Text(
                          formattedAmount,
                          style: GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.w700, color: EcoColors.primary, height: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, size: 12, color: EcoColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('SECURED BY ECO-VAULT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: EcoColors.onSurfaceVariant)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Numpad
                  _buildNumpad(),
                ],
              ),
            ),
          ),

          // Send button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(48),
                  gradient: const LinearGradient(colors: [EcoColors.primaryContainer, EcoColors.primaryFixedDim]),
                  boxShadow: [BoxShadow(color: EcoColors.primaryContainer.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(48))),
                  child: _sending
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: EcoColors.surface))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _recipientInfo?['name'] != null 
                                  ? 'PAY TO ${_recipientInfo!['name'].toString().toUpperCase()}'
                                  : 'SEND MONEY',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: EcoColors.surface),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: EcoColors.surface, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              return GestureDetector(
                onTap: () {
                  if (key == '⌫') {
                    _deleteDigit();
                  } else {
                    _appendDigit(key);
                  }
                },
                child: Container(
                  width: 72,
                  height: 56,
                  alignment: Alignment.center,
                  child: key == '⌫'
                      ? const Icon(Icons.backspace_outlined, color: EcoColors.onSurfaceVariant, size: 22)
                      : Text(
                          key,
                          style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w500, color: EcoColors.onSurface),
                        ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

