import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeTransitionOverlay extends StatefulWidget {
  final Widget child;

  const ThemeTransitionOverlay({super.key, required this.child});

  @override
  State<ThemeTransitionOverlay> createState() => _ThemeTransitionOverlayState();
}

class _ThemeTransitionOverlayState extends State<ThemeTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _progressAnimation;

  bool _isAnimating = false;
  bool _targetDarkMode = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 76,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 12,
      ),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.2, end: 1.1).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 15,
      ),
    ]).animate(_controller);

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
          _controller.reset();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentDark = themeProvider.isDarkMode;

    if (!_initialized) {
      _targetDarkMode = currentDark;
      _initialized = true;
    } else if (_targetDarkMode != currentDark) {
      _targetDarkMode = currentDark;
      _startTransitionAnimation();
    }
  }

  void _startTransitionAnimation() {
    setState(() {
      _isAnimating = true;
    });
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isAnimating)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final isDark = _targetDarkMode;
                final primaryColor = isDark ? const Color(0xFFFF8A65) : const Color(0xFFFF6E40);
                final bgColor = isDark
                    ? const Color(0xFF111822).withValues(alpha: 0.96 * _fadeAnimation.value)
                    : const Color(0xFFFAF8F5).withValues(alpha: 0.96 * _fadeAnimation.value);
                final textColor = isDark ? const Color(0xFFF5F7FA) : const Color(0xFF1A222E);
                final subTextColor = isDark ? const Color(0xFF9EAAB7) : const Color(0xFF6E7C8E);

                return IgnorePointer(
                  ignoring: false,
                  child: Opacity(
                    opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                    child: Container(
                      color: bgColor,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: _rotationAnimation.value,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: SweepGradient(
                                          colors: isDark
                                              ? [
                                                  const Color(0xFF382318).withValues(alpha: 0.0),
                                                  const Color(0xFFFF8A65).withValues(alpha: 0.8),
                                                  const Color(0xFF2ECC71).withValues(alpha: 0.4),
                                                  const Color(0xFF382318).withValues(alpha: 0.0),
                                                ]
                                              : [
                                                  const Color(0xFFFF6E40).withValues(alpha: 0.0),
                                                  const Color(0xFFFF6E40).withValues(alpha: 0.9),
                                                  const Color(0xFF2ECC71).withValues(alpha: 0.5),
                                                  const Color(0xFFFF6E40).withValues(alpha: 0.0),
                                                ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark ? const Color(0xFF1A222E) : Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDark
                                              ? const Color(0xFFFF8A65).withValues(alpha: 0.35)
                                              : const Color(0xFFFF6E40).withValues(alpha: 0.25),
                                          blurRadius: 30,
                                          spreadRadius: 8,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF293649) : const Color(0xFFE8E4DC),
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: isDark
                                            ? (_rotationAnimation.value * 0.5)
                                            : -(_rotationAnimation.value * 0.5),
                                        child: Icon(
                                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                          size: 52,
                                          color: isDark ? const Color(0xFFFF8A65) : const Color(0xFFFF6E40),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              isDark ? 'SWITCHING TO DARK MODE' : 'SWITCHING TO LIGHT MODE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: textColor,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isDark ? 'Optimizing for low-light comfort' : 'Optimizing for daytime clarity',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: subTextColor,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: 180,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF293649) : const Color(0xFFE8E4DC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withValues(alpha: 0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
