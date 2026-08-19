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
      final isRequired = data['isRequired'] == true || data['required'] == true;
      final downloadUrl = (data['downloadUrl'] ?? data['apkUrl'] ?? data['url'] ?? '').toString().trim();
      final features = (data['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;

      if (_isNewerVersion(currentVersionStr, latestVersionStr)) {
        if (context.mounted) {
          _showUpdateDialog(
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
            'Dukaan Dost is already up to date (v$currentVersionStr).',
            title: 'LATEST VERSION',
          );
        }
      }
    } catch (_) {
      if (isManual && context.mounted) {
        AppNotifier.info(
          context,
          'Unable to reach update server. Please check your network connection.',
          title: 'UPDATE CHECK',
        );
      }
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    try {
      final cParts = current.split('.').map((s) => int.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 0).toList();
      final lParts = latest.split('.').map((s) => int.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < cParts.length ? cParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void _showUpdateDialog(
    BuildContext context, {
    required String currentVersion,
    required String newVersion,
    required List<String> features,
    required bool isRequired,
    required String downloadUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isRequired,
      builder: (ctx) => PopScope(
        canPop: !isRequired,
        child: _UpdateDialogWidget(
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

class _UpdateDialogWidget extends StatefulWidget {
  final String currentVersion;
  final String newVersion;
  final List<String> features;
  final bool isRequired;
  final String downloadUrl;

  const _UpdateDialogWidget({
    required this.currentVersion,
    required this.newVersion,
    required this.features,
    required this.isRequired,
    required this.downloadUrl,
  });

  @override
  State<_UpdateDialogWidget> createState() => _UpdateDialogWidgetState();
}

class _UpdateDialogWidgetState extends State<_UpdateDialogWidget> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = '';

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
          _statusMessage = 'Installation permission denied. Cannot proceed with update.';
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
              _statusMessage = 'Downloading: $downloadedMb MB / $totalMb MB (${(_progress * 100).toStringAsFixed(0)}%)';
            });
          }
        },
      );

      setState(() => _statusMessage = 'Download complete. Launching package installer...');

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        setState(() {
          _statusMessage = 'Failed to launch installer: ${result.message}';
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
        _statusMessage = 'Download failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppColors.borderSubtle, width: 1.2)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.terracotta.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.system_update_rounded, color: AppColors.terracotta, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPDATE AVAILABLE',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.textPrimary),
                ),
                Text(
                  'v${widget.currentVersion} -> v${widget.newVersion}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.terracotta),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of Dukaan Dost (v${widget.newVersion}) is ready to install.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),

            if (widget.features.isNotEmpty) ...[
              Text(
                "What's New in this update:",
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warmNavy),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.features.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: AppColors.forestMint),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (_isDownloading || _progress > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: AppColors.canvas,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.terracotta),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ] else if (_statusMessage.isNotEmpty) ...[
              Text(
                _statusMessage,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!widget.isRequired && !_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'LATER',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _isDownloading ? null : _startDownload,
          icon: _isDownloading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.download_rounded, size: 16),
          label: Text(
            _progress == 1.0 ? 'INSTALL NOW' : 'DOWNLOAD & UPDATE',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.terracotta,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ],
    );
  }
}
