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
            'Dukaan Dost is already running the latest version (v$currentVersionStr).',
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
      isDismissible: !isRequired,
      enableDrag: !isRequired,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PopScope(
        canPop: !isRequired,
        child: _UpdateSheetWidget(
          currentVersion: currentVersion,
          newVersion: newVersion,
          features: features,
          isRequired: isRequired,
          downloadUrl: downloadUrl,
        ),
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

  Future<void> _startDownload() async {
    if (widget.downloadUrl.isEmpty || !widget.downloadUrl.startsWith('http')) {
      setState(() => _statusMessage = 'Invalid update download link.');
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = 'Requesting storage permission...';
      _progress = 0;
    });

    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.request();
      if (status.isDenied) {
        setState(() {
          _isDownloading = false;
          _statusMessage = 'Please enable install permissions from Settings to update.';
        });
        return;
      }
    }

    setState(() => _statusMessage = 'Downloading update package...');

    try {
      final appDocDir = await getTemporaryDirectory();
      final savePath = '${appDocDir.path}/dukaan-dost-v${widget.newVersion}.apk';

      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      final dio = Dio();
      await dio.download(
        widget.downloadUrl,
        savePath,
        onReceiveProgress: (rcv, total) {
          if (total != -1) {
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

      setState(() => _statusMessage = 'Download complete. Launching package installer...');

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        setState(() {
          _statusMessage = 'Tap Install Now to complete package installation.';
          _isDownloading = false;
        });
      } else {
        setState(() {
          _isDownloading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Download failed. Please check connection and retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || AppColors.isDark;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 36,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.terracotta.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Icon(Icons.rocket_launch_rounded, color: AppColors.terracotta, size: 28),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'NEW UPDATE AVAILABLE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.forestMint.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.forestMint.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'v${widget.newVersion}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forestMint,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current version: v${widget.currentVersion}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (widget.features.isNotEmpty) ...[
              Text(
                "WHAT'S NEW IN THIS VERSION",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: widget.features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppColors.forestMint.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_rounded, size: 12, color: AppColors.forestMint),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_mbProgress.isNotEmpty)
                          Text(
                            _mbProgress,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.terracotta,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        minHeight: 10,
                        backgroundColor: isDark ? const Color(0xFF242E3D) : const Color(0xFFE8E4DC),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.terracotta),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            Row(
              children: [
                if (!widget.isRequired && !_isDownloading) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.borderStrong),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'LATER',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _startDownload,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Icon(Icons.download_for_offline_rounded, size: 20),
                    label: Text(
                      _progress == 1.0 ? 'INSTALL UPDATE' : 'UPDATE NOW',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      shadowColor: AppColors.terracotta.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
