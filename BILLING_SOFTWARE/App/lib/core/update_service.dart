import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'theme.dart';
import 'app_notifier.dart';

class UpdateService {
  static const String repoRawUrl = 'https://raw.githubusercontent.com/rakeshsingh157/BILLING-version/main/version.json';
  static const List<String> fallbackUrls = [
    'https://raw.githubusercontent.com/rakeshsingh157/BILLING-version/main/version.json',
    'https://raw.githubusercontent.com/rakeshsingh157/BILLING-version/master/version.json',
    'https://raw.githubusercontent.com/rakeshsingh157/BILLING-version/main/Version/version.json',
    'https://raw.githubusercontent.com/rakeshsingh157/BILLING-version/master/Version/version.json',
  ];

  static Future<void> checkForUpdates(BuildContext context, {bool isManual = false}) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);

      Map<String, dynamic>? data;

      for (final url in fallbackUrls) {
        try {
          final response = await dio.get(url);
          if (response.statusCode == 200) {
            final raw = response.data;
            if (raw is Map<String, dynamic>) {
              data = raw;
              break;
            } else if (raw is String) {
              data = jsonDecode(raw) as Map<String, dynamic>;
              break;
            }
          }
        } catch (_) {}
      }

      if (data == null) {
        if (isManual && context.mounted) {
          AppNotifier.info(
            context,
            'You are running the latest version of Dukaan Dost.',
            title: 'UP TO DATE',
          );
        }
        return;
      }

      final latestVersionStr = (data['version'] ?? '1.0.0').toString().trim();
      final latestCode = (data['versionCode'] as num?)?.toInt() ?? 0;
      final isRequired = data['isRequired'] == true || data['required'] == true;
      final downloadUrl = (data['downloadUrl'] ?? data['apkUrl'] ?? data['url'] ?? '').toString().trim();
      final features = (data['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      final bool hasUpdate = _isNewerVersion(
        currentVersion: currentVersionStr,
        currentCode: currentCode,
        latestVersion: latestVersionStr,
        latestCode: latestCode,
      );

      if (hasUpdate) {
        if (context.mounted) {
          _showUpdateModal(
            context,
            currentVersion: currentVersionStr,
            newVersion: latestVersionStr,
            features: features,
            isRequired: isRequired,
            downloadUrl: downloadUrl,
          );
        }
      } else {
        if (isManual && context.mounted) {
          AppNotifier.success(
            context,
            'Dukaan Dost is running the latest version (v$currentVersionStr).',
            title: 'LATEST VERSION',
          );
        }
      }
    } catch (_) {
      if (isManual && context.mounted) {
        AppNotifier.info(
          context,
          'Unable to reach update server. Please check your internet connection.',
          title: 'UPDATE CHECK',
        );
      }
    }
  }

  static bool _isNewerVersion({
    required String currentVersion,
    required int currentCode,
    required String latestVersion,
    required int latestCode,
  }) {
    try {
      final cParts = currentVersion.split('.').map((s) => int.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 0).toList();
      final lParts = latestVersion.split('.').map((s) => int.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < cParts.length ? cParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }

      if (latestCode > 0 && currentCode > 0) {
        return latestCode > currentCode;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  static void _showUpdateModal(
    BuildContext context, {
    required String currentVersion,
    required String newVersion,
    required List<String> features,
    required bool isRequired,
    required String downloadUrl,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpdateSheetWidget(
        currentVersion: currentVersion,
        newVersion: newVersion,
        features: features,
        isRequired: isRequired,
        downloadUrl: downloadUrl,
      ),
    );
  }
}

class _UpdateSheetWidget extends StatefulWidget {
  final String currentVersion;
  final String newVersion;
  final List<String> features;
  final bool isRequired;
  final String downloadUrl;

  const _UpdateSheetWidget({
    required this.currentVersion,
    required this.newVersion,
    required this.features,
    required this.isRequired,
    required this.downloadUrl,
  });

  @override
  State<_UpdateSheetWidget> createState() => _UpdateSheetWidgetState();
}

class _UpdateSheetWidgetState extends State<_UpdateSheetWidget> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = '';
  String _mbProgress = '';
  CancelToken? _cancelToken;
  String? _currentSavePath;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  void _cancelDownload() async {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('Download cancelled by user');
    }

    if (_currentSavePath != null) {
      try {
        final file = File(_currentSavePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    setState(() {
      _isDownloading = false;
      _progress = 0.0;
      _statusMessage = 'Download cancelled.';
      _mbProgress = '';
      _cancelToken = null;
    });
  }

  Future<void> _startDownload() async {
    if (widget.downloadUrl.isEmpty || !widget.downloadUrl.startsWith('http')) {
      setState(() => _statusMessage = 'Invalid update download link.');
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = 'Requesting installation permissions...';
      _progress = 0;
    });

    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.request();
      if (status.isDenied) {
        setState(() {
          _isDownloading = false;
          _statusMessage = 'Please enable install permissions in Settings to continue.';
        });
        return;
      }
    }

    setState(() => _statusMessage = 'Connecting to download server...');
    _cancelToken = CancelToken();

    try {
      final appDocDir = await getTemporaryDirectory();
      final savePath = '${appDocDir.path}/dukaan-dost-v${widget.newVersion}.apk';
      _currentSavePath = savePath;

      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      final dio = Dio();
      await dio.download(
        widget.downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (rcv, total) {
          if (total != -1 && mounted) {
            setState(() {
              _progress = rcv / total;
              final downloadedMb = (rcv / (1024 * 1024)).toStringAsFixed(1);
              final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
              _mbProgress = '$downloadedMb MB / $totalMb MB';
              _statusMessage = 'Downloading update (${(_progress * 100).toStringAsFixed(0)}%)';
            });
          }
        },
      );

      if (!mounted) return;
      setState(() => _statusMessage = 'Download complete. Launching installer...');

      final result = await OpenFilex.open(savePath);
      if (!mounted) return;

      if (result.type != ResultType.done) {
        setState(() {
          _statusMessage = 'Tap Install Update to complete package setup.';
          _isDownloading = false;
        });
      } else {
        setState(() {
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Download interrupted. Please check connection and retry.';
      });
    }
  }

  IconData _getFeatureIcon(int index) {
    switch (index % 5) {
      case 0:
        return Icons.rocket_launch_rounded;
      case 1:
        return Icons.bolt_rounded;
      case 2:
        return Icons.shield_rounded;
      case 3:
        return Icons.palette_rounded;
      default:
        return Icons.language_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || AppColors.isDark;

    return PopScope(
      canPop: !widget.isRequired && !_isDownloading,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131A26) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF293649) : const Color(0xFFE8E4DC),
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.75 : 0.18),
              blurRadius: 40,
              offset: const Offset(0, -12),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),

              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3B4D66) : const Color(0xFFD8D2C4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.terracotta.withValues(alpha: isDark ? 0.18 : 0.12),
                              ),
                            ),
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.terracotta.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.terracotta.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.rocket_launch_rounded,
                                  color: AppColors.terracotta,
                                  size: 30,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'NEW VERSION AVAILABLE',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: isDark ? Colors.white : const Color(0xFF1F2421),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'A brand new update of Dukaan Dost is ready to install',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF9EAAB7) : const Color(0xFF5A645A),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2838) : const Color(0xFFF3EFEA),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2E3D52) : const Color(0xFFE0DACF),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'v${widget.currentVersion}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF7E8D9E) : const Color(0xFF7C877C),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: isDark ? const Color(0xFF7E8D9E) : const Color(0xFF7C877C),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.forestMint.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.forestMint.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  'v${widget.newVersion} • LATEST',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.forestMint,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      if (widget.features.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.stars_rounded, size: 16, color: AppColors.chaiGold),
                            const SizedBox(width: 6),
                            Text(
                              "WHAT'S NEW IN THIS UPDATE",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: isDark ? const Color(0xFF8E9EAF) : const Color(0xFF6E786E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF192230) : const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2A374A) : const Color(0xFFE8E4DC),
                            ),
                          ),
                          child: Column(
                            children: widget.features.asMap().entries.map((entry) {
                              final index = entry.key;
                              final feature = entry.value;
                              final icon = _getFeatureIcon(index);

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == widget.features.length - 1 ? 0 : 12,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.terracotta.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(icon, size: 14, color: AppColors.terracotta),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        feature,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFFF0F4F8) : const Color(0xFF1F2421),
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (_isDownloading || _progress > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF192230) : const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.terracotta.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _statusMessage,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF1F2421),
                                    ),
                                  ),
                                  if (_mbProgress.isNotEmpty)
                                    Text(
                                      _mbProgress,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.terracotta,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _progress > 0 ? _progress : null,
                                  minHeight: 12,
                                  backgroundColor: isDark ? const Color(0xFF293649) : const Color(0xFFE2DDD5),
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.terracotta),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (_isDownloading)
                        OutlinedButton.icon(
                          onPressed: _cancelDownload,
                          icon: Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                          label: Text(
                            'CANCEL DOWNLOAD',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.error,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.terracotta.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _startDownload,
                                icon: const Icon(Icons.download_rounded, size: 20),
                                label: Text(
                                  _progress == 1.0
                                      ? 'INSTALL UPDATE NOW'
                                      : 'DOWNLOAD & UPDATE TO V${widget.newVersion}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.terracotta,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),

                            if (!widget.isRequired) ...[
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  'Remind Me Later',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF7E8D9E) : const Color(0xFF7C877C),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
