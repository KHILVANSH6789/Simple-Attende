// ============================================================
// lib/providers/update_provider.dart
// ============================================================
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UpdateProvider extends ChangeNotifier {
  static const String _channelName = 'com.simpleattende/updater';
  static const MethodChannel _channel = MethodChannel(_channelName);

  static const String _githubUser = 'KHILVANSH6789';
  static const String _githubRepo = 'Simple-Attende';

  static const String currentVersion = '1.0.3';

  bool _isChecking = false;
  bool _hasUpdate = false;
  String _latestVersion = '';
  String _releaseNotes = '';
  String? _apkUrl;
  String? _releaseHtmlUrl;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  double _downloadedMb = 0.0;
  double _totalMb = 0.0;
  String? _downloadedApkPath;
  String? _statusMessage;
  bool _dismissedBanner = false;

  // Getters
  bool get isChecking => _isChecking;
  bool get hasUpdate => _hasUpdate;
  String get latestVersion => _latestVersion;
  String get releaseNotes => _releaseNotes;
  String? get apkUrl => _apkUrl;
  String? get releaseHtmlUrl => _releaseHtmlUrl;

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  double get downloadedMb => _downloadedMb;
  double get totalMb => _totalMb;
  String? get downloadedApkPath => _downloadedApkPath;
  bool get isReadyToInstall => _downloadedApkPath != null && File(_downloadedApkPath!).existsSync();
  String? get statusMessage => _statusMessage;
  bool get dismissedBanner => _dismissedBanner;

  void dismissBanner() {
    _dismissedBanner = true;
    notifyListeners();
  }

  /// Checks if [remote] version is strictly newer than [current].
  static bool isNewerVersion(String current, String remote) {
    String clean(String v) => v.trim().replaceAll('v', '').split('+').first.split('-').first;
    final cParts = clean(current).split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final rParts = clean(remote).split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (cParts.length < 3) {
      cParts.add(0);
    }
    while (rParts.length < 3) {
      rParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (rParts[i] > cParts[i]) return true;
      if (rParts[i] < cParts[i]) return false;
    }
    return false;
  }

  /// Check GitHub Releases for new version
  Future<bool> checkForUpdates({bool silent = false}) async {
    _isChecking = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
          'https://api.github.com/repos/$_githubUser/$_githubRepo/releases/latest');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final tag = (data['tag_name'] as String? ?? '').replaceAll('v', '');
        final body = data['body'] as String? ?? '';
        final htmlUrl = data['html_url'] as String?;

        // Find APK asset
        String? apkDownload;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            apkDownload = asset['browser_download_url'] as String?;
            break;
          }
        }

        if (tag.isNotEmpty && isNewerVersion(currentVersion, tag)) {
          _hasUpdate = true;
          _latestVersion = tag;
          _releaseNotes = body;
          _releaseHtmlUrl = htmlUrl;
          _apkUrl = apkDownload;
          _statusMessage = '🎉 New version v$_latestVersion is available!';

          // Trigger native status bar notification
          _triggerSystemNotification(
            title: 'Simple Attende Update Available',
            body: 'Version v$_latestVersion is available. Tap to open and update.',
          );

          _isChecking = false;
          notifyListeners();
          return true;
        } else {
          _hasUpdate = false;
          _statusMessage = '✓ You are on the latest version (v$currentVersion).';
          _isChecking = false;
          notifyListeners();
          return false;
        }
      } else {
        if (!silent) _statusMessage = 'Could not check for updates (server returned ${res.statusCode}).';
      }
    } catch (e) {
      if (!silent) _statusMessage = 'Unable to check for updates. Check internet connection.';
    } finally {
      _isChecking = false;
      notifyListeners();
    }
    return false;
  }

  /// Starts downloading the APK and immediately prompts installation when done
  Future<void> downloadAndInstall() async {
    if (_apkUrl == null || _apkUrl!.isEmpty) {
      _statusMessage = 'No APK download link found for this release.';
      notifyListeners();
      return;
    }

    _isDownloading = true;
    _downloadProgress = 0.0;
    _downloadedMb = 0.0;
    _totalMb = 0.0;
    _statusMessage = 'Downloading update...';
    notifyListeners();

    http.Client? client;
    IOSink? sink;

    try {
      final dir = await getTemporaryDirectory();
      final apkFile = File('${dir.path}/Simple-Attende-v$_latestVersion.apk');

      // If file already exists and is non-empty, remove it before downloading fresh
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      client = http.Client();
      final req = http.Request('GET', Uri.parse(_apkUrl!));
      final response = await client.send(req);

      final totalBytes = response.contentLength ?? 0;
      _totalMb = totalBytes > 0 ? (totalBytes / (1024 * 1024)) : 0.0;
      int receivedBytes = 0;

      sink = apkFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        _downloadedMb = receivedBytes / (1024 * 1024);
        if (totalBytes > 0) {
          _downloadProgress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
        }
        notifyListeners();
      }

      await sink.flush();
      await sink.close();
      sink = null;

      _downloadProgress = 1.0;
      _downloadedApkPath = apkFile.path;
      _isDownloading = false;
      _statusMessage = 'Download complete! Opening installer...';
      notifyListeners();

      // Launch package installer
      await installDownloadedApk();
    } catch (e) {
      _isDownloading = false;
      _statusMessage = 'Download failed: $e';
      notifyListeners();
    } finally {
      client?.close();
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
    }
  }

  /// Prompts the Android OS package installer to install the downloaded APK
  Future<bool> installDownloadedApk() async {
    if (_downloadedApkPath == null) return false;
    final file = File(_downloadedApkPath!);
    if (!file.existsSync()) return false;

    try {
      final result = await _channel.invokeMethod<bool>(
        'installApk',
        {'path': _downloadedApkPath},
      );
      return result ?? true;
    } catch (e) {
      _statusMessage = 'Failed to launch installer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _triggerSystemNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
      });
    } catch (_) {
      // Notifications might be disabled or denied, which is fine
    }
  }
}
