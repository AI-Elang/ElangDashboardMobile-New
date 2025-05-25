import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class UpdateService {
  static const String VERSION_CHECK_URL =
      "https://raw.githubusercontent.com/AI-Elang/ElangDashboardUpdateApp-New/main/version.json";

  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<void> _updateTrigger =
      StreamController<void>.broadcast();

  bool _isDownloading = false;
  bool _isDialogShowing = false;
  bool _isCheckingUpdate = false;
  bool _hasNewVersion = false;
  bool _isUpdateRequired(
    String currentVersion,
    int currentBuild,
    String remoteVersion,
    int remoteBuild,
  ) {
    final List<int> current = currentVersion.split('.').map(int.parse).toList();
    final List<int> remote = remoteVersion.split('.').map(int.parse).toList();

    // Compare major version
    if (remote[0] != current[0]) return remote[0] > current[0];

    // Compare minor version
    if (remote[1] != current[1]) return remote[1] > current[1];

    // Compare patch version
    if (remote[2] != current[2]) return remote[2] > current[2];

    // If all version numbers are same, compare build number
    return remoteBuild > currentBuild;
  }

  DateTime? _lastDismissedTime;
  BuildContext? _currentContext;

  UpdateService._internal() {
    _initializeNotifications();
    _setupUpdateListener();
  }

  void _setupUpdateListener() {
    _updateTrigger.stream.listen((_) async {
      if (!_isCheckingUpdate && _currentContext != null) {
        _isCheckingUpdate = true;
        final updateInfo = await _compareVersions();

        if (updateInfo != null && !_hasNewVersion) {
          _hasNewVersion = true;
          await _showUpdateNotification(updateInfo);
        } else if (updateInfo == null) {
          _hasNewVersion = false;
        }

        _isCheckingUpdate = false;
      }
    });
  }

  void triggerUpdateCheck() {
    _updateTrigger.add(null);
  }

  void stopUpdateCheck() {
    _currentContext = null;
  }

  Future<void> _initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) async {
        if (_currentContext != null) {
          final updateInfo = await _compareVersions();
          if (updateInfo != null) {
            showUpdateDialog(_currentContext!, updateInfo);
          }
        }
      },
    );

    // Create the notification channel
    const channel = AndroidNotificationChannel(
      'update_channel',
      'App Updates',
      description: 'Notifications for app updates',
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> startUpdateCheck(BuildContext context) async {
    _currentContext = context;
    await checkForUpdate(context);
  }

  Future<void> checkForUpdate(BuildContext context) async {
    if (_isDownloading || _isDialogShowing) return;

    try {
      final updateInfo = await _compareVersions();
      if (updateInfo != null && !_isDialogShowing) {
        final canShowDialog = _lastDismissedTime == null ||
            DateTime.now().difference(_lastDismissedTime!) >
                Duration(minutes: updateInfo['reminder_delay'] ?? 2);

        if (canShowDialog) {
          _showUpdateNotification(updateInfo);
          if (context.mounted) {
            await showUpdateDialog(context, updateInfo);
          }
        }
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  Future<void> _showUpdateNotification(Map<String, dynamic> updateInfo) async {
    const androidDetails = AndroidNotificationDetails(
      'update_channel',
      'App Updates',
      channelDescription: 'Notifications for app updates',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
    );

    await _notificationsPlugin.show(
      0,
      'Pembaruan Tersedia',
      'Versi ${updateInfo['version']} telah tersedia! Ketuk untuk mengupdate.',
      const NotificationDetails(android: androidDetails),
      payload: 'update',
    );
  }

  Future<Map<String, dynamic>?> _compareVersions() async {
    try {
      final response = await http.get(Uri.parse(VERSION_CHECK_URL));
      if (response.statusCode != 200) return null;

      final remoteConfig = json.decode(response.body);
      final packageInfo = await PackageInfo.fromPlatform();

      final installedVersion = packageInfo.version;
      final installedBuild = int.parse(packageInfo.buildNumber);
      final remoteVersion = remoteConfig['version'].toString();
      final remoteBuild = remoteConfig['build_number'] as int;

      final needsUpdate = _isUpdateRequired(
        installedVersion,
        installedBuild,
        remoteVersion,
        remoteBuild,
      );

      return needsUpdate ? remoteConfig : null;
    } catch (e) {
      debugPrint('Version comparison error: $e');
      return null;
    }
  }

  Future<void> downloadAndInstallUpdate(
    String url,
    Function(double) onProgress,
  ) async {
    if (_isDownloading) return;

    _isDownloading = true;
    await WakelockPlus.enable();

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/app-update.apk';

      await _downloadWithRetry(url, savePath, onProgress);
      await _installUpdate(savePath);
    } finally {
      await WakelockPlus.disable();
      _isDownloading = false;
    }
  }

  Future<void> _downloadWithRetry(
    String url,
    String savePath,
    Function(double) onProgress,
  ) async {
    final dio = Dio();
    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        // Pastikan file lama dihapus jika ada
        final file = File(savePath);
        if (await file.exists()) {
          await file.delete();
        }

        debugPrint('Starting download from: $url');
        debugPrint('Saving to: $savePath');

        // Download file
        await dio.download(
          url,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = received / total;
              onProgress(progress);
              debugPrint(
                  'Download progress: ${(progress * 100).toStringAsFixed(1)}%');
            }
          },
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
            validateStatus: (status) => status! < 500,
            receiveTimeout: const Duration(minutes: 5),
            sendTimeout: const Duration(minutes: 5),
          ),
        );

        debugPrint('Download completed');

        // Verifikasi file yang didownload
        if (await _verifyDownload(savePath)) {
          debugPrint('Download verified successfully');
          return;
        }
        throw Exception('APK verification failed');
      } catch (e) {
        debugPrint('Download error: $e');
        retries++;
        if (retries >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: math.pow(2, retries).toInt()));
      }
    }
  }

  Future<bool> _verifyDownload(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('APK file does not exist');
        return false;
      }

      final fileLength = await file.length();
      if (fileLength < 1024 * 1024) {
        // Minimal 1MB
        debugPrint('APK file too small: ${fileLength ~/ 1024}KB');
        return false;
      }

      // Cukup verifikasi ukuran file saja untuk saat ini
      debugPrint('APK file size verified: ${fileLength ~/ 1024}KB');
      return true;
    } catch (e) {
      debugPrint('APK verification error: $e');
      return false;
    }
  }

  Future<void> _installUpdate(String filePath) async {
    // Pastikan file ada dan valid
    if (!await _verifyDownload(filePath)) {
      throw Exception('Invalid APK file');
    }

    try {
      // Dapatkan permission yang diperlukan
      final status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        throw Exception('Installation permission denied');
      }

      final result = await OpenFile.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        throw Exception('APK installation failed: ${result.message}');
      }

      // Clean up dan exit setelah delay singkat
      await Future.delayed(const Duration(seconds: 2));
      await File(filePath).delete();
      await FlutterExitApp.exitApp(iosForceExit: true);
    } catch (e) {
      debugPrint('Installation error: $e');
      rethrow;
    }
  }

  Future<void> showUpdateDialog(
    BuildContext context,
    Map<String, dynamic> updateInfo,
  ) async {
    _isDialogShowing = true;
    _currentContext = context;

    await showDialog(
      context: context,
      barrierDismissible: !updateInfo['force_update'],
      builder: (context) => WillPopScope(
        onWillPop: () async => !updateInfo['force_update'],
        child: UpdateDialog(
          updateInfo: updateInfo,
          onDismiss: () {
            _lastDismissedTime = DateTime.now();
          },
        ),
      ),
    );

    _isDialogShowing = false;
  }
}

class UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> updateInfo;
  final VoidCallback onDismiss;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onDismiss,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async =>
          !widget.updateInfo['force_update'] && !_downloading,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.system_update_outlined,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembaruan Tersedia',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Versi ${widget.updateInfo['version']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (widget.updateInfo['force_update'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFCCCC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFFE57373),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pembaruan ini wajib diinstall untuk melanjutkan menggunakan aplikasi.',
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.updateInfo['force_update'] == true)
                const SizedBox(height: 16),
              Text(
                'Yang baru:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List<Widget>.from(
                    (widget.updateInfo['changelog'] as List).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              height: 6,
                              width: 6,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_downloading) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mengunduh pembaruan...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                            minHeight: 10,
                          ),
                        ),
                        if (_progress > 0.05)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(left: 8),
                                height: 4,
                                width: 30 * _progress,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!widget.updateInfo['force_update'])
                      TextButton(
                        onPressed: () {
                          widget.onDismiss();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, // Reduced padding
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Nanti'),
                      ),
                    const SizedBox(width: 8), // Reduced spacing
                    Flexible(
                      // Make button adapt to available space
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() => _downloading = true);
                          try {
                            await UpdateService().downloadAndInstallUpdate(
                              widget.updateInfo['url'],
                              (progress) =>
                                  setState(() => _progress = progress),
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Gagal mengunduh pembaruan: $e'),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, // Reduced padding
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_rounded,
                              size: 18,
                            ),
                            SizedBox(width: 4), // Reduced spacing
                            Text(
                              'Update Sekarang',
                              style: TextStyle(fontSize: 13), // Smaller text
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
