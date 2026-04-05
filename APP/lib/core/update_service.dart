import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import '../core/theme.dart';

class UpdateService {
  // IMPORTANT: Replace this with the Raw URL of your version.json on GitHub!
  // Example: https://raw.githubusercontent.com/username/repo/main/Version/version.json
  static const String versionJsonUrl = 'https://raw.githubusercontent.com/rakeshsingh157/version-ECO-WALLET/main/version.json';

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final dio = Dio();
      final response = await dio.get(versionJsonUrl);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.data is String ? response.data : jsonEncode(response.data));
        final latestVersionStr = data['version'] as String;
        final isRequired = data['isRequired'] as bool? ?? false;
        final downloadUrl = data['downloadUrl'] as String;
        final features = (data['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersionStr = packageInfo.version;

        if (_isNewerVersion(currentVersionStr, latestVersionStr)) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersionStr, features, isRequired, downloadUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    try {
      final cParts = current.split('.').map(int.parse).toList();
      final lParts = latest.split('.').map(int.parse).toList();
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

  static void _showUpdateDialog(BuildContext context, String newVersion, List<String> features, bool isRequired, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: !isRequired,
      builder: (ctx) => PopScope(
        canPop: !isRequired,
        child: _UpdateDialogWidget(
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
  final String newVersion;
  final List<String> features;
  final bool isRequired;
  final String downloadUrl;

  const _UpdateDialogWidget({
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
    if (widget.downloadUrl == 'YOUR_GITHUB_APK_DIRECT_LINK_HERE' || !widget.downloadUrl.startsWith('http')) {
      setState(() => _statusMessage = 'Invalid download link configured.');
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = 'Requesting permissions...';
      _progress = 0;
    });

    // Request permissions
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.request();
      if (status.isDenied) {
         setState(() {
           _isDownloading = false;
           _statusMessage = 'Permission denied. Cannot install.';
         });
         return;
      }
    }

    setState(() => _statusMessage = 'Downloading...');

    try {
      final appDocDir = await getTemporaryDirectory();
      final savePath = '${appDocDir.path}/app-update.apk';

      final dio = Dio();
      await dio.download(
        widget.downloadUrl,
        savePath,
        onReceiveProgress: (rcv, total) {
          if (total != -1) {
            setState(() {
              _progress = rcv / total;
              _statusMessage = 'Downloading... ${(_progress * 100).toStringAsFixed(1)}%';
            });
          }
        },
      );

      setState(() => _statusMessage = 'Download complete! Installing...');

      // Install APK
      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        setState(() {
          _statusMessage = 'Failed to open file: ${result.message}';
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
      backgroundColor: EcoColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.system_update_alt, color: EcoColors.primaryContainer),
          const SizedBox(width: 12),
          Text('Update Available', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: EcoColors.primary)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${widget.newVersion} is now available.', style: GoogleFonts.inter(fontSize: 14, color: EcoColors.onSurface)),
            const SizedBox(height: 16),
            if (widget.features.isNotEmpty) ...[
              Text("What's New:", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: EcoColors.primary)),
              const SizedBox(height: 8),
              ...widget.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: EcoColors.primaryContainer, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(f, style: GoogleFonts.inter(fontSize: 13, color: EcoColors.onSurfaceVariant))),
                  ],
                ),
              )),
              const SizedBox(height: 16),
            ],
            if (_isDownloading || _progress > 0) ...[
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: EcoColors.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(EcoColors.primaryContainer),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: GoogleFonts.inter(fontSize: 12, color: EcoColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ] else if (_statusMessage.isNotEmpty) ...[
              Text(
                _statusMessage,
                style: GoogleFonts.inter(fontSize: 12, color: EcoColors.error),
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
            child: Text('LATER', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: EcoColors.onSurfaceVariant)),
          ),
        ElevatedButton(
          onPressed: _isDownloading ? null : _startDownload,
          style: ElevatedButton.styleFrom(
            backgroundColor: EcoColors.primaryContainer,
            foregroundColor: EcoColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(_progress == 1.0 ? 'INSTALL' : 'UPDATE NOW', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
